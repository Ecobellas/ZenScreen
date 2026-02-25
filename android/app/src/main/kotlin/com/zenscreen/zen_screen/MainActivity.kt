package com.zenscreen.zen_screen

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import com.zenscreen.zen_screen.services.AppMonitoringService
import com.zenscreen.zen_screen.services.PermissionHelper
import com.zenscreen.zen_screen.services.UsageStatsService

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "com.zenscreen/platform"
        private const val EVENT_CHANNEL = "com.zenscreen/app_events"
    }

    private lateinit var permissionHelper: PermissionHelper
    private lateinit var usageStatsService: UsageStatsService

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        permissionHelper = PermissionHelper(this)
        usageStatsService = UsageStatsService(this)

        // -----------------------------------------------------------------
        // Method Channel
        // -----------------------------------------------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // -- Permissions ------------------------------------------
                "checkUsagePermission" -> {
                    result.success(permissionHelper.hasUsageStatsPermission())
                }
                "checkNotificationPermission" -> {
                    result.success(permissionHelper.hasNotificationPermission())
                }
                "checkOverlayPermission" -> {
                    result.success(permissionHelper.hasOverlayPermission())
                }
                "requestUsagePermission" -> {
                    val launched = permissionHelper.requestUsageStatsPermission(this)
                    result.success(launched)
                }
                "requestNotificationPermission" -> {
                    val granted = permissionHelper.requestNotificationPermission(this)
                    result.success(granted)
                }
                "requestOverlayPermission" -> {
                    val launched = permissionHelper.requestOverlayPermission(this)
                    result.success(launched)
                }

                // -- Monitoring service -----------------------------------
                "startMonitoringService" -> {
                    try {
                        AppMonitoringService.start(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopMonitoringService" -> {
                    try {
                        AppMonitoringService.stop(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isServiceRunning" -> {
                    result.success(AppMonitoringService.isRunning)
                }

                // -- Usage stats ------------------------------------------
                "getUsageStats" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()

                    if (!permissionHelper.hasUsageStatsPermission()) {
                        result.success(emptyList<Map<String, Any>>())
                    } else {
                        val stats = usageStatsService.getUsageStats(startTime, endTime)
                        result.success(stats)
                    }
                }
                "getInstalledApps" -> {
                    val apps = usageStatsService.getInstalledApps()
                    result.success(apps)
                }

                else -> result.notImplemented()
            }
        }

        // -----------------------------------------------------------------
        // Event Channel — real-time app open events
        // -----------------------------------------------------------------
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // Wire up the monitoring service callback to push events
                AppMonitoringService.onAppChanged = { packageName, timestamp ->
                    val appName = getAppLabel(packageName)
                    eventSink?.success(
                        mapOf(
                            "packageName" to packageName,
                            "appName" to appName,
                            "timestamp" to timestamp
                        )
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                AppMonitoringService.onAppChanged = null
            }
        })
    }

    /**
     * Resolves a human-readable app label from a package name.
     */
    private fun getAppLabel(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        // Notification permission result is handled by re-checking in Flutter
        // after the user returns to the app.
    }
}
