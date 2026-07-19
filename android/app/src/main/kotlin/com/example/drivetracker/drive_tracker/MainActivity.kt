package com.example.drivetracker.drive_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CONTROL_CHANNEL = "com.example.drivetracker/tracking_control"
    private val EVENT_CHANNEL = "com.example.drivetracker/tracking_events"

    private var eventSink: EventChannel.EventSink? = null
    private var telemetryReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: Send start/stop command signals to native service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL).setMethodCallHandler { call, result ->
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
                else -> {
                    result.notImplemented()
                }
            }
        }

        // EventChannel: Stream telemetry events dynamically
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerTelemetryReceivers()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterTelemetryReceivers()
                    eventSink = null
                }
            }
        )
    }

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

    private fun registerTelemetryReceivers() {
        if (telemetryReceiver != null) return

        telemetryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent?.let {
                    val sink = eventSink ?: return@let
                    when (it.action) {
                        TrackingService.BROADCAST_TELEMETRY -> {
                            val data = mapOf(
                                "type" to "telemetry",
                                "currentSpeed" to it.getDoubleExtra("currentSpeed", 0.0),
                                "maxSpeed" to it.getDoubleExtra("maxSpeed", 0.0),
                                "averageSpeed" to it.getDoubleExtra("averageSpeed", 0.0),
                                "distance" to it.getDoubleExtra("distance", 0.0),
                                "drivingTime" to it.getIntExtra("drivingTime", 0),
                                "stopTime" to it.getIntExtra("stopTime", 0)
                            )
                            sink.success(data)
                        }
                        TrackingService.BROADCAST_STOPPED -> {
                            val data = mapOf(
                                "type" to "stopped",
                                "historyJson" to it.getStringExtra("historyJson"),
                                "startTime" to it.getLongExtra("startTime", 0L),
                                "endTime" to it.getLongExtra("endTime", 0L),
                                "maxSpeed" to it.getDoubleExtra("maxSpeed", 0.0),
                                "averageSpeed" to it.getDoubleExtra("averageSpeed", 0.0),
                                "distance" to it.getDoubleExtra("distance", 0.0),
                                "drivingTime" to it.getIntExtra("drivingTime", 0),
                                "stopTime" to it.getIntExtra("stopTime", 0)
                            )
                            sink.success(data)
                        }
                        else -> {}
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(TrackingService.BROADCAST_TELEMETRY)
            addAction(TrackingService.BROADCAST_STOPPED)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(telemetryReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(telemetryReceiver, filter)
        }
    }

    private fun unregisterTelemetryReceivers() {
        telemetryReceiver?.let {
            unregisterReceiver(it)
            telemetryReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterTelemetryReceivers()
        super.onDestroy()
    }
}
