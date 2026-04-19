//
//  CombatV2EndPhase.swift
//  Hexbound
//
//  Interactive Combat v2 — END state view.
//
//  The END state is the "show me what I got" screen — it replaces the
//  V1 `BattleSummaryView`'s round-log-first layout with a rewards-first
//  stack (architecture doc §4.3). The full chronological battle log is
//  NOT rendered here. It still exists on the VM (`battleLog`), and the
//  downstream `CombatResultDetailView` surfaces it behind a tap-through
//  on the "Battle Log" button — so players who care can review every
//  round, and players who just want to move on can hit CONTINUE in one
//  tap.
//
//  Stack order (top → bottom):
//
//    1. EndHeader                 (VICTORY / DEFEAT cinematic title)
//    2. CombatV2RewardsBlock      (gold / xp / rating + loot strip)
//    3. CombatV2ObjectivesBlock   (3 victory stars)
//    4. CombatV2BattleStatsBlock  (damage / accuracy / best hit)
//    5. Continue CTA              (→ vm.continueFromSummary())
//
//  During `.completing` the rewards block renders a loader so the screen
//  doesn't flash "+0 GOLD" while /pvp/match/complete is in flight. Once
//  `vm.finalCombatData` lands, the tiles crossfade to real values.
//

import SwiftUI

struct CombatV2EndPhase: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                CombatV2EndHeader(
                    playerWon: playerWon,
                    isRanked: isRanked
                )

                CombatV2RewardsBlock(
                    combatData: vm.finalCombatData,
                    isLoading: isLoadingRewards
                )
                .animation(.easeInOut(duration: 0.35), value: vm.finalCombatData != nil)

                CombatV2ObjectivesBlock(vm: vm)

                CombatV2BattleStatsBlock(vm: vm)

                continueButton
            }
            .padding(.vertical, LayoutConstants.spaceSM)
        }
    }

    // MARK: - Continue

    /// The single exit CTA. Disabled while `.completing` so we never fire
    /// `continueFromSummary()` twice. The VM guards this internally but
    /// the UI should still look honest about the wait.
    private var continueButton: some View {
        Button {
            HapticManager.medium()
            vm.continueFromSummary()
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("CONTINUE")
                    .font(DarkFantasyTheme.buttonLabel)
                    .tracking(3)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoadingRewards)
        .opacity(isLoadingRewards ? 0.55 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoadingRewards)
    }

    // MARK: - Derived

    private var playerWon: Bool {
        vm.state.winnerId == vm.state.attackerId
    }

    /// Ranked / unranked split drives the subtitle copy under the VICTORY /
    /// DEFEAT title. Best signal we have client-side is "did the server
    /// report a rating delta?" — if yes, this was a ranked duel.
    private var isRanked: Bool {
        (vm.finalCombatData?.result.ratingChange ?? 0) != 0
    }

    /// Rewards block should show a loader until `finalCombatData` lands.
    /// `.completing` is the intermediate state between the finishing blow
    /// and the server-ack. `.summary` is the gap where the log is frozen
    /// but rewards haven't been requested yet.
    private var isLoadingRewards: Bool {
        if vm.finalCombatData != nil { return false }
        switch vm.phase {
        case .completing: return true
        case .summary:    return true
        default:          return false
        }
    }
}
