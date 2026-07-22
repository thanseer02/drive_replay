package com.example.drivetracker.drive_tracker

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import org.json.JSONObject
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter

class DrivingTracker(private val context: Context, private val bgLooper: Looper) : ActivityTracker {

    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
    private var locationCallback: LocationCallback? = null
    private var currentLocationRequest: LocationRequest? = null

    var accumulatedDistanceMeters: Double = 0.0
    var maxSpeedMetersPerSec: Double = 0.0
    var currentAccelerationMps2: Double = 0.0
    var drivingTimeSeconds: Int = 0
    var stoppedTimeSeconds: Int = 0

    private var smoothedSpeed: Double = -1.0
    private val SPEED_SMOOTHING_ALPHA = 0.3

    var currentSpeedMps: Double = 0.0
    private var isVehicleStopped: Boolean = true
    private var consecutiveStoppedSeconds: Int = 0
    private var continuousStoppedSeconds: Int = 0
    private val MOVING_SPEED_THRESHOLD_MPS = 3.0 / 3.6
    private val STOPPED_CRITERIA_DURATION_SECONDS = 5

    private var lastLocation: Location? = null

    private var traceWriter: BufferedWriter? = null
    var traceLineCount: Int = 0

    private val TAG = "DrivingTracker"
    private val ADAPTIVE_STOP_THRESHOLD_SECONDS = 30

    @SuppressLint("MissingPermission")
    override fun start() {
        Log.d("TrackerTrace", "[DrivingTracker] start() called")
        resetState()
        openTraceWriter(append = false)
        startGps(highAccuracy = true)
    }

    @SuppressLint("MissingPermission")
    override fun restore() {
        val prefs = context.getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
        accumulatedDistanceMeters = prefs.getFloat("distance", 0f).toDouble()
        maxSpeedMetersPerSec = prefs.getFloat("max_speed", 0f).toDouble()
        drivingTimeSeconds = prefs.getInt("driving_time", 0)
        stoppedTimeSeconds = prefs.getInt("stop_time", 0)
        isVehicleStopped = prefs.getBoolean("is_vehicle_stopped", true)
        consecutiveStoppedSeconds = prefs.getInt("consecutive_stopped_seconds", 0)
        smoothedSpeed = prefs.getFloat("smoothed_speed", -1f).toDouble()
        currentSpeedMps = 0.0
        
        traceLineCount = countTraceLines()
        openTraceWriter(append = true)
        startGps(highAccuracy = true)
    }

    override fun stop() {
        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
        closeTraceWriter()
    }

