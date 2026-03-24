import SwiftUI

// MARK: - Hero Tab

enum HeroTab: Int, CaseIterable {
    case equipment = 0
    case stats = 1

    var label: String {
        switch self {
        case .equipment: "INVENTORY"
        case .stats: "STATUS"
        }
    }
}

// MARK: - Hero Detail View

struct HeroDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var selectedTab: HeroTab = .equipment
    @State private var characterVM: CharacterViewModel?
    @State private var inventoryVM: InventoryViewModel?
    @State private var showRespecConfirm = false
    @State private var showSaveConfirm = false
    @State private var statsBadgePulse = false
    @State private var tooltipStat: StatType?

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
                        onRepair: { let _ = Task { await vm.repair(item) } },
                        onClose: { vm.showItemDetail = false }
                    )
                    .transition(.opacity)
                }
            } else {
                ProgressView().tint(DarkFantasyTheme.gold)
            }

            // Sticky Save Bar (stats tab)
            if selectedTab == .stats, let vm = characterVM, vm.hasChanges {
                statsStickyBar(vm: vm)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(DarkFantasyTheme.bgPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("HERO")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { appState.mainPath.append(AppRoute.settings) } label: {
                    Image("icon-settings")
                        .resizable()
                        .frame(width: 24, height: 24)
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
        }
    }

    // MARK: - Actions

    private func repairAllBrokenItems() async {
        guard let vm = inventoryVM else { return }
        let brokenItems = vm.items.filter { ($0.durability ?? 1) <= 0 && ($0.isEquipped ?? false) }
        guard !brokenItems.isEmpty else { return }

        // Optimistic update: mark all broken items as repaired immediately
        var totalCost = 0
        vm.items = vm.items.map { existing in
            guard brokenItems.contains(where: { $0.id == existing.id }) else { return existing }
            var updated = existing
            updated.durability = existing.maxDurability ?? 100
            return updated
        }
        appState.cachedInventory = vm.items
        appState.showToast("All gear repaired!", type: .reward)

        // Fire repair calls in background — update gold from responses
        let service = ShopService(appState: appState)
        for item in brokenItems {
            if let result = await service.repair(inventoryId: item.id) {
                totalCost += result.repairCost
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

    private func useHealthPotion() async {
        guard let items = appState.cachedInventory else { return }
        guard let potion = items.first(where: { $0.consumableType?.contains("health_potion") == true }) else { return }
        let service = InventoryService(appState: appState)
        let _ = await service.useItem(inventoryId: potion.id, consumableType: potion.consumableType)
        appState.invalidateCache("inventory")
        await inventoryVM?.loadInventory()
        appState.showToast("Healed!", type: .reward)
    }

    // MARK: - Tab Selector

    private var hasStatPoints: Bool {
        (appState.currentCharacter?.statPoints ?? 0) > 0
    }

    @ViewBuilder
    private func tabSelector() -> some View {
        let statPoints = appState.currentCharacter?.statPoints ?? 0

        HStack(spacing: 0) {
            ForEach(HeroTab.allCases, id: \.rawValue) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text(tab.label)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                            .foregroundStyle(selectedTab == tab ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)

                        // Stat points badge on STATUS tab (gold capsule, matches avatar badge)
                        if tab == .stats && statPoints > 0 {
                            Text("+\(statPoints)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                                .foregroundStyle(DarkFantasyTheme.textOnGold)
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(DarkFantasyTheme.goldBright)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5)
                                )
                                .shadow(
                                    color: DarkFantasyTheme.goldBright.opacity(0.6),
                                    radius: 6
                                )
                                .accessibilityLabel("\(statPoints) stat points available")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceSM + 4)
                    .background(
                        selectedTab == tab
                            ? DarkFantasyTheme.bgSecondary
                            : tab == .stats && hasStatPoints && selectedTab != .stats
                                ? DarkFantasyTheme.purple.opacity(0.06)
                                : Color.clear
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(
                                selectedTab == tab
                                    ? DarkFantasyTheme.gold
                                    : tab == .stats && hasStatPoints && selectedTab != .stats
                                        ? DarkFantasyTheme.purple.opacity(0.5)
                                        : Color.clear
                            )
                            .frame(height: 3)
                    }
                    // Subtle tint instead of shimmer — no infinite GPU loop
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(DarkFantasyTheme.bgPrimary)
        .overlay(alignment: .bottom) {
            EtchedGroove()
        }
        .animation(.none, value: selectedTab)
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private func tabContent(_ char: Character) -> some View {
        let equippedItems = inventoryVM?.items.filter { $0.isEquipped == true } ?? []

        VStack(spacing: 0) {
            // ── Sticky tab selector (pinned at top, does NOT scroll) ──
            tabSelector()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // ── Tab-specific content ──
                    switch selectedTab {
                    case .equipment:
                        // Hero card only on Inventory tab
                        HeroIntegratedCard(
                            character: char,
                            equippedItems: equippedItems,
                            onTapPortrait: { appState.mainPath.append(AppRoute.appearanceEditor) },
                            onTapSlot: { item in inventoryVM?.selectItem(item) },
                            onRepairAll: { let _ = Task { await repairAllBrokenItems() } },
                            onUseHealthPotion: { let _ = Task { await useHealthPotion() } },
                            onRefillStamina: { appState.mainPath.append(AppRoute.shop) }
                        )

                        // ── Stance widget (separate from equipment card) ──
                        if let stance = char.combatStance {
                            StanceDisplayView(
                                stance: stance,
                                isInteractive: true,
                                onTap: { appState.mainPath.append(AppRoute.stanceSelector) }
                            )
                            .padding(.horizontal, LayoutConstants.screenPadding)
                        }

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
                    }
                }
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
            .animation(.none, value: selectedTab)
        }
    }

    // MARK: - Equipment Bonuses

    @ViewBuilder
    private func equipmentBonusesCard(_ equippedItems: [Item]) -> some View {
        let bonuses = computeBonuses(from: equippedItems)

        VStack(spacing: LayoutConstants.spaceSM) {
            Text("EQUIPMENT BONUSES")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if bonuses.isEmpty {
                Text("No equipment bonuses")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: LayoutConstants.spaceSM
                ) {
                    ForEach(bonuses.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        derivedRow(key.uppercased(), value: "+\(value)", color: DarkFantasyTheme.statColor(for: key))
                    }
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    private func computeBonuses(from items: [Item]) -> [String: Int] {
        var stats: [String: Int] = [:]
        for item in items {
            for (key, val) in item.totalStats {
                stats[key, default: 0] += val
            }
        }
        return stats
    }

    // ========================================
    // MARK: - STATS TAB
    // ========================================

    @ViewBuilder
    private func statsTabContent(_ char: Character, vm: CharacterViewModel) -> some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            // Stat Points Banner (unified component)
            VStack(spacing: LayoutConstants.spaceSM) {
                if vm.availablePoints > 0 {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        StatPointsBadge(points: vm.availablePoints, style: .banner)
                        if vm.hasChanges {
                            Text("(\(vm.pointsSpent) spent)")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }

                // Grouped Stats
                ForEach(StatGroup.allCases, id: \.self) { group in
                    VStack(spacing: LayoutConstants.spaceSM) {
                        // Section header with ornamental lines
                        statGroupHeader(group.rawValue)

                        ForEach(group.stats, id: \.self) { stat in
                            statCell(stat, vm: vm, char: char)
                        }
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            // Extra bottom padding when sticky bar is visible
            .padding(.bottom, vm.hasChanges ? 80 : 0)

            // Respec Stats — directly after stat list
            respecStatsCard(vm: vm)

            GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

            // Derived Stats
            VStack(spacing: LayoutConstants.spaceSM) {
                Text("DERIVED STATS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: LayoutConstants.spaceSM
                ) {
                    derivedRow("Atk Power", value: "\(char.attackPower) \(char.damageTypeName)", color: DarkFantasyTheme.statBarFill)
                    derivedRow("Armor", value: "\(char.armor ?? 0)", color: DarkFantasyTheme.statBarFill)
                    derivedRow("Magic Resist", value: "\(char.magicResist ?? 0)", color: DarkFantasyTheme.statBarFill)
                    derivedRow("Crit Chance", value: String(format: "%.1f%%", char.critChance), color: DarkFantasyTheme.statBarFill)
                    derivedRow("Dodge", value: String(format: "%.1f%%", char.dodgeChance), color: DarkFantasyTheme.statBarFill)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Equipment bonuses
            equipmentBonusesCard(inventoryVM?.items.filter { $0.isEquipped == true } ?? [])

        }
    }

    // MARK: - Stat Cell (3-row layout)

    @ViewBuilder
    private func statCell(_ stat: StatType, vm: CharacterViewModel, char: Character) -> some View {
        let value = vm.currentValue(for: stat)
        let delta = vm.pendingChanges[stat] ?? 0
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)
        let hasPoints = (appState.currentCharacter?.statPoints ?? 0) > 0
        let isClassPrimary = StatType.primaryStats(for: char.characterClass).contains(stat)

        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            // ── Row 1: Icon + Name + Info + Spacer + [-] Value [+] ──
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(stat.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)

                Text(stat.fullName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(color)
                    .lineLimit(1)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        tooltipStat = tooltipStat == stat ? nil : stat
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14)) // SF Symbol — enlarged from 11
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("\(stat.fullName) info")

                // Class recommendation badge
                if isClassPrimary {
                    Text(char.characterClass.displayName.uppercased())
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                }

                Spacer(minLength: 4)

                // Minus button (only when pending delta > 0)
                if delta > 0 {
                    Button { HapticManager.light(); vm.decrement(stat) } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold)) // SF Symbol
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(width: 32, height: 32)
                            .background(DarkFantasyTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.scalePress)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Decrease \(stat.fullName)")
                }

                // Value display
                NumberTickUpText(
                    value: value,
                    color: delta > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textPrimary,
                    font: DarkFantasyTheme.section(size: LayoutConstants.textCard)
                )
                .frame(minWidth: 28, alignment: .trailing)

                // Plus button
                if hasPoints {
                    Button { HapticManager.selection(); vm.increment(stat) } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold)) // SF Symbol
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 32, height: 32)
                            .background(vm.availablePoints > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.scalePress)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(vm.availablePoints <= 0)
                    .accessibilityLabel("Increase \(stat.fullName)")
                }
            }

            // ── Row 2: Derived stat + benefit pills (moved here from Row 1) ──
            HStack(spacing: LayoutConstants.spaceSM) {
                Text(vm.primaryDerivedLabel(for: stat))
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)

                if hasPoints {
                    HStack(spacing: 4) {
                        ForEach(vm.perPointBenefits(for: stat), id: \.self) { hint in
                            Text(hint)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textSuccess)
                                .padding(.horizontal, LayoutConstants.spaceXS)
                                .padding(.vertical, LayoutConstants.space2XS)
                                .background(DarkFantasyTheme.success.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.leading, 30) // Align under name (past icon)

            // ── Row 3: Tooltip (conditional, on info tap) ──
            if tooltipStat == stat {
                Text(stat.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .padding(LayoutConstants.spaceSM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DarkFantasyTheme.bgTertiary)
                    .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(color.opacity(0.2), lineWidth: 0.5)
                    )
                    .transition(.opacity)
            }
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: delta > 0 ? color.opacity(0.06) : DarkFantasyTheme.bgTertiary,
                glowIntensity: delta > 0 ? 0.4 : 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 2,
            inset: 2,
            color: delta > 0 ? color.opacity(0.15) : DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(delta > 0 ? color.opacity(0.5) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: delta > 0 ? color.opacity(0.4) : DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Sticky Save Bar

    @ViewBuilder
    private func statsStickyBar(vm: CharacterViewModel) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Top shadow edge
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, DarkFantasyTheme.bgPrimary.opacity(0.95)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 20)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Button("RESET") { vm.resetChanges() }
                        .buttonStyle(.ghost)
                        .frame(maxWidth: .infinity)

                    Button {
                        showSaveConfirm = true
                    } label: {
                        if vm.isSaving {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("SAVE STATS")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isSaving)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)
                .padding(.bottom, LayoutConstants.spaceMD)
                .background(DarkFantasyTheme.bgPrimary.opacity(0.95))
                .overlay(alignment: .top) {
                    FiligreeLine(color: DarkFantasyTheme.gold.opacity(0.3), notchColor: DarkFantasyTheme.gold.opacity(0.5), notchCount: 5, notchSize: 3)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeOut(duration: 0.25), value: vm.hasChanges)
        .confirmationDialog(
            "Confirm Allocation",
            isPresented: $showSaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Save Stats") {
                Task { await vm.saveStats() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let summary = vm.pendingChanges
                .filter { $0.value > 0 }
                .sorted(by: { $0.key.rawValue < $1.key.rawValue })
                .map { "\($0.key.fullName) +\($0.value)" }
                .joined(separator: ", ")
            Text("\(summary)\n\nRespec costs 50 gems. Make sure this is the build you want.")
        }
    }

    // MARK: - Stat Group Header

    @ViewBuilder
    private func statGroupHeader(_ label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Left line with diamond end
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, DarkFantasyTheme.goldDim.opacity(0.4)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            Text(label)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                .lineLimit(1)
                .fixedSize()

            // Right line with diamond end
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldDim.opacity(0.4), .clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Derived Stat Row

    @ViewBuilder
    private func derivedRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: MotionConstants.tickUpShort), value: value)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
    }

    // MARK: - Respec Stats Card

    @ViewBuilder
    private func respecStatsCard(vm: CharacterViewModel) -> some View {
        let gemCost = 50
        let canAfford = (appState.currentCharacter?.gems ?? 0) >= gemCost

        VStack(spacing: LayoutConstants.spaceSM) {
            Text("RESET STATS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showRespecConfirm {
                VStack(spacing: LayoutConstants.spaceSM) {
                    Text("Reset all stat points to base values? You will get all spent points back.")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Button("CANCEL") {
                            showRespecConfirm = false
                        }
                        .buttonStyle(.ghost)

                        Button {
                            Task { await vm.respecStats() }
                            showRespecConfirm = false
                        } label: {
                            if vm.isRespeccing {
                                ProgressView().tint(DarkFantasyTheme.textOnGold)
                            } else {
                                HStack(spacing: LayoutConstants.spaceXS) {
                                    Text("CONFIRM")
                                    Text("(\(gemCost)")
                                    Image("icon-gem")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                    Text(")")
                                }
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(!canAfford || vm.isRespeccing)
                    }
                }
            } else {
                Button {
                    showRespecConfirm = true
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold)) // SF Symbol icon — keep as is
                        Text("RESPEC STATS")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        Spacer()
                        HStack(spacing: LayoutConstants.space2XS) {
                            Text("\(gemCost)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            Image("icon-gem")
                                .resizable()
                                .frame(width: 14, height: 14)
                        }
                        .foregroundStyle(canAfford ? DarkFantasyTheme.cyan : DarkFantasyTheme.danger)
                    }
                    .foregroundStyle(canAfford ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textTertiary)
                    .padding(LayoutConstants.cardPadding)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.bgTertiary,
                            glowIntensity: 0.4,
                            cornerRadius: LayoutConstants.panelRadius
                        )
                    )
                    .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
                    .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 12, thickness: 1.5)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - PvP Section

    @ViewBuilder
    private func pvpSection(_ char: Character) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("PVP")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                pvpStat("Rating", value: "\(char.pvpRating)", color: DarkFantasyTheme.rankColor(for: char.pvpRating))
                pvpStat("Record", value: "\(char.pvpWins)W / \(char.pvpLosses)L", color: DarkFantasyTheme.textPrimary)
                pvpStat("Rank", value: char.rankName, color: DarkFantasyTheme.rankColor(for: char.pvpRating))
            }
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.4), length: 12, thickness: 1.5)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func pvpStat(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: MotionConstants.tickUpShort), value: value)
        }
        .frame(maxWidth: .infinity)
    }


    // MARK: - Low Resources Widget

    @ViewBuilder
    private func lowResourcesWidget(_ char: Character) -> some View {
        let lowHP = char.hpPercentage < 0.5
        let lowStamina = char.staminaPercentage < 0.3
        let hasHealthPotion = appState.cachedInventory?.contains {
            $0.consumableType?.contains("health_potion") == true && ($0.quantity ?? 0) > 0
        } ?? false
        let hasStaminaPotion = appState.cachedInventory?.contains {
            $0.consumableType?.contains("stamina_potion") == true && ($0.quantity ?? 0) > 0
        } ?? false

        if lowHP && !hasHealthPotion {
            lowResourceBanner(
                icon: "pot_health_small",
                sfFallback: "heart.fill",
                title: "Health is low",
                subtitle: "Restore HP with a health potion",
                accentColor: DarkFantasyTheme.hpBlood,
                ctaText: "Get Potions"
            ) {
                appState.mainPath.append(AppRoute.shop)
            }
        }

        if lowStamina && !hasStaminaPotion {
            lowResourceBanner(
                icon: "pot_stamina_small",
                sfFallback: "bolt.fill",
                title: "Stamina is low",
                subtitle: "Buy stamina potions to keep fighting",
                accentColor: DarkFantasyTheme.stamina,
                ctaText: "Get Potions"
            ) {
                appState.mainPath.append(AppRoute.shop)
            }
        }
    }

    @ViewBuilder
    private func lowResourceBanner(
        icon: String,
        sfFallback: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        ctaText: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.spaceMD) {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: sfFallback)
                        .font(.system(size: 24))
                        .foregroundStyle(accentColor)
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(title)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(accentColor)
                    Text(subtitle)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(ctaText)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(accentColor)
                    .clipShape(Capsule())
            }
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: accentColor.opacity(0.08),
                    glowColor: accentColor.opacity(0.04),
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: accentColor.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
            )
            .cornerBrackets(color: accentColor.opacity(0.4), length: 12, thickness: 1.5)
            .shadow(color: accentColor.opacity(0.1), radius: 4, y: 1)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.scalePress(0.97))
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // ========================================
    // MARK: - INVENTORY (inline in Equipment tab)
    // ========================================

    @ViewBuilder
    private func inventoryInlineContent(_ vm: InventoryViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Header + count
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("INVENTORY")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                CurrencyDisplay(
                    gold: vm.gold,
                    gems: appState.currentCharacter?.gems ?? 0,
                    animated: false
                )
                Text("·").foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("\(vm.items.count) items")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Item grid — always show all 28 slots
            if vm.errorMessage != nil {
                ErrorStateView.loadFailed { let _ = Task { await vm.loadInventory() } }
            } else if vm.isLoading && vm.items.isEmpty {
                // Loading state
                inventoryLoadingGrid()
            } else {
                // Content state (shows empty slots when no items)
                // Cache computed properties once to avoid O(n log n) per cell
                let sorted = vm.sortedItems
                let equipped = vm.equippedBySlot
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
                    spacing: LayoutConstants.inventoryGap
                ) {
                    ForEach(0..<max(vm.totalSlots, 28), id: \.self) { index in
                        if index < sorted.count {
                            ItemCardView(
                                item: sorted[index],
                                context: .inventory(equippedItem: equipped[sorted[index].equipSlot])
                            ) {
                                vm.selectItem(sorted[index])
                            }
                        } else {
                            // Empty slot — same structure as SkeletonInventoryItem
                            VStack {
                                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                                    )
                                    .innerBorder(cornerRadius: LayoutConstants.cardRadius - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.06))
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                // Expand inventory button — secondary style, full width
                if vm.canExpand {
                    Button {
                        Task { await vm.expandInventory() }
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "plus.square.dashed")
                            Text("+10 Slots (\(vm.expandCost) gold)")
                        }
                    }
                    .buttonStyle(.secondary)
                    .disabled(vm.gold < vm.expandCost)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
    }

    // MARK: - Inventory Loading Grid

    private func inventoryLoadingGrid() -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
            spacing: LayoutConstants.inventoryGap
        ) {
            ForEach(0..<12, id: \.self) { _ in
                SkeletonInventoryItem()
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Inventory Search & Sort Bar

    @ViewBuilder
    private func inventorySearchBar(_ vm: InventoryViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Search field
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                TextField("", text: Binding(
                    get: { vm.searchText },
                    set: { vm.searchText = $0 }
                ))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .placeholder(when: vm.searchText.isEmpty) {
                    Text("Search items...")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .buttonStyle(.scalePress)
                }

                // Sort picker
                Menu {
                    ForEach(InventorySortMode.allCases, id: \.self) { mode in
                        Button {
                            vm.sortMode = mode
                        } label: {
                            Label(mode.rawValue, systemImage: mode.icon)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(height: LayoutConstants.buttonHeightSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgTertiary,
                    glowColor: DarkFantasyTheme.bgSecondary,
                    glowIntensity: 0.2,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )

        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }
}
