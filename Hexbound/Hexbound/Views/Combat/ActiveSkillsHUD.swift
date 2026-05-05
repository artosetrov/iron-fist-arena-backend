//
//  ActiveSkillsHUD.swift
//  Hexbound
//
//  Interactive Combat v1 — Phase 3. Row of 3 active-skill buttons for the
//  player. Tap a ready slot to arm it for the next /strike; tap again to
//  cancel. Locked (cooldown > 0) slots show remaining rounds. Empty slots
//  render as a dimmed placeholder. Designed to sit just above the zone
//  selector in InteractiveBattleView.
//

import SwiftUI

struct ActiveSkillsHUD: View {
    let actives: [InteractiveActiveSlotSnapshot]
    let pendingSlot: Int?
    let isInteractive: Bool
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            ForEach(0..<3, id: \.self) { idx in
                let slot = actives.first(where: { $0.slotIndex == idx })
                ActiveSkillSlotButton(
                    slotIndex: idx,
                    slot: slot,
                    isArmed: pendingSlot == idx,
                    isInteractive: isInteractive,
                    onTap: { onTap(idx) }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// Combat HUD slot — adapter on top of the shared `ActiveSlotTile`
/// primitive (Views/Components/ActiveSlotTile.swift). Maps the
/// server's `InteractiveActiveSlotSnapshot` model into the tile's
/// state enum and layers combat-only overlays (cooldown countdown,
/// armed border, "USED" stamp, ready-flash pulse) on top via the
/// tile's `overlay` ViewBuilder.
///
/// Combat v3.1 unification (2026-05-03): chrome (frame, border, fill,
/// number, gold left bar) is no longer drawn here — it comes from
/// `ActiveSlotTile`. Only behavior + transient combat state lives in
/// this adapter.
private struct ActiveSkillSlotButton: View {
    let slotIndex: Int
    let slot: InteractiveActiveSlotSnapshot?
    let isArmed: Bool
    let isInteractive: Bool
    let onTap: () -> Void

    @State private var readyFlash = false

    private var isEmpty: Bool { slot == nil }
    private var isOnCooldown: Bool { (slot?.cooldownRemaining ?? 0) > 0 }
    private var isReady: Bool { slot?.isReady == true }
    private var canTap: Bool { isInteractive && isReady }
    private var isConsumable: Bool { slot?.isConsumable == true }
    private var isConsumed: Bool { slot?.consumed == true }

    /// Map server snapshot to shared tile state. Empty / consumed
    /// snapshots show as `.locked` (padlock) — combat doesn't allow
    /// equipping mid-fight, so the inviting "+" affordance from the
    /// talents-page `.empty` state would mislead.
    private var tileState: ActiveSlotTileState {
        if let slot, let action = slot.talentAction {
            return .filled(.sfSymbol(action.sfSymbol))
        }
        if let slot, slot.isConsumable {
            return .filled(.sfSymbol("cross.vial.fill"))
        }
        return .locked
    }

    var body: some View {
        ActiveSlotTile(
            slotNumber: slotIndex,
            state: tileState,
            isDisabled: !canTap,
            action: onTap
        ) {
            combatOverlay
        }
        .frame(width: 56, height: 56)
        .opacity(canTap ? 1.0 : (isEmpty ? 0.5 : 0.85))
        .animation(.easeOut(duration: 0.25), value: slot?.cooldownRemaining)
        .animation(.easeOut(duration: 0.3),  value: isReady)
        .onChange(of: isReady) { _, newValue in
            guard newValue, !isEmpty else { return }
            readyFlash = true
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                await MainActor.run { readyFlash = false }
            }
        }
        .accessibilityLabel(Text(accessibilityLabel))
    }

    /// Combat-only transient overlays — cooldown dim + countdown,
    /// "USED" stamp on consumed consumables, armed gold border on
    /// the slot the player has queued for the next strike, and the
    /// one-shot ready-flash pulse when the cooldown expires.
    @ViewBuilder
    private var combatOverlay: some View {
        if isOnCooldown, let slot {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
            Text("\(slot.cooldownRemaining)")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .contentTransition(.numericText(countsDown: true))
                .id("cd-\(slotIndex)-\(slot.cooldownRemaining)")
        } else if isConsumable && isConsumed {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
            Text("USED")
                .font(DarkFantasyTheme.badge)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        // Armed border — gold 2pt stroke when the player has queued
        // this slot for the next strike. Layered on top of the tile's
        // base border so the underlying chrome stays consistent.
        if isArmed {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                .allowsHitTesting(false)
        }
        // One-shot ready-flash pulse on cooldown → 0.
        if readyFlash {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                .opacity(0.85)
                .allowsHitTesting(false)
        }
    }

    private var accessibilityLabel: String {
        guard let slot else { return "Empty active slot \(slotIndex + 1)" }
        if isConsumable && isConsumed { return "\(slot.name), used this battle" }
        if isOnCooldown { return "\(slot.name), cooldown \(slot.cooldownRemaining) rounds" }
        if isArmed { return "\(slot.name), armed" }
        return "\(slot.name), ready"
    }
}

// MARK: - Opponent actives preview (read-only)

struct OpponentActivesPreview: View {
    let actives: [InteractiveActiveSlotSnapshot]

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<3, id: \.self) { idx in
                let slot = actives.first(where: { $0.slotIndex == idx })
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.bgElevated)
                    Circle()
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    if let action = slot?.talentAction {
                        Image(systemName: action.sfSymbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                (slot?.cooldownRemaining ?? 0) > 0
                                    ? DarkFantasyTheme.textDisabled
                                    : DarkFantasyTheme.danger.opacity(0.85)
                            )
                    }
                }
                .frame(width: 22, height: 22)
                .opacity(slot == nil ? 0.3 : 1.0)
            }
        }
        .accessibilityLabel(Text("Opponent active skills"))
    }
}

