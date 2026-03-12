import Foundation

enum AppConstants {
    // MARK: - Backend API
    static let apiBaseURL = URL(string: "https://iron-fist-arena-backend.vercel.app")!

    // MARK: - Supabase
    static let supabaseProjectURL = "https://gqnyozmqbhgzprsftdzp.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdxbnlvem1xYmhnenByc2Z0ZHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0NjYzMTQsImV4cCI6MjA1ODA0MjMxNH0.71bRYJv1VAtgsk1jRTINqC-YVZJR0KBIB7MESbdYKHM"
    static let supabaseAuthURL = "\(supabaseProjectURL)/auth/v1"
    static let supabaseRealtimeURL = "wss://gqnyozmqbhgzprsftdzp.supabase.co/realtime/v1/websocket"

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

    // MARK: - Game
    static let maxStamina = 120
    static let freePvpPerDay = 3
    static let pvpStaminaCost = 10
}
