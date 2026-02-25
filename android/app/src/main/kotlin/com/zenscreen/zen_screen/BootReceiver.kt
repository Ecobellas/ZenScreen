package com.zenscreen.zen_screen

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.zenscreen.zen_screen.services.AppMonitoringService

/**
 * Restarts the monitoring foreground service after device reboot
 * if it was previously running.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences("zenscreen_prefs", Context.MODE_PRIVATE)
            val wasRunning = prefs.getBoolean("monitoring_enabled", false)
            if (wasRunning) {
                AppMonitoringService.start(context)
            }
        }
    }
}