    override fun tick(): Map<String, Any> {
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
                continuousStoppedSeconds = 0
                startGps(highAccuracy = true)
            }
            consecutiveStoppedSeconds = 0
            drivingTimeSeconds++
        }

        if (isVehicleStopped && continuousStoppedSeconds == ADAPTIVE_STOP_THRESHOLD_SECONDS) {
            Log.d("TrackerTrace", "[DrivingTracker] Switching to low accuracy GPS (ADAPTIVE_STOP_THRESHOLD_SECONDS reached)")
            startGps(highAccuracy = false)
        }

        val avgSpeedMps = if (drivingTimeSeconds > 0) accumulatedDistanceMeters / drivingTimeSeconds else 0.0

        Log.d("TrackerTrace", "[DrivingTracker] tick() stats: currentSpeed=$currentSpeedMps, maxSpeed=$maxSpeedMetersPerSec, avgSpeed=$avgSpeedMps, dist=$accumulatedDistanceMeters, drivingTime=$drivingTimeSeconds, stopTime=$stoppedTimeSeconds, isStopped=$isVehicleStopped")

        return mapOf(
            "currentSpeed" to currentSpeedMps,
            "maxSpeed" to maxSpeedMetersPerSec,
            "averageSpeed" to avgSpeedMps,
            "distance" to accumulatedDistanceMeters,
            "drivingTime" to drivingTimeSeconds,
            "stopTime" to stoppedTimeSeconds,
            "acceleration" to currentAccelerationMps2,
            "smoothedSpeed" to smoothedSpeed,
            "isVehicleStopped" to isVehicleStopped,
            "consecutiveStoppedSeconds" to consecutiveStoppedSeconds
        )
    }

    @SuppressLint("MissingPermission")
    private fun startGps(highAccuracy: Boolean) {
        val priority = if (highAccuracy) Priority.PRIORITY_HIGH_ACCURACY else Priority.PRIORITY_BALANCED_POWER_ACCURACY
        val interval = if (highAccuracy) 1000L else 5000L
        val request = LocationRequest.Builder(priority, interval).apply {
            setMinUpdateIntervalMillis(interval)
            setMinUpdateDistanceMeters(0f)
        }.build()

        if (currentLocationRequest?.priority == request.priority) {
            Log.d("TrackerTrace", "[DrivingTracker] startGps: Priority unchanged, skipping")
            return
        }
        currentLocationRequest = request
        Log.d("TrackerTrace", "[DrivingTracker] startGps: requestLocationUpdates (interval=$interval)")

        locationCallback?.let { fusedLocationClient.removeLocationUpdates(it) }
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                Log.d("TrackerTrace", "[DrivingTracker] onLocationResult: ${result.locations.size} locations received")
                result.locations.forEach { processNewLocation(it) }
            }
        }
        fusedLocationClient.requestLocationUpdates(request, locationCallback!!, bgLooper)
    }

    private fun processNewLocation(location: Location) {
        Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: lat=${location.latitude}, lng=${location.longitude}, speed=${location.speed}, acc=${location.accuracy}, time=${location.time}")
        // Relax accuracy threshold to allow for mock locations and urban canyons
        if (location.hasAccuracy() && location.accuracy > 100.0f) {
            Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: REJECTED due to poor accuracy (${location.accuracy} > 100)")
            return
        }

        var rawSpeed = 0.0
        if (location.hasSpeed() && location.speed > 0) {
            rawSpeed = location.speed.toDouble()
            Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: Using GPS rawSpeed=$rawSpeed")
        } else if (lastLocation != null) {
            val dist = lastLocation!!.distanceTo(location).toDouble()
            val timeDiffNanos = location.elapsedRealtimeNanos - lastLocation!!.elapsedRealtimeNanos
            val timeDiffSecs = timeDiffNanos / 1_000_000_000.0
            if (timeDiffSecs > 0) rawSpeed = dist / timeDiffSecs
            Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: Using fallback rawSpeed=$rawSpeed (dist=$dist, timeDiffSecs=$timeDiffSecs)")
        } else {
            Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: No speed available, and no lastLocation to calculate.")
        }

        val prevSpeed = currentSpeedMps
        smoothedSpeed = if (smoothedSpeed < 0.0) rawSpeed
        else (SPEED_SMOOTHING_ALPHA * rawSpeed) + ((1.0 - SPEED_SMOOTHING_ALPHA) * smoothedSpeed)
        currentSpeedMps = smoothedSpeed
        Log.d("TrackerTrace", "[DrivingTracker] processNewLocation: smoothedSpeed=$smoothedSpeed (currentSpeedMps=$currentSpeedMps)")

        if (lastLocation != null) {
            val timeDiffNanos = location.elapsedRealtimeNanos - lastLocation!!.elapsedRealtimeNanos
            val timeDiffSecs = timeDiffNanos / 1_000_000_000.0
            currentAccelerationMps2 = if (timeDiffSecs > 0) (currentSpeedMps - prevSpeed) / timeDiffSecs else 0.0
        }

        if (lastLocation != null) {
            val dist = lastLocation!!.distanceTo(location).toDouble()
            if (dist > 1.0 || currentSpeedMps >= MOVING_SPEED_THRESHOLD_MPS) {
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
        drivingTimeSeconds = 0
        stoppedTimeSeconds = 0
        smoothedSpeed = -1.0
        currentSpeedMps = 0.0
        isVehicleStopped = true
        consecutiveStoppedSeconds = 0
        continuousStoppedSeconds = 0
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
