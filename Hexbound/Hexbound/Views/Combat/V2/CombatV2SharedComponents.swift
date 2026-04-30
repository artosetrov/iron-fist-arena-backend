//
//  CombatV2SharedComponents.swift
//  Hexbound
//
//  Shared pieces used across multiple V2 combat UX states. These are
//  extracted from the V1 `InteractiveBattleView` so the state-specific
//  views can compose a coherent screen without duplicating layout work.
//
//  IMPORTANT: the duel header is mounted ONCE at the root of
//  `InteractiveBattleV2View`, OUTSIDE the state switch. This preserves
//  VFX anchor coordinates — the FighterAnchorKey preference only fires
//  on first layout, and re-mounting on state change would yank FX to
//  the default (0.25, 0.75) positions mid-battle.
//

import SwiftUI

// MARK: - V2 Duel Header
//
// A refined, noise-reduced version of the V1 header. Visual rules:
//   • YOU portrait on the left (green frame), ENEMY on the right (red).
//   • Below each portrait: name + level · class, then a thin HP bar and
//     a single HP readout. NO stance chips, NO intent chips, NO active
//     previews — those belong to the CHOOSE state's dedicated strip.
//   • Outcome role (winner/loser) drives a subtle gold glow on the
//     winner and a dim on the loser — peak-verdict only.
//
// Why this matters: the V1 header stacks 4–6 extra chips/banners below
// each avatar and rewrites itself every 1.5 s (intent → confirmed →
// intent). V2 keeps the header as a stable identity strip and pushes
// all transient info down into the state-specific panels below.

struct CombatV2DuelHeader: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            fighterColumn(
                side: .player,
                profile: vm.attackerProfile,
                currentHp: vm.state.attackerHp,
                maxHp: vm.state.attackerMaxHp,
                slideX: vm.playerSlideX,
                flash: vm.playerFlash,
                popups: vm.damagePopups.filter { !$0.onDefender },
                outcomeRole: vm.playerOutcomeRole
            )
            fighterColumn(
                side: .enemy,
                profile: vm.defenderProfile,
                currentHp: vm.state.defenderHp,
                maxHp: vm.state.defenderMaxHp,
                slideX: vm.enemySlideX,
                flash: vm.enemyFlash,
                popups: vm.damagePopups.filter { $0.onDefender },
                outcomeRole: vm.opponentOutcomeRole
            )
        }
        .animation(.easeOut(duration: 0.25), value: vm.playerOutcomeRole)
        .animation(.easeOut(duration: 0.25), value: vm.opponentOutcomeRole)
    }

    @ViewBuilder
    private func fighterColumn(
        side: DuelSide,
        profile: FighterProfile?,
        currentHp: Int,
        maxHp: Int,
        slideX: CGFloat,
        flash: Bool,
        popups: [DamagePopup],
        outcomeRole: OutcomeRole?
    ) -> some View {
        let borderColor = side == .player ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        let sideLabel = side == .player ? "YOU" : "ENEMY"

        VStack(spacing: LayoutConstants.spaceXS) {
            Text(sideLabel)
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(borderColor)

            CombatV2AvatarTile(
                profile: profile,
                borderColor: borderColor,
                mirror: side == .enemy,
                slideX: slideX,
                flash: flash,
                popups: popups
            )
            .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                [FighterAnchorKey.Entry(side: side, bounds: $0)]
            }

            Text(profile?.name.uppercased() ?? "…")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(subtitle(for: profile))
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            HPBarView(
                currentHp: currentHp,
                maxHp: maxHp,
                size: .compact,
                showTextInside: false,
                pulseOnCritical: true
            )

            Text("\(currentHp) / \(maxHp)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(hpTextColor(current: currentHp, max: maxHp, side: borderColor))
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.25), value: currentHp)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .opacity(outcomeRole == .loser ? 0.72 : 1.0)
        .shadow(
            color: outcomeRole == .winner ? DarkFantasyTheme.gold.opacity(0.4) : .clear,
            radius: outcomeRole == .winner ? 16 : 0
        )
    }

    private func subtitle(for profile: FighterProfile?) -> String {
        guard let profile else { return "—" }
        return "Lv.\(profile.level) \(profile.characterClass.displayName)"
    }

    private func hpTextColor(current: Int, max: Int, side: Color) -> Color {
        let ratio = max > 0 ? Double(current) / Double(max) : 0
        if ratio <= 0.25 { return DarkFantasyTheme.hpBlood }
        return side
    }
}

// MARK: - Avatar Tile (extracted for re-use)

struct CombatV2AvatarTile: View {
    let profile: FighterProfile?
    let borderColor: Color
    let mirror: Bool
    let slideX: CGFloat
    let flash: Bool
    let popups: [DamagePopup]

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgSecondary
            if let profile {
                AvatarImageView(
                    skinKey: profile.avatar,
                    characterClass: profile.characterClass,
                    size: 200
                )
                .scaleEffect(x: mirror ? -1 : 1, y: 1)
            } else {
                HexPulseLoader(.compact)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(borderColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.danger.opacity(flash ? 0.35 : 0.0))
                .allowsHitTesting(false)
        )
        .overlay(alignment: .top) {
            ZStack {
                ForEach(popups) { popup in
                    DamagePopupBubble(popup: popup)
                }
            }
            .allowsHitTesting(false)
        }
        .offset(x: slideX)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Round Strip (ROUND N / M · state tag)
//
// A compact meta strip that sits above the active state panel. Left:
// round number out of total cap. Right: a short phase tag that always
// matches the current UX state — never says "CHOOSE" during RESOLVE
// like V1 did.
//
// Format `ROUND N / M` (D-3, locked 2026-04-29 in
// `docs/07_ui_ux/COMBAT_UX_INTEGRATION_PLAN.md` §8): the engine is a
// hard-capped 15-round duel, NOT a best-of-N match. "BEST OF 7" wording
// implied first-to-4-wins semantics that don't exist in the resolver.
// `N / 15` is honest, lets the player gauge pacing, reads in any locale.

struct CombatV2RoundStrip: View {
    let roundNumber: Int
    /// The maxRounds cap (`InteractiveBattleViewModel.maxRounds`, currently 15).
    /// Param name kept for source compatibility with earlier callers.
    let bestOf: Int
    let stateTag: String

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Text("ROUND \(roundNumber) / \(bestOf)")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.gold)

