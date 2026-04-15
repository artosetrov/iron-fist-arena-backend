//
//  ActiveSlotsBar.swift
//  Hexbound
//
//  Interactive Combat v1 — Phase 1.6.
//  Horizontal row of 3 active-skill slots shown above the talent tree canvas.
//  Empty slots prompt the player to unlock & equip an activatable talent.
//  Tapping a filled slot clears it.
//

import SwiftUI

struct ActiveSlotsBar: View {
    @Bindable var vm: PassiveTreeViewModel

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            header
            Spacer(minLength: LayoutConstants.spaceSM)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(0..<vm.maxActiveSlots, id: \.self) { index in
                    slotView(for: index)
                }
            }
            editButton
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text("ACTIVE SKILLS")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .tracking(2)
            Text("\(vm.activeSlots.count)/\(vm.maxActiveSlots) equipped")
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
    }

    // MARK: - Slot

    @ViewBuilder
    private func slotView(for index: Int) -> some View {
        let slot = vm.activeSlots.first(where: { $0.slotIndex == index })
        Button {
            // Tap ALWAYS opens the picker (Phase 4.C). Clearing moved to the
            // picker sheet itself — single point of truth for loadout edits.
            vm.openActiveSkillPicker(focusedSlotIndex: index)
            HapticManager.light()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(slot != nil
                          ? DarkFantasyTheme.bgTertiary
                          : DarkFantasyTheme.bgPrimary)

                if let slot {
                    filledSlot(slot)
                } else {
                    emptySlot
                }
            }
            .frame(width: 52, height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(slot != nil
                            ? DarkFantasyTheme.gold.opacity(0.6)
                            : DarkFantasyTheme.borderSubtle,
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.isMutating)
    }

    private func filledSlot(_ slot: ActiveSlot) -> some View {
        let sfSymbol: String = {
            switch slot.kind {
            case .talent:     return slot.activeActionType?.sfSymbol ?? "sparkles"
            case .consumable: return "cross.vial.fill"
            }
        }()
        return Image(systemName: sfSymbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(DarkFantasyTheme.gold)
            .padding(LayoutConstants.spaceSM)
    }

    /// Explicit "Edit" affordance — the single entry point for the picker.
    /// Also helps discoverability when all 3 slots are already filled.
    private var editButton: some View {
        Button {
            vm.openActiveSkillPicker(focusedSlotIndex: nil)
            HapticManager.light()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                .padding(LayoutConstants.spaceSM)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(vm.isMutating)
        .accessibilityLabel("Edit active skills loadout")
    }

    private var emptySlot: some View {
        Image(systemName: "plus")
            .resizable()
            .scaledToFit()
            .foregroundStyle(DarkFantasyTheme.textDisabled)
            .padding(LayoutConstants.spaceMD)
    }
}
