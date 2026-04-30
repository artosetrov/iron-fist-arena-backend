//
//  CombatV2EndComponents.swift
//  Hexbound
//
//  Interactive Combat v2 — END state building blocks.
//
//  Architecture doc §4.3 pushes REWARDS above STATS, inverting the V1
//  order. Rationale: the player cares about what they got FIRST
//  (gold / xp / rating / loot) and about how they earned it SECOND
//  (damage dealt, accuracy, best hit). V1 sent them to a stats header
//  before rewards even registered. The V2 stack is:
//
//    1. EndHeader         (VICTORY / DEFEAT + outcome tint)
//    2. RewardsBlock      (gold / xp / rating delta + loot strip)
//    3. ObjectivesBlock   (3 stars — Victory / Survivor / Critical)
//    4. BattleStatsBlock  (damage / accuracy / best hit — reuses
//                          BattleStatsHeader from V1)
//    5. Continue CTA      (lives in CombatV2EndPhase, not here)
//
//  This file keeps each block a pure `View` taking only the inputs it
//  needs. Composition lives in `CombatV2EndPhase.swift` so the V2 host
//  can tweak padding / backgrounds / scroll behavior without editing
//  every leaf component.
//

import SwiftUI

// MARK: - End Header (VICTORY / DEFEAT)

/// Top of the END screen. A single tracked title plus a thin subtitle
/// rail. Uses `cinematicTitle` for the outcome word and the existing
/// gold / danger tints so the victory overlay and this title agree.
struct CombatV2EndHeader: View {
    let playerWon: Bool
    let isRanked: Bool

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(playerWon ? "VICTORY" : "DEFEAT")
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(4)
                .foregroundStyle(outcomeColor)
                .shadow(color: outcomeColor.opacity(0.4), radius: 18)

            Text(subtitle)
                .font(DarkFantasyTheme.caption)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    private var outcomeColor: Color {
        playerWon ? DarkFantasyTheme.gold : DarkFantasyTheme.danger
    }

    private var subtitle: String {
        if isRanked {
            return playerWon ? "YOU CLAIMED THE DUEL" : "YOU LOST THE DUEL"
        }
        return playerWon ? "THE DUEL IS YOURS" : "THE DUEL IS LOST"
    }
}

// MARK: - Rewards Block
//
// Row of three hero tiles (gold / xp / rating delta) plus a loot strip
// underneath. Values come from `vm.finalCombatData`, which lands on
// `.finished` after the `/pvp/match/complete` round-trip. While the
// VM is still in `.completing` this block renders a loader instead of
// placeholder zeros — showing "0 GOLD" for a split second reads like
// a bug.

struct CombatV2RewardsBlock: View {
    let combatData: CombatData?
    let isLoading: Bool

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader

