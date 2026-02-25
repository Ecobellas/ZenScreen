package com.zenscreen.zen_screen.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Foreground service that continuously monitors which app is in the foreground.
 *
 * Checks the current foreground app every [POLL_INTERVAL_MS] milliseconds using
 * [UsageStatsManager]. When a foreground app change is detected, the new app's
 * package name and timestamp are stored for the Flutter EventChannel to pick up.
 *
 * Must be started as a foreground service to survive the app being backgrounded.
 */
class AppMonitoringService : Service() {

    companion object {
        const val CHANNEL_ID = "zenscreen_monitoring"
        const val NOTIFICATION_ID = 1
        const val POLL_INTERVAL_MS = 1500L // Check every 1.5 seconds

        /** Whether the service is currently running. */
        @Volatile
        var isRunning = false
            private set

        /**
         * Callback invoked on the main thread when a new foreground app is
         * detected. Set by [MainActivity] to forward events to Flutter.
         */
        var onAppChanged: ((packageName: String, timestamp: Long) -> Unit)? = null

        fun start(context: Context) {
            val intent = Intent(context, AppMonitoringService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, AppMonitoringService::class.java)
            context.stopService(intent)
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        handler.post(pollRunnable)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        isRunning = false
        onAppChanged = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // -------------------------------------------------------------------------
    // Foreground app detection
    // -------------------------------------------------------------------------

    private fun checkForegroundApp() {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 5000 // Look back 5 seconds

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()
        var latestPackage: String? = null
        var latestTimestamp = 0L

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                if (event.timeStamp > latestTimestamp) {
                    latestTimestamp = event.timeStamp
                    latestPackage = event.packageName
                }
            }
        }

        if (latestPackage != null && latestPackage != lastForegroundPackage) {
            lastForegroundPackage = latestPackage
            onAppChanged?.invoke(latestPackage, latestTimestamp)
        }
    }

    // -------------------------------------------------------------------------
    // Notification
    // -------------------------------------------------------------------------

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ZenScreen Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when ZenScreen is actively monitoring app usage"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ZenScreen is active")
            .setContentText("Monitoring your app usage mindfully")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
