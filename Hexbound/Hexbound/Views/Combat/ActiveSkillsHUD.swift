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
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                }

                if isOnCooldown, let slot {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(Color.black.opacity(0.55))
                    Text("\(slot.cooldownRemaining)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
            }
            .frame(width: 56, height: 56)
            .opacity(canTap ? 1.0 : (isEmpty ? 0.5 : 0.85))
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
