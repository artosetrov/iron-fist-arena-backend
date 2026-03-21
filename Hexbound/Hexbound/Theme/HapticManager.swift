import UIKit

// MARK: - Haptic Feedback Manager (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.4)
// Centralized haptic feedback for consistent game feel.
// Rule: Haptic = special moments only. Never on scroll, passive viewing, or every tap.

@MainActor
enum HapticManager {

    // MARK: - Impact Feedback (physical hits)

    /// Light tap — stat increment, filter toggle, minor interaction
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact — equip item, claim reward, purchase confirm
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact — FIGHT press, critical hit, boss encounter, legendary reveal
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback (outcomes)

    /// Success — victory, achievement claimed, purchase complete, level up
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning — low stamina, dangerous action about to happen
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error — form validation fail, insufficient funds, action blocked
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback (choices)

    /// Selection changed — tab switch, stance zone tap, filter select
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
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
