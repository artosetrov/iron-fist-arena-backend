//
//  CombatV2ChoosePhase.swift
//  Hexbound
//
//  Interactive Combat v2 — CHOOSE state view.
//
//  This is the ONE interactive decision screen in the entire combat
//  surface. Architecture doc §4.1. Layout (top → bottom):
//
//    1. Round strip          (ROUND N · BEST OF M · CHOOSE YOUR STRIKE)
//    2. Attack zone picker   (head / chest / legs — hero ATK bonus text)
//    3. Defend zone picker   (head / chest / legs — hero DEF bonus text)
//    4. Enemy intent locks   (hidden rune until enough history; reveals
//                             a dim heuristic marker on the zone the
//                             opponent most often attacks / defends)
//    5. Active skills HUD    (only if the player has equipped actives)
//    6. Action bar           (SKIP · STRIKE with radial timer ring)
//
//  Rules the view enforces, derived directly from the architecture doc
//  and the prototype:
//
//    • The STRIKE CTA is disabled until BOTH zones have been actively
//      picked this round. The VM's default `.chest` does not count —
//      that's the whole point of the refactor (prevents a reflex STRIKE
//      submitting untouched defaults the player never looked at).
//
//    • When `vm.uxState == .choose(locked: true)` the whole panel
//      dims to 60% and disables — the exchange is in flight and the
//      CHOOSE screen is waiting for the server to round-trip before
//      RESOLVE takes over. We keep CHOOSE mounted (vs. flashing to an
//      empty RESOLVE state) so the transition reads as a short pause,
//      not a stutter.
//
//    • No scale animations. Feedback uses opacity / border / text color
//      only (project rule `feedback_no_scale_animations`).
//

import SwiftUI

struct CombatV2ChoosePhase: View {
    @Bindable var vm: InteractiveBattleViewModel

    /// `true` when the server is resolving this round. Panel dims + disables.
    let locked: Bool

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            CombatV2RoundStrip(
                roundNumber: vm.currentRoundNumber,
                bestOf: InteractiveBattleViewModel.maxRounds,
                stateTag: locked ? "STRIKING…" : "CHOOSE YOUR STRIKE"
            )

            zonePicker(
                title: "ATTACK",
                selection: vm.selectedAttackZone,
                touched: vm.attackTouched,
                likelyOpponent: vm.likelyOpponentDefend, // their likely DEF → our ATK hint
                hintCaption: "ENEMY TENDS TO GUARD",
                onPick: { vm.pickAttack($0) },
                isAttack: true
            )

            zonePicker(
                title: "DEFEND",
                selection: vm.selectedDefendZone,
                touched: vm.defendTouched,
                likelyOpponent: vm.likelyOpponentAttack, // their likely ATK → our DEF hint
                hintCaption: "ENEMY TENDS TO AIM",
                onPick: { vm.pickDefend($0) },
                isAttack: false
            )

            if !vm.playerActives.isEmpty {
                activesRow
            }

