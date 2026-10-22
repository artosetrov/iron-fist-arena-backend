import SwiftUI

// MARK: - Configuration Types

/// One star slot in the Victory screen. Always three per run for visual rhythm.
/// The player sees the label whether earned or not — missed conditions act as
/// replayability hooks ("next time try to…").
struct StarCondition {
    let label: String
    let earned: Bool
}

struct BattleResultConfig {
    // Core
    let isVictory: Bool
    let title: String
    let subtitle: String?
    let illustrationImage: String? // kept for DungeonVictoryView compatibility

    // Victory Stars — per-condition slots with labels.
    // Nil / empty = don't show stars. `earned == false` renders a faint outline
    // slot with the unreached label, so the player sees what they missed.
    var starConditions: [StarCondition]? = nil

    // Rewards
    let goldReward: Int?
    let xpReward: Int?
    let ratingChange: Int?
    let firstWinBonus: Bool

    // XP hero counter data
    var xpBefore: Int? = nil  // XP before this fight
    var xpNeeded: Int? = nil  // Total XP needed for next level

    // XP bar (optional — arena/pvp show this)
    let xpBarConfig: XPBarConfig?

    // Dungeon progress (optional — dungeon shows this)
    let dungeonProgress: DungeonProgressConfig?

    // Loot
    let lootItems: [LootItemDisplay]
    let onLootTap: ((Int) -> Void)?

    // Combat log (optional — PvP/Arena shows turn-by-turn recap)
    var combatLog: [CombatLogSummaryEntry] = []

    // Buttons
    let buttons: [ResultButton]

    // PvP duel layout (you vs the rival). Nil = the classic card used by
    // dungeon / training results.
    var duel: DuelResultInfo? = nil

    // Reward card (2026-10-22, docs/07_ui_ux/REWARD_CARDS.md). The family is
    // where the fight was; `cardTier` the window's own reading of what it was
    // worth (a ladder tier, a boss level — nil reads the gold and XP), lifted
    // by the loot's rarity; `cardArt` the illustration (nil: the most valuable
    // reward, as on the CLAIMED! card).
    var cardFamily: RewardCardFamily = .arena
    var cardTier: RewardCardTier? = nil
    var cardArt: RewardCardArt? = nil
}

extension BattleResultConfig {
    /// The frame's metal: the window's reading, lifted by the best loot.
    var resolvedCardTier: RewardCardTier {
        var readings: [RewardCardTier?] = [cardTier ?? RewardCardTier(gold: goldReward ?? 0, xp: xpReward ?? 0)]
        for item in lootItems {
            readings.append(RewardCardTier(rarity: item.rarity))
        }
        return RewardCardTier.best(readings)
    }

    /// The illustration: the window's own, or the most valuable thing won.
    var resolvedCardArt: RewardCardArt {
        cardArt ?? .headline(
            gold: goldReward ?? 0,
            gems: 0,
            xp: xpReward ?? 0,
            items: lootItems.map { (imageKey: $0.imageKey, rarity: $0.rarity) },
            hasConsumables: lootItems.contains { $0.fallbackIcon == ItemType.consumable.icon }
        )
    }
}

extension RewardCardArt {
    /// A dungeon boss on its own lair: the full figure (the portrait when the
    /// figure is not bundled), in front of the dungeon's painted trail when it
    /// has one. nil when the boss has no art at all.
    @MainActor
    static func dungeonBoss(_ boss: BossInfo?, dungeonId: String?) -> RewardCardArt? {
        guard let boss, let asset = EnemyPortraitResolver.fullBodyAsset(boss) else { return nil }
        var art = RewardCardArt.figure(asset)
        if let trail = DungeonTrailConfig.config(for: dungeonId)?.background, UIImage(named: trail) != nil {
            art.backdrop = trail
        }
        return art
    }
}

/// PvP result header: the player against the rival, rating before → after,
/// and the rival actions (profile, message) that used to be two of four
/// stacked full-width buttons.
struct DuelResultInfo {
    let playerSkinKey: String?
    let playerClass: CharacterClass
    let playerLevel: Int
    /// Rating before this fight; nil hides the "before → after" line.
    let ratingBefore: Int?
    let rivalName: String
    let rivalSkinKey: String?
    let rivalClass: CharacterClass
    let rivalLevel: Int
    let onViewRival: (() -> Void)?
    let onMessageRival: (() -> Void)?
}

/// Turn-by-turn display entry for the collapsible Combat Log section in the
/// result modal. Built by CombatResultDetailView from CombatData.combatLog.
struct CombatLogSummaryEntry: Identifiable {
    let id = UUID()
    let isPlayerAttacking: Bool
    let attackerName: String
    let damage: Int
    let heal: Int
    let isCrit: Bool
    let isMiss: Bool
    let isDodge: Bool
    let isBlocked: Bool
}

