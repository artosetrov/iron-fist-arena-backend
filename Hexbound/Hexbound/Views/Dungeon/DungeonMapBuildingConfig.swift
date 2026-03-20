import SwiftUI

// MARK: - Dungeon Map Building Data Model

/// A dungeon node on the dungeon map (analogous to CityBuilding on the hub).
struct DungeonMapBuilding: Identifiable {
    let id: String               // dungeon slug (e.g. "training_camp")
    let imageName: String        // asset name in xcassets (e.g. "building-dungeon")
    let label: String            // display name
    let minLevel: Int            // level required to unlock
    var relativeX: CGFloat       // 0.0...1.0 position on terrain X
    var relativeY: CGFloat       // 0.0...1.0 position on terrain Y
    var relativeSize: CGFloat    // size relative to terrain height
    let glowColor: Color         // glow color on tap / idle
    let fallbackIcon: String     // SF Symbol fallback if asset missing
    let sortOrder: Int           // display order (0 = first dungeon)
}

// MARK: - Default Dungeon Map Configurations (hardcoded fallback)

/// 10 dungeons spread across the dungeon map.
/// Positions are rough defaults — admin editor overrides via server.
let defaultDungeonMapBuildings: [DungeonMapBuilding] = [
    DungeonMapBuilding(
        id: "training_camp",
        imageName: "building-dungeon-training-camp",
        label: "Training Camp",
        minLevel: 1,
        relativeX: 0.08,
        relativeY: 0.70,
        relativeSize: 0.18,
        glowColor: Color(hex: 0xE68C33),
        fallbackIcon: "shield.lefthalf.filled",
        sortOrder: 0
    ),
    DungeonMapBuilding(
        id: "desecrated_catacombs",
        imageName: "building-dungeon-catacombs",
        label: "Catacombs",
        minLevel: 10,
        relativeX: 0.20,
        relativeY: 0.45,
        relativeSize: 0.18,
        glowColor: Color(hex: 0x8040B0),
        fallbackIcon: "building.columns.fill",
        sortOrder: 1
    ),
    DungeonMapBuilding(
        id: "volcanic_forge",
        imageName: "building-dungeon-volcanic-forge",
        label: "Volcanic Forge",
        minLevel: 20,
        relativeX: 0.32,
        relativeY: 0.65,
        relativeSize: 0.18,
        glowColor: Color(hex: 0xFF6626),
        fallbackIcon: "flame.fill",
        sortOrder: 2
    ),
    DungeonMapBuilding(
        id: "fungal_grotto",
        imageName: "building-dungeon-fungal-grotto",
        label: "Fungal Grotto",
        minLevel: 30,
        relativeX: 0.42,
        relativeY: 0.35,
        relativeSize: 0.18,
        glowColor: Color(hex: 0x4CAF50),
        fallbackIcon: "leaf.fill",
        sortOrder: 3
    ),
    DungeonMapBuilding(
        id: "scorched_mines",
        imageName: "building-dungeon-scorched-mines",
        label: "Scorched Mines",
        minLevel: 40,
        relativeX: 0.52,
        relativeY: 0.60,
        relativeSize: 0.18,
        glowColor: Color(hex: 0xE65100),
        fallbackIcon: "hammer.fill",
        sortOrder: 4
    ),
    DungeonMapBuilding(
        id: "frozen_abyss",
        imageName: "building-dungeon-frozen-abyss",
        label: "Frozen Abyss",
        minLevel: 50,
        relativeX: 0.62,
        relativeY: 0.30,
        relativeSize: 0.18,
        glowColor: Color(hex: 0x42A5F5),
        fallbackIcon: "snowflake",
        sortOrder: 5
    ),
    DungeonMapBuilding(
        id: "realm_of_light",
        imageName: "building-dungeon-realm-of-light",
        label: "Realm of Light",
        minLevel: 60,
        relativeX: 0.72,
        relativeY: 0.55,
        relativeSize: 0.18,
        glowColor: Color(hex: 0xFFD54F),
        fallbackIcon: "sun.max.fill",
        sortOrder: 6
    ),
    DungeonMapBuilding(
        id: "shadow_depths",
        imageName: "building-dungeon-shadow-depths",
        label: "Shadow Depths",
        minLevel: 70,
        relativeX: 0.80,
        relativeY: 0.40,
        relativeSize: 0.18,
        glowColor: Color(hex: 0x424242),
        fallbackIcon: "moon.fill",
        sortOrder: 7
    ),
    DungeonMapBuilding(
        id: "clockwork_citadel",
        imageName: "building-dungeon-clockwork-citadel",
        label: "Clockwork Citadel",
        minLevel: 80,
        relativeX: 0.88,
        relativeY: 0.60,
        relativeSize: 0.18,
        glowColor: Color(hex: 0x78909C),
        fallbackIcon: "gearshape.2.fill",
        sortOrder: 8
    ),
    DungeonMapBuilding(
        id: "infernal_throne",
        imageName: "building-dungeon-infernal-throne",
        label: "Infernal Throne",
        minLevel: 90,
        relativeX: 0.94,
        relativeY: 0.35,
        relativeSize: 0.20,
        glowColor: Color(hex: 0xB71C1C),
        fallbackIcon: "crown.fill",
        sortOrder: 9
    ),
]

// MARK: - Resolved dungeon map buildings (server overrides → hardcoded defaults)

@MainActor
func resolvedDungeonMapBuildings(from cache: GameDataCache) -> [DungeonMapBuilding] {
    let overrides = cache.dungeonMapLayout
    guard !overrides.isEmpty else { return defaultDungeonMapBuildings }

    return defaultDungeonMapBuildings.map { building in
        var b = building
        if let o = overrides[building.id] {
            b.relativeX = o.x
            b.relativeY = o.y
            if let size = o.size { b.relativeSize = size }
        }
        return b
    }
}

// MARK: - Convenience

var dungeonMapBuildings: [DungeonMapBuilding] { defaultDungeonMapBuildings }
