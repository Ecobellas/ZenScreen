import Foundation
import UserNotifications

/// Handles permission requests and status checks on iOS.
///
/// - Notification permission: fully functional via UNUserNotificationCenter.
/// - Screen Time authorization: stubbed (requires FamilyControls entitlement
///   from an approved Apple Developer account).
/// - Overlay permission: not applicable on iOS (always returns true).
class PermissionServiceIOS {

    static let shared = PermissionServiceIOS()

    private init() {}

    // MARK: - Notification Permission

    /// Requests notification permission and returns the grant result.
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Checks whether notification permission is currently authorized.
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Screen Time / Usage Permission (Stub)

    /// Requests Screen Time authorization.
    ///
    /// - TODO: Implement using FamilyControls.AuthorizationCenter when the
    ///   Apple Developer account has the Family Controls entitlement approved.
    ///   ```swift
    ///   import FamilyControls
    ///   AuthorizationCenter.shared.requestAuthorization(for: .individual)
    ///   ```
    func requestUsagePermission(completion: @escaping (Bool) -> Void) {
        // TODO: Requires FamilyControls entitlement — returning false for now.
        completion(false)
    }

    /// Checks if Screen Time authorization has been granted.
    ///
    /// - TODO: Implement using FamilyControls.AuthorizationCenter.shared.authorizationStatus
    func checkUsagePermission(completion: @escaping (Bool) -> Void) {
        // TODO: Requires FamilyControls entitlement — returning false for now.
        completion(false)
    }

    // MARK: - Overlay Permission (Not applicable on iOS)

    /// iOS does not have a separate overlay permission concept.
    /// Always returns true.
    func requestOverlayPermission(completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    /// iOS does not have a separate overlay permission concept.
    /// Always returns true.
    func checkOverlayPermission(completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
