import Foundation
import SwiftUI

// MARK: - Localization Manager

/// Manages runtime language switching without restarting the app.
/// Stores user preference and provides localized string lookup.
@MainActor @Observable
final class LocalizationManager {

    static let shared = LocalizationManager()

    /// Currently selected language code (e.g. "en", "ru").
    private(set) var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            bundle = Self.bundle(for: currentLanguage)
        }
    }

    /// Bundle for the current language's .lproj folder.
    private(set) var bundle: Bundle

    private init() {
        self.currentLanguage = "en"
        self.bundle = Self.bundle(for: "en")
    }

    /// Look up a localized string by key, with optional format arguments.
    func localized(_ key: String, _ args: CVarArg...) -> String {
        let template = bundle.localizedString(forKey: key, value: nil, table: nil)
        if args.isEmpty { return template }
        return String(format: template, arguments: args)
    }

    // MARK: - Private

    private static func bundle(for languageCode: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            // Fallback to English
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                return enBundle
            }
            return Bundle.main
        }
        return langBundle
    }
}

// MARK: - String Extension

@MainActor
extension String {
    /// Returns the localized version of this string key.
    /// Usage: `"shop.title".localized`
    var localized: String {
        LocalizationManager.shared.localized(self)
    }

    /// Returns the localized version with format arguments.
    /// Usage: `"dungeon.floor".localized(with: 5)` → "Floor 5"
    func localized(with args: CVarArg...) -> String {
        let template = LocalizationManager.shared.bundle.localizedString(
            forKey: self, value: nil, table: nil
        )
        return String(format: template, arguments: args)
    }
}

// MARK: - SwiftUI Text Extension

@MainActor
extension Text {
    /// Create a Text from a localization key using our custom LocalizationManager.
    /// Usage: `Text(l10n: "shop.title")`
    init(l10n key: String) {
        self.init(key.localized)
    }

    /// Create a Text from a localization key with format args.
    /// Usage: `Text(l10n: "dungeon.floor", args: 5)`
    init(l10n key: String, args: CVarArg...) {
        let template = LocalizationManager.shared.bundle.localizedString(
            forKey: key, value: nil, table: nil
        )
        self.init(String(format: template, arguments: args))
    }
}

// MARK: - Type-Safe Keys (most common)

@MainActor
enum L10n {
    // Common
    static var ok: String { "common.ok".localized }
    static var cancel: String { "common.cancel".localized }
    static var save: String { "common.save".localized }
    static var delete: String { "common.delete".localized }
    static var confirm: String { "common.confirm".localized }
    static var loading: String { "common.loading".localized }
    static var error: String { "common.error".localized }
    static var retry: String { "common.retry".localized }
    static var comingSoon: String { "common.comingSoon".localized }

    // Auth
    static var login: String { "auth.login".localized }
    static var register: String { "auth.register".localized }
    static var logout: String { "auth.logout".localized }

    // Shop
    static var shopTitle: String { "shop.title".localized }
    static var merchant: String { "shop.merchant".localized }

    // Arena
    static var arenaTitle: String { "arena.title".localized }
    static var findMatch: String { "arena.findMatch".localized }
    static var victory: String { "arena.victory".localized }
    static var defeat: String { "arena.defeat".localized }

    // Errors
    static var networkError: String { "error.network".localized }
    static var serverError: String { "error.serverError".localized }
    static var notEnoughGold: String { "error.notEnoughGold".localized }
    static var notEnoughGems: String { "error.notEnoughGems".localized }
}
