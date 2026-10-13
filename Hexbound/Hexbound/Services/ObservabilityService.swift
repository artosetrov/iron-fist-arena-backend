import Foundation
import Sentry

/// Crash reporting and analytics delivery.
///
/// Before this existed a Release build reported nothing at all: there was no
/// crash SDK, and `AnalyticsService` shipped with `NoopAnalyticsBackend`, so
/// `setBackend(_:)` was never called and every event went nowhere. A beta with
/// no crash reports and no funnel data cannot answer "did the launch work".
///
/// Configuration lives in `Info.plist` (fed by `Config/*.xcconfig`):
///   HexboundSentryDSN — the project DSN. Leave it empty to disable Sentry
///                       entirely; the app then keeps the no-op backend and
///                       behaves exactly as before.
///
/// Privacy: `sendDefaultPii` stays false, so Sentry does not attach IP
/// addresses or usernames. The only identity attached is the account id, which
/// `PrivacyInfo.xcprivacy` already declares as collected and linked. No message
/// contents, no email addresses, no receipts.
@MainActor
enum ObservabilityService {

    private(set) static var isEnabled = false

    /// Start crash reporting and route analytics through Sentry.
    /// Safe to call once, early, before any other service.
    static func start() {
        guard !isEnabled else { return }

        guard let dsn = AppConstants.sentryDSN, !dsn.isEmpty else {
            #if DEBUG
            print("[observability] No Sentry DSN configured — crash reporting disabled")
            #endif
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = AppConstants.Environment.current.rawValue
            options.releaseName = "\(AppConstants.bundleIdentifier)@\(AppConstants.appVersion)+\(AppConstants.buildNumber)"

            // Never attach IP address, username, or request bodies.
            options.sendDefaultPii = false

            // Crashes and errors are the point; traces are sampled lightly so a
            // beta does not burn the quota.
            options.tracesSampleRate = 0.1

            // Debug builds crash on purpose during development — keep that
            // noise out of the project.
            options.enabled = !AppConstants.isDebugBuild
            options.attachStacktrace = true

            #if DEBUG
            options.debug = true
            #endif
        }

        isEnabled = true
        AnalyticsService.shared.setBackend(SentryAnalyticsBackend())
    }

    /// Attach the signed-in account to subsequent events, so a crash can be
    /// traced to the session that produced it. Only the account id — no email,
    /// no display name.
    static func setUser(id: String?) {
        guard isEnabled else { return }

        guard let id else {
            SentrySDK.setUser(nil)
            return
        }

        let user = User()
        user.userId = id
        SentrySDK.setUser(user)
    }

    /// Record a handled error that did not crash the app but should not have
    /// happened — a failed purchase redemption, a decode mismatch.
    static func capture(_ error: Error, context: String) {
        #if DEBUG
        print("[observability] \(context): \(error)")
        #endif
        guard isEnabled else { return }
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: context, key: "context")
        }
    }

    /// Leave a trail of what the player did before a crash.
    static func breadcrumb(_ message: String, category: String) {
        guard isEnabled else { return }
        let crumb = Breadcrumb(level: .info, category: category)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}

// MARK: - Analytics backend

/// Delivers the typed funnel events from `AnalyticsService` to Sentry.
///
/// The event contract is unchanged — this only gives it somewhere to land.
/// Swapping in a dedicated product-analytics SDK later means replacing this one
/// type, exactly as `AnalyticsService` was designed for.
struct SentryAnalyticsBackend: AnalyticsBackend {
    func track(_ event: AnalyticsEvent) async {
        let crumb = Breadcrumb(level: .info, category: "analytics")
        crumb.message = event.name
        crumb.data = event.properties
        SentrySDK.addBreadcrumb(crumb)

        #if DEBUG
        print("[analytics] \(event.name) \(event.properties)")
        #endif
    }
}
