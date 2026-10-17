import CoreGraphics

// MARK: - Dungeon Trail Config
//
// Where everything sits on each dungeon's trail map (`DungeonTrailView`).
// Every background is a painted panorama in the hub's projection with ten
// open clearings: two staggered rows zigzagging left to right, the lair on
// the far right. Points are normalized to the image (0…1 from the top-left)
// and mark the FEET of each boss; `entrance` is where the trail starts.
// Art + prompts: docs/08_prompts/DUNGEON_TRAIL_MAPS_PROMPTS.md.

struct DungeonTrailConfig {
    let dungeonId: String
    /// Imageset name of the painted map.
    let background: String
    /// Where the trail comes in (the gate / cave mouth on the left).
    let entrance: CGPoint
    /// Feet of bosses 1…10 in fight order; the last one is the lair.
    let stands: [CGPoint]

    /// Native aspect of every trail background (source art 6336 × 2688).
    static let imageAspect: CGFloat = 6336.0 / 2688.0
    /// Boss height as a fraction of the map height. The lair boss stands
    /// taller so the finale reads from across the map.
    static let bossHeight: CGFloat = 0.19
    static let lairHeight: CGFloat = 0.27

    static func config(for dungeonId: String?) -> DungeonTrailConfig? {
        guard let dungeonId else { return nil }
        return all.first { $0.dungeonId == dungeonId }
    }

    static let all: [DungeonTrailConfig] = [
        DungeonTrailConfig(
            dungeonId: "training_camp",
            background: "bg-trail-training-camp",
            entrance: .init(x: 0.03, y: 0.62),
            stands: [
                .init(x: 0.14, y: 0.69), .init(x: 0.19, y: 0.38), .init(x: 0.30, y: 0.70), .init(x: 0.40, y: 0.35),
                .init(x: 0.46, y: 0.71), .init(x: 0.54, y: 0.38), .init(x: 0.63, y: 0.68), .init(x: 0.69, y: 0.36),
                .init(x: 0.87, y: 0.74), .init(x: 0.88, y: 0.39)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "desecrated_catacombs",
            background: "bg-trail-desecrated-catacombs",
            entrance: .init(x: 0.05, y: 0.45),
            stands: [
                .init(x: 0.12, y: 0.69), .init(x: 0.23, y: 0.43), .init(x: 0.28, y: 0.71), .init(x: 0.36, y: 0.47),
                .init(x: 0.45, y: 0.71), .init(x: 0.53, y: 0.47), .init(x: 0.61, y: 0.72), .init(x: 0.69, y: 0.48),
                .init(x: 0.80, y: 0.68), .init(x: 0.88, y: 0.45)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "volcanic_forge",
            background: "bg-trail-volcanic-forge",
            entrance: .init(x: 0.10, y: 0.45),
            stands: [
                .init(x: 0.17, y: 0.68), .init(x: 0.28, y: 0.33), .init(x: 0.35, y: 0.67), .init(x: 0.45, y: 0.33),
                .init(x: 0.48, y: 0.69), .init(x: 0.53, y: 0.50), .init(x: 0.61, y: 0.70), .init(x: 0.64, y: 0.31),
                .init(x: 0.77, y: 0.68), .init(x: 0.86, y: 0.42)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "fungal_grotto",
            background: "bg-trail-fungal-grotto",
            entrance: .init(x: 0.06, y: 0.40),
            stands: [
                .init(x: 0.13, y: 0.68), .init(x: 0.24, y: 0.50), .init(x: 0.31, y: 0.71), .init(x: 0.41, y: 0.51),
                .init(x: 0.46, y: 0.72), .init(x: 0.57, y: 0.51), .init(x: 0.62, y: 0.71), .init(x: 0.73, y: 0.50),
                .init(x: 0.77, y: 0.69), .init(x: 0.86, y: 0.49)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "scorched_mines",
            background: "bg-trail-scorched-mines",
            entrance: .init(x: 0.05, y: 0.50),
            stands: [
                .init(x: 0.12, y: 0.68), .init(x: 0.21, y: 0.36), .init(x: 0.30, y: 0.69), .init(x: 0.38, y: 0.43),
                .init(x: 0.47, y: 0.74), .init(x: 0.55, y: 0.41), .init(x: 0.64, y: 0.74), .init(x: 0.70, y: 0.43),
                .init(x: 0.80, y: 0.70), .init(x: 0.88, y: 0.47)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "frozen_abyss",
            background: "bg-trail-frozen-abyss",
            entrance: .init(x: 0.08, y: 0.32),
            stands: [
                .init(x: 0.13, y: 0.72), .init(x: 0.22, y: 0.42), .init(x: 0.32, y: 0.72), .init(x: 0.40, y: 0.43),
                .init(x: 0.49, y: 0.73), .init(x: 0.56, y: 0.42), .init(x: 0.65, y: 0.74), .init(x: 0.70, y: 0.45),
                .init(x: 0.83, y: 0.75), .init(x: 0.86, y: 0.46)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "realm_of_light",
            background: "bg-trail-realm-of-light",
            entrance: .init(x: 0.08, y: 0.42),
            stands: [
                .init(x: 0.14, y: 0.52), .init(x: 0.22, y: 0.38), .init(x: 0.31, y: 0.69), .init(x: 0.39, y: 0.43),
                .init(x: 0.46, y: 0.70), .init(x: 0.54, y: 0.43), .init(x: 0.61, y: 0.70), .init(x: 0.70, y: 0.43),
                .init(x: 0.79, y: 0.70), .init(x: 0.87, y: 0.41)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "shadow_realm",
            background: "bg-trail-shadow-realm",
            entrance: .init(x: 0.05, y: 0.65),
            stands: [
                .init(x: 0.13, y: 0.73), .init(x: 0.22, y: 0.40), .init(x: 0.33, y: 0.73), .init(x: 0.40, y: 0.38),
                .init(x: 0.48, y: 0.74), .init(x: 0.55, y: 0.40), .init(x: 0.63, y: 0.74), .init(x: 0.70, y: 0.41),
                .init(x: 0.80, y: 0.73), .init(x: 0.88, y: 0.42)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "clockwork_citadel",
            background: "bg-trail-clockwork-citadel",
            entrance: .init(x: 0.05, y: 0.45),
            stands: [
                .init(x: 0.10, y: 0.69), .init(x: 0.22, y: 0.44), .init(x: 0.28, y: 0.71), .init(x: 0.37, y: 0.46),
                .init(x: 0.46, y: 0.72), .init(x: 0.54, y: 0.45), .init(x: 0.62, y: 0.71), .init(x: 0.70, y: 0.47),
                .init(x: 0.79, y: 0.73), .init(x: 0.86, y: 0.47)
            ]
        ),
        DungeonTrailConfig(
            dungeonId: "infernal_throne",
            background: "bg-trail-infernal-throne",
            entrance: .init(x: 0.06, y: 0.52),
            stands: [
                .init(x: 0.13, y: 0.66), .init(x: 0.22, y: 0.34), .init(x: 0.32, y: 0.66), .init(x: 0.40, y: 0.33),
                .init(x: 0.48, y: 0.70), .init(x: 0.56, y: 0.33), .init(x: 0.64, y: 0.70), .init(x: 0.71, y: 0.35),
                .init(x: 0.82, y: 0.68), .init(x: 0.89, y: 0.38)
            ]
        ),
    ]
}
