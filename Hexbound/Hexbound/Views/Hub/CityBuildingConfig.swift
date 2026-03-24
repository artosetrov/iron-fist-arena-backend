import SwiftUI

// MARK: - City Building Data Model

struct CityBuilding: Identifiable {
    let id: String
    let imageName: String        // asset name in xcassets
    let label: String            // banner text
    let route: AppRoute?         // navigation target (nil = Coming Soon placeholder)
    var relativeX: CGFloat       // 0.0...1.0 position on terrain X
    var relativeY: CGFloat       // 0.0...1.0 position on terrain Y
    var relativeSize: CGFloat    // size relative to terrain height
    let glowColor: Color         // glow color on tap / idle
    let fallbackIcon: String     // SF Symbol fallback if asset missing
    var labelYOffset: CGFloat = 0 // extra Y offset for label (relative to terrain height)
}

// MARK: - Default Building Configurations (hardcoded fallback)

let defaultCityBuildings: [CityBuilding] = [
    CityBuilding(
        id: "shop",
        imageName: "building-shop",
        label: "SHOP",
        route: .shop,
        relativeX: 0.42,
        relativeY: 0.48,
        relativeSize: 0.24,
        glowColor: Color.orange,
        fallbackIcon: "bag.fill"
    ),
    CityBuilding(
        id: "battlepass",
        imageName: "building-battlepass",
        label: "BATTLE PASS",
        route: .battlePass,
        relativeX: 0.50,
        relativeY: 0.82,
        relativeSize: 0.24,
        glowColor: Color.orange,
        fallbackIcon: "star.circle.fill"
    ),
    CityBuilding(
        id: "achievements",
        imageName: "building-achievements",
        label: "ACHIEVEMENTS",
        route: .achievements,
        relativeX: 0.53,
        relativeY: 0.17,
        relativeSize: 0.22,
        glowColor: Color.orange,
        fallbackIcon: "medal.fill"
    ),
    CityBuilding(
        id: "gold-mine",
        imageName: "building-gold-mine",
        label: "GOLD MINE",
        route: .goldMine,
        relativeX: 0.22,
        relativeY: 0.52,
        relativeSize: 0.22,
        glowColor: Color.orange,
        fallbackIcon: "hammer.fill"
    ),
    CityBuilding(
        id: "tavern",
        imageName: "building-tavern",
        label: "TAVERN",
        route: .tavern,
        relativeX: 0.65,
        relativeY: 0.56,
        relativeSize: 0.26,
        glowColor: Color.orange,
        fallbackIcon: "mug.fill"
    ),
    CityBuilding(
        id: "arena",
        imageName: "building-arena",
        label: "ARENA",
        route: .arena,
        relativeX: 0.71,
        relativeY: 0.27,
        relativeSize: 0.30,
        glowColor: Color.orange,
        fallbackIcon: "shield.lefthalf.filled"
    ),
    CityBuilding(
        id: "dungeon",
        imageName: "building-dungeon",
        label: "DUNGEON RUSH",
        route: .dungeonRush,
        relativeX: 0.88,
        relativeY: 0.50,
        relativeSize: 0.21,
        glowColor: Color.orange,
        fallbackIcon: "door.left.hand.open"
    ),
    CityBuilding(
        id: "ranks",
        imageName: "building-ranks",
        label: "RANKS",
        route: .leaderboard,
        relativeX: 0.90,
        relativeY: 0.17,
        relativeSize: 0.32,
        glowColor: Color.orange,
        fallbackIcon: "trophy.fill",
        labelYOffset: -0.04
    ),
    CityBuilding(
        id: "guild-hall",
        imageName: "building-guild-hall",
        label: "GUILD HALL",
        route: .guildHall,
        relativeX: 0.12,
        relativeY: 0.38,
        relativeSize: 0.24,
        glowColor: Color.orange,
        fallbackIcon: "person.3.fill"
    ),
    CityBuilding(
        id: "black-market",
        imageName: "building-black-market",
        label: "BLACK MARKET",
        route: nil,
        relativeX: 0.78,
        relativeY: 0.75,
        relativeSize: 0.24,
        glowColor: Color.orange,
        fallbackIcon: "bag.circle.fill"
    ),
]

// MARK: - Resolved buildings (server overrides → hardcoded defaults)

@MainActor
func resolvedCityBuildings(from cache: GameDataCache) -> [CityBuilding] {
    let overrides = cache.hubLayout
    guard !overrides.isEmpty else { return defaultCityBuildings }

    return defaultCityBuildings.map { building in
        var b = building
        if let o = overrides[building.id] {
            b.relativeX = o.x
            b.relativeY = o.y
            if let size = o.size { b.relativeSize = size }
        }
        return b
    }
}

// MARK: - Convenience (for views without cache access, uses defaults)

var cityBuildings: [CityBuilding] { defaultCityBuildings }
