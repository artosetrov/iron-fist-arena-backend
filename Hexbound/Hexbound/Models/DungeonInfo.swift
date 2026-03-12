import SwiftUI

// MARK: - Boss Info

struct BossInfo: Identifiable {
    let id: Int          // 1–10 boss number
    let name: String
    let level: Int
    let hp: Int
    let description: String
    let loot: [LootPreview]

    var emoji: String {
        switch id {
        case 1: return "🗡️"
        case 2: return "⚙️"
        case 3: return "🕷️"
        case 4: return "🦴"
        case 5: return "🔥"
        case 6: return "🧙"
        case 7: return "🐍"
        case 8: return "👹"
        case 9: return "💀"
        case 10: return "👑"
        default: return "👾"
        }
    }
}

// MARK: - Loot Preview

struct LootPreview: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let detail: String    // "120–180" or "Rare (15%)"
}

// MARK: - Boss State

enum BossState {
    case defeated
    case current
    case locked
}

// MARK: - Dungeon State

enum DungeonState {
    case locked(requirement: String)
    case inProgress(defeated: Int)
    case completed
}

// MARK: - Dungeon Info

struct DungeonInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let minLevel: Int
    let maxLevel: Int
    let energyCost: Int
    let bosses: [BossInfo]
    let themeColor: Color
    let rewardIcons: [String]    // Quick preview icons for dungeon card

    var totalBosses: Int { bosses.count }

    // MARK: - Static Data

    static let all: [DungeonInfo] = [
        trainingCamp,
        desecratedCatacombs,
        volcanicForge,
    ]

    static let difficultyCosts: [String: Int] = [
        "easy": 15, "normal": 20, "hard": 25
    ]

    // MARK: - Training Camp

    static let trainingCamp = DungeonInfo(
        id: "training_camp",
        name: "Training Camp",
        icon: "⚔️",
        description: "On the outskirts of the Stray City lies an old training ground, built by the first Arena fighters.",
        minLevel: 1, maxLevel: 10, energyCost: 10,
        bosses: [
            BossInfo(id: 1, name: "Straw Dummy", level: 1, hp: 250,
                     description: "A lifeless target — until the wind picks up.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "50–80"),
                        LootPreview(icon: "⭐", name: "XP", detail: "20–30"),
                     ]),
            BossInfo(id: 2, name: "Rusty Golem", level: 2, hp: 320,
                     description: "Gears grind. Rust crumbles. It still hits hard.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "60–100"),
                        LootPreview(icon: "🗡️", name: "Rusty Blade", detail: "Common"),
                     ]),
            BossInfo(id: 3, name: "Cave Spider", level: 3, hp: 380,
                     description: "Eight legs, venomous fangs, zero mercy.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "70–110"),
                        LootPreview(icon: "🧪", name: "Venom Vial", detail: "15%"),
                     ]),
            BossInfo(id: 4, name: "Bone Warrior", level: 4, hp: 450,
                     description: "Reassembled from fallen fighters. Sworn to guard.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "80–130"),
                        LootPreview(icon: "🛡️", name: "Bone Shield", detail: "Uncommon (20%)"),
                     ]),
            BossInfo(id: 5, name: "Fire Imp", level: 5, hp: 500,
                     description: "Small, fast, and loves setting things on fire.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "90–150"),
                        LootPreview(icon: "📜", name: "Fire Scroll", detail: "10%"),
                     ]),
            BossInfo(id: 6, name: "Scarecrow Mage", level: 6, hp: 580,
                     description: "Waves a stick. Sparks occasionally fly.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "100–170"),
                        LootPreview(icon: "🗡️", name: "Mage Wand", detail: "Rare (15%)"),
                        LootPreview(icon: "📜", name: "Arcane Scroll", detail: "5%"),
                     ]),
            BossInfo(id: 7, name: "Shadow Stalker", level: 7, hp: 650,
                     description: "You won't see it coming. Literally.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "110–180"),
                        LootPreview(icon: "🗡️", name: "Shadow Dagger", detail: "Rare (12%)"),
                     ]),
            BossInfo(id: 8, name: "Iron Guardian", level: 8, hp: 750,
                     description: "Built to protect. Refuses to fall.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "120–200"),
                        LootPreview(icon: "🛡️", name: "Iron Plate", detail: "Rare (10%)"),
                     ]),
            BossInfo(id: 9, name: "Plague Bearer", level: 9, hp: 850,
                     description: "Its breath alone can fell a kingdom.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "130–220"),
                        LootPreview(icon: "🧪", name: "Plague Elixir", detail: "Epic (5%)"),
                     ]),
            BossInfo(id: 10, name: "Arena Warden", level: 10, hp: 1000,
                     description: "The final test. Only the worthy may pass.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "200–350"),
                        LootPreview(icon: "🗡️", name: "Warden's Blade", detail: "Epic (8%)"),
                        LootPreview(icon: "💎", name: "Gems", detail: "5–10"),
                     ]),
        ],
        themeColor: Color(hex: 0xE68C33),
        rewardIcons: ["🪙", "🗡️", "📜", "💎"]
    )

    // MARK: - Desecrated Catacombs

    static let desecratedCatacombs = DungeonInfo(
        id: "desecrated_catacombs",
        name: "Desecrated Catacombs",
        icon: "💀",
        description: "Beneath the old cemetery lies a labyrinth of crumbling tombs and forgotten kings.",
        minLevel: 10, maxLevel: 20, energyCost: 12,
        bosses: [
            BossInfo(id: 1, name: "Tomb Rat King", level: 10, hp: 600,
                     description: "Leads a swarm of diseased vermin.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "150–250"),
                        LootPreview(icon: "⭐", name: "XP", detail: "40–60"),
                     ]),
            BossInfo(id: 2, name: "Crypt Walker", level: 11, hp: 700,
                     description: "Shambles endlessly through the dark corridors.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "160–270"),
                        LootPreview(icon: "🗡️", name: "Crypt Sword", detail: "Uncommon"),
                     ]),
            BossInfo(id: 3, name: "Ghoul Brute", level: 12, hp: 800,
                     description: "Feeds on the fallen. Grows stronger each bite.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "180–300"),
                        LootPreview(icon: "🛡️", name: "Ghoul Hide", detail: "Rare (15%)"),
                     ]),
            BossInfo(id: 4, name: "Banshee", level: 13, hp: 880,
                     description: "Her wail pierces flesh and soul alike.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "200–320"),
                        LootPreview(icon: "📜", name: "Wail Scroll", detail: "10%"),
                     ]),
            BossInfo(id: 5, name: "Skeleton Knight", level: 14, hp: 950,
                     description: "Once a king's champion. Now a hollow guard.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "220–350"),
                        LootPreview(icon: "🗡️", name: "Knight's Edge", detail: "Rare (12%)"),
                     ]),
            BossInfo(id: 6, name: "Corpse Weaver", level: 15, hp: 1050,
                     description: "Stitches the dead into abominations.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "250–380"),
                        LootPreview(icon: "🧪", name: "Death Thread", detail: "Rare (8%)"),
                     ]),
            BossInfo(id: 7, name: "Wraith Assassin", level: 16, hp: 1150,
                     description: "Phases through walls. Strikes from nowhere.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "270–400"),
                        LootPreview(icon: "🗡️", name: "Wraith Blade", detail: "Epic (5%)"),
                     ]),
            BossInfo(id: 8, name: "Bone Colossus", level: 17, hp: 1300,
                     description: "A tower of fused skeletons. Unstoppable.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "300–450"),
                        LootPreview(icon: "🛡️", name: "Bone Armor", detail: "Epic (5%)"),
                     ]),
            BossInfo(id: 9, name: "Necro Priest", level: 18, hp: 1450,
                     description: "Commands the dead with whispered curses.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "350–500"),
                        LootPreview(icon: "📜", name: "Necrotic Tome", detail: "Epic (4%)"),
                     ]),
            BossInfo(id: 10, name: "Lich King Verath", level: 20, hp: 1800,
                     description: "Death incarnate. The catacombs are his domain.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "500–800"),
                        LootPreview(icon: "🗡️", name: "Lich Scythe", detail: "Legendary (3%)"),
                        LootPreview(icon: "💎", name: "Gems", detail: "10–20"),
                     ]),
        ],
        themeColor: Color(hex: 0x8040B0),
        rewardIcons: ["🪙", "🗡️", "🛡️", "💎"]
    )

    // MARK: - Volcanic Forge

    static let volcanicForge = DungeonInfo(
        id: "volcanic_forge",
        name: "Volcanic Forge",
        icon: "🔥",
        description: "Deep inside the molten mountain, ancient forges still burn with primal fire.",
        minLevel: 20, maxLevel: 30, energyCost: 15,
        bosses: [
            BossInfo(id: 1, name: "Lava Crawler", level: 20, hp: 1000,
                     description: "Slithers through magma like water.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "300–500"),
                        LootPreview(icon: "⭐", name: "XP", detail: "80–120"),
                     ]),
            BossInfo(id: 2, name: "Ember Sprite", level: 21, hp: 1100,
                     description: "A dancing flame with a violent temper.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "320–530"),
                        LootPreview(icon: "📜", name: "Ember Rune", detail: "Uncommon"),
                     ]),
            BossInfo(id: 3, name: "Slag Brute", level: 22, hp: 1250,
                     description: "Forged from cooling lava. Nearly indestructible.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "350–560"),
                        LootPreview(icon: "🛡️", name: "Slag Plate", detail: "Rare (15%)"),
                     ]),
            BossInfo(id: 4, name: "Flame Hound", level: 23, hp: 1350,
                     description: "Hunts by heat signature. Never loses prey.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "380–600"),
                        LootPreview(icon: "🗡️", name: "Hound Fang", detail: "Rare (12%)"),
                     ]),
            BossInfo(id: 5, name: "Molten Shaman", level: 24, hp: 1500,
                     description: "Channels the mountain's fury into deadly spells.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "400–650"),
                        LootPreview(icon: "📜", name: "Lava Burst Scroll", detail: "10%"),
                     ]),
            BossInfo(id: 6, name: "Obsidian Knight", level: 25, hp: 1650,
                     description: "Glass-like armor that shatters and reforms.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "450–700"),
                        LootPreview(icon: "🗡️", name: "Obsidian Blade", detail: "Epic (5%)"),
                     ]),
            BossInfo(id: 7, name: "Furnace Worm", level: 26, hp: 1800,
                     description: "Burrows through solid rock. Leaves trails of fire.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "480–750"),
                        LootPreview(icon: "🧪", name: "Magma Core", detail: "Epic (5%)"),
                     ]),
            BossInfo(id: 8, name: "Cinderlord", level: 27, hp: 2000,
                     description: "A walking inferno. Turns air to ash.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "500–800"),
                        LootPreview(icon: "🛡️", name: "Cinder Mail", detail: "Epic (4%)"),
                     ]),
            BossInfo(id: 9, name: "Magma Titan", level: 28, hp: 2300,
                     description: "The forge's greatest creation. Or its greatest mistake.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "550–900"),
                        LootPreview(icon: "🗡️", name: "Titan Hammer", detail: "Epic (3%)"),
                     ]),
            BossInfo(id: 10, name: "Pyrox the Eternal", level: 30, hp: 3000,
                     description: "Born when the world was fire. Will burn until it ends.",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "800–1200"),
                        LootPreview(icon: "🗡️", name: "Pyrox Greatsword", detail: "Legendary (2%)"),
                        LootPreview(icon: "💎", name: "Gems", detail: "15–30"),
                     ]),
        ],
        themeColor: Color(hex: 0xFF6626),
        rewardIcons: ["🪙", "🗡️", "🛡️", "💎"]
    )
}
