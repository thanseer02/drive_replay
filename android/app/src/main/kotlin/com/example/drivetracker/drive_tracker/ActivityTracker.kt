package com.example.drivetracker.drive_tracker

interface ActivityTracker {
    fun start()
    fun restore()
    fun stop()
    fun tick(): Map<String, Any>
}
