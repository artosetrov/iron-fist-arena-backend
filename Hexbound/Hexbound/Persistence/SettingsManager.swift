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

    /// Volume of spoken lines (NPC voice-over, onboarding narration).
    var voiceVolume: Float {
        didSet { UserDefaults.standard.set(voiceVolume, forKey: AppConstants.udVoiceVolume) }
    }

    /// NPC voice-over on/off (independent of SFX and music).
    var npcVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(npcVoiceEnabled, forKey: AppConstants.udNPCVoiceEnabled) }
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
        // Speech must sit above ducked BGM, so it defaults much louder than music/SFX.
        self.voiceVolume = UserDefaults.standard.object(forKey: AppConstants.udVoiceVolume) as? Float ?? 0.8
        self.npcVoiceEnabled = UserDefaults.standard.object(forKey: AppConstants.udNPCVoiceEnabled) as? Bool ?? true
        self.pushNotifications = UserDefaults.standard.object(forKey: AppConstants.udPushNotifications) as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }
}
