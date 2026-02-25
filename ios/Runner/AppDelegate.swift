import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var eventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // ---------------------------------------------------------------------
        // Method Channel
        // ---------------------------------------------------------------------
        let methodChannel = FlutterMethodChannel(
            name: "com.zenscreen/platform",
            binaryMessenger: controller.binaryMessenger
        )

        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }

        // ---------------------------------------------------------------------
        // Event Channel — real-time app open events
        // ---------------------------------------------------------------------
        let eventChannel = FlutterEventChannel(
            name: "com.zenscreen/app_events",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(AppEventStreamHandler())

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Method Call Router

    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let permissionService = PermissionServiceIOS.shared
        let usageService = UsageDataServiceIOS.shared

        switch call.method {

        // -- Permissions ------------------------------------------------------
        case "checkUsagePermission":
            permissionService.checkUsagePermission { granted in
                result(granted)
            }

        case "checkNotificationPermission":
            permissionService.checkNotificationPermission { granted in
                result(granted)
            }

        case "checkOverlayPermission":
            permissionService.checkOverlayPermission { granted in
                result(granted)
            }

        case "requestUsagePermission":
            permissionService.requestUsagePermission { granted in
                result(granted)
            }

        case "requestNotificationPermission":
            permissionService.requestNotificationPermission { granted in
                result(granted)
            }

        case "requestOverlayPermission":
            permissionService.requestOverlayPermission { granted in
                result(granted)
            }

        // -- Monitoring service -----------------------------------------------
        case "startMonitoringService":
            let started = usageService.startMonitoring()
            result(started)

        case "stopMonitoringService":
            let stopped = usageService.stopMonitoring()
            result(stopped)

        case "isServiceRunning":
            let running = usageService.isMonitoring()
            result(running)

        // -- Usage stats ------------------------------------------------------
        case "getUsageStats":
            let args = call.arguments as? [String: Any] ?? [:]
            let startTime = args["startTime"] as? Int64 ?? 0
            let endTime = args["endTime"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
            let stats = usageService.getUsageStats(startTime: startTime, endTime: endTime)
            result(stats)

        case "getInstalledApps":
            let apps = usageService.getInstalledApps()
            result(apps)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Event Stream Handler

/// Handles the EventChannel stream for real-time app open events.
/// Currently a stub on iOS — will deliver events once Screen Time API
/// integration is complete.
class AppEventStreamHandler: NSObject, FlutterStreamHandler {

    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // TODO: Connect to DeviceActivityMonitor events when entitlement is approved.
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
