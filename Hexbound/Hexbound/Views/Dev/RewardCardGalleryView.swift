#if DEBUG
import SwiftUI

/// TEMPORARY (throwaway branch claude/sim-cards only): cycles through every reward
/// card frame and the real reward windows so CI can screenshot them on a simulator.
/// Launch with `-RewardCardGallery`.
struct RewardCardGalleryView: View {
    @Environment(AppState.self) private var appState
    @State private var page = 0
    @State private var ready = false
    static let interval: Double = 4.5
    static let pageCount = Page.all.count

    var body: some View {
        let pages = Page.all
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            if ready {
                pages[page % pages.count].view
                    .id(page)
            }
            VStack {
                Text("\(page % pages.count + 1)/\(pages.count) · \(pages[page % pages.count].name)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .background(DarkFantasyTheme.bgAbyss.opacity(0.85))
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .task {
            prepareHero()
            ready = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.interval))
                page += 1
                if pages[page % pages.count].name.hasPrefix("level up") {
                    appState.levelUpNewLevel = 24
                    appState.levelUpStatPoints = 3
                    appState.levelUpPassivePoints = 1
                }
            }
        }
    }

    /// A stand-in hero so the hero illustrations have someone to show.
    private func prepareHero() {
        let json = #"{"id":"gallery","characterName":"Art","class":"warrior","origin":"orc","avatar":"orc_m_ironjaw","level":24,"gold":1000,"currentHp":100,"maxHp":100,"currentStamina":100,"maxStamina":100,"pvpRating":1450,"pvpWins":12,"pvpLosses":5}"#
        appState.currentCharacter = try? JSONDecoder().decode(Character.self, from: Data(json.utf8))
        appState.levelUpNewLevel = 24
        appState.levelUpStatPoints = 3
        appState.levelUpPassivePoints = 1
    }

    struct Page {
        let name: String
        let view: AnyView

        static var all: [Page] {
            var pages: [Page] = RewardCardFamily.allCases.map { family in
                Page(name: "frames · \(family.rawValue)", view: AnyView(FamilySheet(family: family)))
            }
            pages += claimPages
            pages += battlePages
            pages += ceremonyPages
            pages += activityPages
            return pages
        }

        // MARK: CLAIMED!

        static var claimPages: [Page] {
            [
                claim("claim · login day 3", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Day 3", goldReward: 300, gemsReward: 0, xpReward: 0, lootItems: [], family: .tribute, tier: .bronze)),
                claim("claim · login day 7", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Day 7", goldReward: 0, gemsReward: 25, xpReward: 0, lootItems: [], family: .tribute, tier: .gold)),
                claim("claim · battle pass", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Level 2 — Free", goldReward: 160, gemsReward: 0, xpReward: 0, lootItems: [], family: .glory, tier: .iron)),
                claim("claim · achievement", ClaimRewardConfig(title: "CLAIMED!", subtitle: "First Blood", goldReward: 200, gemsReward: 5, xpReward: 100, lootItems: [], family: .glory, art: .object("achievement-pvp-first-blood", fill: 0.56))),
                claim("claim · quests bonus", ClaimRewardConfig(title: "CLAIMED!", subtitle: "All quests completed", goldReward: 450, gemsReward: 10, xpReward: 300, lootItems: [], family: .tribute, tier: .silver)),
                claim("claim · mail with loot", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Season gift", goldReward: 1200, gemsReward: 0, xpReward: 0, lootItems: [
                    ClaimLootItem(id: "a", name: "Pyrox Greatsword", quantity: 1, imageKey: "loot-pyrox-greatsword", fallbackIcon: "shippingbox", rarity: .epic, rarityColor: DarkFantasyTheme.rarityEpic),
                    ClaimLootItem(id: "b", name: "Necrotic Tome", quantity: 1, imageKey: "loot-necrotic-tome", fallbackIcon: "shippingbox", rarity: .rare, rarityColor: DarkFantasyTheme.rarityRare),
                    ClaimLootItem(id: "c", name: "Health Potion", quantity: 3, imageKey: "health_potion_large", fallbackIcon: "cross.vial", rarity: .uncommon, rarityColor: DarkFantasyTheme.rarityUncommon),
                    ClaimLootItem(id: "d", name: "Stamina Potion", quantity: 2, imageKey: "stamina_potion_large", fallbackIcon: "cross.vial", rarity: .uncommon, rarityColor: DarkFantasyTheme.rarityUncommon),
                ], family: .tribute)),
                claim("claim · contraband", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Drop #3", goldReward: 0, gemsReward: 120, xpReward: 0, lootItems: [], family: .merchant)),
                claim("claim · potion only", ClaimRewardConfig(title: "CLAIMED!", subtitle: "Day 2", goldReward: 0, gemsReward: 0, xpReward: 0, lootItems: [
                    ClaimLootItem(id: "p", name: "S. Potion", quantity: 1, imageKey: "stamina_potion_small", fallbackIcon: "cross.vial", rarity: .common, rarityColor: DarkFantasyTheme.rarityCommon),
                ], family: .tribute, tier: .iron)),
            ]
        }

        static func claim(_ name: String, _ config: ClaimRewardConfig) -> Page {
            Page(name: name, view: AnyView(ClaimRewardModalView(config: config, onDismiss: {})))
        }

        // MARK: Battles

        static var battlePages: [Page] {
            let epic = LootItemDisplay(name: "Pyrox Greatsword", rarityName: "EPIC", rarityColor: DarkFantasyTheme.rarityEpic, imageKey: "loot-pyrox-greatsword", imageUrl: nil, sfIcon: nil, sfColor: nil, fallbackIcon: "shippingbox", rarityTier: 3)
            let rare = LootItemDisplay(name: "Necrotic Tome", rarityName: "RARE", rarityColor: DarkFantasyTheme.rarityRare, imageKey: "loot-necrotic-tome", imageUrl: nil, sfIcon: nil, sfColor: nil, fallbackIcon: "shippingbox", rarityTier: 2)
            let duel = DuelResultInfo(playerSkinKey: "orc_m_ironjaw", playerClass: .warrior, playerLevel: 24, ratingBefore: 1426, rivalName: "Morgrath", rivalSkinKey: "orc_m_bloodlord", rivalClass: .warrior, rivalLevel: 25, onViewRival: nil, onMessageRival: nil)
            let win = BattleResultConfig(
                isVictory: true, title: "VICTORY!", subtitle: "vs. Morgrath", illustrationImage: nil,
                goldReward: 180, xpReward: 60, ratingChange: 24, firstWinBonus: true,
                xpBefore: 600, xpNeeded: 1000,
                xpBarConfig: XPBarConfig(displayLevel: 24, progress: 0.66, leveledUp: false),
                dungeonProgress: nil,
                lootItems: [rare], onLootTap: nil,
                buttons: [ResultButton(title: "CONTINUE", style: .primary, action: {})],
                duel: duel,
                cardFamily: .arena, cardTier: .gold
            )
            let loss = BattleResultConfig(
                isVictory: false, title: "DEFEAT", subtitle: "vs. Rook the Grim", illustrationImage: nil,
                goldReward: 0, xpReward: 15, ratingChange: -9, firstWinBonus: false,
                xpBarConfig: nil, dungeonProgress: nil,
                lootItems: [], onLootTap: nil,
                buttons: [ResultButton(title: "CONTINUE", style: .secondary, action: {})],
                duel: DuelResultInfo(playerSkinKey: "orc_m_ironjaw", playerClass: .warrior, playerLevel: 24, ratingBefore: 1450, rivalName: "Rook the Grim", rivalSkinKey: "human_m_bastion_lord", rivalClass: .tank, rivalLevel: 26, onViewRival: nil, onMessageRival: nil),
                cardFamily: .arena, cardTier: .silver
            )
            let boss = BattleResultConfig(
                isVictory: true, title: "BOSS DEFEATED", subtitle: "Golden Golem · Scorched Mines", illustrationImage: nil,
                goldReward: 650, xpReward: 210, ratingChange: nil, firstWinBonus: false,
                xpBarConfig: XPBarConfig(displayLevel: 24, progress: 0.82, leveledUp: false),
                dungeonProgress: DungeonProgressConfig(defeated: 7, total: 10, isComplete: false),
                lootItems: [epic, rare], onLootTap: nil,
                buttons: [ResultButton(title: "FIGHT NEXT", style: .primary, action: {})],
                cardFamily: .dungeon, cardArt: .figure("boss-golden-golem-full")
            )
            return [
                Page(name: "arena · victory", view: AnyView(BattleResultCardView(config: win))),
                Page(name: "arena · defeat", view: AnyView(BattleResultCardView(config: loss))),
                Page(name: "dungeon · boss", view: AnyView(BattleResultCardView(config: boss))),
            ]
        }

        // MARK: Ceremonies

        static var ceremonyPages: [Page] {
            [
                Page(name: "level up", view: AnyView(LevelUpModalView())),
                Page(name: "rank up", view: AnyView(RankUpCeremonyView(oldRank: "Silver I", newRank: "Gold III", newRating: 1520, goldReward: 0, gemReward: 0, onDismiss: {}))),
                Page(name: "season summary", view: AnyView(SeasonSummaryModalView(summary: SeasonSummaryData(seasonName: "Dark Forge", finalLevel: 42, totalBattles: 120, wins: 74, peakRank: 3, goldEarned: 18450, rewardsClaimed: 30, hadPremium: true), onDismiss: {}))),
                Page(name: "tutorial victory", view: AnyView(VictoryOverlayView(heroName: "Art"))),
            ]
        }

        // MARK: Activities and shop

        static var activityPages: [Page] {
            [
                Page(name: "wheel · win", view: AnyView(MinigameResultModal(isWin: true, title: "YOU WON!", amountText: "+450 gold", winnings: 450, tier: .gold, onContinue: {}) {
                    Image("fortune-wheel-face").resizable().scaledToFit()
                })),
                Page(name: "shell · loss", view: AnyView(MinigameResultModal(isWin: false, title: "EMPTY CUP", amountText: "−100 gold", winnings: 0, onContinue: {}) {
                    Image("shell_cup").resizable().scaledToFit()
                })),
                Page(name: "rush · treasure", view: AnyView(TreasureRewardOverlay(gold: 340, buff: nil, buffAssetName: nil, onDismiss: {}))),
                Page(name: "mine · haul", view: AnyView(MineClaimRewardView(reward: .init(kind: .haul, goldEarned: 260, gemsEarned: 1, chest: nil), onDismiss: {}))),
                Page(name: "shop · gem pack", view: AnyView(PurchaseRewardRevealView(content: PurchaseRevealContent(artAsset: "shop-gems-tier3", accent: DarkFantasyTheme.purple, burst: .epic, rewards: [.gems(550)]), onDismiss: {}))),
                Page(name: "descent · victory", view: AnyView(DescentResultCard(
                    result: DescentResult(outcome: "victory", keptGold: 1840, keptItems: [
                        DescentBagItem(kind: "item", name: "Pyrox Greatsword", rarity: "epic", itemType: "weapon", itemLevel: 24, imageKey: "loot-pyrox-greatsword", imageUrl: nil, shardTier: nil, amount: 1),
                        DescentBagItem(kind: "shard", name: "Legendary Shard", rarity: "legendary", itemType: nil, itemLevel: nil, imageKey: nil, imageUrl: nil, shardTier: "t1", amount: 3),
                    ], lostGold: 0, lostItems: [], xp: 620, depthReached: 2, rooms: 21, kills: 15),
                    depthKey: "molten", depthRoman: "III", staminaCost: 30, isStarting: false, onAgain: {}, onLeave: {}
                ))),
                Page(name: "descent · defeat", view: AnyView(DescentResultCard(
                    result: DescentResult(outcome: "dead", keptGold: 210, keptItems: [
                        DescentBagItem(kind: "item", name: "Necrotic Tome", rarity: "rare", itemType: "relic", itemLevel: 22, imageKey: "loot-necrotic-tome", imageUrl: nil, shardTier: nil, amount: 1),
                    ], lostGold: 210, lostItems: [
                        DescentBagItem(kind: "item", name: "Bone Shield", rarity: "uncommon", itemType: "shield", itemLevel: 21, imageKey: "loot-bone-shield", imageUrl: nil, shardTier: nil, amount: 1),
                    ], xp: 180, depthReached: 1, rooms: 9, kills: 6),
                    depthKey: "ossuary", depthRoman: "II", staminaCost: 30, isStarting: false, onAgain: {}, onLeave: {}
                ))),
            ]
        }
    }

    /// The five tiers of one family, small, with a line of content each.
    struct FamilySheet: View {
        let family: RewardCardFamily
        var body: some View {
            GeometryReader { geo in
                let w = (geo.size.width - 3 * LayoutConstants.spaceSM) / 2
                ScrollView {
                    LazyVGrid(columns: [GridItem(.fixed(w)), GridItem(.fixed(w))], spacing: LayoutConstants.spaceSM) {
                        ForEach(RewardCardTier.allCases, id: \.self) { tier in
                            RewardCard(
                                family: family,
                                tier: tier,
                                art: .object("reward-art-gold-heap"),
                                width: w,
                                artRatio: 0.7,
                                title: tier.assetKey.uppercased(),
                                content: {
                                    Text("+120").font(DarkFantasyTheme.cardTitle).foregroundStyle(DarkFantasyTheme.goldBright)
                                },
                                actions: { EmptyView() }
                            )
                        }
                    }
                    .padding(.top, 40)
                }
            }
        }
    }
}
#endif
