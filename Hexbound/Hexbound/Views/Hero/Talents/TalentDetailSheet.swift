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
    let isPending: Bool
    let isUnlockable: Bool
    /// Points still available AFTER current pending allocation — what the user can still spend.
    let pointsAvailable: Int
    let isMutating: Bool
    /// Callbacks are rank-aware: `onStage` advances the staged target rank by
    /// one (locked→1 for single-rank, rank N→N+1 for ranked). `onUnstage`
    /// rolls back one rank step (or clears the key when returning to
    /// committed rank).
    let onStage: () -> Void
    let onUnstage: () -> Void
    let onClose: () -> Void

    // Interactive Combat v1 — Active Slot controls.
    // equippedSlotIndex == nil → node is not currently in any slot.
    let equippedSlotIndex: Int?
    let onEquip: () -> Void
    let onUnequip: () -> Void

    // Talents v2 — ranked metadata. Defaults let older call sites keep compiling
    // while the callers are being migrated.
    var currentRank: Int = 0
    var maxRank: Int = 1
    var pendingTargetRank: Int? = nil
    /// Cost to advance from the current EFFECTIVE rank to the next rank; nil
    /// when at max. Computed in the VM.
    var nextRankCost: Int? = nil

    private var isRanked: Bool { maxRank > 1 }
    private var effectiveRank: Int { max(currentRank, pendingTargetRank ?? 0) }
    private var canAdvance: Bool {
        guard effectiveRank < maxRank else { return false }
        guard let cost = nextRankCost else { return false }
        return pointsAvailable >= cost
    }
    private var canRollback: Bool {
        (pendingTargetRank ?? 0) > currentRank
    }

    /// Fallback for legacy copy: "STAGE — N SP" for single-rank unlockable.
    private var stageSingleCost: Int { node.rankCostSchedule.first ?? node.cost }
    private var canAfford: Bool { pointsAvailable >= stageSingleCost }

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

            if isRanked {
                rankLadder
            }

            Divider()
                .background(DarkFantasyTheme.borderSubtle)

            cta

            if isUnlocked, node.isActivatable == true {
                activeSlotCTA
            }
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
                state: isUnlocked
                    ? .unlocked
                    : (isPending ? .pending : (isUnlockable ? .unlockable : .locked)),
                currentRank: currentRank,
                stagedRank: pendingTargetRank ?? 0
            )
            .padding(.top, node.maxRankResolved > 1 ? 10 : 0)

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
        if isRanked {
            rankedCTA
        } else {
            flatCTA
        }
    }

    /// Legacy single-rank CTA (keystones, ultimates, and any v1 non-ranked
    /// nodes). Shows STAGE / UNSTAGE / UNLOCKED / LOCKED exactly like before.
    @ViewBuilder
    private var flatCTA: some View {
        if isUnlocked {
            unlockedPill
        } else if isPending {
            unstageButton
        } else if !isUnlockable {
            lockedPill
        } else {
            Button(action: onStage) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    if isMutating {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                    }
                    Text(canAfford ? "STAGE — \(stageSingleCost) SP" : "NOT ENOUGH POINTS")
                        .font(DarkFantasyTheme.buttonLabel)
                        .tracking(1)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canAfford || isMutating)
            .opacity(canAfford ? 1 : 0.6)
        }
    }

    /// Ranked CTA (Talents v2). Shows a progression-aware control:
    ///   - locked (effectiveRank == 0, not unlockable) → LOCKED pill
    ///   - can unlock/advance → primary "UNLOCK — N SP" / "RANK UP — N SP"
    ///   - at max rank → MAX RANK pill
    ///   - with a staged rank above committed → additional rollback row
    @ViewBuilder
    private var rankedCTA: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if effectiveRank == 0 && !isUnlockable {
                lockedPill
            } else if effectiveRank >= maxRank {
                maxRankPill
            } else {
                advanceButton
            }

            if canRollback {
                rollbackButton
            }
        }
    }

    /// Primary rank-advance button. Copy depends on whether the next step is
    /// the first-time unlock or a rank-up of an already-unlocked node.
    private var advanceButton: some View {
        let cost = nextRankCost ?? stageSingleCost
        let isFirstUnlock = currentRank == 0 && (pendingTargetRank ?? 0) == 0
        let label: String = {
            if pointsAvailable < cost { return "NOT ENOUGH POINTS" }
            if isFirstUnlock { return "UNLOCK — \(cost) SP" }
            if pendingTargetRank != nil && (pendingTargetRank ?? 0) < maxRank {
                // Additional stack on top of what's already staged — keep the CTA sharp.
                return "STAGE RANK \(effectiveRank + 1) — \(cost) SP"
            }
            return "RANK UP — \(cost) SP"
        }()

        return Button(action: onStage) {
            HStack(spacing: LayoutConstants.spaceSM) {
                if isMutating {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                }
                Text(label)
                    .font(DarkFantasyTheme.buttonLabel)
                    .tracking(1)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!canAdvance || isMutating)
        .opacity(canAdvance ? 1 : 0.6)
    }

    /// Rollback a single staged rank step (→ committed floor).
    private var rollbackButton: some View {
        Button(action: onUnstage) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("UNSTAGE RANK \(pendingTargetRank ?? effectiveRank)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(
                        DarkFantasyTheme.gold.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isMutating)
    }

    // MARK: - Rank ladder (Talents v2)

    /// Per-rank cost ladder: "1 SP → 2 SP → 3 SP" with the current committed
    /// rank filled gold, pending ranks dashed, remainder muted.
    private var rankLadder: some View {
        let costs = node.rankCostSchedule
        return HStack(spacing: 0) {
            ForEach(costs.indices, id: \.self) { i in
                rankLadderStep(index: i, cost: costs[i])
                if i < costs.count - 1 {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    /// One step on the rank ladder. States mirror the pip strip on the tile.
    @ViewBuilder
    private func rankLadderStep(index i: Int, cost: Int) -> some View {
        let isCommitted = i < currentRank
        let isStaged = i >= currentRank && i < (pendingTargetRank ?? 0)
        let isNext = i == effectiveRank && effectiveRank < maxRank
        let color: Color = {
            if isCommitted { return DarkFantasyTheme.gold }
            if isStaged    { return DarkFantasyTheme.goldBright }
            if isNext      { return DarkFantasyTheme.goldDim }
            return DarkFantasyTheme.textDisabled
        }()

        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isCommitted ? DarkFantasyTheme.gold : Color.clear)
                Circle()
                    .strokeBorder(
                        color,
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            dash: isStaged ? [2, 2] : []
                        )
                    )
                Text("\(i + 1)")
                    .font(DarkFantasyTheme.badge)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        isCommitted ? DarkFantasyTheme.textOnGold : color
                    )
            }
            .frame(width: 22, height: 22)

            Text("\(cost) SP")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(
                    isCommitted || isStaged
                        ? DarkFantasyTheme.textPrimary
                        : DarkFantasyTheme.textSecondary
                )
        }
    }

    /// "MAX RANK" decoration — shown when both committed and staged reach the
    /// ceiling so the player sees why there's no more rank-up button.
    private var maxRankPill: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "crown.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text("MAX RANK")
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

    private var unstageButton: some View {
        Button(action: onUnstage) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "minus.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("UNSTAGE — REFUND \(stageSingleCost) SP")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
        .disabled(isMutating)
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

    // MARK: - Active slot CTA

    @ViewBuilder
    private var activeSlotCTA: some View {
        if let slotIndex = equippedSlotIndex {
            Button(action: onUnequip) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "xmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                    Text("UNEQUIP (SLOT \(slotIndex + 1))")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(2)
                }
                .foregroundStyle(DarkFantasyTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutConstants.spaceMS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .stroke(DarkFantasyTheme.danger.opacity(0.5), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMutating)
        } else {
            Button(action: onEquip) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                    Text("EQUIP AS ACTIVE")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(2)
                }
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LayoutConstants.spaceMS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isMutating)
        }
    }

    private var lockedPill: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image("icon-padlock")
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
