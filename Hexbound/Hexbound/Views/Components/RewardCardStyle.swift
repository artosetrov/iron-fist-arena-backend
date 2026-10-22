import SwiftUI

// MARK: - Reward cards (2026-10-22)
//
// Every victory and reward window is a painted card, like the hero cards of the
// gate deck: a frame, a big illustration, then the numbers.
//
//   • The frame's crest and corners say WHERE the reward came from (`RewardCardFamily`).
//   • Its metal and stones say WHAT IT IS WORTH (`RewardCardTier`, iron → mythic —
//     the ladder of the hero cards).
//   • The frames are cut in three pieces and stretch to any height (`RewardCardFrame`),
//     so one card holds one reward or ten.
//
// Art and prompts: docs/08_prompts/REWARD_CARD_FRAMES_PROMPTS.md. Which window uses
// which family and how its tier is decided: docs/07_ui_ux/REWARD_CARDS.md.

/// Where a reward came from. Picks the frame's crest and corners and the scene
/// painted behind the card's illustration.
enum RewardCardFamily: String, CaseIterable {
    /// PvP: victory, defeat, rank up, the scripted first fight. Crossed swords and a shield.
    case arena
    /// Dungeon bosses, defeats in a dungeon, Dungeon Rush treasure. A crowned skull, claws.
    case dungeon
    /// Shell game, fortune wheel, Fortune's Table. Dice and a wheel, coins.
    case fortune
    /// Gold Mine payouts. Pickaxes and a lantern, timber.
    case mine
    /// Shop purchases, contraband, special offers. Scales and a purse, ribbons.
    case merchant
    /// Daily login, quests, mail, referrals. Scroll, quill and seal, an hourglass.
    case tribute
    /// Achievements, battle pass, the season summary. Laurels, a star, banners.
    case glory
    /// Level up. Wings around a sun.
    case ascension

    /// Painted scene behind the illustration.
    var backdrop: String {
        switch self {
        case .arena: "bg-arena"
        case .dungeon: "bg-dungeon"
        case .fortune: "bg-fortune-wheel"
        case .mine: "bg-gold-mine"
        case .merchant: "bg-shop"
        case .tribute: "bg-tavern"
        case .glory: "bg-title"
        case .ascension: "bg-forge"
        }
    }
}

/// What a reward is worth: the metal and stones of the frame. The same ladder as
/// `HeroCardTier`, so a mythic reward and a mythic hero look like kin.
enum RewardCardTier: Int, CaseIterable, Comparable {
    case iron = 1, bronze, silver, gold, mythic

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The `<tier>` part of `reward-frame-<family>-<tier>-…`.
    var assetKey: String {
        switch self {
        case .iron: "iron"
        case .bronze: "bronze"
        case .silver: "silver"
        case .gold: "gold"
        case .mythic: "mythic"
        }
    }

    /// Item rarity: common is iron … legendary is mythic.
    init(rarity: ItemRarity) {
        switch rarity {
        case .common: self = .iron
        case .uncommon: self = .bronze
        case .rare: self = .silver
        case .epic: self = .gold
        case .legendary: self = .mythic
        }
    }

    /// Hero level, in the brackets of the hero cards: 1–9 iron, 10–19 bronze,
    /// 20–29 silver, 30–39 gold, 40+ mythic.
    init(level: Int) {
        switch level {
        case ..<10: self = .iron
        case 10..<20: self = .bronze
        case 20..<30: self = .silver
        case 30..<40: self = .gold
        default: self = .mythic
        }
    }

    /// PvP ladder tier key (`PvPRank.key`).
    init(rankKey: String) {
        switch rankKey {
        case "bronze": self = .bronze
        case "silver": self = .silver
        case "gold", "platinum": self = .gold
        case "diamond", "master", "grandmaster", "challenger": self = .mythic
        default: self = .iron
        }
    }

    /// Currency only. Gems weigh as 20 gold, XP as half a gold piece; a win in the
    /// arena (~150 gold) is bronze, a seventh-day login (25 gems) silver, a gem pack gold
    /// and up. Purely cosmetic — windows with a better reading (rank, level, streak
    /// day) pass that instead.
    init(gold: Int = 0, gems: Int = 0, xp: Int = 0) {
        let value = gold + gems * 20 + xp / 2
        switch value {
        case ..<150: self = .iron
        case 150..<400: self = .bronze
        case 400..<1200: self = .silver
        case 1200..<5000: self = .gold
        default: self = .mythic
        }
    }

