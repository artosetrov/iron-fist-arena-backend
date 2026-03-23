import Foundation

enum AppConstants {

    // MARK: - Environment
    // Switch via Xcode scheme: Edit Scheme → Run → Arguments → Environment Variables
    // Set HEXBOUND_ENV = "staging" for staging, or leave unset for production

    enum Environment: String {
        case production
        case staging

        static var current: Environment {
            if let env = ProcessInfo.processInfo.environment["HEXBOUND_ENV"],
               let parsed = Environment(rawValue: env) {
                return parsed
            }
            #if DEBUG
            return .staging
            #else
            return .production
            #endif
        }
    }

    // MARK: - Backend API
    static var apiBaseURL: URL {
        switch Environment.current {
        case .production:
            return URL(string: "https://api.hexboundapp.com")!
        case .staging:
            // TODO: Replace with actual staging URL when available
            return URL(string: "https://api.hexboundapp.com")!
        }
    }

    // MARK: - Supabase
    static let supabaseProjectURL = "https://gqnyozmqbhgzprsftdzp.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdxbnlvem1xYmhnenByc2Z0ZHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0NjYzMTQsImV4cCI6MjA1ODA0MjMxNH0.71bRYJv1VAtgsk1jRTINqC-YVZJR0KBIB7MESbdYKHM"
    static let supabaseAuthURL = "\(supabaseProjectURL)/auth/v1"
    static let supabaseRealtimeURL = "wss://gqnyozmqbhgzprsftdzp.supabase.co/realtime/v1/websocket"

    // MARK: - Google Sign-In
    static let googleClientID = "443362223078-f8bse9a7lddqb2ajoqo18tbqlbigekv0.apps.googleusercontent.com"

    // MARK: - Networking
    static let requestTimeout: TimeInterval = 30
    static let maxRetries = 0

    // MARK: - Keychain Keys
    static let keychainAccessToken = "hexbound_access_token"
    static let keychainRefreshToken = "hexbound_refresh_token"

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

    // MARK: - Game
    static let maxStamina = 120
    static let freePvpPerDay = 3
    static let pvpStaminaCost = 10
}
