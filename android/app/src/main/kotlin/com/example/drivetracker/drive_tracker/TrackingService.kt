package com.example.drivetracker.drive_tracker

import android.annotation.SuppressLint
import android.app.*
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONArray
import org.json.JSONObject

class TrackingService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    // Ticker properties for 1-second updates
    private var tickerHandler: Handler? = null
    private var tickerRunnable: Runnable? = null

    // Telemetry tracking variables
    private var isTracking = false
    private var startTimeMillis: Long = 0
    private var lastLocation: Location? = null
    
    private var accumulatedDistanceMeters: Double = 0.0
    private var maxSpeedMetersPerSec: Double = 0.0
    private var drivingTimeSeconds: Int = 0
    private var stoppedTimeSeconds: Int = 0
    private var pointCount: Int = 0
    private var speedSumMetersPerSec: Double = 0.0

    // Speed smoothing filter configurations
    private var smoothedSpeed: Double = -1.0
    private val SPEED_SMOOTHING_ALPHA = 0.3 // EMA alpha

    // State machine parameters for stopped durations
    private var currentSpeedMps: Double = 0.0
    private var isVehicleStopped: Boolean = true // Start as stopped
    private var consecutiveStoppedSeconds: Int = 0

    private val MOVING_SPEED_THRESHOLD_MPS = 3.0 / 3.6 // 3 km/h = 0.833 m/s
    private val STOPPED_CRITERIA_DURATION_SECONDS = 5

    // List of coordinates recorded
    private val locationHistory = mutableListOf<Map<String, Any>>()

    companion object {
        const val CHANNEL_ID = "tracking_service_channel"
        const val NOTIFICATION_ID = 4567

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        
        // Broadcast signals to MainActivity
        const val BROADCAST_TELEMETRY = "com.example.drivetracker.TELEMETRY_UPDATE"
        const val BROADCAST_STOPPED = "com.example.drivetracker.TRACKING_STOPPED"

        var isServiceRunning = false
        
        // Expose active tracking instance to MainActivity MethodChannel
        @Volatile
        var activeInstance: TrackingService? = null
    }

    // Telemetry state getters for MethodChannel recovery
    fun getStartTime(): Long = startTimeMillis
    fun getCurrentSpeedMps(): Double = currentSpeedMps
    fun getMaxSpeedMetersPerSec(): Double = maxSpeedMetersPerSec
    fun getAverageSpeedMps(): Double = if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0
    fun getAccumulatedDistanceMeters(): Double = accumulatedDistanceMeters
    fun getDrivingTimeSeconds(): Int = drivingTimeSeconds
    fun getStoppedTimeSeconds(): Int = stoppedTimeSeconds

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
    }

    override fun onDestroy() {
        stopTelemetryTicker()
        isServiceRunning = false
        if (activeInstance == this) {
            activeInstance = null
        }
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                if (!isTracking) {
                    startTrackingService()
                }
            }
            ACTION_STOP -> {
                stopTrackingService()
            }
        }
        return START_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun startTrackingService() {
        isServiceRunning = true
        activeInstance = this
        isTracking = true
        startTimeMillis = System.currentTimeMillis()
        accumulatedDistanceMeters = 0.0
        maxSpeedMetersPerSec = 0.0
        drivingTimeSeconds = 0
        stoppedTimeSeconds = 0
        pointCount = 0
        speedSumMetersPerSec = 0.0
        smoothedSpeed = -1.0
        currentSpeedMps = 0.0
        isVehicleStopped = true
        consecutiveStoppedSeconds = 0
        lastLocation = null
        locationHistory.clear()

        // Start Foreground Notification
        val notification = buildNotification("Drive Tracker active", "Initializing GPS connection...")
        startForeground(NOTIFICATION_ID, notification)

        // Setup Location Request to update every 1 second
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000L).apply {
            setMinUpdateIntervalMillis(1000L)
            setMinUpdateDistanceMeters(0.0f)
        }.build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (location in locationResult.locations) {
                    processNewLocation(location)
                }
            }
        }

        if (hasAccessPermissions()) {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
        } else {
            stopSelf()
        }

        // Start 1-Second Telemetry Ticker
        startTelemetryTicker()
    }

    private fun startTelemetryTicker() {
        stopTelemetryTicker()
        tickerHandler = Handler(Looper.getMainLooper())
        tickerRunnable = object : Runnable {
            override fun run() {
                if (isTracking) {
                    tickTelemetry()
                    tickerHandler?.postDelayed(this, 1000L)
                }
            }
        }
        tickerHandler?.postDelayed(tickerRunnable!!, 1000L)
    }

    private fun stopTelemetryTicker() {
        tickerRunnable?.let {
            tickerHandler?.removeCallbacks(it)
            tickerRunnable = null
        }
        tickerHandler = null
    }

    private fun tickTelemetry() {
        // Run state machine checks
        if (currentSpeedMps < MOVING_SPEED_THRESHOLD_MPS) {
            // Speed is below 3 km/h
            if (!isVehicleStopped) {
                // Currently considered MOVING
                consecutiveStoppedSeconds++
                if (consecutiveStoppedSeconds > STOPPED_CRITERIA_DURATION_SECONDS) {
                    // Staid below 3 km/h for >5 seconds -> Transition to STOPPED state
                    isVehicleStopped = true
                    
                    // Retroactively adjust duration properties
                    drivingTimeSeconds = (drivingTimeSeconds - consecutiveStoppedSeconds).coerceAtLeast(0)
                    stoppedTimeSeconds += consecutiveStoppedSeconds
                    consecutiveStoppedSeconds = 0
                } else {
                    // Continue counting as moving for now
                    drivingTimeSeconds++
                }
            } else {
                // Alread in STOPPED state
                stoppedTimeSeconds++
            }
        } else {
            // Speed is at or above 3 km/h -> Transition to MOVING immediately
            if (isVehicleStopped) {
                isVehicleStopped = false
                lastLocation = null // Reset last position to avoid calculation gaps
            }
            consecutiveStoppedSeconds = 0
            drivingTimeSeconds++
        }

        // Calculate statistics
        val currentSpeedKmh = currentSpeedMps * 3.6
        val distanceKm = accumulatedDistanceMeters / 1000.0
        val avgSpeedMps = if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0

        // Live notification content
        val textContent = String.format(
            Locale.US,
            "Distance: %.2f km | Speed: %.1f km/h",
            distanceKm,
            currentSpeedKmh
        )
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, buildNotification("Active Tracking", textContent))

        // Broadcast stats back to MainActivity
        sendTelemetryBroadcast(
            speedMps = currentSpeedMps,
            maxSpeedMps = maxSpeedMetersPerSec,
            avgSpeedMps = avgSpeedMps,
            distanceMeters = accumulatedDistanceMeters,
            drivingSec = drivingTimeSeconds,
            stoppedSec = stoppedTimeSeconds
        )
    }

    private fun processNewLocation(location: Location) {
        // Ignore bad GPS points (accuracy > 30 meters)
        if (location.accuracy > 30.0f) {
            return
        }

        val lastLoc = lastLocation

        // Exponential Moving Average speed smoothing integration
        val rawSpeed = location.speed.toDouble()
        smoothedSpeed = if (smoothedSpeed < 0.0) {
            rawSpeed
        } else {
            (SPEED_SMOOTHING_ALPHA * rawSpeed) + ((1.0 - SPEED_SMOOTHING_ALPHA) * smoothedSpeed)
        }

        // Speed is set according to EMA smoothing
        currentSpeedMps = smoothedSpeed

        // Accumulate distance increments only if vehicle is in MOVING state
        if (!isVehicleStopped && lastLoc != null) {
            val distance = lastLoc.distanceTo(location)
            accumulatedDistanceMeters += distance
        }

        // Max Speed updates
        if (currentSpeedMps > maxSpeedMetersPerSec) {
            maxSpeedMetersPerSec = currentSpeedMps
        }
        speedSumMetersPerSec += currentSpeedMps
        pointCount++

        lastLocation = location

        // Heading and Altitude logs
        val heading = if (location.hasBearing()) location.bearing.toDouble() else 0.0
        val altitude = if (location.hasAltitude()) location.altitude else 0.0

        // Parse coordinate node
        val point = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "speed" to currentSpeedMps,
            "accuracy" to location.accuracy.toDouble(),
            "heading" to heading,
            "altitude" to altitude,
            "timestamp" to location.time
        )
        locationHistory.add(point)
    }

    private fun sendTelemetryBroadcast(
        speedMps: Double,
        maxSpeedMps: Double,
        avgSpeedMps: Double,
        distanceMeters: Double,
        drivingSec: Int,
        stoppedSec: Int
    ) {
        val intent = Intent(BROADCAST_TELEMETRY).apply {
            putExtra("currentSpeed", speedMps)
            putExtra("maxSpeed", maxSpeedMps)
            putExtra("averageSpeed", avgSpeedMps)
            putExtra("distance", distanceMeters)
            putExtra("drivingTime", drivingSec)
            putExtra("stopTime", stoppedSec)
            putExtra("heading", if (locationHistory.isNotEmpty()) locationHistory.last()["heading"] as Double else 0.0)
            putExtra("altitude", if (locationHistory.isNotEmpty()) locationHistory.last()["altitude"] as Double else 0.0)
        }
        sendBroadcast(intent)
    }

    private fun saveRideToSQLiteNatively() {
        try {
            val dbFile = getDatabasePath("drive_tracker.db")
            if (!dbFile.exists()) {
                Log.e("TrackingService", "SQLite file doesn't exist yet, skipping native insert.")
                return
            }

            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            Log.d("TrackingService", "Connecting to drive_tracker.db natively...")

            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val startStr = format.format(Date(startTimeMillis)) + "Z"
            val endStr = format.format(Date(System.currentTimeMillis())) + "Z"

            val averageSpeedVal = if (drivingTimeSeconds > 0) (accumulatedDistanceMeters / drivingTimeSeconds) else 0.0

            db.beginTransaction()
            try {
                // 1. Insert completed drive record
                val rideValues = ContentValues().apply {
                    put("startTime", startStr)
                    put("endTime", endStr)
                    put("maxSpeed", maxSpeedMetersPerSec * 3.6) // km/h
                    put("averageSpeed", averageSpeedVal * 3.6) // km/h
                    put("distance", accumulatedDistanceMeters / 1000.0) // km
                    put("drivingTime", drivingTimeSeconds)
                    put("stopTime", stoppedTimeSeconds)
                    put("createdAt", endStr)
                }
                val rideId = db.insert("rides", null, rideValues)
                Log.d("TrackingService", "Saved ride row: ID = $rideId")

                // 2. Insert trace nodes
                if (rideId != -1L) {
                    for (item in locationHistory) {
                        val locValues = ContentValues().apply {
                            put("rideId", rideId)
                            put("latitude", item["latitude"] as Double)
                            put("longitude", item["longitude"] as Double)
                            put("speed", (item["speed"] as Double) * 3.6) // km/h
                            put("accuracy", item["accuracy"] as Double)
                            put("heading", item["heading"] as Double)
                            put("altitude", item["altitude"] as Double)

                            val logTime = item["timestamp"] as Long
                            val logTimeStr = format.format(Date(logTime)) + "Z"
                            put("timestamp", logTimeStr)
                        }
                        db.insert("ride_locations", null, locValues)
                    }
                    Log.d("TrackingService", "Successfully saved ${locationHistory.size} locations natively.")
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
            db.close()
        } catch (e: Exception) {
            Log.e("TrackingService", "Failed to natively save ride to SQLite", e)
        }
    }

    private fun stopTrackingService() {
        if (!isTracking) return
        isTracking = false

        stopTelemetryTicker()
        fusedLocationClient.removeLocationUpdates(locationCallback)

        // Natively write track and locations straight to SQLite database
        saveRideToSQLiteNatively()

        // Convert locations list to JSON format matching stream format
        val jsonArray = JSONArray()
        for (item in locationHistory) {
            val obj = JSONObject().apply {
                put("latitude", item["latitude"])
                put("longitude", item["longitude"])
                put("speed", item["speed"])
                put("accuracy", item["accuracy"])
                put("heading", item["heading"])
                put("altitude", item["altitude"])
                put("timestamp", item["timestamp"])
            }
            jsonArray.put(obj)
        }

        // Broadcast Stopped state with retroactive log metadata
        val intent = Intent(BROADCAST_STOPPED).apply {
            putExtra("historyJson", jsonArray.toString())
            putExtra("startTime", startTimeMillis)
            putExtra("endTime", System.currentTimeMillis())
            putExtra("maxSpeed", maxSpeedMetersPerSec)
            putExtra("averageSpeed", if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0)
            putExtra("distance", accumulatedDistanceMeters)
            putExtra("drivingTime", drivingTimeSeconds)
            putExtra("stopTime", stoppedTimeSeconds)
        }
        sendBroadcast(intent)

        stopForeground(true)
        if (activeInstance == this) {
            activeInstance = null
        }
        stopSelf()
    }

    private fun buildNotification(title: String, content: String): Notification {
        val stopIntent = Intent(this, TrackingService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val clickIntent = Intent(this, MainActivity::class.java)
        val clickPendingIntent = PendingIntent.getActivity(
            this,
            0,
            clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(clickPendingIntent)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop Tracking", stopPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Drive Tracking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors current GPS coordinates in real-time"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun hasAccessPermissions(): Boolean {
        val fineLocation = ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION)
        return fineLocation == PackageManager.PERMISSION_GRANTED
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
