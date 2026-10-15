import UIKit

// MARK: - Haptic Feedback Manager (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.4)
// Centralized haptic feedback for consistent game feel.
// Rule: Haptic = special moments only. Never on scroll, passive viewing, or every tap.

@MainActor
enum HapticManager {

    // MARK: - Shared generators
    //
    // Latency pass (2026-10-15): a generator used to be allocated per call
    // and fired without `prepare()`, so the Taptic Engine spun up cold on
    // every tap (iOS documents up to tens of ms before the buzz lands).
    // One long-lived generator per style, re-prepared after each fire,
    // keeps the engine warm for the next interaction.
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    /// Warm every generator. Call on launch and when a screen with
    /// tap-heavy interaction (combat, minigames) appears.
    static func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    private static var isEnabled: Bool { SettingsManager.shared.hapticsEnabled }

    // MARK: - Impact Feedback (physical hits)

    /// Light tap — stat increment, filter toggle, minor interaction
    static func light() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Medium impact — equip item, claim reward, purchase confirm
    static func medium() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Heavy impact — FIGHT press, critical hit, boss encounter, legendary reveal
    static func heavy() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Notification Feedback (outcomes)

    /// Success — victory, achievement claimed, purchase complete, level up
    static func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Warning — low stamina, dangerous action about to happen
    static func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Error — form validation fail, insufficient funds, action blocked
    static func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Selection Feedback (choices)

    /// Selection changed — tab switch, stance zone tap, filter select
    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Compound Patterns (game-specific)

    /// Victory celebration — triple success tap
    static func victory() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            medium()
        }
    }

    /// Defeat — single somber warning
    static func defeat() {
        warning()
    }

    /// Legendary item reveal — heavy + delay + success
    static func legendaryReveal() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            success()
        }
    }

    /// Coin cascade — rapid light taps (for coin fly animation)
    static func coinCascade(count: Int) {
        let cappedCount = min(count, 8) // Cap at 8 to avoid haptic overload
        for i in 0..<cappedCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                light()
            }
        }
    }

    /// Rank up — heavy slam + success
    static func rankUp() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            success()
        }
    }

    /// Screen shake feedback — paired with visual shake
    static func shake() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            medium()
        }
    }

    /// Stamp effect — single decisive impact (achievement claimed, floor cleared)
    static func stamp() {
        medium()
    }
}
