//
//  ActiveSkillPickerSheet.swift
//  Hexbound
//
//  Interactive Combat v1 — Phase 4.C.
//  Bottom sheet that lets the player assemble a 3-slot Active Skill loadout
//  (talents + a single health potion) and commit it atomically via
//  POST /api/passives/active-slots/batch.
//
//  Flow:
//    - Opened from TalentsSummaryCard (empty slot "+" tap) via
//      PassiveTreeViewModel.openActiveSkillPicker(focusedSlotIndex:).
//    - Header strip shows the draft 3-slot loadout. Tap a slot to focus it
//      for replacement; tap the focused slot again to clear it.
//    - TALENTS tab lists unlocked activatable talents.
//    - POTIONS tab lists allowed health potions with owned count and
//      inline Buy via ShopService.buyConsumable().
//    - Constraint: max 1 consumable per loadout (server enforces; client mirrors).
//    - SAVE commits via vm.commitLoadout(_:), RESET discards edits.
//

import SwiftUI

struct ActiveSkillPickerSheet: View {
    @Bindable var vm: PassiveTreeViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// Draft copy of `vm.activeSlots` — edited locally, committed on SAVE.
    @State private var draftSlots: [ActiveSlot] = []
    /// 0 = TALENTS, 1 = POTIONS
    @State private var selectedTab: Int = 0
    /// Current slot target for insertion/replacement inside the picker.
    @State private var focusedSlotIndex: Int? = nil
    /// In-flight buy state per consumable_type — disables the row during the POST.
    @State private var buyingType: String? = nil
    /// In-flight save state.
    @State private var isSaving: Bool = false

    private let tabs = ["TALENTS", "POTIONS"]

    /// Shop service for inline consumable buys.
    private var shopService: ShopService { ShopService(appState: appState) }

    // MARK: - Derived

    private var hasChanges: Bool {
        // Compare draft vs committed by (slotIndex, nodeId/consumableType, kind).
        let draftKey = draftSlots.map(slotKey).sorted()
        let currentKey = vm.activeSlots.map(slotKey).sorted()
        return draftKey != currentKey
    }

    private func slotKey(_ s: ActiveSlot) -> String {
        switch s.kind {
        case .talent:     return "\(s.slotIndex):t:\(s.nodeId ?? "")"
        case .consumable: return "\(s.slotIndex):c:\(s.consumableType ?? "")"
        }
    }

    /// Unlocked + activatable talents — the picker list source for TALENTS tab.
    private var equippableTalents: [PassiveNode] {
        vm.nodes.filter { node in
            vm.unlockedIds.contains(node.id) && node.isActivatable == true
        }
        .sorted { ($0.tier, $0.name) < ($1.tier, $1.name) }
    }

    private var consumableInDraft: ActiveSlot? {
        draftSlots.first(where: { $0.kind == .consumable })
    }

    private func draftTalentSlot(for nodeId: String) -> ActiveSlot? {
        draftSlots.first(where: { $0.kind == .talent && $0.nodeId == nodeId })
    }

    private func draftConsumableSlot(for type: String) -> ActiveSlot? {
        draftSlots.first(where: { $0.kind == .consumable && $0.consumableType == type })
    }

