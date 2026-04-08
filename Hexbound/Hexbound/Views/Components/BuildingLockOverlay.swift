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
                    .font(DarkFantasyTheme.badge)
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
enum BuildingUnlockConfig {
    /// Maps CityBuilding.id → required character level
    static let levels: [String: Int] = [
        "arena": 1,
        "shop": 1,
        "achievements": 1,
        "dungeon": 3,
        "gold-mine": 5,
        "tavern": 7,
        "battlepass": 10,
        "ranks": 10,
        "guild-hall": 15,
        "black-market": 99,  // Coming Soon — effectively locked
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
}
