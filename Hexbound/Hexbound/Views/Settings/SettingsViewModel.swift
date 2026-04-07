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

    var linkAccountMessage: String?
    var isDeleting = false

    init(appState: AppState) {
        self.appState = appState
    }

    func linkAccount() {
        appState.mainPath.append(AppRoute.upgradeGuest)
    }

    func logout() {
        appState.logout()
    }

    func deleteAccount() async {
        guard !isDeleting else { return }
        isDeleting = true
        do {
            _ = try await APIClient.shared.postRaw("/api/user/delete")
            isDeleting = false
            appState.logout()
        } catch {
            isDeleting = false
            appState.showToast("Failed to delete account", subtitle: error.localizedDescription, type: .error)
        }
    }
}
