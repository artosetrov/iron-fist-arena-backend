import SwiftUI

// MARK: - Combat FX Asset Map
// Maps CombatLog turn data → PNG asset names for the image overlay system.
// Assets are 256×256 PNG illustrations in Assets.xcassets with "fx-" prefix.

enum CombatFXAssetMap {

    // MARK: - Main Mapping

    /// Returns the asset name and display mode for a given combat turn.
    /// - Parameter turn: The combat log entry to map
    /// - Parameter isPlayerAttacking: Whether the player is the attacker
    /// - Returns: FX descriptor or nil if no FX should play
    static func fxForTurn(_ turn: CombatLog, isPlayerAttacking: Bool) -> CombatFXDescriptor? {
        if turn.isDodge {
            // Code-drawn callout (no baked-text PNG; see ART_STYLE_GUIDE, Generation Rules 1)
            return CombatFXDescriptor(
                asset: nil,
                mode: .fullscreen,
                tintColor: nil,
                callout: .dodge
            )
        }

        if turn.isMiss {
            return CombatFXDescriptor(
                asset: nil,
                mode: .fullscreen,
                tintColor: nil,
                callout: .miss
            )
        }

        if turn.isBlocked {
            return CombatFXDescriptor(
                asset: randomBlock(),
                mode: .onDefender,
                tintColor: nil
            )
        }

        // Damage hit
        if turn.damage > 0 {
            let damageAsset = assetForDamageType(turn.damageType)

            if turn.isCrit {
                // Crit: damage FX on avatar + fullscreen code-drawn CRIT callout
                return CombatFXDescriptor(
                    asset: damageAsset,
                    mode: .onDefender,
                    tintColor: nil,
                    callout: .crit
                )
            } else {
                return CombatFXDescriptor(
                    asset: damageAsset,
                    mode: .onDefender,
                    tintColor: nil
                )
            }
        }

        return nil
    }

    /// Returns heal FX descriptor
    static func healFX() -> CombatFXDescriptor {
        CombatFXDescriptor(
            asset: randomHeal(),
            mode: .onAttacker,
            tintColor: nil
        )
    }

    /// Returns status effect FX descriptor
    static func statusFX(_ status: String) -> CombatFXDescriptor {
        let asset: String
        switch status.lowercased() {
        case "poison":
            asset = "fx-poison-splat"
        case "burn":
            asset = randomFire()
        default:
            asset = "fx-physical-burst"
        }
        return CombatFXDescriptor(
            asset: asset,
            mode: .onDefender,
            tintColor: nil
        )
    }

    // MARK: - Asset Pools (randomized for variety)

    private static let physicalAssets = [
        "fx-physical-burst",
        "fx-physical-impact",
        "fx-physical-explosion",
        "fx-physical-slash",
        "fx-physical-arc",
        "fx-physical-beam",
        "fx-physical-doublehit"
    ]

    private static let magicalAssets = [
        "fx-magical-burst",
        "fx-magical-fractal",
        "fx-magical-vortex"
    ]

    private static let poisonAssets = [
        "fx-poison-skull",
        "fx-poison-blob"
    ]

    private static let fireAssets = [
        "fx-fire-flame",
        "fx-fire-pillar"
    ]

    private static let trueAssets = [
        "fx-true-lightning"
    ]

    private static let blockAssets = [
        "fx-block-hexshield",
        "fx-block-runeshield",
        "fx-block-silvershield"
    ]

    private static let healAssets = [
        "fx-heal-nature",
        "fx-heal-divine"
    ]

    // MARK: - Randomizers

    private static func assetForDamageType(_ type: String?) -> String {
        switch type?.lowercased() {
        case "physical":
            return physicalAssets.randomElement() ?? "fx-physical-burst"
        case "magical":
            return magicalAssets.randomElement() ?? "fx-magical-burst"
        case "poison":
            return poisonAssets.randomElement() ?? "fx-poison-skull"
        case "fire":
            return fireAssets.randomElement() ?? "fx-fire-flame"
        case "true_damage":
            return trueAssets.randomElement() ?? "fx-true-lightning"
        default:
            // Default to physical for unknown types
            return physicalAssets.randomElement() ?? "fx-physical-burst"
        }
    }

    private static func randomBlock() -> String {
        blockAssets.randomElement() ?? "fx-block-hexshield"
    }

    private static func randomHeal() -> String {
        healAssets.randomElement() ?? "fx-heal-nature"
    }

    private static func randomFire() -> String {
        fireAssets.randomElement() ?? "fx-fire-flame"
    }
}

// MARK: - FX Descriptor

struct CombatFXDescriptor {
    /// PNG FX plate (shape only: slash, burst, shield). `nil` for text-only callouts.
    let asset: String?
    let mode: CombatFXMode
    let tintColor: Color?
    /// Code-drawn text callout shown fullscreen, on top of the plate when both are present.
    var callout: CombatFXCallout? = nil
}

// MARK: - Combat Callout (code-drawn text)
// Replaces the retired baked-text PNGs (fx-dodge-text, fx-miss-text, fx-crit-text,
// fx-critical-text). Text is design-system typography and localizable.

enum CombatFXCallout: Equatable {
    case dodge
    case miss
    case crit

    @MainActor var text: String {
        switch self {
        case .dodge: return "combat.dodge".localized
        case .miss:  return "combat.miss".localized
        case .crit:  return "combat.crit".localized
        }
    }

    var color: Color {
        switch self {
        case .dodge: return DarkFantasyTheme.info
        case .miss:  return DarkFantasyTheme.textSecondary
        case .crit:  return DarkFantasyTheme.goldBright
        }
    }
}

enum CombatFXMode {
    /// Displayed centered on the defender's avatar (160×160pt)
    case onDefender
    /// Displayed centered on the attacker's avatar (for heals)
    case onAttacker
    /// Displayed centered on screen (240pt plates, or code-drawn CRIT / DODGE / MISS callouts)
    case fullscreen
}