struct XPBarConfig {
    let displayLevel: Int
    let progress: CGFloat
    let leveledUp: Bool
    /// This fight levels the hero up: the LEVEL UP! line is laid out from the
    /// start and shown when `leveledUp` lands, so the card never grows (and
    /// the stage never jumps to its compact size) mid-ceremony.
    var willLevelUp: Bool = false
}

struct DungeonProgressConfig {
    let defeated: Int
    let total: Int
    let isComplete: Bool
    /// Bug #16: Training Camp and other PvE tracks can override the "Dungeon
    /// Progress" / "DUNGEON CLEARED!" copy with their own label. Nil = default
    /// dungeon copy.
    var progressLabel: String = "Dungeon Progress"
    var completeLabel: String = "DUNGEON CLEARED!"

    var fraction: Double {
        Double(defeated) / Double(max(total, 1))
    }
}

struct LootItemDisplay {
    let name: String
    let rarityName: String
    let rarityColor: Color
    let imageKey: String?
    let imageUrl: String?
    let sfIcon: String?
    let sfColor: Color?
    let fallbackIcon: String
    /// 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary
    var rarityTier: Int = 0

    /// Derived ItemRarity from tier (for unified ItemCardView)
    var rarity: ItemRarity {
        ItemRarity.allCases.first { $0.tier == rarityTier } ?? .common
    }
}

struct ResultButton {
    let title: String
    let icon: String?         // SF Symbol name
    let assetIcon: String?    // Asset image name (takes priority over icon)
    let style: ResultButtonStyle
    let action: () -> Void

    init(title: String, icon: String? = nil, assetIcon: String? = nil, style: ResultButtonStyle, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.assetIcon = assetIcon
        self.style = style
        self.action = action
    }
}

enum ResultButtonStyle {
    case primary, secondary, ghost
}

// MARK: - Type-Erased ButtonStyle

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { config in
            AnyView(style.makeBody(configuration: config))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Spinning Rays Background

/// Animated spinning rays (spokes) like a light wheel — gold radial beams rotating continuously
/// with pulsing brightness. Uses TimelineView for real per-frame animation (Canvas ignores
/// SwiftUI animation interpolation, so withAnimation on rotation doesn't work).
struct SpinningRaysView: View {
    @State private var pulsePhase: Double = 0
    let spokeCount: Int = 14
    let color: Color = DarkFantasyTheme.goldBright
    /// Full rotation period in seconds
    let rotationDuration: Double = 20
    /// Pulse cycle period in seconds
    let pulseDuration: Double = 3

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed: Double = timeline.date.timeIntervalSinceReferenceDate
            let rotationRad: Double = (elapsed / rotationDuration).truncatingRemainder(dividingBy: 1.0) * .pi * 2
            let pulse: Double = 0.75 + 0.25 * sin(elapsed / pulseDuration * .pi * 2)

            raysCanvas(elapsed: elapsed, rotationRad: rotationRad, pulse: pulse)
        }
    }

    private func raysCanvas(elapsed: Double, rotationRad: Double, pulse: Double) -> some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.4)
            let radius: Double = max(geo.size.width, geo.size.height) * 1.2

            Canvas { context, _ in
                drawSpokes(context: &context, center: center, radius: radius, rotationRad: rotationRad, pulse: pulse, elapsed: elapsed)
            }
        }
    }

    private func drawSpokes(context: inout GraphicsContext, center: CGPoint, radius: Double, rotationRad: Double, pulse: Double, elapsed: Double) {
        let angleStep: Double = .pi * 2 / Double(spokeCount)
        let halfWidth: Double = 0.06

        for i in 0..<spokeCount {
            let angle: Double = Double(i) * angleStep + rotationRad
            let spokePulse: Double = i.isMultiple(of: 2)
                ? pulse
                : 0.75 + 0.25 * sin(elapsed / pulseDuration * .pi * 2 + .pi * 0.6)

            let path = spokePath(center: center, radius: radius, angle: angle, halfWidth: halfWidth)
            let endPoint = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            let gradient = Gradient(colors: [
                color.opacity(0.40 * spokePulse),
                color.opacity(0.10 * spokePulse),
                color.opacity(0)
            ])
            context.fill(path, with: .linearGradient(gradient, startPoint: center, endPoint: endPoint))
        }
    }

    private func spokePath(center: CGPoint, radius: Double, angle: Double, halfWidth: Double) -> Path {
        var path = Path()
        path.move(to: center)
        let leftX: Double = center.x + radius * cos(angle - halfWidth)
        let leftY: Double = center.y + radius * sin(angle - halfWidth)
        path.addLine(to: CGPoint(x: leftX, y: leftY))
        let rightX: Double = center.x + radius * cos(angle + halfWidth)
        let rightY: Double = center.y + radius * sin(angle + halfWidth)
        path.addLine(to: CGPoint(x: rightX, y: rightY))
        path.closeSubpath()
        return path
    }
}
