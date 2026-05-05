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
        // Compressed ~30pt vs. original to free vertical space for the
        // 460pt talent canvas (so HERO header + tabs + summary + canvas +
        // reset all fit one iPhone screen). Padding ratchets:
        // outer spaceMS→spaceSM, divider/spRow vertical pads removed, slots
        // capped at compact height.
        VStack(spacing: 0) {
            spRow
            divider
            activeSkillsRow
        }
        .padding(LayoutConstants.spaceSM)
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
            .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Active skills row

    private var activeSkillsRow: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
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
    //
    // Combat v3.1 unification (2026-05-03): all 3 slot variants
    // (empty / filled / premium-locked) now flow through the shared
    // `ActiveSlotTile` primitive in `Views/Components/`. Talents and
    // combat use the same chrome — same border, same number style,
    // same gold left bar, same premium gem treatment. The old inline
    // `emptySlotTile`, `filledSlotTile`, `premiumSlotTile`,
    // `slotChrome`, `slotNumber`, and `premiumAccent` helpers were
    // collapsed into this adapter.

    @ViewBuilder
    private func slotTile(index: Int) -> some View {
        let isPremium = index >= vm.maxActiveSlots
        if isPremium {
            ActiveSlotTile(
                slotNumber: index,
                state: .premium(gemCost: premiumSlotGemCost),
                isDisabled: vm.isMutating,
                action: {
                    onTapPremiumSlot()
                    HapticManager.light()
                }
            )
            .accessibilityLabel("Unlock 4th active slot for \(premiumSlotGemCost) gems")
        } else if let slot = vm.activeSlots.first(where: { $0.slotIndex == index }) {
            ActiveSlotTile(
                slotNumber: index,
                state: .filled(iconKind(for: slot)),
                isDisabled: vm.isMutating,
                action: {
                    vm.openActiveSkillPicker(focusedSlotIndex: index)
                    HapticManager.light()
                }
            )
        } else {
            ActiveSlotTile(
                slotNumber: index,
                state: .empty,
                isDisabled: vm.isMutating,
                action: {
                    vm.openActiveSkillPicker(focusedSlotIndex: index)
                    HapticManager.light()
                }
            )
        }
    }

    /// Adapter: project the talents-page `ActiveSlot` model onto the
    /// shared tile's `ActiveSlotTileIcon`. Consumables prefer the
    /// catalog asset by `consumable_type` key (e.g. `health_potion_medium`)
    /// and fall back to the `cross.vial.fill` SF Symbol when no asset
    /// is bundled. Talent slots use the action-type SF Symbol.
    private func iconKind(for slot: ActiveSlot) -> ActiveSlotTileIcon {
        switch slot.kind {
        case .consumable:
            if let key = slot.consumableType, UIImage(named: key) != nil {
                return .asset(key)
            }
            return .sfSymbol("cross.vial.fill")
        case .talent:
            return .sfSymbol(slot.activeActionType?.sfSymbol ?? "sparkles")
        }
    }
}
