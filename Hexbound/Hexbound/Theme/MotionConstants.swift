import SwiftUI

// MARK: - Motion System (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3)
// Unified animation constants for the entire app.
// Philosophy: feedback, storytelling, guidance — never decoration.

enum MotionConstants {

    // MARK: - Speed Tiers

    /// Instant: button press, toggle, micro-feedback (0.1–0.15s)
    static let instant: Double = 0.12
    /// Fast: tab switch, card appear, sheet open (0.2–0.3s)
    static let fast: Double = 0.25
    /// Normal: screen transition, panel slide, progress fill (0.35–0.5s)
    static let normal: Double = 0.4
    /// Reward: loot reveal, level up, rank change (0.5–0.8s)
    static let reward: Double = 0.6
    /// Epic: legendary drop, first win, rank-up ceremony (0.8–1.5s)
    static let epic: Double = 1.2

    // MARK: - Easing Presets (SwiftUI Animation)

    /// Snappy response for micro-interactions
    static let snappy = Animation.easeOut(duration: 0.2)
    /// Smooth transitions between states
    static let smooth = Animation.easeInOut(duration: 0.35)
    /// Natural spring for sheets, modals, cards
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    /// Bouncier spring for rewards, celebrations
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.55)
    /// Dramatic entrance for epic reveals
    static let dramatic = Animation.spring(response: 0.5, dampingFraction: 0.6)
    /// Gentle breathing for idle ambient loops
    static let breathing = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
    /// Pulse loop for attention CTAs (FIGHT button, claimable badge)
    static let pulse = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
    /// Slow glow for rarity ambient effects
    static let glowLoop = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

    // MARK: - Button Press Scales
    // DEPRECATED: All press scales have been replaced with opacity feedback

    /// Primary gold CTA press (deprecated)
    // static let pressPrimary: CGFloat = 0.95
    /// Secondary buttons (deprecated)
    // static let pressSecondary: CGFloat = 0.97
    /// FIGHT / main action — deeper press (deprecated)
    // static let pressFight: CGFloat = 0.92
    /// Danger actions (deprecated)
    // static let pressDanger: CGFloat = 0.96
    /// Ghost / tertiary — minimal press (deprecated)
    // static let pressGhost: CGFloat = 0.98
    /// Claim / reward buttons — deepest for satisfaction (deprecated)
    // static let pressClaim: CGFloat = 0.90

    // MARK: - Card Behavior

    /// Card appearing in list/grid (slide up distance)
    static let cardSlideDistance: CGFloat = 8
    // Card press scale (deprecated — use opacity instead)
    // static let cardPress: CGFloat = 0.97
    // Card selection scale (deprecated — use opacity instead)
    // static let cardSelect: CGFloat = 1.02
    /// Stagger delay between cards in a list
    static let cardStagger: Double = 0.05

    // MARK: - Panel / Sheet

    /// Sheet slide-up from bottom
    static let sheetSpring = Animation.spring(response: 0.35, dampingFraction: 0.72)
    /// Modal center scale-in
    static let modalScaleFrom: CGFloat = 0.9
    /// Overlay background fade duration
    static let overlayFade: Double = 0.25

    // MARK: - Reward Reveal Phases

    /// Anticipation pause before reveal (screen dims)
    static let anticipationDuration: Double = 0.3
    /// Item reveal animation
    static let revealDuration: Double = 0.35
    /// Celebration burst
    static let celebrationDuration: Double = 0.4
    /// Settle into final position
    static let settleDuration: Double = 0.15

    // MARK: - Number Tick-Up

    /// Standard tick-up for gold/XP/rating
    static let tickUpDuration: Double = 0.5
    /// Short tick-up for small changes
    static let tickUpShort: Double = 0.3
    /// Extended tick-up for big numbers (level up, season summary)
    static let tickUpLong: Double = 0.8

    // MARK: - Progress Bar

    /// Minimum fill animation duration
    static let progressFillMin: Double = 0.3
    /// Duration multiplier per percentage point
    static let progressFillPerPoint: Double = 0.01
    /// Maximum fill animation duration (prevents absurdly long fills)
    static let progressFillMax: Double = 1.2

    // MARK: - Particle Counts (by rarity / context)

    static let particlesCommon: Int = 0
    static let particlesUncommon: Int = 5
    static let particlesRare: Int = 15
    static let particlesEpic: Int = 25
    static let particlesLegendary: Int = 40
    static let particlesClaim: Int = 20
    static let particlesCoinFly: Int = 8

    // MARK: - Screen Shake

    /// Standard impact shake (crit hit, boss encounter)
    static let shakeIntensity: CGFloat = 5
    /// Light shake (damage received)
    static let shakeLightIntensity: CGFloat = 3
    /// Shake cycles
    static let shakeCycles: Int = 3
    /// Shake total duration
    static let shakeDuration: Double = 0.25

    // MARK: - VS Screen / Battle Intro

    /// VS text scale-in (starts large, slams to normal)
    static let vsScaleFrom: CGFloat = 2.5
    /// VS text target scale
    static let vsScaleTo: CGFloat = 1.0
    /// VS slam duration
    static let vsSlamDuration: Double = 0.2
    /// Full intro sequence duration
    static let vsIntroTotal: Double = 1.2

    // MARK: - Tab Switch

    /// Tab content crossfade
    static let tabCrossfade: Double = 0.2
    /// Tab indicator slide
    static let tabIndicatorSlide = Animation.spring(response: 0.25, dampingFraction: 0.75)
}

// MARK: - Computed Helpers

extension MotionConstants {
    /// Calculate progress bar fill duration based on percentage change
    static func progressFillDuration(deltaPercent: Double) -> Double {
        let raw = progressFillMin + (abs(deltaPercent) * progressFillPerPoint)
        return min(raw, progressFillMax)
    }

    /// Calculate stagger delay for item at index
    static func staggerDelay(index: Int) -> Double {
        Double(index) * cardStagger
    }

    /// Reward reveal total duration for a given rarity tier (0=common, 4=legendary)
    static func rewardRevealDuration(rarityTier: Int) -> Double {
        switch rarityTier {
        case 0: return revealDuration + settleDuration                                           // ~0.5s
        case 1: return revealDuration + celebrationDuration + settleDuration                     // ~0.9s
        case 2: return anticipationDuration + revealDuration + celebrationDuration + settleDuration // ~1.2s
        case 3: return anticipationDuration * 1.3 + revealDuration * 1.2 + celebrationDuration + settleDuration // ~1.5s
        default: return anticipationDuration * 1.5 + revealDuration * 1.5 + celebrationDuration * 1.5 + settleDuration // ~2.0s
        }
    }
}