            if isLoading || combatData == nil {
                loadingState
            } else {
                rewardTiles
                if let loot = combatData?.loot, !loot.isEmpty {
                    lootStrip(items: loot)
                }
            }
        }
    }

    // MARK: Section header

    private var sectionHeader: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
            Text("REWARDS")
                .font(DarkFantasyTheme.uiLabel)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }

    // MARK: Loading state

    private var loadingState: some View {
        HStack {
            Spacer()
            HexPulseLoader(.compact, message: "TALLYING THE SPOILS")
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: Reward tiles

    private var rewardTiles: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            rewardTile(
                label: "GOLD",
                value: formattedGold,
                subValue: nil,
                iconName: "coin",
                systemFallback: "circle.hexagonpath.fill",
                tint: DarkFantasyTheme.gold
            )
            rewardTile(
                label: "XP",
                value: formattedXp,
                subValue: nil,
                iconName: nil,
                systemFallback: "sparkles",
                tint: DarkFantasyTheme.info
            )
            // Combat V2 D-1 (2026-04-29): show rating delta + new total. Total
            // line is `nil` on old backends that don't ship `rating_after`,
            // so the tile gracefully degrades to delta-only there.
            rewardTile(
                label: "RATING",
                value: formattedRating,
                subValue: formattedRatingTotal,
                iconName: nil,
                systemFallback: "chart.line.uptrend.xyaxis",
                tint: ratingTint
            )
        }
    }

    @ViewBuilder
    private func rewardTile(
        label: String,
        value: String,
        subValue: String?,
        iconName: String?,
        systemFallback: String,
        tint: Color
    ) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            if let iconName {
                CachedAssetImage(
                    key: iconName,
                    url: nil,
                    systemIcon: systemFallback,
                    contentMode: .fit
                )
                .frame(width: 28, height: 28)
            } else {
                Image(systemName: systemFallback)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subValue {
                Text(subValue)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(label)
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.12), radius: 10)
    }

    // MARK: Loot strip
    //
    // Horizontal scroller of dropped items. Rarity dot on the top-right
    // corner makes the mix glanceable without a legend. Tapping an item
    // here is a no-op — the inventory view is where the player interacts
    // with loot. The strip is READ-ONLY and purely celebratory.

    @ViewBuilder
    private func lootStrip(items: [CombatLootItem]) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text("LOOT")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(items, id: \.identifier) { item in
                        lootTile(item: item)
                    }
                }
                .padding(.horizontal, 1) // avoid stroke clipping
            }
        }
    }

    private func lootTile(item: CombatLootItem) -> some View {
        let tint = rarityTint(item.rarity)
        return VStack(spacing: LayoutConstants.space2XS) {
            CachedAssetImage(
                key: item.imageKey ?? "item_placeholder",
                url: item.imageUrl,
                systemIcon: "shield.lefthalf.filled",
                contentMode: .fit
            )
            .frame(width: 44, height: 44)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .shadow(color: tint.opacity(0.6), radius: 4)
                    .offset(x: 2, y: -2)
            }

            Text(item.displayName.uppercased())
                .font(DarkFantasyTheme.badge)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 72)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(tint.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Derived formatting

    private var formattedGold: String {
        let amount = combatData?.rewards?.gold
            ?? combatData?.result.goldReward
            ?? 0
        return amount > 0 ? "+\(amount)" : "—"
    }

    private var formattedXp: String {
        let amount = combatData?.rewards?.xp
            ?? combatData?.result.xpReward
            ?? 0
        return amount > 0 ? "+\(amount)" : "—"
    }

    private var formattedRating: String {
        guard let delta = combatData?.result.ratingChange else { return "—" }
        if delta > 0  { return "+\(delta)" }
        if delta < 0  { return "\(delta)" }
        return "±0"
    }

    /// Absolute rating after the match (D-1, 2026-04-29). Returns `nil` on
    /// old backends that haven't yet shipped `rating_after` — the tile
    /// drops the secondary line in that case rather than showing a stale
    /// or guessed value.
    private var formattedRatingTotal: String? {
        guard let after = combatData?.result.ratingAfter else { return nil }
        return "\(after)"
    }

    private var ratingTint: Color {
        guard let delta = combatData?.result.ratingChange else {
            return DarkFantasyTheme.textTertiary
        }
        if delta > 0 { return DarkFantasyTheme.success }
        if delta < 0 { return DarkFantasyTheme.danger }
        return DarkFantasyTheme.textTertiary
    }

    private func rarityTint(_ rawRarity: String?) -> Color {
        switch rawRarity?.lowercased() {
        case "common":     return DarkFantasyTheme.rarityCommon
        case "uncommon":   return DarkFantasyTheme.rarityUncommon
        case "rare":       return DarkFantasyTheme.rarityRare
        case "epic":       return DarkFantasyTheme.rarityEpic
        case "legendary":  return DarkFantasyTheme.rarityLegendary
        default:           return DarkFantasyTheme.textTertiary
        }
    }
}

// MARK: - Objectives Block (3 stars)
//
// Reuses `BattleStar` + `BattleVictoryStars` from the V1 summary view so
// the star tiles look identical across the upgrade. The star definitions
// are computed client-side from the frozen battle log + final HP ratio —
// same logic as V1, lifted verbatim so there's no behavior drift.

struct CombatV2ObjectivesBlock: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text("OBJECTIVES")
                .font(DarkFantasyTheme.uiLabel)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            BattleVictoryStars(stars: stars)
        }
    }

    private var stars: [BattleStar] {
        let hpRatio = vm.state.attackerMaxHp > 0
            ? Double(vm.state.attackerHp) / Double(vm.state.attackerMaxHp)
            : 0
        let playerWon = vm.state.winnerId == vm.state.attackerId
        let survivor  = playerWon && hpRatio > 0.5
        let critLanded = vm.battleLog.contains { exchange in
            exchange.allyEvents.contains(where: { $0.isCritStrike })
        }
        return [
            BattleStar(kind: .victory,  earned: playerWon,  title: "CLAIM",      subtitle: "VICTORY"),
            BattleStar(kind: .survivor, earned: survivor,   title: "STAY ABOVE", subtitle: "50% HP"),
            BattleStar(kind: .critical, earned: critLanded, title: "LAND A",     subtitle: "CRITICAL HIT"),
        ]
    }
}

// MARK: - Battle Stats Block (damage / accuracy / best hit)
//
// Thin wrapper over the V1 `BattleStatsHeader` so the V2 host doesn't
// need to know about aggregation. Compute once on first appear — the
// battle log is frozen by the time we reach END, so this never changes.

struct CombatV2BattleStatsBlock: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text("BATTLE STATS")
                .font(DarkFantasyTheme.uiLabel)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            BattleStatsHeader(stats: stats, playerWon: playerWon)
        }
    }

    private var stats: RoundExchange.BattleStats {
        RoundExchange.aggregate(log: vm.battleLog)
    }

    private var playerWon: Bool {
        vm.state.winnerId == vm.state.attackerId
    }
}
