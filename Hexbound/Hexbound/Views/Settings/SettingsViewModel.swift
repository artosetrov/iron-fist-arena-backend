import SwiftUI

@MainActor @Observable
final class SettingsViewModel {
    private let appState: AppState
    private let settings = SettingsManager.shared

    var soundEnabled: Bool {
        get { !settings.isMuted }
        set { settings.isMuted = !newValue }
    }

    var musicEnabled: Bool {
        get { settings.bgmVolume > 0 }
        set {
            settings.bgmVolume = newValue ? 0.2 : 0
            AudioManager.shared.syncVolume()
        }
    }

    var bgmVolume: Double {
        get { Double(settings.bgmVolume) * 100 }
        set {
            settings.bgmVolume = Float(newValue / 100)
            AudioManager.shared.syncVolume()
        }
    }

    var sfxVolume: Double {
        get { Double(settings.sfxVolume) * 100 }
        set { settings.sfxVolume = Float(newValue / 100) }
    }

    var pushNotifications: Bool {
        get { settings.pushNotifications }
        set { settings.pushNotifications = newValue }
    }

    var selectedLanguageIndex: Int {
        get { Self.languages.firstIndex(of: settings.language) ?? 0 }
        set { settings.language = Self.languages[newValue] }
    }

    static let languages = ["en", "es", "fr", "de", "pt", "ru", "ja", "ko", "zh"]
    static let languageNames = [
        "English", "Spanish", "French", "German",
        "Portuguese", "Russian", "Japanese", "Korean", "Chinese"
    ]

    var linkAccountMessage: String?

    init(appState: AppState) {
        self.appState = appState
    }

    func linkAccount() {
        linkAccountMessage = "Coming soon..."
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            linkAccountMessage = nil
        }
    }

    func logout() {
        appState.logout()
    }

    func deleteAccount() async {
        do {
            _ = try await APIClient.shared.postRaw("/api/user/delete")
            appState.logout()
        } catch {
            appState.showToast("Failed to delete account", subtitle: error.localizedDescription, type: .error)
        }
    }
}