// MARK: - Floating-text banner (Phase 3.B + Phase 4 polish)

/// Per-action display metadata — single source of truth for label, SF Symbol,
/// and accent color. Also used by the VM to dispatch the matching SFX.
struct ActiveFireStyle {
    let label: String
    let icon: String
    let color: Color

    static func forAction(_ action: TalentSlotAction) -> ActiveFireStyle {
        switch action {
        case .burstDamage:   return .init(label: "STRIKE",    icon: "bolt.fill",                color: DarkFantasyTheme.danger)
        case .healSelf:      return .init(label: "RECOVERY",  icon: "cross.case.fill",          color: DarkFantasyTheme.success)
        case .shieldSelf:    return .init(label: "GUARD",     icon: "shield.lefthalf.filled",   color: DarkFantasyTheme.info)
        case .stunEnemy:     return .init(label: "CONTROL",   icon: "bolt.slash.fill",          color: DarkFantasyTheme.gold)
        case .execute:       return .init(label: "FINISHER",  icon: "scope",                    color: DarkFantasyTheme.danger)
        // Talents v2 ultimates (2026-04-29)
        case .stealth:       return .init(label: "VANISH",    icon: "eye.slash.fill",           color: DarkFantasyTheme.gold)
        case .aoeDamage:     return .init(label: "CATACLYSM", icon: "flame.fill",               color: DarkFantasyTheme.danger)
        case .cooldownReset: return .init(label: "REWIND",    icon: "clock.arrow.circlepath",   color: DarkFantasyTheme.info)
        case .aoeStun:       return .init(label: "QUAKE",     icon: "bolt.horizontal.fill",     color: DarkFantasyTheme.gold)
        }
    }
}

/// Transient banner shown when a player or opponent fires an active. Pass the
/// `actionType` raw string from the /strike response — the view maps it to a
/// display label and accent color. Caller controls visibility lifetime by
/// nilling out its binding source ~1.5s after the strike reveal.
struct ActiveFireBanner: View {
    let actionType: String?
    let isOpponent: Bool

    @State private var glowPulse: CGFloat = 0.0

    private var style: ActiveFireStyle? {
        guard let raw = actionType, let action = TalentSlotAction(rawValue: raw) else {
            return nil
        }
        var s = ActiveFireStyle.forAction(action)
        // Opponent-fired actives always tint red regardless of base action color
        // so the player instantly recognizes "they did something bad to me".
        if isOpponent {
            s = ActiveFireStyle(label: s.label, icon: s.icon, color: DarkFantasyTheme.danger)
        }
        return s
    }

    var body: some View {
        if let s = style {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: s.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(s.label + "!")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
            }
            .foregroundStyle(s.color)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgElevated.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(s.color.opacity(0.7), lineWidth: 1)
            )
            .background(
                // Pulsing radial glow that fades in + fades out once per fire.
                // Opacity-only animation — no scale — honors the project-wide
                // "no scale animations" rule.
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(s.color.opacity(glowPulse))
                    .blur(radius: 12)
                    .allowsHitTesting(false)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onAppear {
                glowPulse = 0.55
                withAnimation(.easeOut(duration: 0.6)) {
                    glowPulse = 0.0
                }
            }
        }
    }
}

// MARK: - Consumable Fire Banner (Phase 4.C)

/// Transient banner shown when a player fires a consumable (health potion).
/// Visually distinct from `ActiveFireBanner` — green success tint + potion icon —
/// so players register "I drank a potion" separately from "I fired a talent".
/// Caller nils the `consumableType` binding after ~1.5s to dismiss.
struct ConsumableFireBanner: View {
    let consumableType: String?
    let isOpponent: Bool

    @State private var glowPulse: CGFloat = 0.0

    /// Human-readable label derived from the server's `consumable_type`. We
    /// intentionally avoid pulling the full `ConsumableMeta` registry here —
    /// the banner is a momentary cue, not a catalog row.
    private var label: String {
        guard let raw = consumableType else { return "POTION" }
        switch raw {
        case "health_potion_small":  return "SMALL POTION"
        case "health_potion_medium": return "MEDIUM POTION"
        case "health_potion_large":  return "LARGE POTION"
        default:
            // Fallback: humanize the snake_case key ("foo_bar" -> "FOO BAR").
            return raw.replacingOccurrences(of: "_", with: " ").uppercased()
        }
    }

    private var tint: Color {
        // Opponent potions (reserved for Phase 5+) should read as a threat,
        // so tint red in that case; player potions are a positive moment.
        isOpponent ? DarkFantasyTheme.danger : DarkFantasyTheme.success
    }

    var body: some View {
        if consumableType != nil {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(label + "!")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgElevated.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(tint.opacity(0.7), lineWidth: 1)
            )
            .background(
                // Mirrors ActiveFireBanner — opacity-only pulsing glow.
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(tint.opacity(glowPulse))
                    .blur(radius: 12)
                    .allowsHitTesting(false)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
            .onAppear {
                glowPulse = 0.55
                withAnimation(.easeOut(duration: 0.6)) {
                    glowPulse = 0.0
                }
            }
        }
    }
}