    /// The richest of several readings: a rare drop lifts a modest card.
    static func best(_ tiers: [RewardCardTier?]) -> RewardCardTier {
        tiers.compactMap { $0 }.max() ?? .iron
    }

    /// Light behind the illustration.
    var light: Color {
        switch self {
        case .iron: DarkFantasyTheme.goldDim
        case .bronze: DarkFantasyTheme.gold
        case .silver: DarkFantasyTheme.info
        case .gold: DarkFantasyTheme.goldBright
        case .mythic: DarkFantasyTheme.rarityEpic
        }
    }
}

/// What the card's illustration shows: a painted scene of the family (or one given)
/// with a big subject standing in it.
struct RewardCardArt: Equatable {
    enum Subject: Equatable {
        /// An asset: a boss, a reward illustration, an item.
        case image(String)
        /// A hero portrait, resolved like everywhere else (`AvatarImageView`).
        case avatar(skinKey: String?, characterClass: CharacterClass)
        /// Scene only.
        case none
    }

    var subject: Subject
    /// Scene behind the subject; `nil` uses the family's.
    var backdrop: String? = nil
    /// Subject height as a share of the illustration's height.
    var fill: CGFloat = 0.82
    /// How far the subject's base sinks below the illustration (hidden by its fade):
    /// busts and full figures sink, objects stand on the fade.
    var sink: CGFloat = 0.02
    /// Mirror the subject (an enemy faces left).
    var mirrored = false

    /// A boss or an opponent: big, cut by the fade.
    static func figure(_ asset: String, mirrored: Bool = false) -> RewardCardArt {
        RewardCardArt(subject: .image(asset), fill: 1.08, sink: 0.16, mirrored: mirrored)
    }

    /// A hero portrait, big, cut by the fade.
    static func hero(skinKey: String?, characterClass: CharacterClass, mirrored: Bool = false) -> RewardCardArt {
        RewardCardArt(subject: .avatar(skinKey: skinKey, characterClass: characterClass), fill: 1.0, sink: 0.06, mirrored: mirrored)
    }

    /// An object (gold, a chest, an item) standing in the scene.
    static func object(_ asset: String, fill: CGFloat = 0.72) -> RewardCardArt {
        RewardCardArt(subject: .image(asset), fill: fill, sink: -0.06)
    }

    /// The illustration for a bundle of rewards: the most valuable thing in it.
    static func headline(gold: Int, gems: Int, xp: Int, items: [(imageKey: String?, rarity: ItemRarity)], hasConsumables: Bool) -> RewardCardArt {
        if let item = items.filter({ $0.imageKey != nil }).max(by: { $0.rarity.tier < $1.rarity.tier }),
           item.rarity.tier >= ItemRarity.rare.tier, let key = item.imageKey {
            return .object(key, fill: 0.62)
        }
        if gems > 0 { return .object(gems >= 100 ? "reward-art-gems-heap" : "reward-art-gems-few") }
        if gold > 0 {
            switch gold {
            case ..<300: return .object("reward-art-gold-purse", fill: 0.66)
            case 300..<2000: return .object("reward-art-gold-heap")
            default: return .object("rush2-chest-gold-open", fill: 0.78)
            }
        }
        if hasConsumables { return .object("reward-art-potions") }
        if let key = items.first?.imageKey { return .object(key, fill: 0.62) }
        if xp > 0 { return .object("reward-art-xp", fill: 0.68) }
        return RewardCardArt(subject: .none)
    }
}

/// Layout constants shared by every reward card.
enum RewardCardLayout {
    /// Card width on a phone: the screen minus its margins, capped.
    static func width(for available: CGFloat) -> CGFloat {
        min(available - 2 * LayoutConstants.screenPadding, 380)
    }

    /// Illustration height as a share of the window width — full, and the compact
    /// size used when the full card does not fit the screen.
    static let artRatio: CGFloat = 0.9
    static let compactArtRatio: CGFloat = 0.58

    /// How far the title climbs onto the illustration's fade.
    static let titleOverlap: CGFloat = 34

    /// Inset of the reward list from the rails, and of the buttons (the band the
    /// frame metrics are measured in — ornaments never reach into it).
    static let contentInset: CGFloat = 0.04
    static let actionInset: CGFloat = 0.08

    /// The illustration and the card body run this far under the frame so no seam shows.
    static let bleed: CGFloat = 0.015

    /// Length of the cross-fade between the frame's caps and its repeated rail strip.
    static let capFade: CGFloat = 10

    /// Colour of the card body; the illustration fades into it.
    static let body = DarkFantasyTheme.bgSecondary
}
