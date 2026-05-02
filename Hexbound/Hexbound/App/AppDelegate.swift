import UIKit
import UserNotifications

/// Handles APNS device token registration and push notification delivery.
/// Wired into SwiftUI via @UIApplicationDelegateAdaptor in HexboundApp.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Shared push service — set from HexboundApp so we can forward tokens.
    var pushService: PushNotificationService?
    /// Main-router deep-link handler wired from HexboundApp once SwiftUI state exists.
    var routeHandler: (@MainActor (AppRoute) -> Void)? {
        didSet {
            guard let routeHandler, let queuedRoute = pendingPushRoute else { return }
            pendingPushRoute = nil
            Task { @MainActor in
                routeHandler(queuedRoute)
            }
        }
    }
    private var pendingPushRoute: AppRoute?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - APNS Token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            pushService?.storeToken(deviceToken)
            await pushService?.registerToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("[Push] Failed to register for remote notifications: \(error)")
        #endif
    }

    // MARK: - Foreground Notification

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Notification Tap

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle deep link from push payload
        if let route = userInfo["route"] as? String {
            #if DEBUG
            print("[Push] Deep link route: \(route)")
            #endif
            guard let parsedRoute = AppRoute.pushDeepLink(from: route) else {
                #if DEBUG
                print("[Push] Unsupported deep link route: \(route)")
                #endif
                completionHandler()
                return
            }

            if let routeHandler {
                Task { @MainActor in
                    routeHandler(parsedRoute)
                }
            } else {
                pendingPushRoute = parsedRoute
            }
        }

        completionHandler()
    }
}
