//
//  ActiveSkillPickerRow.swift
//  Hexbound
//
//  Interactive Combat v1 — Phase 4.C.
//  One row in the Active Skill Picker list. Three display modes:
//    1. `.talent`     — unlocked activatable node. CTA: Equip / Equipped.
//    2. `.consumable` owned  — health potion with count > 0. CTA: Equip / Equipped.
//    3. `.consumable` unowned — price shown + inline Buy CTA (ShopService.buyConsumable).
//
//  Callers (ActiveSkillPickerSheet) own the draft state; this view is
//  purely presentational + delegates via closures.
//

import SwiftUI

struct ActiveSkillPickerRow: View {
    enum Mode {
        case talent(node: PassiveNode)
        case consumable(meta: ConsumableMeta)
    }

    let mode: Mode
    let isEquipped: Bool
    /// Which draft slot (0..maxSlots-1) this row currently occupies, if any.
    let equippedSlotIndex: Int?
    /// Owned count (consumables only). `nil` for talents.
    let ownedCount: Int?
    /// Price in gold (consumables only). `nil` for talents.
    let priceGold: Int?
    /// Player's current gold — used to greyscale Buy when too poor.
    let playerGold: Int
    /// True while the Buy POST is in flight for this row.
    let isBuying: Bool
    /// False when the draft loadout has no room for this row's type.
    let hasRoom: Bool

    let onEquip: () -> Void
    let onUnequip: () -> Void
    /// Consumable-only. Nil for talents.
    let onBuy: (() async -> Void)?

    // MARK: - Derived

    private var title: String {
        switch mode {
        case .talent(let node):    return node.name
        case .consumable(let meta): return meta.name
        }
    }

    private var subtitle: String? {
        switch mode {
        case .talent(let node):
            if let action = node.activeActionType {
                let cd = node.activeCooldown ?? 0
                return "\(action.shortLabel) · \(cd)T CD"
            }
            return nil
        case .consumable(let meta):
            return meta.description
        }
    }

    private var iconSymbol: String {
        switch mode {
        case .talent(let node):
            return node.activeActionType?.sfSymbol ?? "sparkles"
        case .consumable:
            return "cross.vial.fill"
        }
    }

    private var iconTint: Color {
        switch mode {
        case .talent:
            return DarkFantasyTheme.gold
        case .consumable(let meta):
            return rarityColor(meta.rarity)
        }
    }

    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common":     return DarkFantasyTheme.rarityCommon
        case "uncommon":   return DarkFantasyTheme.rarityUncommon
        case "rare":       return DarkFantasyTheme.rarityRare
        case "epic":       return DarkFantasyTheme.rarityEpic
        case "legendary":  return DarkFantasyTheme.rarityLegendary
        default:           return DarkFantasyTheme.textSecondary
        }
    }

    private var isConsumableOwned: Bool {
        if case .consumable = mode {
            return (ownedCount ?? 0) > 0
        }
        return false
    }

    private var isConsumableUnowned: Bool {
        if case .consumable = mode {
            return (ownedCount ?? 0) == 0
        }
        return false
    }

    private var canAffordBuy: Bool {
        guard let price = priceGold else { return false }
        return playerGold >= price
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            iconBadge
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(title)
                        .font(DarkFantasyTheme.uiLabel.bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                    if let count = ownedCount, count > 0 {
                        countBadge(count)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(2)
                }
            }
            Spacer()
            cta
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(isEquipped ? DarkFantasyTheme.bgTertiary : DarkFantasyTheme.bgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(
                    isEquipped ? DarkFantasyTheme.gold.opacity(0.6) : DarkFantasyTheme.borderSubtle,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Icon badge

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
            Image(systemName: iconSymbol)
                .resizable()
                .scaledToFit()
                .foregroundStyle(iconTint)
                .padding(LayoutConstants.spaceXS)
        }
        .frame(width: 44, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(iconTint.opacity(0.4), lineWidth: 1)
        )
    }

    private func countBadge(_ count: Int) -> some View {
        Text("×\(count)")
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
    }

    // MARK: - CTA

    @ViewBuilder
    private var cta: some View {
        if isEquipped {
            equippedChip
        } else if isConsumableUnowned {
            buyButton
        } else if !hasRoom {
            slotFullChip
        } else {
            equipButton
        }
    }

    private var equippedChip: some View {
        Button {
            onUnequip()
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                Text(equippedSlotIndex.map { "SLOT \($0 + 1)" } ?? "EQUIPPED")
            }
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .tracking(1)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule().fill(DarkFantasyTheme.gold)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Equipped — tap to unequip")
    }

    private var equipButton: some View {
        Button {
            onEquip()
        } label: {
            Text("EQUIP")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(1)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule().fill(Color.clear)
                )
                .overlay(
                    Capsule().stroke(DarkFantasyTheme.gold.opacity(0.7), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var slotFullChip: some View {
        Text("SLOTS FULL")
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(DarkFantasyTheme.textDisabled)
            .tracking(1)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule().fill(Color.clear)
            )
            .overlay(
                Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .accessibilityLabel("Loadout full — unequip another skill first")
    }

    @ViewBuilder
    private var buyButton: some View {
        let price = priceGold ?? 0
        Button {
            guard let onBuy, canAffordBuy, !isBuying else { return }
            Task { await onBuy() }
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                if isBuying {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                        .scaleEffect(0.7)
                } else {
                    Text("BUY")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(canAffordBuy ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
                        .tracking(1)
                    Text("\(price)g")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(canAffordBuy ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule().fill(canAffordBuy ? DarkFantasyTheme.gold : DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Capsule().stroke(
                    canAffordBuy ? Color.clear : DarkFantasyTheme.borderSubtle,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canAffordBuy || isBuying || onBuy == nil)
        .accessibilityLabel(canAffordBuy ? "Buy for \(price) gold" : "Not enough gold")
    }
}
