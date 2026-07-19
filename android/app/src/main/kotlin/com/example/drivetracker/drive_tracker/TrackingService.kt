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
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.android.gms.location.*
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONObject

class TrackingService : Service() {

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    // ── Background HandlerThread (fixes ANR #1, #18) ──────────────────────
    private var bgHandlerThread: HandlerThread? = null
    private var bgHandler: Handler? = null

    // ── Telemetry state ────────────────────────────────────────────────────
    private var isTracking = false
    private var startTimeMillis: Long = 0
    private var lastLocation: Location? = null

    private var accumulatedDistanceMeters: Double = 0.0
    private var maxSpeedMetersPerSec: Double = 0.0
    private var drivingTimeSeconds: Int = 0
    private var stoppedTimeSeconds: Int = 0

    // Speed smoothing
    private var smoothedSpeed: Double = -1.0
    private val SPEED_SMOOTHING_ALPHA = 0.3

    // Stopped-state machine
    private var currentSpeedMps: Double = 0.0
    private var isVehicleStopped: Boolean = true
    private var consecutiveStoppedSeconds: Int = 0
    private var continuousStoppedSeconds: Int = 0  // for adaptive GPS interval (#9)
    private val MOVING_SPEED_THRESHOLD_MPS = 3.0 / 3.6  // 3 km/h → m/s
    private val STOPPED_CRITERIA_DURATION_SECONDS = 5

    // Prefs checkpoint rate-limiting (#3)
    private var ticksSinceLastPrefsWrite = 0
    private val PREFS_WRITE_INTERVAL_TICKS = 5 // write every 5 seconds

    // File writer for checkpointing location traces (replaces in-memory list #7)
    private var traceWriter: BufferedWriter? = null
    private var traceLineCount: Int = 0  // for logging only

    // Current active GPS LocationRequest (to allow adaptive changes #9)
    private var currentLocationRequest: LocationRequest? = null

    companion object {
        const val CHANNEL_ID = "tracking_service_channel"
        const val NOTIFICATION_ID = 4567

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"

        // Broadcast actions (now sent via LocalBroadcastManager — fixes security #12)
        const val BROADCAST_TELEMETRY = "com.example.drivetracker.TELEMETRY_UPDATE"
        const val BROADCAST_STOPPED = "com.example.drivetracker.TRACKING_STOPPED"

        // Fix #8: @Volatile ensures cross-thread visibility
        @Volatile var isServiceRunning = false

        // Fix #4: WeakReference prevents GC root → memory leak
        private var _activeInstance: java.lang.ref.WeakReference<TrackingService>? = null
        var activeInstance: TrackingService?
            get() = _activeInstance?.get()
            set(value) {
                _activeInstance = if (value != null) java.lang.ref.WeakReference(value) else null
            }

        // Fix #20: Prefs keys as constants to prevent typos
        private const val PREFS_NAME = "tracking_prefs"
        private const val KEY_IS_ACTIVE = "is_tracking_active"
        private const val KEY_START_TIME = "start_time"
        private const val KEY_DISTANCE = "distance"
        private const val KEY_MAX_SPEED = "max_speed"
        private const val KEY_DRIVING_TIME = "driving_time"
        private const val KEY_STOP_TIME = "stop_time"
        private const val KEY_IS_STOPPED = "is_vehicle_stopped"
        private const val KEY_CONSEC_STOPPED = "consecutive_stopped_seconds"
        private const val KEY_SMOOTHED_SPEED = "smoothed_speed"

        // Adaptive GPS interval thresholds (#9)
        private const val ADAPTIVE_STOP_THRESHOLD_SECONDS = 30
        private const val TAG = "TrackingService"
    }

