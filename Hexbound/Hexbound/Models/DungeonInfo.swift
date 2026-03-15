import SwiftUI

// MARK: - Boss Info

struct BossInfo: Identifiable {
    let id: Int          // 1–10 boss number
    let name: String
    let level: Int
    let hp: Int
    let description: String
    let portraitImage: String   // Asset name for portrait (head & shoulders)
    let fullImage: String       // Asset name for full body (combat pose)
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
    var imageUrl: String? = nil
    var imageKey: String? = nil
    var rarity: ItemRarity = .common

    /// Convert to a lightweight Item for the detail sheet
    func toItem() -> Item {
        Item(
            id: id.uuidString,
            itemName: name,
            itemType: .weapon,
            rarity: rarity,
            itemLevel: 1,
            imageUrl: imageUrl,
            imageKey: imageKey
        )
    }
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
                     portraitImage: "boss-straw-dummy-portrait",
                     fullImage: "boss-straw-dummy-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "50–80", imageKey: "loot-gold"),
                        LootPreview(icon: "⭐", name: "XP", detail: "20–30", imageKey: "loot-xp"),
                     ]),
            BossInfo(id: 2, name: "Rusty Golem", level: 2, hp: 320,
                     description: "Gears grind. Rust crumbles. It still hits hard.",
                     portraitImage: "boss-rusty-golem-portrait",
                     fullImage: "boss-rusty-golem-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "60–100", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Rusty Blade", detail: "Common", imageKey: "loot-rusty-blade", rarity: .common),
                     ]),
            BossInfo(id: 3, name: "Cave Spider", level: 3, hp: 380,
                     description: "Eight legs, venomous fangs, zero mercy.",
                     portraitImage: "boss-cave-spider-portrait",
                     fullImage: "boss-cave-spider-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "70–110", imageKey: "loot-gold"),
                        LootPreview(icon: "🧪", name: "Venom Vial", detail: "15%", imageKey: "loot-venom-vial", rarity: .uncommon),
                     ]),
            BossInfo(id: 4, name: "Bone Warrior", level: 4, hp: 450,
                     description: "Reassembled from fallen fighters. Sworn to guard.",
                     portraitImage: "boss-bone-warrior-portrait",
                     fullImage: "boss-bone-warrior-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "80–130", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Bone Shield", detail: "Uncommon (20%)", imageKey: "loot-bone-shield", rarity: .uncommon),
                     ]),
            BossInfo(id: 5, name: "Fire Imp", level: 5, hp: 500,
                     description: "Small, fast, and loves setting things on fire.",
                     portraitImage: "boss-fire-imp-portrait",
                     fullImage: "boss-fire-imp-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "90–150", imageKey: "loot-gold"),
                        LootPreview(icon: "📜", name: "Fire Scroll", detail: "10%", imageKey: "loot-fire-scroll", rarity: .uncommon),
                     ]),
            BossInfo(id: 6, name: "Scarecrow Mage", level: 6, hp: 580,
                     description: "Waves a stick. Sparks occasionally fly.",
                     portraitImage: "boss-scarecrow-mage-portrait",
                     fullImage: "boss-scarecrow-mage-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "100–170", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Mage Wand", detail: "Rare (15%)", imageKey: "loot-mage-wand", rarity: .rare),
                        LootPreview(icon: "📜", name: "Arcane Scroll", detail: "5%", imageKey: "loot-arcane-scroll", rarity: .rare),
                     ]),
            BossInfo(id: 7, name: "Shadow Stalker", level: 7, hp: 650,
                     description: "You won't see it coming. Literally.",
                     portraitImage: "boss-shadow-stalker-portrait",
                     fullImage: "boss-shadow-stalker-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "110–180", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Shadow Dagger", detail: "Rare (12%)", imageKey: "loot-shadow-dagger", rarity: .rare),
                     ]),
            BossInfo(id: 8, name: "Iron Guardian", level: 8, hp: 750,
                     description: "Built to protect. Refuses to fall.",
                     portraitImage: "boss-iron-guardian-portrait",
                     fullImage: "boss-iron-guardian-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "120–200", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Iron Plate", detail: "Rare (10%)", imageKey: "loot-iron-plate", rarity: .rare),
                     ]),
            BossInfo(id: 9, name: "Plague Bearer", level: 9, hp: 850,
                     description: "Its breath alone can fell a kingdom.",
                     portraitImage: "boss-plague-bearer-portrait",
                     fullImage: "boss-plague-bearer-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "130–220", imageKey: "loot-gold"),
                        LootPreview(icon: "🧪", name: "Plague Elixir", detail: "Epic (5%)", imageKey: "loot-plague-elixir", rarity: .epic),
                     ]),
            BossInfo(id: 10, name: "Arena Warden", level: 10, hp: 1000,
                     description: "The final test. Only the worthy may pass.",
                     portraitImage: "boss-arena-warden-portrait",
                     fullImage: "boss-arena-warden-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "200–350", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Warden's Blade", detail: "Epic (8%)", imageKey: "loot-wardens-blade", rarity: .epic),
                        LootPreview(icon: "💎", name: "Gems", detail: "5–10", imageKey: "loot-gems"),
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
                     portraitImage: "boss-tomb-rat-king-portrait",
                     fullImage: "boss-tomb-rat-king-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "150–250", imageKey: "loot-gold"),
                        LootPreview(icon: "⭐", name: "XP", detail: "40–60", imageKey: "loot-xp"),
                     ]),
            BossInfo(id: 2, name: "Crypt Walker", level: 11, hp: 700,
                     description: "Shambles endlessly through the dark corridors.",
                     portraitImage: "boss-crypt-walker-portrait",
                     fullImage: "boss-crypt-walker-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "160–270", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Crypt Sword", detail: "Uncommon", imageKey: "loot-crypt-sword", rarity: .uncommon),
                     ]),
            BossInfo(id: 3, name: "Ghoul Brute", level: 12, hp: 800,
                     description: "Feeds on the fallen. Grows stronger each bite.",
                     portraitImage: "boss-ghoul-brute-portrait",
                     fullImage: "boss-ghoul-brute-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "180–300", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Ghoul Hide", detail: "Rare (15%)", imageKey: "loot-ghoul-hide", rarity: .rare),
                     ]),
            BossInfo(id: 4, name: "Banshee", level: 13, hp: 880,
                     description: "Her wail pierces flesh and soul alike.",
                     portraitImage: "boss-banshee-portrait",
                     fullImage: "boss-banshee-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "200–320", imageKey: "loot-gold"),
                        LootPreview(icon: "📜", name: "Wail Scroll", detail: "10%", imageKey: "loot-wail-scroll", rarity: .uncommon),
                     ]),
            BossInfo(id: 5, name: "Skeleton Knight", level: 14, hp: 950,
                     description: "Once a king's champion. Now a hollow guard.",
                     portraitImage: "boss-skeleton-knight-portrait",
                     fullImage: "boss-skeleton-knight-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "220–350", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Knight's Edge", detail: "Rare (12%)", imageKey: "loot-knights-edge", rarity: .rare),
                     ]),
            BossInfo(id: 6, name: "Corpse Weaver", level: 15, hp: 1050,
                     description: "Stitches the dead into abominations.",
                     portraitImage: "boss-corpse-weaver-portrait",
                     fullImage: "boss-corpse-weaver-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "250–380", imageKey: "loot-gold"),
                        LootPreview(icon: "🧪", name: "Death Thread", detail: "Rare (8%)", imageKey: "loot-death-thread", rarity: .rare),
                     ]),
            BossInfo(id: 7, name: "Wraith Assassin", level: 16, hp: 1150,
                     description: "Phases through walls. Strikes from nowhere.",
                     portraitImage: "boss-wraith-assassin-portrait",
                     fullImage: "boss-wraith-assassin-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "270–400", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Wraith Blade", detail: "Epic (5%)", imageKey: "loot-wraith-blade", rarity: .epic),
                     ]),
            BossInfo(id: 8, name: "Bone Colossus", level: 17, hp: 1300,
                     description: "A tower of fused skeletons. Unstoppable.",
                     portraitImage: "boss-bone-colossus-portrait",
                     fullImage: "boss-bone-colossus-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "300–450", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Bone Armor", detail: "Epic (5%)", imageKey: "loot-bone-armor", rarity: .epic),
                     ]),
            BossInfo(id: 9, name: "Necro Priest", level: 18, hp: 1450,
                     description: "Commands the dead with whispered curses.",
                     portraitImage: "boss-necro-priest-portrait",
                     fullImage: "boss-necro-priest-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "350–500", imageKey: "loot-gold"),
                        LootPreview(icon: "📜", name: "Necrotic Tome", detail: "Epic (4%)", imageKey: "loot-necrotic-tome", rarity: .epic),
                     ]),
            BossInfo(id: 10, name: "Lich King Verath", level: 20, hp: 1800,
                     description: "Death incarnate. The catacombs are his domain.",
                     portraitImage: "boss-lich-king-portrait",
                     fullImage: "boss-lich-king-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "500–800", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Lich Scythe", detail: "Legendary (3%)", imageKey: "loot-lich-scythe", rarity: .legendary),
                        LootPreview(icon: "💎", name: "Gems", detail: "10–20", imageKey: "loot-gems"),
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
                     portraitImage: "boss-lava-crawler-portrait",
                     fullImage: "boss-lava-crawler-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "300–500", imageKey: "loot-gold"),
                        LootPreview(icon: "⭐", name: "XP", detail: "80–120", imageKey: "loot-xp"),
                     ]),
            BossInfo(id: 2, name: "Ember Sprite", level: 21, hp: 1100,
                     description: "A dancing flame with a violent temper.",
                     portraitImage: "boss-ember-sprite-portrait",
                     fullImage: "boss-ember-sprite-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "320–530", imageKey: "loot-gold"),
                        LootPreview(icon: "📜", name: "Ember Rune", detail: "Uncommon", imageKey: "loot-ember-rune", rarity: .uncommon),
                     ]),
            BossInfo(id: 3, name: "Slag Brute", level: 22, hp: 1250,
                     description: "Forged from cooling lava. Nearly indestructible.",
                     portraitImage: "boss-slag-brute-portrait",
                     fullImage: "boss-slag-brute-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "350–560", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Slag Plate", detail: "Rare (15%)", imageKey: "loot-slag-plate", rarity: .rare),
                     ]),
            BossInfo(id: 4, name: "Flame Hound", level: 23, hp: 1350,
                     description: "Hunts by heat signature. Never loses prey.",
                     portraitImage: "boss-flame-hound-portrait",
                     fullImage: "boss-flame-hound-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "380–600", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Hound Fang", detail: "Rare (12%)", imageKey: "loot-hound-fang", rarity: .rare),
                     ]),
            BossInfo(id: 5, name: "Molten Shaman", level: 24, hp: 1500,
                     description: "Channels the mountain's fury into deadly spells.",
                     portraitImage: "boss-molten-shaman-portrait",
                     fullImage: "boss-molten-shaman-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "400–650", imageKey: "loot-gold"),
                        LootPreview(icon: "📜", name: "Lava Burst Scroll", detail: "10%", imageKey: "loot-lava-scroll", rarity: .uncommon),
                     ]),
            BossInfo(id: 6, name: "Obsidian Knight", level: 25, hp: 1650,
                     description: "Glass-like armor that shatters and reforms.",
                     portraitImage: "boss-obsidian-knight-portrait",
                     fullImage: "boss-obsidian-knight-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "450–700", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Obsidian Blade", detail: "Epic (5%)", imageKey: "loot-obsidian-blade", rarity: .epic),
                     ]),
            BossInfo(id: 7, name: "Furnace Worm", level: 26, hp: 1800,
                     description: "Burrows through solid rock. Leaves trails of fire.",
                     portraitImage: "boss-furnace-worm-portrait",
                     fullImage: "boss-furnace-worm-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "480–750", imageKey: "loot-gold"),
                        LootPreview(icon: "🧪", name: "Magma Core", detail: "Epic (5%)", imageKey: "loot-magma-core", rarity: .epic),
                     ]),
            BossInfo(id: 8, name: "Cinderlord", level: 27, hp: 2000,
                     description: "A walking inferno. Turns air to ash.",
                     portraitImage: "boss-cinderlord-portrait",
                     fullImage: "boss-cinderlord-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "500–800", imageKey: "loot-gold"),
                        LootPreview(icon: "🛡️", name: "Cinder Mail", detail: "Epic (4%)", imageKey: "loot-cinder-mail", rarity: .epic),
                     ]),
            BossInfo(id: 9, name: "Magma Titan", level: 28, hp: 2300,
                     description: "The forge's greatest creation. Or its greatest mistake.",
                     portraitImage: "boss-magma-titan-portrait",
                     fullImage: "boss-magma-titan-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "550–900", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Titan Hammer", detail: "Epic (3%)", imageKey: "loot-titan-hammer", rarity: .epic),
                     ]),
            BossInfo(id: 10, name: "Pyrox the Eternal", level: 30, hp: 3000,
                     description: "Born when the world was fire. Will burn until it ends.",
                     portraitImage: "boss-pyrox-portrait",
                     fullImage: "boss-pyrox-full",
                     loot: [
                        LootPreview(icon: "🪙", name: "Gold", detail: "800–1200", imageKey: "loot-gold"),
                        LootPreview(icon: "🗡️", name: "Pyrox Greatsword", detail: "Legendary (2%)", imageKey: "loot-pyrox-greatsword", rarity: .legendary),
                        LootPreview(icon: "💎", name: "Gems", detail: "15–30", imageKey: "loot-gems"),
                     ]),
        ],
        themeColor: Color(hex: 0xFF6626),
        rewardIcons: ["🪙", "🗡️", "🛡️", "💎"]
    )
}
