package com.example.drivetracker.drive_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CONTROL_CHANNEL = "com.example.drivetracker/tracking_control"
    private val EVENT_CHANNEL = "com.example.drivetracker/tracking_events"

    private var eventSink: EventChannel.EventSink? = null
    // Fix #5: telemetryReceiver is registered/unregistered in onResume/onPause
    private var telemetryReceiver: BroadcastReceiver? = null
    private var isReceiverRegistered = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: control the tracking service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTracking" -> {
                        startTrackingService()
                        result.success(true)
                    }
                    "stopTracking" -> {
                        stopTrackingService()
                        result.success(true)
                    }
                    "isTracking" -> {
                        result.success(TrackingService.isServiceRunning)
                    }
                    "getTelemetry" -> {
                        // Fix #4: access via WeakReference, no direct field read
                        val service = TrackingService.activeInstance
                        if (service != null) {
                            result.success(mapOf(
                                "isTracking" to true,
                                "startTime" to service.getStartTime(),
                                "currentSpeed" to service.getCurrentSpeedMps(),
                                "maxSpeed" to service.getMaxSpeedMetersPerSec(),
                                "averageSpeed" to service.getAverageSpeedMps(),
                                "distance" to service.getAccumulatedDistanceMeters(),
                                "drivingTime" to service.getDrivingTimeSeconds(),
                                "stopTime" to service.getStoppedTimeSeconds()
                            ))
                        } else {
                            result.success(mapOf("isTracking" to false))
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // EventChannel: stream live telemetry to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Receiver registration is driven by onResume/onPause, not stream lifecycle
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    // Fix #5: Register receiver in onResume (not in stream handler)
    override fun onResume() {
        super.onResume()
        registerTelemetryReceiver()
    }

    // Fix #5: Unregister in onPause to prevent Activity leak
    override fun onPause() {
        super.onPause()
        unregisterTelemetryReceiver()
    }

    override fun onDestroy() {
        unregisterTelemetryReceiver()
        super.onDestroy()
    }

    // ─── Receiver ────────────────────────────────────────────────────────────

    private fun buildTelemetryReceiver(): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                val sink = eventSink ?: return
                when (intent.action) {
                    TrackingService.BROADCAST_TELEMETRY -> {
                        runOnUiThread {
                            sink.success(mapOf(
                                "type" to "telemetry",
                                "currentSpeed" to intent.getDoubleExtra("currentSpeed", 0.0),
                                "maxSpeed" to intent.getDoubleExtra("maxSpeed", 0.0),
                                "averageSpeed" to intent.getDoubleExtra("averageSpeed", 0.0),
                                "distance" to intent.getDoubleExtra("distance", 0.0),
                                "drivingTime" to intent.getIntExtra("drivingTime", 0),
                                "stopTime" to intent.getIntExtra("stopTime", 0),
                                "acceleration" to intent.getDoubleExtra("acceleration", 0.0),
                                "heading" to intent.getDoubleExtra("heading", 0.0),
                                "altitude" to intent.getDoubleExtra("altitude", 0.0)
                            ))
                        }
                    }
                    TrackingService.BROADCAST_STOPPED -> {
                        runOnUiThread {
                            sink.success(mapOf(
                                "type" to "stopped",
                                "startTime" to intent.getLongExtra("startTime", 0L),
                                "endTime" to intent.getLongExtra("endTime", 0L),
                                "maxSpeed" to intent.getDoubleExtra("maxSpeed", 0.0),
                                "averageSpeed" to intent.getDoubleExtra("averageSpeed", 0.0),
                                "distance" to intent.getDoubleExtra("distance", 0.0),
                                "drivingTime" to intent.getIntExtra("drivingTime", 0),
                                "stopTime" to intent.getIntExtra("stopTime", 0)
                            ))
                        }
                    }
                }
            }
        }
    }

    private fun registerTelemetryReceiver() {
        if (isReceiverRegistered) return
        val receiver = buildTelemetryReceiver()
        telemetryReceiver = receiver
        val filter = IntentFilter().apply {
            addAction(TrackingService.BROADCAST_TELEMETRY)
            addAction(TrackingService.BROADCAST_STOPPED)
        }
        // Fix #12/#13: Use LocalBroadcastManager — internal only, no RECEIVER_EXPORTED needed
        LocalBroadcastManager.getInstance(this).registerReceiver(receiver, filter)
        isReceiverRegistered = true
    }

    private fun unregisterTelemetryReceiver() {
        if (!isReceiverRegistered) return
        telemetryReceiver?.let {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(it)
            telemetryReceiver = null
        }
        isReceiverRegistered = false
    }

    // ─── Service control ──────────────────────────────────────────────────────

    private fun startTrackingService() {
        val intent = Intent(this, TrackingService::class.java).apply {
            action = TrackingService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopTrackingService() {
        val intent = Intent(this, TrackingService::class.java).apply {
            action = TrackingService.ACTION_STOP
        }
        startService(intent)
    }
}
