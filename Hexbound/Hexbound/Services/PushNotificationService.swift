import Foundation
import UserNotifications
import UIKit

/// Manages push notification permission requests, token registration with backend,
/// and notification handling.
@MainActor @Observable
final class PushNotificationService {

    private(set) var isRegistered = false
    private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined

    /// Request push notification permission and register with APNS.
    /// Should be called after user logs in and has a valid auth token.
    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                // Register with APNS — this triggers AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            #if DEBUG
            print("[Push] Permission request failed: \(error)")
            #endif
        }

        // Update status
        let settings = await center.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    /// Register the device token with our backend.
    /// Called from AppDelegate when APNS token is received.
    func registerToken(_ deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        #if DEBUG
        print("[Push] Device token: \(tokenString)")
        #endif

        do {
            let _: SuccessResponse = try await APIClient.shared.post(
                APIEndpoints.pushRegister,
                body: ["platform": "ios", "token": tokenString]
            )
            isRegistered = true
        } catch {
            #if DEBUG
            print("[Push] Token registration failed: \(error)")
            #endif
        }
    }

    /// Unregister token when user logs out.
    func unregisterToken() async {
        guard let tokenString = lastKnownToken else { return }
        do {
            let _: SuccessResponse = try await APIClient.shared.post(
                APIEndpoints.pushUnregister,
                body: ["token": tokenString]
            )
            isRegistered = false
        } catch {
            #if DEBUG
            print("[Push] Token unregistration failed: \(error)")
            #endif
        }
    }

    /// Check current notification permission status.
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    // MARK: - Token Storage

    private var lastKnownToken: String? {
        get { UserDefaults.standard.string(forKey: "push_device_token") }
        set { UserDefaults.standard.set(newValue, forKey: "push_device_token") }
    }

    /// Store token for later unregister use.
    func storeToken(_ deviceToken: Data) {
        lastKnownToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
