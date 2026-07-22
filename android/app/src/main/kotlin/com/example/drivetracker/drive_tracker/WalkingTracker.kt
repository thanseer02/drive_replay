package com.example.drivetracker.drive_tracker

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import org.json.JSONObject
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter

class WalkingTracker(private val context: Context, private val bgLooper: Looper) : ActivityTracker, SensorEventListener {

    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
    private var locationCallback: LocationCallback? = null
    private var currentLocationRequest: LocationRequest? = null

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var stepSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

    var accumulatedDistanceMeters: Double = 0.0
    var maxSpeedMetersPerSec: Double = 0.0
    var currentAccelerationMps2: Double = 0.0
    var walkingTimeSeconds: Int = 0
    var stoppedTimeSeconds: Int = 0

    var totalSteps: Int = 0
    var initialStepCount: Int = -1

    var currentSpeedMps: Double = 0.0
    private var isWalkingStopped: Boolean = true
    private var consecutiveStoppedSeconds: Int = 0
    private val MOVING_SPEED_THRESHOLD_MPS = 0.2 // Very low threshold for walking
    private val STOPPED_CRITERIA_DURATION_SECONDS = 5

    private var lastLocation: Location? = null

    private var traceWriter: BufferedWriter? = null
    var traceLineCount: Int = 0

    // Calorie calculation constants
    private val DEFAULT_WEIGHT_KG = 70.0