            actionBar
        }
        .disabled(locked)
        .opacity(locked ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: locked)
        .animation(.easeInOut(duration: 0.25), value: vm.attackTouched)
        .animation(.easeInOut(duration: 0.25), value: vm.defendTouched)
    }

    // MARK: - Zone Picker

    /// A single ATK or DEF row with three zone tiles and an optional
    /// enemy-intent hint caption. The hint is deliberately soft: small
    /// text, no exclamation, no red highlight — the tell is a *pattern*,
    /// not a fact, and we never want it to bait misreads.
    @ViewBuilder
    private func zonePicker(
        title: String,
        selection: InteractiveBodyZone,
        touched: Bool,
        likelyOpponent: InteractiveBodyZone?,
        hintCaption: String,
        onPick: @escaping (InteractiveBodyZone) -> Void,
        isAttack: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Text(title)
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(touched
                        ? DarkFantasyTheme.gold
                        : DarkFantasyTheme.textSecondary)
                    .tracking(2)

                Spacer(minLength: 0)

                if !touched {
                    Text("TAP TO CHOOSE")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)
                }
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(InteractiveBodyZone.allCases, id: \.self) { zone in
                    CombatV2ZoneTile(
                        zone: zone,
                        isSelected: touched && selection == zone,
                        isAttack: isAttack,
                        enemyHint: likelyOpponent == zone,
                        fallbackIcon: Self.fallbackIcon(for: zone)
                    ) {
                        HapticManager.selection()
                        onPick(zone)
                    }
                }
            }

            if let likely = likelyOpponent {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image(systemName: "eye")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("\(hintCaption) \(likely.rawValue.uppercased())")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)
                }
            }
        }
    }

    // MARK: - Actives Row

    /// The active-skills HUD as a full-width row under the pickers.
    /// Reuses the existing V1 `ActiveSkillsHUD` — cooldowns, tap-to-arm,
    /// and all the wiring already work there.
    private var activesRow: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text("ACTIVE SKILLS")
                .font(DarkFantasyTheme.uiLabel)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            ActiveSkillsHUD(
                actives: vm.playerActives,
                pendingSlot: vm.pendingActiveSlot,
                isInteractive: !locked,
                onTap: { vm.toggleActiveSlot($0) }
            )
        }
    }

    // MARK: - Action Bar

    /// SKIP on the left, STRIKE (with integrated radial timer) on the
    /// right. STRIKE's enabled state is driven ENTIRELY by
    /// `vm.canSubmitStrike` — which requires both zones to have been
    /// actively touched this round. SKIP is always enabled during
    /// CHOOSE (even while locked → but the whole panel is disabled at
    /// the parent level, so SKIP is unreachable in that case).
    private var actionBar: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button {
                HapticManager.medium()
                vm.skipAndSubmit()
            } label: {
                Text("SKIP")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
            }
            .buttonStyle(SecondaryButtonStyle())
            .frame(maxWidth: .infinity)

            TimerRingStrikeButton(
                remainingFraction: timerFraction,
                isCritical: vm.predictTimeRemaining <= 1.5,
                isBusy: locked,
                action: {
                    HapticManager.medium()
                    vm.submitStrike()
                }
            )
            .opacity(vm.canSubmitStrike || locked ? 1.0 : 0.45)
            .disabled(!(vm.canSubmitStrike || locked))
            .frame(maxWidth: .infinity)
        }
    }

    private var timerFraction: Double {
        let total = InteractiveBattleViewModel.predictWindowSeconds
        guard total > 0 else { return 0 }
        return max(0, min(1, vm.predictTimeRemaining / total))
    }

    private static func fallbackIcon(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "brain.head.profile"
        case .chest: return "heart.fill"
        case .legs:  return "figure.walk"
        }
    }
}

// MARK: - Zone Tile
//
// V2 version of the picker tile. Differences from V1's `ZoneTileButton`:
//   • Exposes an `enemyHint: Bool` that paints a subtle dim rune corner
//     when this zone is the opponent's most-frequent pick. Replaces the
//     "??? intent chip" cycle from V1 and lets the player read one screen.
//   • Selected state uses opacity + border + text color — no scale bump.
//   • Untouched state is visibly "not yet chosen" — gold border missing,
//     label dim, rune icon softened. This is the visual affordance that
//     tells the player the STRIKE CTA is waiting on *them*.

struct CombatV2ZoneTile: View {
    let zone: InteractiveBodyZone
    let isSelected: Bool
    let isAttack: Bool
    let enemyHint: Bool
    let fallbackIcon: String
    let action: () -> Void

    @State private var showTooltip = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.space2XS) {
                CachedAssetImage(
                    key: InteractiveStanceBonuses.assetName(for: zone),
                    url: nil,
                    systemIcon: fallbackIcon,
                    contentMode: .fit
                )
                .frame(width: 32, height: 32)
                .opacity(isSelected ? 1.0 : 0.85)

                Text(zone.rawValue.uppercased())
                    .font(DarkFantasyTheme.badge)
                    .tracking(1.5)

                Text(bonusText)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(
                        isSelected
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.textTertiary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(isSelected
                          ? DarkFantasyTheme.gold.opacity(0.18)
                          : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(isSelected
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.borderSubtle,
                            lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if enemyHint {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(6)
                }
            }
            .foregroundStyle(isSelected
                             ? DarkFantasyTheme.gold
                             : DarkFantasyTheme.textPrimary)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.35) {
            HapticManager.selection()
            showTooltip = true
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            CombatInfoTooltipContent(
                title: tooltipTitle,
                message: tooltipMessage
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityHint(Text("Long press for details"))
    }

    private var bonusText: String {
        isAttack
            ? InteractiveStanceBonuses.attackBonusText(for: zone)
            : InteractiveStanceBonuses.defendBonusText(for: zone)
    }

    private var tooltipTitle: String {
        let channel = isAttack ? "ATTACK" : "DEFENSE"
        return "\(channel) · \(zone.rawValue.uppercased())"
    }

    private var tooltipMessage: String {
        isAttack
            ? InteractiveStanceBonuses.attackTooltip(for: zone)
            : InteractiveStanceBonuses.defendTooltip(for: zone)
    }
}
