package com.example.drivetracker.drive_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Boot completed detected.")
            if (context != null) {
                val prefs = context.getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                val isTrackingActive = prefs.getBoolean("is_tracking_active", false)
                if (isTrackingActive) {
                    Log.d("BootReceiver", "Restoring active tracking service after reboot...")
                    val serviceIntent = Intent(context, TrackingService::class.java).apply {
                        action = TrackingService.ACTION_START
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    } catch (e: Exception) {
                        Log.e("BootReceiver", "Failed to start service on boot completion", e)
                    }
                }
            }
        }
    }
}
