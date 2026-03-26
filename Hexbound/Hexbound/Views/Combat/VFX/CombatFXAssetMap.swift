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
            return CombatFXDescriptor(
                asset: "fx-dodge-text",
                mode: .fullscreen,
                tintColor: nil
            )
        }

        if turn.isMiss {
            return CombatFXDescriptor(
                asset: "fx-miss-text",
                mode: .fullscreen,
                tintColor: nil
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
                // Crit: damage FX on avatar + fullscreen CRIT text
                return CombatFXDescriptor(
                    asset: damageAsset,
                    mode: .onDefender,
                    tintColor: nil,
                    critOverlay: randomCritText()
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

    private static let critTextAssets = [
        "fx-crit-text",
        "fx-critical-text"
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

    private static func randomCritText() -> String {
        critTextAssets.randomElement() ?? "fx-crit-text"
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
    let asset: String
    let mode: CombatFXMode
    let tintColor: Color?
    var critOverlay: String? = nil
}

enum CombatFXMode {
    /// Displayed centered on the defender's avatar (160×160pt)
    case onDefender
    /// Displayed centered on the attacker's avatar (for heals)
    case onAttacker
    /// Displayed centered on screen (240×240pt, for CRIT/DODGE/MISS text)
    case fullscreen
}