            Spacer(minLength: LayoutConstants.spaceSM)

            Text(stateTag)
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.space2XS)
    }
}

// MARK: - Stance Summary Strip (read-only, RESOLVE + END)
//
// On the RESOLVE screen we show both players' actual picks this round
// as read-only pills. On the END screen, the strip is hidden.
// No "predicted" / "hidden" modes — the exchange has landed, so both
// sides are knowable and confirmed.

struct CombatV2StanceSummaryStrip: View {
    let playerAttack: InteractiveBodyZone
    let playerDefend: InteractiveBodyZone
    let opponentAttack: InteractiveBodyZone
    let opponentDefend: InteractiveBodyZone

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            stanceColumn(
                title: "YOU",
                titleColor: DarkFantasyTheme.success,
                attack: playerAttack,
                defend: playerDefend
            )
            Divider()
                .frame(width: 1, height: 32)
                .overlay(DarkFantasyTheme.borderSubtle)
            stanceColumn(
                title: "ENEMY",
                titleColor: DarkFantasyTheme.danger,
                attack: opponentAttack,
                defend: opponentDefend
            )
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func stanceColumn(
        title: String,
        titleColor: Color,
        attack: InteractiveBodyZone,
        defend: InteractiveBodyZone
    ) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text(title)
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(titleColor)
            HStack(spacing: LayoutConstants.spaceXS) {
                zonePill(label: "ATK", zone: attack)
                zonePill(label: "DEF", zone: defend)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func zonePill(label: String, zone: InteractiveBodyZone) -> some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(zone.rawValue.uppercased())
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Verdict Chip (RESOLVE screen header)
//
// A single bold pill that names the round's outcome. Unlike V1, there's
// no competing round-log card — the verdict IS the chip. Colors match
// `CombatVerdictFlash` so the radial screen flash and the chip agree.

struct CombatV2VerdictChip: View {
    let verdict: RoundVerdict

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(verdict.bannerText)
                .font(DarkFantasyTheme.section)
                .tracking(3)
                .foregroundStyle(color)
            Text(verdict.subtitle)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.spaceLG)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .stroke(color.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: color.opacity(0.35), radius: 12)
    }

    private var color: Color {
        switch verdict {
        case .outplayed: return DarkFantasyTheme.gold
        case .outread:   return DarkFantasyTheme.danger
        case .struck:    return DarkFantasyTheme.info
        case .held:      return DarkFantasyTheme.textSecondary
        }
    }
}

// MARK: - Result Row (per-side summary of what happened this round)
//
// Two identical rows side-by-side on RESOLVE: attacker name, zones,
// damage, and a tiny outcome tag (CRIT / BLOCK / DODGE / MISS).

struct CombatV2ResultRow: View {
    let side: DuelSide
    let attackZone: InteractiveBodyZone
    let defendZone: InteractiveBodyZone
    let damage: Int
    let outcome: ResultOutcome

    enum ResultOutcome: Equatable {
        case hit
        case crit
        case block
        case dodge
        case miss
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Text(sideLabel)
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(sideColor)
                .frame(width: 52, alignment: .leading)

            Text("\(attackZone.rawValue.uppercased()) → \(defendZone.rawValue.uppercased())")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer(minLength: LayoutConstants.space2XS)

            Text(resultLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(resultColor)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: damage)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.45))
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(sideColor)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
        }
    }

    private var sideLabel: String { side == .player ? "YOU" : "ENEMY" }

    private var sideColor: Color {
        side == .player ? DarkFantasyTheme.success : DarkFantasyTheme.danger
    }

    private var resultLabel: String {
        switch outcome {
        case .hit:   return "\(damage) DMG"
        case .crit:  return "\(damage) CRIT!"
        case .block: return "BLOCKED"
        case .dodge: return "DODGED"
        case .miss:  return "MISS"
        }
    }

    private var resultColor: Color {
        switch outcome {
        case .hit:   return DarkFantasyTheme.textPrimary
        case .crit:  return DarkFantasyTheme.gold
        case .block: return DarkFantasyTheme.info
        case .dodge: return DarkFantasyTheme.textTertiary
        case .miss:  return DarkFantasyTheme.textTertiary
        }
    }
}

// MARK: - RoundExchange → ResultOutcome helpers
//
// Derive the per-side outcome from the server-authoritative turn info so
// both RESOLVE rows agree with the damage popups and verdict flash.

extension CombatV2ResultRow.ResultOutcome {
    static func from(turn: InteractiveStrikeTurn?) -> CombatV2ResultRow.ResultOutcome {
        guard let turn else { return .miss }
        if turn.isDodge == true { return .dodge }
        if turn.isMiss == true  { return .miss }
        if turn.isCrit == true  { return .crit }
        if turn.damage <= 0     { return .block }
        return .hit
    }
}

// NOTE: Use `RoundVerdict.bannerText` / `.subtitle` for chip copy — those
// are already part of the model. The old `RoundExchange.Verdict.displayLabel`
// extension was removed: it referenced a nested type that doesn't exist
// (`RoundExchange.verdict` is typed `RoundVerdict`, not `.Verdict`).
