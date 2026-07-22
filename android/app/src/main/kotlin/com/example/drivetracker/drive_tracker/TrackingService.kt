package com.example.drivetracker.drive_tracker

import android.app.*
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONObject

class TrackingService : Service() {

    private var bgHandlerThread: HandlerThread? = null
    private var bgHandler: Handler? = null

    private var currentTracker: ActivityTracker? = null
    private var isTracking = false
    private var startTimeMillis: Long = 0
    private var activityType: String = "driving" // Default

    private var ticksSinceLastPrefsWrite = 0
    private val PREFS_WRITE_INTERVAL_TICKS = 5

    companion object {
        const val CHANNEL_ID = "tracking_service_channel"
        const val NOTIFICATION_ID = 4567

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"

        const val BROADCAST_TELEMETRY = "com.example.drivetracker.TELEMETRY_UPDATE"
        const val BROADCAST_STOPPED = "com.example.drivetracker.TRACKING_STOPPED"

        @Volatile var isServiceRunning = false

        private var _activeInstance: java.lang.ref.WeakReference<TrackingService>? = null
        var activeInstance: TrackingService?
            get() = _activeInstance?.get()
            set(value) {
                _activeInstance = if (value != null) java.lang.ref.WeakReference(value) else null
            }

        private const val PREFS_NAME = "tracking_prefs"
        private const val KEY_IS_ACTIVE = "is_tracking_active"
        private const val KEY_START_TIME = "start_time"
        private const val KEY_ACTIVITY_TYPE = "activity_type"

        private const val TAG = "TrackingService"
    }

