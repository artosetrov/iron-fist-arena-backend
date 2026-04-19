import Foundation

enum AppConstants {

    private enum ConfigKey {
        static let environment = "HexboundEnvironment"
        static let apiBaseURL = "HexboundAPIBaseURL"
        static let supabaseProjectURL = "HexboundSupabaseProjectURL"
        static let supabaseAnonKey = "HexboundSupabaseAnonKey"
        static let googleClientID = "HexboundGoogleClientID"
        static let googleReversedClientID = "HexboundGoogleReversedClientID"
    }

    // MARK: - Environment
    // Runtime environment now comes from build-time xcconfig + Info.plist.
    // Debug and Release can be wired to different backends without changing Swift code.

    enum Environment: String {
        case production
        case staging

        static var current: Environment {
            let configuredValue = AppConstants.requiredConfigValue(for: ConfigKey.environment)
            guard let parsed = Environment(rawValue: configuredValue) else {
                fatalError("Invalid HexboundEnvironment value: \(configuredValue)")
            }
            return parsed
        }
    }

    // MARK: - Backend API
    static var apiBaseURL: URL {
        let configuredValue = requiredConfigValue(for: ConfigKey.apiBaseURL)
        guard let url = URL(string: configuredValue) else {
            fatalError("Invalid HexboundAPIBaseURL: \(configuredValue)")
        }
        return url
    }

    // MARK: - Supabase
    static let supabaseProjectURL = requiredConfigValue(for: ConfigKey.supabaseProjectURL)
    static let supabaseAnonKey = requiredConfigValue(for: ConfigKey.supabaseAnonKey)
    static let supabaseAuthURL = "\(supabaseProjectURL)/auth/v1"
    static let supabaseRealtimeURL: String = {
        guard var components = URLComponents(string: supabaseProjectURL) else {
            fatalError("Invalid HexboundSupabaseProjectURL: \(supabaseProjectURL)")
        }
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/realtime/v1/websocket"
        guard let value = components.string else {
            fatalError("Failed to build Supabase realtime URL")
        }
        return value
    }()

    // MARK: - Google Sign-In
    static let googleClientID = requiredConfigValue(for: ConfigKey.googleClientID)
    static let googleReversedClientID = requiredConfigValue(for: ConfigKey.googleReversedClientID)

    // MARK: - Networking
    static let requestTimeout: TimeInterval = 30
    static let maxRetries = 0

    // MARK: - Keychain Keys
    static let keychainAccessToken = "hexbound_access_token"
    static let keychainRefreshToken = "hexbound_refresh_token"
    static let keychainIsGuest = "hexbound_is_guest"
    static let keychainDeviceId = "hexbound_device_id"

    // MARK: - UserDefaults Keys
    static let udRememberMe = "remember_me"
    static let udBGMVolume = "bgm_volume"
    static let udSFXVolume = "sfx_volume"
    static let udIsMuted = "is_muted"
    static let udLanguage = "language"
    static let udPushNotifications = "push_notifications"
    static let udTutorialCompleted = "tutorial_completed_steps"
    static let udFTUECompleted = "ftue_completed_objectives"
    static let udFTUEDismissed = "ftue_dismissed"
    static let udNPCMerchantDismissed = "npc_merchant_dismissed"
    static let udNPCArenaGuideDismissed = "npc_arena_guide_dismissed"

    // MARK: - Game (DEPRECATED fallbacks)
    //
    // ⚠️ These constants are DEPRECATED fallbacks only. The real values come from
    // `/api/game/init` → `cache.gameConfig.*` and must be read cache-first with these
    // as last-resort fallbacks (see `CityMapView`, `ArenaViewModel` for pattern).
    //
    // Do NOT add new hardcoded game constants here. The `check_ios_backend_drift.sh`
    // preflight guard will block any new `static let` additions matching the forbidden
    // name pattern. New game constants belong in `backend/src/lib/game/balance.ts` and
    // must be exposed via `GameConfig` → `/api/game/init`.
    //
    // W4 Polish will remove these entirely once the SSoT migration is disk-persisted
    // and version-gated.

    // DEPRECATED: use cache.gameConfig.maxStamina — unused fallback, pending W4 removal
    static let maxStamina = 180
    // DEPRECATED: use cache.gameConfig.freePvpPerDay — migrated 2026-04-09 (W1.D3), kept as fallback
    static let freePvpPerDay = 3
    // DEPRECATED: use cache.gameConfig.pvpStaminaCost — pending full migration in W4
    static let pvpStaminaCost = 10

    private static func requiredConfigValue(for key: String) -> String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Missing Info.plist value for \(key)")
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.hasPrefix("__MISSING_") {
            fatalError("Unconfigured Info.plist value for \(key)")
        }

        return value
    }
}
