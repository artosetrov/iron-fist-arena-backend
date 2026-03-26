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

    /// Extended lore text for boss detail sheet.
    /// Uses server description if long enough, otherwise generates client-side lore.
    var extendedLore: String {
        // If server already sends a meaty description (2+ sentences), use it
        if description.count > 80 { return description }
        // Client-side extended lore keyed by boss name (fallback for short server descriptions)
        let tagline = description.isEmpty ? "A fearsome dungeon guardian." : description
        return tagline + "\n\n" + Self.clientLore(for: name)
    }

    private static func clientLore(for name: String) -> String {
        let loreLookup: [String: String] = [
            "Tomb Rat King": "Once a common sewer rat, it gorged on cursed alchemical runoff until it grew to monstrous size. Now it commands legions of diseased vermin from its throne of bones, spreading plague through the tunnels. Adventurers who underestimate its swarm tactics rarely return.",
            "Iron Sentinel": "Forged in the dying embers of a forgotten war, this construct still follows its last order: destroy all intruders. Its rusted joints creak with every swing, but each blow carries the weight of enchanted steel. Some say a trapped soul still screams inside its hollow chest.",
            "Broodmother Arachne": "Deep in the silk-choked caverns, she tends her thousand eggs. Her venom dissolves armor and flesh alike, and her web traps have ensnared even seasoned knights. The clicking of her mandibles echoes through the dark — a sound that haunts survivors forever.",
            "Bone Colossus": "Assembled from the remains of a hundred fallen warriors by a mad necromancer, this skeletal giant towers above the crypt halls. Each bone remembers its former life, and the colossus fights with the combined fury of all the souls bound within it.",
            "Pyrox the Eternal": "Born from the heart of a volcanic eruption, Pyrox has burned for millennia. Its molten core radiates heat that melts stone, and its breath turns sand to glass. Only weapons quenched in dragon blood can pierce its obsidian hide.",
            "The Fungal Sovereign": "What was once an elven druid became one with the mycelium network spanning miles underground. It speaks through spores and controls every mushroom, vine, and root in its domain. Those who breathe its pollen become extensions of its will.",
            "Serpent Pharaoh": "An ancient king who traded his humanity for immortality through serpent magic. His cobra crown grants dominion over all reptiles, and his gaze can paralyze the bravest warriors. His tomb holds treasures from a civilization lost to time.",
            "Gorefang the Butcher": "A demon summoned during a failed ritual, Gorefang broke free of its binding circle and slaughtered the cultists who called it forth. Now it guards its lair with savage glee, decorating the walls with the remains of challengers.",
            "The Lich Sovereign": "Once the greatest archmage of the eastern kingdoms, she chose undeath over mortality. Her phylactery is hidden somewhere in the deepest vault, making her nearly impossible to destroy permanently. Her spells can shatter minds and rend reality itself.",
            "Abyssal Overlord": "The final guardian of the darkest dungeon, the Overlord commands all the horrors that lurk in the deep. It was ancient when the world was young, and its power grows with every soul that perishes in its domain. Few have seen its true form and lived to describe it.",
        ]
        return loreLookup[name] ?? "Legends speak of this creature in hushed tones. Its power is matched only by the treasures it guards. Many have sought to defeat it — few have succeeded."
    }

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

    // MARK: - Server Data Parsing

    /// Parse a DungeonInfo from the /api/dungeons/list response dictionary.
    static func from(serverData d: [String: Any]) -> DungeonInfo? {
        guard let slug = d["slug"] as? String,
              let name = d["name"] as? String else { return nil }

        let levelReq = d["level_req"] as? Int ?? 1
        let energyCost = d["energy_cost"] as? Int ?? 10
        let description = d["description"] as? String ?? ""
        let sortOrder = d["sort_order"] as? Int ?? 0

        // Parse dungeon-wide drops → loot previews for all bosses
        let serverDrops = d["drops"] as? [[String: Any]] ?? []
        let dungeonLoot: [LootPreview] = serverDrops.compactMap { dr in
            guard let item = dr["item"] as? [String: Any],
                  let itemName = item["name"] as? String else { return nil }
            let rarityStr = item["rarity"] as? String ?? "common"
            let rarity = ItemRarity(rawValue: rarityStr) ?? .common
            let dropChance = dr["drop_chance"] as? Double ?? 0
            let itemType = item["type"] as? String ?? "weapon"
            return LootPreview(
                icon: Self.iconForItemType(itemType),
                name: itemName,
                detail: "\(rarity.displayName) (\(Int(dropChance))%)",
                imageUrl: item["image_url"] as? String,
                imageKey: item["image_key"] as? String,
                rarity: rarity
            )
        }

        // Base loot (gold + XP are always rewarded)
        let baseLoot: [LootPreview] = [
            LootPreview(icon: "🪙", name: "Gold", detail: "Varies", imageKey: "loot-gold"),
            LootPreview(icon: "⭐", name: "XP", detail: "Varies", imageKey: "loot-xp"),
        ]
        let combinedLoot = baseLoot + dungeonLoot

        // Parse bosses
        let serverBosses = d["bosses"] as? [[String: Any]] ?? []
        let bosses: [BossInfo] = serverBosses.enumerated().map { idx, b in
            let bossImageUrl = b["image_url"] as? String
            // Use server image_url as portrait if available, fallback to generic
            let portrait: String = {
                guard let url = bossImageUrl, !url.isEmpty else {
                    return "boss-generic-portrait"
                }
                return url
            }()
            return BossInfo(
                id: idx + 1,
                name: b["name"] as? String ?? "Unknown",
                level: b["level"] as? Int ?? levelReq,
                hp: b["hp"] as? Int ?? 500,
                description: b["description"] as? String ?? "",
                portraitImage: portrait,
                fullImage: portrait,  // Use same URL for full image
                loot: combinedLoot
            )
        }

        // Determine theme color based on sort order / difficulty tier
        let themeColor: Color = {
            switch sortOrder {
            case 0: return DarkFantasyTheme.glowArena  // Training Camp orange
            case 1: return DarkFantasyTheme.glowMystic  // Catacombs purple
            case 2: return DarkFantasyTheme.glowForge  // Volcanic red-orange
            case 3: return DarkFantasyTheme.glowNature  // Fungal green
            case 4: return DarkFantasyTheme.glowVolcanic  // Scorched deep orange
            case 5: return DarkFantasyTheme.glowIce  // Frozen blue
            case 6: return DarkFantasyTheme.glowTreasure  // Realm of Light gold
            case 7: return DarkFantasyTheme.glowShadow  // Shadow dark
            case 8: return DarkFantasyTheme.glowStone  // Clockwork steel
            case 9: return DarkFantasyTheme.bgDungeonDeep  // Abyssal deep blue
            default: return DarkFantasyTheme.glowBlood  // Infernal red
            }
        }()

        // Determine icon based on dungeon slug
        let icon: String = {
            if slug.contains("training") { return "⚔️" }
            if slug.contains("catacomb") { return "💀" }
            if slug.contains("volcanic") || slug.contains("forge") { return "🔥" }
            if slug.contains("fungal") || slug.contains("grotto") { return "🍄" }
            if slug.contains("scorched") || slug.contains("mine") { return "⛏️" }
            if slug.contains("frozen") || slug.contains("abyss") { return "❄️" }
            if slug.contains("light") || slug.contains("realm") { return "✨" }
            if slug.contains("shadow") { return "🌑" }
            if slug.contains("clockwork") || slug.contains("citadel") { return "⚙️" }
            if slug.contains("abyssal") || slug.contains("depth") { return "🌊" }
            if slug.contains("infernal") || slug.contains("throne") { return "👑" }
            return "🏰"
        }()

        // Reward icons from actual drops (unique item type icons)
        let rewardIcons: [String] = {
            var icons = ["🪙"]  // Gold always present
            let uniqueIcons = Array(Set(dungeonLoot.map { $0.icon })).prefix(3)
            icons.append(contentsOf: uniqueIcons)
            if icons.count < 4 { icons.append("📜") }
            return Array(icons.prefix(4))
        }()

        // Max level = last boss level, or levelReq + 10
        let maxLevel = bosses.last?.level ?? (levelReq + 10)

        return DungeonInfo(
            id: slug,
            name: name,
            icon: icon,
            description: description,
            minLevel: levelReq,
            maxLevel: maxLevel,
            energyCost: energyCost,
            bosses: bosses,
            themeColor: themeColor,
            rewardIcons: rewardIcons
        )
    }

    /// Map item type string to an emoji icon
    private static func iconForItemType(_ type: String) -> String {
        switch type {
        case "weapon": return "🗡️"
        case "helmet": return "🪖"
        case "chest": return "🛡️"
        case "gloves": return "🧤"
        case "legs": return "👖"
        case "boots": return "🥾"
        case "accessory": return "💍"
        case "amulet": return "📿"
        case "belt": return "🎗️"
        case "relic": return "🔮"
        case "necklace": return "📿"
        case "ring": return "💎"
        case "consumable": return "🧪"
        default: return "📦"
        }
    }

    // MARK: - Static Fallback Data

    static let fallback: [DungeonInfo] = [
        trainingCamp,
        desecratedCatacombs,
        volcanicForge,
    ]

    /// Deprecated — use dynamic loading. Kept as fallback only.
    static let all: [DungeonInfo] = fallback

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
        themeColor: DarkFantasyTheme.glowArena,
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
        themeColor: DarkFantasyTheme.glowMystic,
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
        themeColor: DarkFantasyTheme.glowForge,
        rewardIcons: ["🪙", "🗡️", "🛡️", "💎"]
    )
}
