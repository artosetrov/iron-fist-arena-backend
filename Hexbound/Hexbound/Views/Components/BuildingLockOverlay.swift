import SwiftUI

/// Lock overlay shown on hub buildings that haven't been unlocked yet.
/// Displays a lock icon and required level.
struct BuildingLockOverlay: View {
    let requiredLevel: Int

    var body: some View {
        ZStack {
            // Darken the building
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(Color.black.opacity(0.6))

            // Lock icon + level
            VStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "lock.fill")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text("LV.\(requiredLevel)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(LayoutConstants.spaceSM)
            .background(DarkFantasyTheme.bgDarkPanel.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        }
    }
}

/// Configuration for building unlock levels (client-side static config).
/// The character level is server-authoritative — this just controls UI visibility.
///
/// W2.D4 — Front-loaded Epic Seven schedule (2/4/6/6/8/8/12).
/// Arena opens immediately after tutorial victory (the player is already there).
/// Rationale: dense early-game unlock cadence creates a constant "what unlocks
/// next?" anticipation loop during the first week of play.
///
/// See: docs/07_ui_ux/W2_D4_UNLOCK_SCHEDULE.md
enum BuildingUnlockConfig {
    /// Maps CityBuilding.id → required character level
    static let levels: [String: Int] = [
        "arena": 1,            // Entered during tutorial — always open
        "shop": 2,             // First post-tutorial unlock (immediate hook)
        "achievements": 4,     // Reward tracking kicks in
        "dungeon": 6,          // PvE content gate
        "gold-mine": 6,        // Passive income unlock (paired with dungeon)
        "tavern": 8,           // Social / daily loop hook
        "battlepass": 8,       // Long-term progression (paired with tavern)
        "ranks": 12,           // Endgame competitive tier
        "guild-hall": 99,      // Coming Soon — effectively locked ("SOON")
        "black-market": 99,    // Coming Soon — effectively locked ("SOON")
    ]

    /// Check if building is unlocked for given character level
    static func isUnlocked(_ buildingId: String, characterLevel: Int) -> Bool {
        guard let required = levels[buildingId] else { return true }
        return characterLevel >= required
    }

    /// Get required level for a building (nil = always unlocked)
    static func requiredLevel(for buildingId: String) -> Int? {
        levels[buildingId]
    }

    /// Buildings that unlock at exactly this level (used by ceremony dispatcher).
    static func buildingsUnlocking(at level: Int) -> [String] {
        levels
            .filter { $0.value == level && $0.value < 99 && $0.value > 1 }
            .map(\.key)
            .sorted()
    }

    /// Buildings that will unlock at level+1 — used for anticipation toasts on
    /// the level BEFORE the unlock ("One more level — Gold Mine awakens.")
    static func buildingsUnlockingNext(currentLevel: Int) -> [String] {
        buildingsUnlocking(at: currentLevel + 1)
    }
}
