package com.app.drivereplay

import android.content.Context
import android.content.SharedPreferences
import android.location.Location
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NativeLocationEngine : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val TAG = "NativeLocationEngine"
    private lateinit var context: Context
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var prefs: SharedPreferences

    private var eventSink: EventChannel.EventSink? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    
    private var isTracking = false
    private var totalDistance = 0.0
    private var lastLocation: Location? = null
    private var maxSpeed = 0.0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
        prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        methodChannel = MethodChannel(binding.binaryMessenger, "com.drivereplay.location/method")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.drivereplay.location/stream")
        eventChannel?.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        stopTracking()
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        when (call.method) {
            "startTracking" -> {
                val tripId = call.argument<Int>("tripId") ?: -1
                startTracking(tripId)
                result.success(true)
            }
            "stopTracking" -> {
                stopTracking()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        setEventSink(null)
    }

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            val location = locationResult.lastLocation ?: return
            Log.i(TAG, "RAW_GPS: lat=${location.latitude}, lng=${location.longitude}, speed=${location.speed}, acc=${location.accuracy}, time=${location.time}")
            processLocation(location)
        }
    }

    private var mockHandler: android.os.Handler? = null
    private var mockRunnable: Runnable? = null
    private var mockLat = 37.7749
    private var mockLng = -122.4194

    private fun startMockLocationGenerator() {
        mockHandler = android.os.Handler(Looper.getMainLooper())
        mockRunnable = object : Runnable {
            override fun run() {
                if (!isTracking) return
                mockLat += 0.0001
                mockLng += 0.0001
                val mockLoc = Location("mock").apply {
                    latitude = mockLat
                    longitude = mockLng
                    speed = 15.0f
                    accuracy = 5.0f
                    time = System.currentTimeMillis()
                    elapsedRealtimeNanos = android.os.SystemClock.elapsedRealtimeNanos()
                }
                Log.i(TAG, "RAW_GPS: lat=${mockLoc.latitude}, lng=${mockLoc.longitude}, speed=${mockLoc.speed}, acc=${mockLoc.accuracy}, time=${mockLoc.time}")
                processLocation(mockLoc)
                mockHandler?.postDelayed(this, 1000)
            }
        }
        mockHandler?.postDelayed(mockRunnable!!, 1000)
    }

    private fun stopMockLocationGenerator() {
        mockRunnable?.let { mockHandler?.removeCallbacks(it) }
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
        if (isTracking && sink != null && lastLocation != null) {
            // Push current state
            sendUpdateToFlutter(lastLocation!!, lastLocation!!.speed.toDouble(), totalDistance)
        }
    }

    fun startTracking(tripId: Int) {
        if (isTracking) return
        Log.i(TAG, "Starting Native Location Tracking for trip $tripId")
        
        // Recover state or reset
        val activeTripId = prefs.getLong("flutter.current_active_trip_id", -1)
        if (activeTripId == tripId.toLong()) {
            totalDistance = prefs.getDouble("flutter.current_active_trip_distance", 0.0)
        } else {
            totalDistance = 0.0
            prefs.edit().putLong("flutter.current_active_trip_id", tripId.toLong()).apply()
        }
        
        lastLocation = null
        maxSpeed = 0.0
        isTracking = true

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000)
            .setMinUpdateDistanceMeters(3.0f)
            .build()

        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
            startMockLocationGenerator()
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing", e)
            sendErrorToFlutter("PERMISSION_DENIED", "Location permission missing")
        }
    }

    fun stopTracking() {
        if (!isTracking) return
        Log.i(TAG, "Stopping Native Location Tracking")
        isTracking = false
        fusedLocationClient.removeLocationUpdates(locationCallback)
        stopMockLocationGenerator()
    }

    private fun processLocation(position: Location) {
        // 1. Noise Filtering (Accuracy)
        if (position.accuracy > 30.0) {
            Log.d(TAG, "Filtered: Poor accuracy (${position.accuracy}m)")
            return
        }

        // 2. Time Consistency Filtering
        if (lastLocation != null && position.time <= lastLocation!!.time) {
            Log.d(TAG, "Filtered: Stale or duplicate timestamp")
            return
        }

        var effectiveSpeed = position.speed.toDouble()
        if (effectiveSpeed < 0.0) effectiveSpeed = 0.0

        if (lastLocation != null) {
            val distance = lastLocation!!.distanceTo(position).toDouble()
            val timeDeltaSecs = (position.time - lastLocation!!.time) / 1000.0

            if (effectiveSpeed == 0.0 && timeDeltaSecs > 0) {
                effectiveSpeed = distance / timeDeltaSecs
            }

            // 3. Speed Jump Filtering (Impossible Speeds > 250 km/h = 69.4 m/s)
            if (timeDeltaSecs > 0) {
                val calculatedSpeedMps = distance / timeDeltaSecs
                if (calculatedSpeedMps > 69.4) {
                    Log.w(TAG, "Filtered: Impossible GPS Jump detected (${calculatedSpeedMps * 3.6} km/h).")
                    return
                }
            }

            // 4. Jitter Filtering (Ignore micro-movements < 3 meters)
            if (distance < 3.0) {
                Log.d(TAG, "Filtered: Jitter movement (${distance}m)")
            } else {
                totalDistance += distance
                lastLocation = position
                // Persist distance for Dart and recovery (Flutter shared_preferences format uses 'flutter.' prefix)
                prefs.edit().putDouble("flutter.current_active_trip_distance", totalDistance).apply()
            }
        } else {
            lastLocation = position
        }

        if (effectiveSpeed > maxSpeed) {
            maxSpeed = effectiveSpeed
        }

        sendUpdateToFlutter(position, effectiveSpeed, totalDistance)
    }

    private fun sendUpdateToFlutter(position: Location, speed: Double, distance: Double) {
        if (eventSink == null) return
        
        val data = mapOf(
            "type" to "UPDATE",
            "speed" to speed,
            "distance" to distance,
            "latitude" to position.latitude,
            "longitude" to position.longitude,
            "accuracy" to position.accuracy,
            "heading" to position.bearing.toDouble(),
            "altitude" to position.altitude
        )
        eventSink?.success(data)
    }

    private fun sendErrorToFlutter(code: String, message: String) {
        eventSink?.error(code, message, null)
    }

    // Helper for Double preferences
    private fun SharedPreferences.Editor.putDouble(key: String, double: Double): SharedPreferences.Editor =
        putLong(key, java.lang.Double.doubleToRawLongBits(double))

    private fun SharedPreferences.getDouble(key: String, default: Double): Double {
        if (!contains(key)) return default
        return java.lang.Double.longBitsToDouble(getLong(key, 0))
    }
}
