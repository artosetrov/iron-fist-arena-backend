import SwiftUI

// MARK: - City Building Data Model

struct CityBuilding: Identifiable {
    let id: String
    let imageName: String        // asset name in xcassets
    let label: String            // banner text
    let route: AppRoute          // navigation target
    let relativeX: CGFloat       // 0.0...1.0 position on terrain X
    let relativeY: CGFloat       // 0.0...1.0 position on terrain Y
    let relativeSize: CGFloat    // size relative to terrain height
    let glowColor: Color         // glow color on tap / idle
    let fallbackIcon: String     // SF Symbol fallback if asset missing
    var labelYOffset: CGFloat = 0 // extra Y offset for label (relative to terrain height)
}

// MARK: - Building Configurations

let cityBuildings: [CityBuilding] = [
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
        glowColor: Color.purple,
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
        label: "DUNGEON",
        route: .dungeonSelect,
        relativeX: 0.88,
        relativeY: 0.50,
        relativeSize: 0.21,
        glowColor: Color(hex: 0x7B2D8B),
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
        labelYOffset: 0.05
    ),
]