    private var hasFocusedSlot: Bool { focusedSlotIndex != nil }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            previewStrip
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceSM)
                .padding(.bottom, LayoutConstants.spaceMD)

            TabSwitcher(tabs: tabs, selectedIndex: $selectedTab)
                .padding(.horizontal, LayoutConstants.spaceMD)

            Group {
                if selectedTab == 0 {
                    talentsList
                } else {
                    potionsList
                }
            }
            .frame(maxHeight: .infinity)

            footer
        }
        .background(DarkFantasyTheme.bgSecondary.ignoresSafeArea())
        .onAppear {
            draftSlots = vm.activeSlots
            focusedSlotIndex = initialFocusedSlotIndex()
        }
        .onDisappear {
            vm.pickerFocusedSlotIndex = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("ACTIVE SKILLS")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(2)
                Text("Equip up to \(vm.maxActiveSlots) — 1 may be a potion")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                    .padding(LayoutConstants.spaceSM)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Preview strip (3-slot draft)

    private var previewStrip: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(0..<vm.maxActiveSlots, id: \.self) { index in
                    previewTile(for: index)
                }
            }

            if draftSlots.count >= vm.maxActiveSlots && !hasFocusedSlot {
                Text("Loadout full — tap a slot above to choose what to replace.")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func previewTile(for index: Int) -> some View {
        let slot = draftSlots.first(where: { $0.slotIndex == index })
        let isFocused = focusedSlotIndex == index
        Button {
            if slot == nil {
                focusedSlotIndex = index
                HapticManager.light()
                return
            }

            if isFocused {
                draftSlots.removeAll { $0.slotIndex == index }
            } else {
                focusedSlotIndex = index
            }
            HapticManager.light()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill((slot != nil || isFocused) ? DarkFantasyTheme.bgTertiary : DarkFantasyTheme.bgPrimary)

                if let slot {
                    VStack(spacing: LayoutConstants.space2XS) {
                        Image(systemName: previewSymbol(for: slot))
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .frame(height: LayoutConstants.iconMD)
                        Text(slot.name)
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(LayoutConstants.spaceSM)
                } else {
                    VStack(spacing: LayoutConstants.space2XS) {
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(DarkFantasyTheme.textDisabled)
                            .frame(height: LayoutConstants.iconSM)
                        Text("Slot \(index + 1)")
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(DarkFantasyTheme.textDisabled)
                            .tracking(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(
                        isFocused
                            ? DarkFantasyTheme.gold
                            : (slot != nil
                                ? DarkFantasyTheme.gold.opacity(0.6)
                                : DarkFantasyTheme.borderSubtle),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func previewSymbol(for slot: ActiveSlot) -> String {
        switch slot.kind {
        case .talent:
            return slot.activeActionType?.sfSymbol ?? "sparkles"
        case .consumable:
            return "cross.vial.fill"
        }
    }

    // MARK: - Talents list

    @ViewBuilder
    private var talentsList: some View {
        if equippableTalents.isEmpty {
            emptyTalents
        } else {
            ScrollView {
                LazyVStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(equippableTalents, id: \.id) { node in
                        ActiveSkillPickerRow(
                            mode: .talent(node: node),
                            isEquipped: draftTalentSlot(for: node.id) != nil,
                            equippedSlotIndex: draftTalentSlot(for: node.id)?.slotIndex,
                            ownedCount: nil,
                            priceGold: nil,
                            playerGold: appState.currentCharacter?.gold ?? 0,
                            isBuying: false,
                            hasRoom: hasRoomForTalent(),
                            onEquip: { equipTalent(node) },
                            onUnequip: { unequipTalent(node) },
                            onBuy: nil
                        )
                    }
                }
                .padding(LayoutConstants.spaceMD)
            }
        }
    }

    private var emptyTalents: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text("No active talents unlocked")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Text("Unlock an activatable node in the tree below to equip it here.")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceLG)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LayoutConstants.spaceLG)
    }

    // MARK: - Potions list

    @ViewBuilder
    private var potionsList: some View {
        if vm.consumablesMeta.isEmpty {
            emptyPotions
        } else {
            ScrollView {
                VStack(spacing: LayoutConstants.spaceSM) {
                    goldChip
                        .padding(.top, LayoutConstants.spaceSM)

                    LazyVStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(vm.consumablesMeta) { meta in
                            ActiveSkillPickerRow(
                                mode: .consumable(meta: meta),
                                isEquipped: draftConsumableSlot(for: meta.consumableType) != nil,
                                equippedSlotIndex: draftConsumableSlot(for: meta.consumableType)?.slotIndex,
                                ownedCount: meta.ownedCount,
                                priceGold: meta.priceGold,
                                playerGold: appState.currentCharacter?.gold ?? 0,
                                isBuying: buyingType == meta.consumableType,
                                hasRoom: hasRoomForConsumable(meta.consumableType),
                                onEquip: { equipConsumable(meta) },
                                onUnequip: { unequipConsumable(meta) },
                                onBuy: { await buyConsumable(meta) }
                            )
                        }
                    }
                }
                .padding(LayoutConstants.spaceMD)
            }
        }
    }

    private var goldChip: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            CurrencyDisplay(
                gold: appState.currentCharacter?.gold ?? 0,
                size: .mini,
                currencyType: .gold,
                animated: false
            )
            Spacer()
            if consumableInDraft != nil {
                Text("1 potion equipped")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.gold)
            } else {
                Text("Max 1 potion per loadout")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var emptyPotions: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "cross.vial")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text("No potions available")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LayoutConstants.spaceLG)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, DarkFantasyTheme.bgSecondary.opacity(0.95)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: LayoutConstants.iconSM)

            HStack(spacing: LayoutConstants.spaceSM) {
                Button("RESET") {
                    draftSlots = vm.activeSlots
                    focusedSlotIndex = initialFocusedSlotIndex()
                    HapticManager.light()
                }
                .buttonStyle(.ghost)
                .frame(maxWidth: .infinity)
                .disabled(!hasChanges || isSaving)

                Button {
                    Task { await saveLoadout() }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isSaving {
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                        }
                        Text("SAVE LOADOUT")
                    }
                }
                .buttonStyle(.primary)
                .frame(maxWidth: .infinity)
                .disabled(!hasChanges || isSaving)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)
            .background(DarkFantasyTheme.bgSecondary.opacity(0.95))
        }
    }

    // MARK: - Draft mutation helpers

    /// Slot to insert into. When the picker was opened from a specific slot,
    /// new selections replace that slot; otherwise use the lowest free slot.
    private func preferredInsertSlotIndex() -> Int? {
        if let focused = focusedSlotIndex {
            return focused
        }
        let taken = Set(draftSlots.map(\.slotIndex))
        for i in 0..<vm.maxActiveSlots where !taken.contains(i) {
            return i
        }
        return nil
    }

    private func hasRoomForTalent() -> Bool {
        hasFocusedSlot || draftSlots.count < vm.maxActiveSlots
    }

    private func hasRoomForConsumable(_ type: String) -> Bool {
        // Already equipped? Row shows "Equipped" and lets user unequip.
        if draftConsumableSlot(for: type) != nil { return true }
        // Focused slot means "replace this slot", even when the loadout is full.
        if hasFocusedSlot { return true }
        // Another consumable occupies the 1-per-loadout budget → no room.
        if consumableInDraft != nil { return false }
        return draftSlots.count < vm.maxActiveSlots
    }

    private func equipTalent(_ node: PassiveNode) {
        guard draftTalentSlot(for: node.id) == nil else { return }
        guard let slotIndex = preferredInsertSlotIndex() else { return }
        draftSlots.removeAll { $0.slotIndex == slotIndex || $0.nodeId == node.id }
        let slot = ActiveSlot(
            slotIndex: slotIndex,
            kind: .talent,
            nodeId: node.id,
            nodeKey: node.nodeKey,
            consumableType: nil,
            name: node.name,
            description: node.description,
            icon: node.icon,
            activeActionType: node.activeActionType,
            activeCooldown: node.activeCooldown,
            activeMagnitude: node.activeMagnitude,
            equippedAt: nil
        )
        draftSlots.append(slot)
        draftSlots.sort { $0.slotIndex < $1.slotIndex }
        advanceFocusedSlot(afterFilling: slotIndex)
        HapticManager.light()
    }

    private func unequipTalent(_ node: PassiveNode) {
        draftSlots.removeAll { $0.kind == .talent && $0.nodeId == node.id }
        HapticManager.light()
    }

    private func equipConsumable(_ meta: ConsumableMeta) {
        guard draftConsumableSlot(for: meta.consumableType) == nil else { return }
        guard let slotIndex = preferredInsertSlotIndex() else { return }
        // Enforce 1-per-loadout: replace any existing consumable.
        draftSlots.removeAll { $0.kind == .consumable || $0.slotIndex == slotIndex }
        let slot = ActiveSlot(
            slotIndex: slotIndex,
            kind: .consumable,
            nodeId: nil,
            nodeKey: nil,
            consumableType: meta.consumableType,
            name: meta.name,
            description: meta.description,
            icon: nil,
            activeActionType: nil,
            activeCooldown: nil,
            activeMagnitude: nil,
            equippedAt: nil
        )
        draftSlots.append(slot)
        draftSlots.sort { $0.slotIndex < $1.slotIndex }
        advanceFocusedSlot(afterFilling: slotIndex)
        HapticManager.light()
    }

    private func unequipConsumable(_ meta: ConsumableMeta) {
        draftSlots.removeAll { $0.kind == .consumable && $0.consumableType == meta.consumableType }
        HapticManager.light()
    }

    // MARK: - Actions

    private func buyConsumable(_ meta: ConsumableMeta) async {
        guard buyingType == nil else { return }
        buyingType = meta.consumableType
        defer { buyingType = nil }
        let ok = await shopService.buyConsumable(consumableType: meta.consumableType, quantity: 1)
        if ok {
            // Refresh meta so owned_count reflects the purchase, flipping Buy → Equip.
            await vm.refreshConsumablesMeta()
            SFXManager.shared.play(.uiConfirm)
        }
    }

    private func saveLoadout() async {
        guard hasChanges, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        let ok = await vm.commitLoadout(draftSlots)
        if ok {
            SFXManager.shared.play(.uiConfirm)
            appState.showToast("Loadout saved", type: .success)
            dismiss()
        }
    }

    private func initialFocusedSlotIndex() -> Int? {
        if let focused = vm.pickerFocusedSlotIndex,
           (0..<vm.maxActiveSlots).contains(focused) {
            return focused
        }
        let taken = Set(draftSlots.map(\.slotIndex))
        for index in 0..<vm.maxActiveSlots where !taken.contains(index) {
            return index
        }
        return nil
    }

    private func advanceFocusedSlot(afterFilling slotIndex: Int) {
        guard focusedSlotIndex == slotIndex else { return }
        let taken = Set(draftSlots.map(\.slotIndex))
        focusedSlotIndex = (0..<vm.maxActiveSlots).first(where: { !taken.contains($0) })
    }
}
