//
//  TalentsSummaryCard.swift
//  Hexbound
//
//  Top summary card on the TALENTS tab: skill-points counter + 4-slot active-skill
//  loadout grid. Replaces the older separate SP banner + ActiveSlotsBar pair.
//
//  Slot count is driven by `vm.maxActiveSlots`. When the player has 3 slots
//  unlocked, the 4th tile renders as a "premium" placeholder that prompts
//  to unlock with gems (Phase 4 backend).
//

import SwiftUI

struct TalentsSummaryCard: View {
    @Bindable var vm: PassiveTreeViewModel

    /// Cost in gems to unlock the 4th active slot. Mirrors backend balance constant.
    let premiumSlotGemCost: Int
    /// Called when the locked premium tile is tapped. Host presents confirm.
    let onTapPremiumSlot: () -> Void

    /// Max slots achievable (including premium). 4 today.
    private let maxSlotsEver: Int = 4

    var body: some View {
        VStack(spacing: 0) {
            spRow
            divider
            activeSkillsRow
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Skill points row

    private var spRow: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("SKILL POINTS")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(2)
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                    Text("\(vm.pointsAvailableAfterPending) available")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    if vm.hasPendingChanges {
                        Text("(−\(vm.pendingCost) pending)")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                }
            }
            Spacer()
            unlockedCountPill
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    private var unlockedCountPill: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text("\(vm.unlockedNodes.count)")
                .font(DarkFantasyTheme.uiLabel.bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
            Text("/\(vm.nodes.count)")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule().fill(DarkFantasyTheme.bgPrimary)
        )
        .overlay(
            Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderSubtle)
            .frame(height: 1)
            .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Active skills row

    private var activeSkillsRow: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("ACTIVE SKILLS")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(2)
                Text("·")
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("\(vm.activeSlots.count) / \(vm.maxActiveSlots) equipped")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(0..<maxSlotsEver, id: \.self) { index in
                    slotTile(index: index)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.bottom, LayoutConstants.space2XS)
    }

    // MARK: - Slot tile

    @ViewBuilder
    private func slotTile(index: Int) -> some View {
        let isPremium = index >= vm.maxActiveSlots
        if isPremium {
            premiumSlotTile(index: index)
        } else if let slot = vm.activeSlots.first(where: { $0.slotIndex == index }) {
            filledSlotTile(slot: slot, index: index)
        } else {
            emptySlotTile(index: index)
        }
    }

    // Empty slot — dashed border, "+" icon, slot number top-left.
    private func emptySlotTile(index: Int) -> some View {
        Button {
            vm.openActiveSkillPicker(focusedSlotIndex: index)
            HapticManager.light()
        } label: {
            slotChrome(borderStyle: .dashed, borderColor: DarkFantasyTheme.borderSubtle, fill: DarkFantasyTheme.bgPrimary) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.textDisabled)
                    .frame(width: 16, height: 16)
            }
            .overlay(alignment: .topLeading) { slotNumber(index: index, color: DarkFantasyTheme.textDisabled) }
        }
        .buttonStyle(.plain)
        .disabled(vm.isMutating)
    }

    // Filled slot — solid gold border, icon.
    private func filledSlotTile(slot: ActiveSlot, index: Int) -> some View {
        let symbol: String = {
            switch slot.kind {
            case .talent:     return slot.activeActionType?.sfSymbol ?? "sparkles"
            case .consumable: return "cross.vial.fill"
            }
        }()
        return Button {
            vm.openActiveSkillPicker(focusedSlotIndex: index)
            HapticManager.light()
        } label: {
            slotChrome(
                borderStyle: .solid,
                borderColor: DarkFantasyTheme.gold,
                fill: LinearGradient(
                    colors: [DarkFantasyTheme.gold.opacity(0.18), DarkFantasyTheme.gold.opacity(0.05)],
                    startPoint: .top, endPoint: .bottom
                )
            ) {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .frame(width: 20, height: 20)
            }
            .overlay(alignment: .leading) {
                // 3px gold left bar — matches item-card DNA.
                UnevenRoundedRectangle(
                    topLeadingRadius: LayoutConstants.radiusMD,
                    bottomLeadingRadius: LayoutConstants.radiusMD
                )
                .fill(DarkFantasyTheme.gold)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
            }
            .overlay(alignment: .topLeading) { slotNumber(index: index, color: DarkFantasyTheme.gold) }
        }
        .buttonStyle(.plain)
        .disabled(vm.isMutating)
    }

    // Premium locked slot — purple gem + cost.
    private func premiumSlotTile(index: Int) -> some View {
        Button {
            onTapPremiumSlot()
            HapticManager.light()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(
                        LinearGradient(
                            colors: [
                                premiumAccent.opacity(0.08),
                                premiumAccent.opacity(0.02)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .strokeBorder(premiumAccent.opacity(0.35), lineWidth: 1.5)

                VStack(spacing: LayoutConstants.spaceXS) {
                    // Diamond-shaped gem
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.83, green: 0.63, blue: 0.94),
                                         Color(red: 0.60, green: 0.36, blue: 0.78),
                                         Color(red: 0.35, green: 0.16, blue: 0.54)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(45))
                        .shadow(color: premiumAccent.opacity(0.5), radius: 6)
                    Text("\(premiumSlotGemCost)")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(premiumAccent)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .topLeading) { slotNumber(index: index, color: premiumAccent.opacity(0.8)) }
        }
        .buttonStyle(.plain)
        .disabled(vm.isMutating)
        .accessibilityLabel("Unlock 4th active slot for \(premiumSlotGemCost) gems")
    }

    /// Epic/purple premium accent — no token exists in DarkFantasyTheme for this,
    /// so we derive one that matches the design-system rarity epic color.
    private var premiumAccent: Color { Color(red: 0.71, green: 0.49, blue: 0.84) }

    // MARK: - Helpers

    private enum BorderStyle { case solid, dashed }

    private func slotChrome<Fill: ShapeStyle, Content: View>(
        borderStyle: BorderStyle,
        borderColor: Color,
        fill: Fill,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(fill)
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .strokeBorder(
                    borderColor,
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        dash: borderStyle == .dashed ? [4, 4] : []
                    )
                )
            content()
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func slotNumber(index: Int, color: Color) -> some View {
        Text(String(format: "%02d", index + 1))
            .font(DarkFantasyTheme.badge)
            .foregroundStyle(color)
            .padding(.leading, LayoutConstants.spaceXS)
            .padding(.top, LayoutConstants.spaceXS)
    }
}
