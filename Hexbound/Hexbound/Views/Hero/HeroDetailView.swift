import SwiftUI

// MARK: - Hero Tab

enum HeroTab: Int, CaseIterable {
    case equipment = 0
    case stats = 1
    case talents = 2

    var label: String {
        switch self {
        case .equipment: "INVENTORY"
        case .stats: "STATUS"
        case .talents: "TALENTS"
        }
    }
}

// MARK: - Hero Detail View

struct HeroDetailView: View {
    @Environment(AppState.self) var appState
    @Environment(GameDataCache.self) var cache
    @State var selectedTab: HeroTab = .equipment
    @State var characterVM: CharacterViewModel?
    @State var inventoryVM: InventoryViewModel?
    @State var talentVM: PassiveTreeViewModel?
    @State var showRespecConfirm = false
    @State var tooltipStat: StatType?
    @State var heroHint: NPCHint?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let char = appState.currentCharacter {
                tabContent(char)

                // Item detail overlay (shared across tabs)
                if let vm = inventoryVM, vm.showItemDetail, let item = vm.selectedItem {
                    ItemDetailSheet(
                        item: item,
                        comparedItem: vm.equippedItemInSlot(for: item),
                        playerGems: appState.currentCharacter?.gems ?? 0,
                        upgradeChances: cache.gameConfig?.upgradeChances ?? [100,100,100,100,100,80,60,40,25,15],
                        onEquip: { let _ = Task { await vm.equip(item) } },
                        onUnequip: { let _ = Task { await vm.unequip(item) } },
                        onSell: { let _ = Task { await vm.sell(item) } },
                        onUse: { let _ = Task { await vm.useItem(item) } },
                        onUpgrade: { useProtection in let _ = Task { await vm.upgrade(item, useProtection: useProtection) } },
                        onRepair: { vm.repair(item) },
                        onClose: { vm.showItemDetail = false },
                        // BUG-63: pass player level + class so the sheet can
                        // paint the required-level / class-restriction red and
                        // disable EQUIP before the user taps it.
                        playerLevel: char.level,
                        playerClass: char.characterClass,
                        onDeposit: item.isEquipped != true && item.itemType != .consumable
                            ? { let _ = Task { await vm.depositToStash(item) } }
                            : nil
                    )
                    .transition(.opacity)
                }
            } else {
                HexPulseLoader(.compact)
            }

            // Sticky Save Bar (stats tab)
            if selectedTab == .stats, let vm = characterVM, vm.hasChanges {
                statsStickyBar(vm: vm)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("HERO")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { appState.mainPath.append(AppRoute.settings) } label: {
                    Image("icon-settings")
                        .resizable()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if characterVM == nil { characterVM = CharacterViewModel(appState: appState) }
            if inventoryVM == nil { inventoryVM = InventoryViewModel(appState: appState) }
        }
        .task(id: inventoryVM != nil) {
            guard let vm = inventoryVM else { return }
            await vm.loadInventory()
            updateHeroHint()
        }
        .onChange(of: inventoryVM?.items.count) { _, _ in updateHeroHint() }
        .onChange(of: appState.currentCharacter?.currentHp) { _, _ in updateHeroHint() }
        .contextualHint(heroHint, onCTA: {
            // Route CTA based on hint type
            if let hint = heroHint {
                switch hint.id {
                case "hero_no_gear", "hero_upgrade_no_item":
                    appState.mainPath.append(AppRoute.shop)
                case "hero_low_hp_no_potions":
                    appState.mainPath.append(AppRoute.shop)
                default:
                    break
                }
            }
        })
    }

    // MARK: - Contextual Hint

    func updateHeroHint() {
        guard let char = appState.currentCharacter else { return }
        let items = inventoryVM?.items ?? []
        let equippedCount = items.filter { $0.isEquipped == true }.count
        let potionCount = items.filter { $0.consumableType?.contains("health_potion") == true }.count
        let hasDamagedGear = items.contains { item in
            guard let dur = item.durability, let maxDur = item.maxDurability else { return false }
            return dur < maxDur && (item.isEquipped ?? false)
        }
        let quests = appState.cachedTypedQuests ?? cache.cachedDailyQuests()?.quests ?? []
        let inventoryCount = items.count

        heroHint = ContextualHintProvider.heroHint(
            character: char,
            equippedCount: equippedCount,
            potionCount: potionCount,
            hasDamagedGear: hasDamagedGear,
            quests: quests,
            inventoryCount: inventoryCount
        )
    }

    // MARK: - Actions

    func repairAllDamagedItems() async {
        guard let vm = inventoryVM else { return }
        let damagedItems = vm.items.filter { item in
            guard let dur = item.durability, let maxDur = item.maxDurability else { return false }
            return dur < maxDur && (item.isEquipped ?? false)
        }
        guard !damagedItems.isEmpty else { return }

        // Optimistic update: mark all damaged items as fully repaired
        vm.items = vm.items.map { existing in
            guard damagedItems.contains(where: { $0.id == existing.id }) else { return existing }
            var updated = existing
            updated.durability = existing.maxDurability ?? 100
            return updated
        }
        appState.cachedInventory = vm.items
        HapticManager.success()
        appState.showToast("All gear repaired!", type: .reward)

        // Fire repair calls in background — update gold from responses
        let service = ShopService(appState: appState)
        for item in damagedItems {
            if let result = await service.repair(inventoryId: item.id) {
                // Update with actual server values
                vm.items = vm.items.map { existing in
                    guard existing.id == item.id else { return existing }
                    var updated = existing
                    updated.durability = result.newDurability
                    updated.maxDurability = result.maxDurability
                    return updated
                }
            }
        }
        appState.cachedInventory = vm.items
    }

