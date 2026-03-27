import SwiftUI

@MainActor @Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var rememberMe: Bool {
        didSet { UserDefaults.standard.set(rememberMe, forKey: AppConstants.udRememberMe) }
    }

    var bgmVolume: Float {
        didSet { UserDefaults.standard.set(bgmVolume, forKey: AppConstants.udBGMVolume) }
    }

    var sfxVolume: Float {
        didSet { UserDefaults.standard.set(sfxVolume, forKey: AppConstants.udSFXVolume) }
    }

    var isMuted: Bool {
        didSet { UserDefaults.standard.set(isMuted, forKey: AppConstants.udIsMuted) }
    }

    var pushNotifications: Bool {
        didSet { UserDefaults.standard.set(pushNotifications, forKey: AppConstants.udPushNotifications) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    private init() {
        // Load from UserDefaults with defaults of 20% for audio
        self.rememberMe = UserDefaults.standard.bool(forKey: AppConstants.udRememberMe)
        self.bgmVolume = UserDefaults.standard.object(forKey: AppConstants.udBGMVolume) as? Float ?? 0.2
        self.sfxVolume = UserDefaults.standard.object(forKey: AppConstants.udSFXVolume) as? Float ?? 0.2
        self.isMuted = UserDefaults.standard.bool(forKey: AppConstants.udIsMuted)
        self.pushNotifications = UserDefaults.standard.object(forKey: AppConstants.udPushNotifications) as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
}
