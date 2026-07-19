package com.example.drivetracker.drive_tracker

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import java.util.*
import org.json.JSONArray
import org.json.JSONObject

class TrackingService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    // Telemetry tracking state variables
    private var isTracking = false
    private var startTimeMillis: Long = 0
    private var lastLocation: Location? = null
    
    private var accumulatedDistanceMeters: Double = 0.0
    private var maxSpeedMetersPerSec: Double = 0.0
    private var drivingTimeSeconds: Int = 0
    private var stoppedTimeSeconds: Int = 0
    private var pointCount: Int = 0
    private var speedSumMetersPerSec: Double = 0.0

    // Speed smoothing & drift filter variables
    private var smoothedSpeed: Double = -1.0
    private val MIN_SPEED_METERS_PER_SEC = 1.0 / 3.6 // 1 km/h threshold
    private val SPEED_SMOOTHING_ALPHA = 0.3 // EMA alpha parameter

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
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
    }

    override fun onDestroy() {
        isServiceRunning = false
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
        isTracking = true
        startTimeMillis = System.currentTimeMillis()
        accumulatedDistanceMeters = 0.0
        maxSpeedMetersPerSec = 0.0
        drivingTimeSeconds = 0
        stoppedTimeSeconds = 0
        pointCount = 0
        speedSumMetersPerSec = 0.0
        smoothedSpeed = -1.0
        lastLocation = null
        locationHistory.clear()

        // Start Foreground Notification
        val notification = buildNotification("Drive Tracker active", "Initializing GPS connection...")
        startForeground(NOTIFICATION_ID, notification)

        // Setup Location Request to update every 1 second (High Accuracy)
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
    }

    private fun processNewLocation(location: Location) {
        // 1. Ignore bad GPS points (accuracy worse than 30 meters)
        if (location.accuracy > 30.0f) {
            return
        }

        val lastLoc = lastLocation

        // 2. Exponential Moving Average (EMA) speed smoothing
        val rawSpeed = location.speed.toDouble()
        val currentSpeed = if (rawSpeed < MIN_SPEED_METERS_PER_SEC) 0.0 else rawSpeed

        smoothedSpeed = if (smoothedSpeed < 0.0) {
            currentSpeed
        } else {
            (SPEED_SMOOTHING_ALPHA * currentSpeed) + ((1.0 - SPEED_SMOOTHING_ALPHA) * smoothedSpeed)
        }

        // 3. Ignore speeds under 1 km/h (treating them as 0.0 to prevent odometer drift)
        val speedMps = if (smoothedSpeed < MIN_SPEED_METERS_PER_SEC) 0.0 else smoothedSpeed

        // 4. Update travel time and offset odometer only if moving
        if (lastLoc != null) {
            val timeDeltaSeconds = ((location.time - lastLoc.time) / 1000L).toInt().coerceAtLeast(0)
            if (speedMps >= MIN_SPEED_METERS_PER_SEC) {
                val distance = lastLoc.distanceTo(location)
                accumulatedDistanceMeters += distance
                drivingTimeSeconds += timeDeltaSeconds
            } else {
                stoppedTimeSeconds += timeDeltaSeconds
            }
        } else {
            startTimeMillis = location.time
        }

        // Speed aggregates
        if (speedMps > maxSpeedMetersPerSec) {
            maxSpeedMetersPerSec = speedMps
        }
        speedSumMetersPerSec += speedMps
        pointCount++

        lastLocation = location

        // Heading and Altitude values
        val heading = if (location.hasBearing()) location.bearing.toDouble() else 0.0
        val altitude = if (location.hasAltitude()) location.altitude else 0.0

        // Save coordinate fix to history
        val point = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "speed" to speedMps,
            "accuracy" to location.accuracy.toDouble(),
            "heading" to heading,
            "altitude" to altitude,
            "timestamp" to location.time
        )
        locationHistory.add(point)

        // Calculate current metrics for notification displays
        val currentSpeedKmh = speedMps * 3.6
        val distanceKm = accumulatedDistanceMeters / 1000.0

        // Update Notification content
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
            speedMps = speedMps,
            maxSpeedMps = maxSpeedMetersPerSec,
            avgSpeedMps = if (drivingTimeSeconds + stoppedTimeSeconds > 0) accumulatedDistanceMeters / (drivingTimeSeconds + stoppedTimeSeconds) else 0.0,
            distanceMeters = accumulatedDistanceMeters,
            drivingSec = drivingTimeSeconds,
            stoppedSec = stoppedTimeSeconds,
            heading = heading,
            altitude = altitude
        )
    }

    private fun sendTelemetryBroadcast(
        speedMps: Double,
        maxSpeedMps: Double,
        avgSpeedMps: Double,
        distanceMeters: Double,
        drivingSec: Int,
        stoppedSec: Int,
        heading: Double,
        altitude: Double
    ) {
        val intent = Intent(BROADCAST_TELEMETRY).apply {
            putExtra("currentSpeed", speedMps)
            putExtra("maxSpeed", maxSpeedMps)
            putExtra("averageSpeed", avgSpeedMps)
            putExtra("distance", distanceMeters)
            putExtra("drivingTime", drivingSec)
            putExtra("stopTime", stoppedSec)
            putExtra("heading", heading)
            putExtra("altitude", altitude)
        }
        sendBroadcast(intent)
    }

    private fun stopTrackingService() {
        if (!isTracking) return
        isTracking = false

        fusedLocationClient.removeLocationUpdates(locationCallback)

        // Convert locations list to JSON format
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

        // Broadcast Stopped state with full coordinates payload
        val intent = Intent(BROADCAST_STOPPED).apply {
            putExtra("historyJson", jsonArray.toString())
            putExtra("startTime", startTimeMillis)
            putExtra("endTime", System.currentTimeMillis())
            putExtra("maxSpeed", maxSpeedMetersPerSec)
            putExtra("averageSpeed", if (drivingTimeSeconds + stoppedTimeSeconds > 0) accumulatedDistanceMeters / (drivingTimeSeconds + stoppedTimeSeconds) else 0.0)
            putExtra("distance", accumulatedDistanceMeters)
            putExtra("drivingTime", drivingTimeSeconds)
            putExtra("stopTime", stoppedTimeSeconds)
        }
        sendBroadcast(intent)

        stopForeground(true)
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