    func useHealthPotion() async {
        guard var items = appState.cachedInventory else { return }
        guard let potion = items.first(where: { $0.consumableType?.contains("health_potion") == true }) else { return }

        // Optimistic UI — update inventory + HP instantly
        let previousItems = items
        let previousHp = appState.currentCharacter?.currentHp ?? 0
        let maxHp = appState.currentCharacter?.maxHp ?? 100

        if let qty = potion.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == potion.id }
        }
        appState.cachedInventory = items
        inventoryVM?.items = items

        let estimatedHeal = max(Int(Double(maxHp) * 0.3), 50)
        let newHp = min(previousHp + estimatedHeal, maxHp)
        appState.currentCharacter?.currentHp = newHp

        HapticManager.success()
        appState.showToast("Healed! HP: \(newHp)/\(maxHp)", type: .reward)

        // Fire API in background — server corrects HP on success
        let potionId = potion.id
        let consumableType = potion.consumableType
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(inventoryId: potionId, consumableType: consumableType)
            if !success {
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    inventoryVM?.items = previousItems
                    appState.currentCharacter?.currentHp = previousHp
                }
            }
        }
    }

    // MARK: - Tab Selector

    var hasStatPoints: Bool {
        (appState.currentCharacter?.statPoints ?? 0) > 0
    }

    @ViewBuilder
    func tabSelector() -> some View {
        // Per-tab badges. STATUS → unspent stat points; TALENTS → unspent passive points.
        // Order matches `HeroTab.allCases`: [INVENTORY, STATUS, TALENTS].
        // The previous `.trailing` overlay on the whole TabSwitcher was visually above
        // STATUS when the hero had 2 tabs; after TALENTS was added as a 3rd tab it
        // silently drifted above TALENTS and read the wrong counter. TabSwitcher now
        // owns per-tab badge positioning so this class of bug can't recur.
        let statPoints = appState.currentCharacter?.statPoints ?? 0
        let talentPoints = appState.currentCharacter?.passivePointsAvailable ?? 0
        let badges: [Int?] = [nil, statPoints, talentPoints]

        TabSwitcher(
            tabs: HeroTab.allCases.map(\.label),
            selectedIndex: Binding(
                get: { selectedTab.rawValue },
                set: { newValue in
                    if let tab = HeroTab(rawValue: newValue) {
                        selectedTab = tab
                    }
                }
            ),
            badges: badges
        )
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    func tabContent(_ char: Character) -> some View {
        let equippedItems = inventoryVM?.items.filter { $0.isEquipped == true } ?? []

        VStack(spacing: 0) {
            // ── Sticky tab selector (pinned at top, does NOT scroll) ──
            tabSelector()
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceSM)

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // ── Tab-specific content ──
                    switch selectedTab {
                    case .equipment:
                        // Hero card only on Inventory tab
                        IntegratedCharacterCard(
                            display: char,
                            equippedItems: equippedItems,
                            onTapPortrait: { appState.mainPath.append(AppRoute.appearanceEditor) },
                            onTapSlot: { item in inventoryVM?.selectItem(item) },
                            portraitInfo: {
                                CharacterPortraitXPInfo(
                                    experience: char.experience ?? 0,
                                    xpNeeded: char.xpNeeded,
                                    xpPercentage: char.xpPercentage
                                )
                            },
                            footer: {
                                HPBarView(
                                    currentHp: char.currentHp,
                                    maxHp: char.maxHp,
                                    size: .large,
                                    label: "HP"
                                )
                            }
                        )

                        // ── Repair Equipment widget ──
                        repairEquipmentWidget(equippedItems, char: char)

                        // ── Stance widget (separate from equipment card) ──
                        StanceDisplayView(
                            stance: char.combatStance ?? .default,
                            isInteractive: true,
                            onTap: { appState.mainPath.append(AppRoute.stanceSelector) }
                        )
                        .padding(.horizontal, LayoutConstants.screenPadding)

                        lowResourcesWidget(char)

                        ActiveQuestBanner(questTypes: ["item_upgrade", "consumable_use"])
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        if let vm = inventoryVM {
                            inventoryInlineContent(vm)
                        }

                    case .stats:
                        if let vm = characterVM {
                            statsTabContent(char, vm: vm)
                        }

                    case .talents:
                        if let vm = talentVM {
                            TalentsTabView(vm: vm)
                        } else {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    talentVM = PassiveTreeViewModel(
                                        service: PassiveTreeService(appState: appState),
                                        appState: appState,
                                        characterId: char.id
                                    )
                                }
                        }
                    }
                }
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
            .animation(.none, value: selectedTab)
        }
    }

    // MARK: - Equipment Bonuses

}