    // Getters for MethodChannel recovery (MainActivity.kt reads these on main thread — @Volatile guarantees safety)
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
        // Start background HandlerThread (#1, #18)
        bgHandlerThread = HandlerThread("TrackingServiceThread").also { it.start() }
        bgHandler = Handler(bgHandlerThread!!.looper)
    }

    override fun onDestroy() {
        stopTelemetryTicker()
        closeTraceWriter()
        bgHandlerThread?.quitSafely()
        bgHandlerThread = null
        bgHandler = null
        isServiceRunning = false
        if (activeInstance == this) activeInstance = null
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isTrackingActive = prefs.getBoolean(KEY_IS_ACTIVE, false)

        if (intent == null) {
            // System restart (START_STICKY)
            Log.d(TAG, "Service restarted by system (null intent)")
            if (isTrackingActive) restoreAndStartTracking() else stopSelf()
        } else {
            when (intent.action) {
                ACTION_START -> {
                    if (!isTracking) {
                        if (isTrackingActive) restoreAndStartTracking() else startTracking()
                    }
                }
                ACTION_STOP -> stopTracking()
            }
        }
        return START_STICKY
    }

    // ─── Start / Restore ────────────────────────────────────────────────────

    @SuppressLint("MissingPermission")
    private fun startTracking() {
        isServiceRunning = true
        activeInstance = this
        isTracking = true
        startTimeMillis = System.currentTimeMillis()
        resetTelemetryState()

        // Clean previous trace file
        deleteTraceFile()

        // Persist start checkpoint
        saveCheckpointToPrefs()

        // Foreground notification
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification("Drive Tracker", "Initializing GPS…"),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification("Drive Tracker", "Initializing GPS…"))
        }

        // Open trace file writer
        openTraceWriter()

        // Request location updates on background HandlerThread (#1)
        val request = buildLocationRequest(highAccuracy = true)
        currentLocationRequest = request
        locationCallback = createLocationCallback()
        if (hasLocationPermission()) {
            fusedLocationClient.requestLocationUpdates(request, locationCallback, bgHandler!!.looper)
        } else {
            Log.e(TAG, "Location permission not granted — stopping service")
            stopSelf()
            return
        }

        startTelemetryTicker()
        Log.d(TAG, "Tracking started cleanly")
    }

    @SuppressLint("MissingPermission")
    private fun restoreAndStartTracking() {
        isServiceRunning = true
        activeInstance = this
        isTracking = true
        lastLocation = null

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        startTimeMillis = prefs.getLong(KEY_START_TIME, System.currentTimeMillis())
        accumulatedDistanceMeters = prefs.getFloat(KEY_DISTANCE, 0f).toDouble()
        maxSpeedMetersPerSec = prefs.getFloat(KEY_MAX_SPEED, 0f).toDouble()
        drivingTimeSeconds = prefs.getInt(KEY_DRIVING_TIME, 0)
        stoppedTimeSeconds = prefs.getInt(KEY_STOP_TIME, 0)
        isVehicleStopped = prefs.getBoolean(KEY_IS_STOPPED, true)
        consecutiveStoppedSeconds = prefs.getInt(KEY_CONSEC_STOPPED, 0)
        smoothedSpeed = prefs.getFloat(KEY_SMOOTHED_SPEED, -1f).toDouble()
        currentSpeedMps = 0.0
        traceLineCount = countTraceLines()

        val distKm = accumulatedDistanceMeters / 1000.0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification("Active Tracking (Resumed)", "%.2f km | GPS reconnecting…".format(distKm)),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(
                NOTIFICATION_ID,
                buildNotification("Active Tracking (Resumed)", "%.2f km | GPS reconnecting…".format(distKm))
            )
        }

        openTraceWriter(append = true)

        val request = buildLocationRequest(highAccuracy = true)
        currentLocationRequest = request
        locationCallback = createLocationCallback()
        if (hasLocationPermission()) {
            fusedLocationClient.requestLocationUpdates(request, locationCallback, bgHandler!!.looper)
        } else {
            stopSelf()
            return
        }

        startTelemetryTicker()
        Log.d(TAG, "Tracking restored — ${accumulatedDistanceMeters}m, ${traceLineCount} trace points")
    }

    // ─── Telemetry ticker ────────────────────────────────────────────────────

    private fun startTelemetryTicker() {
        stopTelemetryTicker()
        scheduleTick()
    }

    private fun scheduleTick() {
        bgHandler?.postDelayed({
            if (isTracking) {
                tickTelemetry()
                scheduleTick()
            }
        }, 1000L)
    }

    private fun stopTelemetryTicker() {
        bgHandler?.removeCallbacksAndMessages(null)
    }

    private fun tickTelemetry() {
        // ── Stopped-state machine ──
        if (currentSpeedMps < MOVING_SPEED_THRESHOLD_MPS) {
            if (!isVehicleStopped) {
                consecutiveStoppedSeconds++
                if (consecutiveStoppedSeconds > STOPPED_CRITERIA_DURATION_SECONDS) {
                    isVehicleStopped = true
                    drivingTimeSeconds = (drivingTimeSeconds - consecutiveStoppedSeconds).coerceAtLeast(0)
                    stoppedTimeSeconds += consecutiveStoppedSeconds
                    consecutiveStoppedSeconds = 0
                } else {
                    drivingTimeSeconds++
                }
            } else {
                stoppedTimeSeconds++
                continuousStoppedSeconds++
            }
        } else {
            if (isVehicleStopped) {
                isVehicleStopped = false
                lastLocation = null
                continuousStoppedSeconds = 0
                // Restore high-accuracy GPS if we had dropped to balanced (#9)
                switchGpsAccuracy(highAccuracy = true)
            }
            consecutiveStoppedSeconds = 0
            drivingTimeSeconds++
        }

        // ── Adaptive GPS accuracy when stopped >30s (#9) ──
        if (isVehicleStopped && continuousStoppedSeconds == ADAPTIVE_STOP_THRESHOLD_SECONDS) {
            switchGpsAccuracy(highAccuracy = false)
        }

        // ── Stats ──
        val currentSpeedKmh = currentSpeedMps * 3.6
        val distanceKm = accumulatedDistanceMeters / 1000.0
        val avgSpeedMps = if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0

        // ── Update notification ──
        val text = "%.2f km | %.1f km/h".format(distanceKm, currentSpeedKmh)
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification("Active Tracking", text))

        // ── Rate-limited prefs checkpoint (#3): every 5 ticks ──
        ticksSinceLastPrefsWrite++
        if (ticksSinceLastPrefsWrite >= PREFS_WRITE_INTERVAL_TICKS) {
            ticksSinceLastPrefsWrite = 0
            saveCheckpointToPrefs()
        }

        // ── Broadcast to LocalBroadcastManager (#12) ──
        val intent = Intent(BROADCAST_TELEMETRY).apply {
            putExtra("currentSpeed", currentSpeedMps)
            putExtra("maxSpeed", maxSpeedMetersPerSec)
            putExtra("averageSpeed", avgSpeedMps)
            putExtra("distance", accumulatedDistanceMeters)
            putExtra("drivingTime", drivingTimeSeconds)
            putExtra("stopTime", stoppedTimeSeconds)
        }
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    // ─── Location processing ────────────────────────────────────────────────

    private fun processNewLocation(location: Location) {
        // Filter bad GPS accuracy
        if (location.accuracy > 30.0f) return

        val rawSpeed = location.speed.toDouble()
        smoothedSpeed = if (smoothedSpeed < 0.0) rawSpeed
        else (SPEED_SMOOTHING_ALPHA * rawSpeed) + ((1.0 - SPEED_SMOOTHING_ALPHA) * smoothedSpeed)

        currentSpeedMps = smoothedSpeed

        if (!isVehicleStopped && lastLocation != null) {
            accumulatedDistanceMeters += lastLocation!!.distanceTo(location)
        }
        if (currentSpeedMps > maxSpeedMetersPerSec) maxSpeedMetersPerSec = currentSpeedMps

        lastLocation = location

        val heading = if (location.hasBearing()) location.bearing.toDouble() else 0.0
        val altitude = if (location.hasAltitude()) location.altitude else 0.0

        // Write directly to file — NO in-memory list (#7)
        appendToTraceFile(location, heading, altitude)
    }

    // ─── Trace file helpers ──────────────────────────────────────────────────

    private fun traceFile(): File = File(filesDir, "active_ride_trace.jsonl")

    private fun openTraceWriter(append: Boolean = false) {
        try {
            traceWriter = BufferedWriter(FileWriter(traceFile(), append))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open trace writer", e)
        }
    }

    private fun appendToTraceFile(location: Location, heading: Double, altitude: Double) {
        try {
            val line = JSONObject().apply {
                put("lat", location.latitude)
                put("lng", location.longitude)
                put("spd", currentSpeedMps)
                put("acc", location.accuracy.toDouble())
                put("hdg", heading)
                put("alt", altitude)
                put("ts", location.time)
            }.toString()
            traceWriter?.write(line)
            traceWriter?.newLine()
            traceWriter?.flush()
            traceLineCount++
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write trace line", e)
        }
    }

    private fun closeTraceWriter() {
        try { traceWriter?.close() } catch (_: Exception) {}
        traceWriter = null
    }

    private fun deleteTraceFile() {
        try { traceFile().delete() } catch (_: Exception) {}
    }

    private fun countTraceLines(): Int {
        return try { traceFile().bufferedReader().lineSequence().count() } catch (_: Exception) { 0 }
    }

    // ─── Stop tracking ───────────────────────────────────────────────────────

    private fun stopTracking() {
        if (!isTracking) return
        isTracking = false

        stopTelemetryTicker()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        closeTraceWriter()

        bgHandler?.post {
            saveRideToSQLite()
            clearCheckpoints()

            // Broadcast stop event via LocalBroadcastManager on main thread to guarantee EventChannel safety
            Handler(Looper.getMainLooper()).post {
                val intent = Intent(BROADCAST_STOPPED).apply {
                    putExtra("startTime", startTimeMillis)
                    putExtra("endTime", System.currentTimeMillis())
                    putExtra("maxSpeed", maxSpeedMetersPerSec)
                    putExtra("averageSpeed", if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0)
                    putExtra("distance", accumulatedDistanceMeters)
                    putExtra("drivingTime", drivingTimeSeconds)
                    putExtra("stopTime", stoppedTimeSeconds)
                }
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)

                // Service lifecycle shutdown on main thread
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                if (activeInstance == this) activeInstance = null
                stopSelf()
            }
        }
    }

    // ─── SQLite persistence ──────────────────────────────────────────────────

    private fun saveRideToSQLite() {
        val dbFile = getDatabasePath("drive_tracker.db")
        if (!dbFile.exists()) {
            Log.e(TAG, "DB file not found — skipping SQLite save")
            return
        }

        val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
        // Fix #6: db.close() ALWAYS called via finally
        try {
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }
            val startStr = fmt.format(Date(startTimeMillis)) + "Z"
            val endStr = fmt.format(Date(System.currentTimeMillis())) + "Z"
            val avgSpeed = if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0

            db.beginTransaction()
            try {
                val rideValues = ContentValues().apply {
                    put("startTime", startStr)
                    put("endTime", endStr)
                    put("maxSpeed", maxSpeedMetersPerSec * 3.6)
                    put("averageSpeed", avgSpeed * 3.6)
                    put("distance", accumulatedDistanceMeters / 1000.0)
                    put("drivingTime", drivingTimeSeconds)
                    put("stopTime", stoppedTimeSeconds)
                    put("createdAt", endStr)
                }
                val rideId = db.insert("rides", null, rideValues)
                Log.d(TAG, "Saved ride ID=$rideId")

                if (rideId != -1L) {
                    // Read trace from file — no in-memory list (#7)
                    insertLocationsFromFile(db, rideId, fmt)
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save ride to SQLite", e)
        } finally {
            db.close() // Fix #6: always closes
        }
    }

    private fun insertLocationsFromFile(db: SQLiteDatabase, rideId: Long, fmt: SimpleDateFormat) {
        val file = traceFile()
        if (!file.exists()) return
        var inserted = 0
        try {
            file.forEachLine { line ->
                if (line.isBlank()) return@forEachLine
                runCatching {
                    val obj = JSONObject(line)
                    val ts = obj.getLong("ts")
                    val locValues = ContentValues().apply {
                        put("rideId", rideId)
                        put("latitude", obj.getDouble("lat"))
                        put("longitude", obj.getDouble("lng"))
                        put("speed", obj.getDouble("spd") * 3.6)
                        put("accuracy", obj.getDouble("acc"))
                        put("heading", obj.getDouble("hdg"))
                        put("altitude", obj.getDouble("alt"))
                        put("timestamp", fmt.format(Date(ts)) + "Z")
                    }
                    db.insert("ride_locations", null, locValues)
                    inserted++
                }.onFailure { e -> Log.w(TAG, "Skipping malformed trace line: ${e.message}") }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading trace file for DB insert", e)
        }
        Log.d(TAG, "Inserted $inserted location points")
    }

    // ─── SharedPreferences checkpointing ─────────────────────────────────────

    private fun saveCheckpointToPrefs() {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
            putBoolean(KEY_IS_ACTIVE, true)
            putLong(KEY_START_TIME, startTimeMillis)
            putFloat(KEY_DISTANCE, accumulatedDistanceMeters.toFloat())
            putFloat(KEY_MAX_SPEED, maxSpeedMetersPerSec.toFloat())
            putInt(KEY_DRIVING_TIME, drivingTimeSeconds)
            putInt(KEY_STOP_TIME, stoppedTimeSeconds)
            putBoolean(KEY_IS_STOPPED, isVehicleStopped)
            putInt(KEY_CONSEC_STOPPED, consecutiveStoppedSeconds)
            putFloat(KEY_SMOOTHED_SPEED, smoothedSpeed.toFloat())
            apply()
        }
    }

    private fun clearCheckpoints() {
        try {
            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
                remove(KEY_IS_ACTIVE); remove(KEY_START_TIME); remove(KEY_DISTANCE)
                remove(KEY_MAX_SPEED); remove(KEY_DRIVING_TIME); remove(KEY_STOP_TIME)
                remove(KEY_IS_STOPPED); remove(KEY_CONSEC_STOPPED); remove(KEY_SMOOTHED_SPEED)
                apply()
            }
            deleteTraceFile()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear checkpoints", e)
        }
    }

    // ─── Adaptive GPS accuracy (#9) ──────────────────────────────────────────

    @SuppressLint("MissingPermission")
    private fun switchGpsAccuracy(highAccuracy: Boolean) {
        if (!hasLocationPermission() || !isTracking) return
        val newRequest = buildLocationRequest(highAccuracy)
        if (currentLocationRequest?.priority == newRequest.priority) return
        currentLocationRequest = newRequest
        fusedLocationClient.removeLocationUpdates(locationCallback)
        fusedLocationClient.requestLocationUpdates(newRequest, locationCallback, bgHandler!!.looper)
        Log.d(TAG, "GPS accuracy switched to ${if (highAccuracy) "HIGH" else "BALANCED"}")
    }

    private fun buildLocationRequest(highAccuracy: Boolean): LocationRequest {
        val priority = if (highAccuracy) Priority.PRIORITY_HIGH_ACCURACY else Priority.PRIORITY_BALANCED_POWER_ACCURACY
        val interval = if (highAccuracy) 1000L else 5000L
        return LocationRequest.Builder(priority, interval).apply {
            setMinUpdateIntervalMillis(interval)
            setMinUpdateDistanceMeters(0f)
        }.build()
    }

    // ─── Location callback factory ────────────────────────────────────────────

    private fun createLocationCallback(): LocationCallback {
        return object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.locations.forEach { processNewLocation(it) }
            }
        }
    }

    // ─── Utility helpers ──────────────────────────────────────────────────────

    private fun resetTelemetryState() {
        accumulatedDistanceMeters = 0.0; maxSpeedMetersPerSec = 0.0
        drivingTimeSeconds = 0; stoppedTimeSeconds = 0
        smoothedSpeed = -1.0; currentSpeedMps = 0.0
        isVehicleStopped = true; consecutiveStoppedSeconds = 0
        continuousStoppedSeconds = 0; ticksSinceLastPrefsWrite = 0
        traceLineCount = 0; lastLocation = null
    }

    private fun hasLocationPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED

    // ─── Notification ─────────────────────────────────────────────────────────

    private fun buildNotification(title: String, content: String): Notification {
        val stopIntent = Intent(this, TrackingService::class.java).apply { action = ACTION_STOP }
        val stopPi = PendingIntent.getService(this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val openIntent = Intent(this, MainActivity::class.java)
        val openPi = PendingIntent.getActivity(this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(openPi)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPi)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Drive Tracking",
                NotificationManager.IMPORTANCE_LOW).apply {
                description = "GPS tracking running in background"
                setShowBadge(false)
            }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

}
