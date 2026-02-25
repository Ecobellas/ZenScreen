package com.zenscreen.zen_screen.services

import android.app.Activity
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Helper for checking and requesting platform permissions:
 * - Usage Stats access
 * - Notification permission
 * - Overlay (SYSTEM_ALERT_WINDOW) permission
 */
class PermissionHelper(private val context: Context) {

    companion object {
        const val REQUEST_CODE_NOTIFICATION = 1001
    }

    // -------------------------------------------------------------------------
    // Usage Stats Permission
    // -------------------------------------------------------------------------

    /**
     * Returns true if the app has been granted Usage Stats access.
     */
    fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Opens the Usage Access settings screen so the user can grant permission.
     * Returns true if the intent was launched successfully.
     */
    fun requestUsageStatsPermission(activity: Activity): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // -------------------------------------------------------------------------
    // Notification Permission
    // -------------------------------------------------------------------------

    /**
     * Returns true if notification permission is granted.
     *
     * On Android 13+ (TIRAMISU), this checks the POST_NOTIFICATIONS runtime
     * permission. On older versions, notifications are enabled by default.
     */
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        }
    }

    /**
     * Requests the POST_NOTIFICATIONS runtime permission (Android 13+).
     * On older versions the permission is implicitly granted, so this returns
     * true immediately.
     */
    fun requestNotificationPermission(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_CODE_NOTIFICATION
            )
            // The actual result comes back in onRequestPermissionsResult.
            // For the channel bridge we re-check after the user returns.
            hasNotificationPermission()
        } else {
            true
        }
    }

    // -------------------------------------------------------------------------
    // Overlay (SYSTEM_ALERT_WINDOW) Permission
    // -------------------------------------------------------------------------

    /**
     * Returns true if the app can draw overlays.
     */
    fun hasOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(context)
    }

    /**
     * Opens the overlay permission settings screen.
     * Returns true if the intent was launched successfully.
     */
    fun requestOverlayPermission(activity: Activity): Boolean {
        return try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
