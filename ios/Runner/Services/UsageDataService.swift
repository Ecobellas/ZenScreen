import Foundation

/// Provides app usage data on iOS.
///
/// **NOTE**: Full Screen Time API integration requires the
/// `DeviceActivityMonitor` framework and Apple Family Controls entitlement,
/// which needs Apple Developer Program approval. This service provides the
/// correct interface with stub/mock implementations marked with TODO.
///
/// When the entitlement is approved, replace stubs with:
/// ```swift
/// import DeviceActivity
/// import ManagedSettings
/// import FamilyControls
/// ```
class UsageDataServiceIOS {

    static let shared = UsageDataServiceIOS()

    private init() {}

    // MARK: - Usage Stats

    /// Returns usage statistics for the given time range.
    ///
    /// Each dictionary contains:
    /// - `packageName` (String) — bundle identifier
    /// - `appName` (String) — display name
    /// - `usageTime` (Int) — milliseconds of foreground time
    /// - `openCount` (Int) — number of times launched
    /// - `lastUsed` (Int) — milliseconds since epoch
    ///
    /// - TODO: Implement using DeviceActivityReport / DeviceActivityMonitor
    ///   once FamilyControls entitlement is approved.
    func getUsageStats(startTime: Int64, endTime: Int64) -> [[String: Any]] {
        // TODO: Replace with actual Screen Time API queries.
        // Returning empty data until entitlement is available.
        return []
    }

    // MARK: - Installed Apps

    /// Returns a list of installed apps.
    ///
    /// Each dictionary contains:
    /// - `packageName` (String) — bundle identifier
    /// - `appName` (String) — display name
    /// - `category` (String) — app category
    ///
    /// - TODO: On iOS, the list of installed apps is not directly accessible
    ///   without the Screen Time API. Implement via FamilyControls
    ///   Application tokens when the entitlement is approved.
    func getInstalledApps() -> [[String: Any]] {
        // TODO: Replace with actual Screen Time API / FamilyControls data.
        return []
    }

    // MARK: - Monitoring Service (Stub)

    /// Starts the background usage monitoring.
    ///
    /// - TODO: Implement using DeviceActivityMonitor schedule when
    ///   FamilyControls entitlement is approved.
    ///   ```swift
    ///   let center = DeviceActivityCenter()
    ///   let schedule = DeviceActivitySchedule(...)
    ///   try center.startMonitoring(.daily, during: schedule)
    ///   ```
    func startMonitoring() -> Bool {
        // TODO: Requires DeviceActivityMonitor — returning false for now.
        return false
    }

    /// Stops the background usage monitoring.
    ///
    /// - TODO: Implement using DeviceActivityCenter.stopMonitoring()
    func stopMonitoring() -> Bool {
        // TODO: Requires DeviceActivityMonitor — returning false for now.
        return false
    }

    /// Returns whether monitoring is currently active.
    ///
    /// - TODO: Check DeviceActivityCenter.activities for active schedules.
    func isMonitoring() -> Bool {
        // TODO: Requires DeviceActivityMonitor — returning false for now.
        return false
    }
}