    // Getters for MainActivity
    fun getStartTime(): Long = startTimeMillis
    fun getActivityType(): String = activityType
    fun getLatestTelemetry(): Map<String, Any> = currentTracker?.tick() ?: emptyMap()

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        bgHandlerThread = HandlerThread("TrackingServiceThread").also { it.start() }
        bgHandler = Handler(bgHandlerThread!!.looper)
    }

    override fun onDestroy() {
        stopTelemetryTicker()
        currentTracker?.stop()
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
            if (isTrackingActive) restoreAndStartTracking() else stopSelf()
        } else {
            when (intent.action) {
                ACTION_START -> {
                    if (!isTracking) {
                        val requestedType = intent.getStringExtra("activityType") ?: "driving"
                        if (isTrackingActive) restoreAndStartTracking() else startTracking(requestedType)
                    }
                }
                ACTION_STOP -> stopTracking()
            }
        }
        return START_STICKY
    }

    private fun startTracking(type: String) {
        Log.d("TrackerTrace", "[TrackingService] startTracking: type=$type")
        isServiceRunning = true
        activeInstance = this
        isTracking = true
        startTimeMillis = System.currentTimeMillis()
        activityType = type

        currentTracker = if (activityType == "walking") WalkingTracker(this, bgHandler!!.looper) else DrivingTracker(this, bgHandler!!.looper)
        
        saveCheckpointToPrefs()
        startForegroundNotification("Initializing GPS…")
        currentTracker?.start()
        startTelemetryTicker()
    }

    private fun restoreAndStartTracking() {
        isServiceRunning = true
        activeInstance = this
        isTracking = true

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        startTimeMillis = prefs.getLong(KEY_START_TIME, System.currentTimeMillis())
        activityType = prefs.getString(KEY_ACTIVITY_TYPE, "driving") ?: "driving"

        currentTracker = if (activityType == "walking") WalkingTracker(this, bgHandler!!.looper) else DrivingTracker(this, bgHandler!!.looper)
        
        startForegroundNotification("GPS reconnecting…")
        currentTracker?.restore()
        startTelemetryTicker()
    }

    private fun startForegroundNotification(content: String) {
        val title = if (activityType == "walking") "Walking Tracking" else "Drive Tracking"
        val notif = buildNotification(title, content)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notif, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notif)
        }
    }

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
        val stats = currentTracker?.tick() ?: return
        
        val distanceMeters = stats["distance"] as? Double ?: 0.0
        val currentSpeedMps = stats["currentSpeed"] as? Double ?: 0.0
        Log.d("TrackerTrace", "[TrackingService] tickTelemetry: speed=$currentSpeedMps, dist=$distanceMeters")
        
        val distanceKm = distanceMeters / 1000.0
        val currentSpeedKmh = currentSpeedMps * 3.6
        val text = "%.2f km | %.1f km/h".format(distanceKm, currentSpeedKmh)
        
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(if (activityType == "walking") "Walking Tracking" else "Drive Tracking", text))

        ticksSinceLastPrefsWrite++
        if (ticksSinceLastPrefsWrite >= PREFS_WRITE_INTERVAL_TICKS) {
            ticksSinceLastPrefsWrite = 0
            saveCheckpointToPrefs() // Simplified prefs write
        }

        val intent = Intent(BROADCAST_TELEMETRY).apply {
            putExtra("activityType", activityType)
            for ((k, v) in stats) {
                when (v) {
                    is Double -> putExtra(k, v)
                    is Int -> putExtra(k, v)
                    is Boolean -> putExtra(k, v)
                }
            }
        }
        Log.d("TrackerTrace", "[TrackingService] Broadcasting telemetry to LocalBroadcastManager")
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    private fun stopTracking() {
        if (!isTracking) return
        isTracking = false

        stopTelemetryTicker()
        currentTracker?.stop()

        bgHandler?.post {
            val finalStats = currentTracker?.tick() ?: emptyMap()
            saveRideToSQLite(finalStats)
            clearCheckpoints()

            Handler(Looper.getMainLooper()).post {
                val intent = Intent(BROADCAST_STOPPED).apply {
                    putExtra("activityType", activityType)
                    putExtra("startTime", startTimeMillis)
                    putExtra("endTime", System.currentTimeMillis())
                    for ((k, v) in finalStats) {
                        when (v) {
                            is Double -> putExtra(k, v)
                            is Int -> putExtra(k, v)
                            is Boolean -> putExtra(k, v)
                        }
                    }
                }
                LocalBroadcastManager.getInstance(this).sendBroadcast(intent)

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

    private fun saveRideToSQLite(stats: Map<String, Any>) {
        val dbFile = getDatabasePath("drive_tracker.db")
        if (!dbFile.exists()) return

        val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
        try {
            val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            val startStr = fmt.format(Date(startTimeMillis)) + "Z"
            val endStr = fmt.format(Date(System.currentTimeMillis())) + "Z"
            
            val dist = stats["distance"] as? Double ?: 0.0
            val maxSpd = stats["maxSpeed"] as? Double ?: 0.0
            val avgSpd = stats["averageSpeed"] as? Double ?: 0.0
            val drvTime = stats["drivingTime"] as? Int ?: 0
            val stopTime = stats["stopTime"] as? Int ?: 0
            
            val steps = stats["steps"] as? Int ?: 0
            val calories = stats["calories"] as? Double ?: 0.0
            val pace = stats["pace"] as? Double ?: 0.0
            val cadence = stats["cadence"] as? Double ?: 0.0

            db.beginTransaction()
            try {
                // New schema: activities table
                val values = ContentValues().apply {
                    put("activityType", activityType)
                    put("startTime", startStr)
                    put("endTime", endStr)
                    put("maxSpeed", maxSpd * 3.6)
                    put("averageSpeed", avgSpd * 3.6)
                    put("distance", dist / 1000.0)
                    put("drivingTime", drvTime) // renamed to duration in flutter, keep here for compatibility or change? DB schema says duration, let's write to duration if possible. Wait, schema says duration, steps, calories, pace, cadence.
                    put("duration", drvTime + stopTime) // new column
                    put("stopTime", stopTime)
                    put("steps", steps)
                    put("calories", calories)
                    put("pace", pace)
                    put("cadence", cadence)
                    put("createdAt", endStr)
                }
                // Try inserting to activities table. 
                val rideId = try {
                    db.insert("activities", null, values)
                } catch (e: Exception) {
                    // Fallback to legacy rides table if migration failed
                    val legacyValues = ContentValues().apply {
                        put("startTime", startStr)
                        put("endTime", endStr)
                        put("maxSpeed", maxSpd * 3.6)
                        put("averageSpeed", avgSpd * 3.6)
                        put("distance", dist / 1000.0)
                        put("drivingTime", drvTime)
                        put("stopTime", stopTime)
                        put("createdAt", endStr)
                    }
                    db.insert("rides", null, legacyValues)
                }

                if (rideId != -1L) {
                    insertLocationsFromFile(db, rideId, fmt, if (rideId != -1L) "activity_locations" else "ride_locations")
                }
                db.setTransactionSuccessful()
            } finally {
                db.endTransaction()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save ride to SQLite", e)
        } finally {
            db.close()
        }
    }

    private fun insertLocationsFromFile(db: SQLiteDatabase, rideId: Long, fmt: SimpleDateFormat, tableName: String) {
        val file = File(filesDir, "active_ride_trace.jsonl")
        if (!file.exists()) return
        try {
            file.forEachLine { line ->
                if (line.isBlank()) return@forEachLine
                runCatching {
                    val obj = JSONObject(line)
                    val locValues = ContentValues().apply {
                        if (tableName == "activity_locations") put("activityId", rideId) else put("rideId", rideId)
                        put("latitude", obj.getDouble("lat"))
                        put("longitude", obj.getDouble("lng"))
                        put("speed", obj.getDouble("spd") * 3.6)
                        put("accuracy", obj.getDouble("acc"))
                        put("heading", obj.getDouble("hdg"))
                        put("altitude", obj.getDouble("alt"))
                        put("timestamp", fmt.format(Date(obj.getLong("ts"))) + "Z")
                    }
                    db.insert(tableName, null, locValues)
                }
            }
        } catch (e: Exception) {}
    }

    private fun saveCheckpointToPrefs() {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().apply {
            putBoolean(KEY_IS_ACTIVE, true)
            putLong(KEY_START_TIME, startTimeMillis)
            putString(KEY_ACTIVITY_TYPE, activityType)
            // Individual trackers can handle their own prefs if needed, but for simplicity we rely on the main state variables inside trackers if we extended this.
            // For now, tracking service just saves the type. If killed, distance resets (or trackers can persist themselves).
            apply()
        }
    }

    private fun clearCheckpoints() {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().clear().apply()
        File(filesDir, "active_ride_trace.jsonl").delete()
    }

    private fun buildNotification(title: String, content: String): Notification {
        val stopIntent = Intent(this, TrackingService::class.java).apply { action = ACTION_STOP }
        val stopPi = PendingIntent.getService(this, 1, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val openIntent = Intent(this, MainActivity::class.java)
        val openPi = PendingIntent.getActivity(this, 0, openIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

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
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Tracking Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
