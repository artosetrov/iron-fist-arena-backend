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

    private var strokeColor: Color {
        if isArmed { return DarkFantasyTheme.gold }
        if isReady { return DarkFantasyTheme.gold.opacity(0.5) }
        return DarkFantasyTheme.borderSubtle
    }

    private var iconColor: Color {
        if isEmpty { return DarkFantasyTheme.textDisabled }
        if isOnCooldown { return DarkFantasyTheme.textDisabled }
        return DarkFantasyTheme.gold
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgElevated)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(strokeColor, lineWidth: isArmed ? 2 : 1)

                if let slot, let action = slot.talentAction {
                    Image(systemName: action.sfSymbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                } else {
                    // Empty slot — padlock asset (interactive combat v3).
                    // Falls back to SF Symbol if the bundle asset hasn't
                    // resolved yet so the slot never renders blank.
                    CachedAssetImage(
                        key: "icon-padlock",
                        url: nil,
                        systemIcon: "lock.fill",
                        contentMode: .fit
                    )
                    .frame(width: 22, height: 22)
                    .foregroundStyle(DarkFantasyTheme.textDisabled)
                    .opacity(0.6)
                }

                if isOnCooldown, let slot {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(Color.black.opacity(0.55))
                    Text("\(slot.cooldownRemaining)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .contentTransition(.numericText(countsDown: true))
                        .id("cd-\(slotIndex)-\(slot.cooldownRemaining)")
                }
            }
            .frame(width: 56, height: 56)
            .opacity(canTap ? 1.0 : (isEmpty ? 0.5 : 0.85))
            // Phase 4 polish — animate cooldown tick and "ready" flash.
            // When cooldownRemaining decrements (server → client), the digit
            // rolls via contentTransition; when it hits 0 the dark overlay
            // fades out and the stroke pulses gold once.
            .animation(.easeOut(duration: 0.25),
                       value: slot?.cooldownRemaining)
            .animation(.easeOut(duration: 0.3),
                       value: isReady)
            .onChange(of: isReady) { _, newValue in
                guard newValue, !isEmpty else { return }
                readyFlash = true
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    await MainActor.run { readyFlash = false }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(DarkFantasyTheme.gold, lineWidth: readyFlash ? 2 : 0)
                    .opacity(readyFlash ? 0.85 : 0)
                    .animation(.easeOut(duration: 0.5), value: readyFlash)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canTap)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: String {
        guard let slot else { return "Empty active slot \(slotIndex + 1)" }
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
        case .burstDamage: return .init(label: "BURST",   icon: "bolt.fill",             color: DarkFantasyTheme.danger)
        case .healSelf:    return .init(label: "HEAL",    icon: "cross.case.fill",       color: DarkFantasyTheme.success)
        case .shieldSelf:  return .init(label: "SHIELD",  icon: "shield.lefthalf.filled", color: DarkFantasyTheme.info)
        case .stunEnemy:   return .init(label: "STUN",    icon: "bolt.slash.fill",       color: DarkFantasyTheme.gold)
        case .execute:     return .init(label: "EXECUTE", icon: "scope",                 color: DarkFantasyTheme.danger)
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
