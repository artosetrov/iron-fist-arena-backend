//
//  TalentDetailSheet.swift
//  Hexbound
//
//  Bottom sheet showing a passive node's details and the unlock CTA.
//  Style mirrors ItemDetailSheet patterns — CardStyles modal, gold CTA.
//

import SwiftUI

struct TalentDetailSheet: View {
    let node: PassiveNode
    let isUnlocked: Bool
    let isUnlockable: Bool
    let pointsAvailable: Int
    let isMutating: Bool
    let onUnlock: () -> Void
    let onClose: () -> Void

    private var canAfford: Bool { pointsAvailable >= node.cost }
    private var canUnlockNow: Bool { !isUnlocked && isUnlockable && canAfford }

    private var tierLabel: String {
        switch node.bonusType {
        case "ultimate": return "ULTIMATE"
        case "keystone": return "KEYSTONE"
        default:         return "TIER \(node.tier)"
        }
    }

    private var bonusText: String? {
        guard let stat = node.bonusStat, let value = node.bonusValue else { return nil }
        let sign = value >= 0 ? "+" : ""
        let formatted: String
        if value == floor(value) {
            formatted = "\(sign)\(Int(value))"
        } else {
            formatted = "\(sign)\(String(format: "%.1f", value))"
        }
        return "\(formatted) \(statDisplayName(stat))"
    }

    private func statDisplayName(_ key: String) -> String {
        switch key {
        case "maxHp":       return "Max HP"
        case "armor":       return "Armor"
        case "magicResist": return "Magic Resist"
        case "strength":    return "Strength"
        case "dexterity":   return "Dexterity"
        case "intelligence": return "Intelligence"
        case "vitality":    return "Vitality"
        case "critChance":  return "Crit Chance"
        case "critDamage":  return "Crit Damage"
        case "dodge":       return "Dodge"
        case "lifesteal":   return "Lifesteal"
        default:            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
            header

            if let bonus = bonusText {
                bonusRow(bonus)
            }

            Text(node.description)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(DarkFantasyTheme.borderSubtle)

            cta
        }
        .padding(LayoutConstants.spaceLG)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.modalRadius))
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            TalentNodeView(
                node: node,
                state: isUnlocked ? .unlocked : (isUnlockable ? .unlockable : .locked)
            )

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(tierLabel)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(2)
                Text(node.name)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
            }
            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.semibold)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(width: 14, height: 14)
                    .frame(width: LayoutConstants.touchMin, height: LayoutConstants.touchMin)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bonus row

    private func bonusRow(_ text: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text(text)
                .font(DarkFantasyTheme.uiLabel.bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - CTA

    @ViewBuilder
    private var cta: some View {
        if isUnlocked {
            unlockedPill
        } else if !isUnlockable {
            lockedPill
        } else {
            Button(action: onUnlock) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    if isMutating {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                    }
                    Text(canAfford ? "UNLOCK — \(node.cost) SP" : "NOT ENOUGH POINTS")
                        .font(DarkFantasyTheme.buttonLabel)
                        .tracking(1)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canAfford || isMutating)
            .opacity(canAfford ? 1 : 0.6)
        }
    }

    private var unlockedPill: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text("UNLOCKED")
                .font(DarkFantasyTheme.buttonLabel)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .stroke(DarkFantasyTheme.gold, lineWidth: 1)
        )
    }

    private var lockedPill: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text("LOCKED")
                .font(DarkFantasyTheme.buttonLabel)
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .fill(DarkFantasyTheme.bgDisabled)
        )
    }
}
