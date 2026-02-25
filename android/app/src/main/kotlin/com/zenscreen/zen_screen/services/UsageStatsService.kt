package com.zenscreen.zen_screen.services

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

/**
 * Queries Android's UsageStatsManager for per-app usage data.
 *
 * Requires the PACKAGE_USAGE_STATS permission (granted by user in
 * Usage Access settings).
 */
class UsageStatsService(private val context: Context) {

    private val usageStatsManager: UsageStatsManager
        get() = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    private val packageManager: PackageManager
        get() = context.packageManager

    /**
     * Returns a list of app usage maps for the given time range.
     *
     * Each map contains:
     * - `packageName` (String)
     * - `appName` (String)
     * - `usageTime` (Long, milliseconds)
     * - `openCount` (Int)
     * - `lastUsed` (Long, milliseconds since epoch)
     */
    fun getUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (usageStatsList.isNullOrEmpty()) return emptyList()

        return usageStatsList
            .filter { it.totalTimeInForeground > 0 }
            .map { stats ->
                mapOf(
                    "packageName" to stats.packageName,
                    "appName" to getAppName(stats.packageName),
                    "usageTime" to stats.totalTimeInForeground,
                    "openCount" to getOpenCount(stats.packageName, startTime, endTime),
                    "lastUsed" to stats.lastTimeUsed
                )
            }
            .sortedByDescending { it["usageTime"] as Long }
    }

    /**
     * Counts the number of times an app was moved to foreground in the
     * given time range by querying usage events.
     */
    private fun getOpenCount(packageName: String, startTime: Long, endTime: Long): Int {
        val events = usageStatsManager.queryEvents(startTime, endTime)
        var count = 0
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName == packageName &&
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            ) {
                count++
            }
        }
        return count
    }

    /**
     * Returns a list of installed app metadata.
     *
     * Each map contains:
     * - `packageName` (String)
     * - `appName` (String)
     * - `category` (String) - "social", "game", "productivity", etc.
     */
    fun getInstalledApps(): List<Map<String, Any>> {
        val apps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

        return apps
            .filter { isLaunchable(it.packageName) }
            .map { appInfo ->
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to (appInfo.loadLabel(packageManager)?.toString() ?: appInfo.packageName),
                    "category" to getCategoryName(appInfo)
                )
            }
            .sortedBy { it["appName"] as String }
    }

    /**
     * Resolves a human-readable app name from a package name.
     */
    private fun getAppName(packageName: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    /**
     * Returns a human-readable category name for the app.
     */
    private fun getCategoryName(appInfo: ApplicationInfo): String {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            when (appInfo.category) {
                ApplicationInfo.CATEGORY_GAME -> "game"
                ApplicationInfo.CATEGORY_AUDIO -> "audio"
                ApplicationInfo.CATEGORY_VIDEO -> "video"
                ApplicationInfo.CATEGORY_IMAGE -> "image"
                ApplicationInfo.CATEGORY_SOCIAL -> "social"
                ApplicationInfo.CATEGORY_NEWS -> "news"
                ApplicationInfo.CATEGORY_MAPS -> "maps"
                ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
                else -> "other"
            }
        } else {
            "other"
        }
    }

    /**
     * Returns true if the app has a launcher intent (i.e., it appears in
     * the app drawer and is user-facing).
     */
    private fun isLaunchable(packageName: String): Boolean {
        return packageManager.getLaunchIntentForPackage(packageName) != null
    }
}