    @SuppressLint("MissingPermission")
    override fun start() {
        Log.d("TrackerTrace", "[WalkingTracker] start() called")
        resetState()
        openTraceWriter(append = false)
        startGps()
        stepSensor?.let {
            Log.d("TrackerTrace", "[WalkingTracker] Registering step sensor listener")
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI, Handler(bgLooper))
        } ?: Log.w("TrackerTrace", "[WalkingTracker] Step sensor not available on this device!")
    }

    @SuppressLint("MissingPermission")
    override fun restore() {
        val prefs = context.getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
        accumulatedDistanceMeters = prefs.getFloat("distance", 0f).toDouble()
        maxSpeedMetersPerSec = prefs.getFloat("max_speed", 0f).toDouble()
        walkingTimeSeconds = prefs.getInt("driving_time", 0) // using same keys for now
        stoppedTimeSeconds = prefs.getInt("stop_time", 0)
        isWalkingStopped = prefs.getBoolean("is_vehicle_stopped", true)
        consecutiveStoppedSeconds = prefs.getInt("consecutive_stopped_seconds", 0)
        totalSteps = prefs.getInt("total_steps", 0)
        currentSpeedMps = 0.0
        
        traceLineCount = countTraceLines()
        openTraceWriter(append = true)
        startGps()
        startSensors()
    }

    override fun stop() {
        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
        sensorManager.unregisterListener(this)
        closeTraceWriter()
    }

    override fun tick(): Map<String, Any> {
        if (currentSpeedMps < MOVING_SPEED_THRESHOLD_MPS) {
            if (!isWalkingStopped) {
                consecutiveStoppedSeconds++
                if (consecutiveStoppedSeconds > STOPPED_CRITERIA_DURATION_SECONDS) {
                    isWalkingStopped = true
                    walkingTimeSeconds = (walkingTimeSeconds - consecutiveStoppedSeconds).coerceAtLeast(0)
                    stoppedTimeSeconds += consecutiveStoppedSeconds
                    consecutiveStoppedSeconds = 0
                } else {
                    walkingTimeSeconds++
                }
            } else {
                stoppedTimeSeconds++
            }
        } else {
            if (isWalkingStopped) {
                isWalkingStopped = false
                startGps()
            }
            consecutiveStoppedSeconds = 0
            walkingTimeSeconds++
        }

        val avgSpeedMps = if (walkingTimeSeconds > 0) accumulatedDistanceMeters / walkingTimeSeconds else 0.0
        val cadence = if (walkingTimeSeconds > 0) (totalSteps.toDouble() / (walkingTimeSeconds / 60.0)) else 0.0
        
        // Calories: roughly 0.04 kcal per step or MET based. Let's use simple MET (Walking ~ 3.5 METs)
        // METs * 3.5 * weight_in_kg / 200 = kcal/min
        val kcalPerMin = (3.5 * 3.5 * DEFAULT_WEIGHT_KG) / 200.0
        val calories = (walkingTimeSeconds / 60.0) * kcalPerMin

        // Pace: min/km
        val pace = if (currentSpeedMps > 0.0) (1000.0 / currentSpeedMps) / 60.0 else 0.0

        Log.d("TrackerTrace", "[WalkingTracker] tick() stats: currentSpeed=$currentSpeedMps, maxSpeed=$maxSpeedMetersPerSec, avgSpeed=$avgSpeedMps, dist=$accumulatedDistanceMeters, walkingTime=$walkingTimeSeconds, stopTime=$stoppedTimeSeconds, isStopped=$isWalkingStopped, steps=$totalSteps, cadence=$cadence, calories=$calories, pace=$pace")

        return mapOf(
            "currentSpeed" to currentSpeedMps,
            "maxSpeed" to maxSpeedMetersPerSec,
            "averageSpeed" to avgSpeedMps,
            "distance" to accumulatedDistanceMeters,
            "drivingTime" to walkingTimeSeconds, // Reusing key for compatibility
            "stopTime" to stoppedTimeSeconds,
            "acceleration" to currentAccelerationMps2,
            "steps" to totalSteps,
            "cadence" to cadence,
            "calories" to calories,
            "pace" to pace,
            "isVehicleStopped" to isWalkingStopped
        )
    }

    @SuppressLint("MissingPermission")
    private fun startGps() {
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 2000L).apply {
            setMinUpdateIntervalMillis(2000L)
            setMinUpdateDistanceMeters(1f) // 1 meter for walking
        }.build()

        if (currentLocationRequest?.priority == request.priority) {
            Log.d("TrackerTrace", "[WalkingTracker] startGps: Priority unchanged, skipping")
            return
        }
        currentLocationRequest = request
        Log.d("TrackerTrace", "[WalkingTracker] startGps: requestLocationUpdates")

        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                Log.d("TrackerTrace", "[WalkingTracker] onLocationResult: ${result.locations.size} locations received")
                result.locations.forEach { processNewLocation(it) }
            }
        }
        fusedLocationClient.requestLocationUpdates(request, locationCallback!!, bgLooper)
    }

    private fun startSensors() {
        stepSensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI, Handler(bgLooper))
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            val currentSteps = event.values[0].toInt()
            if (initialStepCount < 0) {
                initialStepCount = currentSteps
            }
            totalSteps += (currentSteps - initialStepCount)
            initialStepCount = currentSteps
            
            // If we are getting steps but GPS says we aren't moving, override speed heuristically?
            // A typical step is ~0.76 meters.
            if (isWalkingStopped && totalSteps > 0) {
                isWalkingStopped = false
                currentSpeedMps = 1.0 // 1 m/s heuristic when walking without GPS ping
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun processNewLocation(location: Location) {
        Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: lat=${location.latitude}, lng=${location.longitude}, speed=${location.speed}, acc=${location.accuracy}, time=${location.time}")
        // Relax accuracy threshold to allow for mock locations and urban canyons
        if (location.hasAccuracy() && location.accuracy > 100.0f) {
            Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: REJECTED due to poor accuracy (${location.accuracy} > 100)")
            return
        }

        var rawSpeed = 0.0
        if (location.hasSpeed() && location.speed > 0) {
            rawSpeed = location.speed.toDouble()
            Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: Using GPS rawSpeed=$rawSpeed")
        } else if (lastLocation != null) {
            val dist = lastLocation!!.distanceTo(location).toDouble()
            val timeDiffNanos = location.elapsedRealtimeNanos - lastLocation!!.elapsedRealtimeNanos
            val timeDiffSecs = timeDiffNanos / 1_000_000_000.0
            if (timeDiffSecs > 0) rawSpeed = dist / timeDiffSecs
            Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: Using fallback rawSpeed=$rawSpeed (dist=$dist, timeDiffSecs=$timeDiffSecs)")
        } else {
            Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: No speed available, and no lastLocation to calculate.")
        }

        val prevSpeed = currentSpeedMps
        currentSpeedMps = rawSpeed
        Log.d("TrackerTrace", "[WalkingTracker] processNewLocation: currentSpeedMps=$currentSpeedMps")

        if (lastLocation != null) {
            val timeDiffNanos = location.elapsedRealtimeNanos - lastLocation!!.elapsedRealtimeNanos
            val timeDiffSecs = timeDiffNanos / 1_000_000_000.0
            currentAccelerationMps2 = if (timeDiffSecs > 0) (currentSpeedMps - prevSpeed) / timeDiffSecs else 0.0
        }

        if (lastLocation != null) {
            val dist = lastLocation!!.distanceTo(location).toDouble()
            if (dist > 0.5 || currentSpeedMps >= MOVING_SPEED_THRESHOLD_MPS) {
                accumulatedDistanceMeters += dist
            }
        }

        if (currentSpeedMps > maxSpeedMetersPerSec) maxSpeedMetersPerSec = currentSpeedMps
        lastLocation = location

        val heading = if (location.hasBearing()) location.bearing.toDouble() else 0.0
        val altitude = if (location.hasAltitude()) location.altitude else 0.0

        appendToTraceFile(location, heading, altitude)
    }

    private fun resetState() {
        accumulatedDistanceMeters = 0.0
        maxSpeedMetersPerSec = 0.0
        currentAccelerationMps2 = 0.0
        walkingTimeSeconds = 0
        stoppedTimeSeconds = 0
        currentSpeedMps = 0.0
        isWalkingStopped = true
        consecutiveStoppedSeconds = 0
        totalSteps = 0
        initialStepCount = -1
        traceLineCount = 0
        lastLocation = null
    }

    private fun traceFile(): File = File(context.filesDir, "active_ride_trace.jsonl")
    private fun openTraceWriter(append: Boolean) {
        try { traceWriter = BufferedWriter(FileWriter(traceFile(), append)) } catch (e: Exception) {}
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
        } catch (e: Exception) {}
    }
    private fun closeTraceWriter() {
        try { traceWriter?.close() } catch (e: Exception) {}
        traceWriter = null
    }
    private fun countTraceLines(): Int = try { traceFile().bufferedReader().lineSequence().count() } catch (e: Exception) { 0 }
}
