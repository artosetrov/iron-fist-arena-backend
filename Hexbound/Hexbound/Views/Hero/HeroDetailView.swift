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
    @State private var statsBadgePulse = false
    @State private var tooltipStat: StatType?
    @State private var heroHint: NPCHint?

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
                        onClose: { vm.showItemDetail = false }
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

    private func updateHeroHint() {
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

    private func repairAllDamagedItems() async {
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

    private func useHealthPotion() async {
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

    private var hasStatPoints: Bool {
        (appState.currentCharacter?.statPoints ?? 0) > 0
    }

    @ViewBuilder
    private func tabSelector() -> some View {
        let statPoints = appState.currentCharacter?.statPoints ?? 0

        TabSwitcher(
            tabs: HeroTab.allCases.map(\.label),
            selectedIndex: Binding(
                get: { selectedTab.rawValue },
                set: { newValue in
                    if let tab = HeroTab(rawValue: newValue) {
                        selectedTab = tab
                    }
                }
            )
        )
        .overlay(alignment: .trailing) {
            // Stat points badge floating over STATUS tab area
            if statPoints > 0 {
                Text("+\(statPoints)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.goldBright)
                    )
                    .overlay(
                        Capsule()
                            .stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5)
                    )
                    .shadow(
                        color: DarkFantasyTheme.goldBright.opacity(statsBadgePulse ? 0.8 : 0.2),
                        radius: statsBadgePulse ? 10 : 4
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            statsBadgePulse = true
                        }
                    }
                    .onDisappear {
                        statsBadgePulse = false
                    }
                    .accessibilityLabel("\(statPoints) stat points available")
                    // Position badge at top-trailing of the STATUS tab half
                    .offset(x: -LayoutConstants.spaceMD, y: -LayoutConstants.spaceSM)
            }
        }
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private func tabContent(_ char: Character) -> some View {
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
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if bonuses.isEmpty {
                Text("No equipment bonuses")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: LayoutConstants.spaceSM
                ) {
                    ForEach(bonuses.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        let label = StatType(rawValue: key.uppercased())?.fullName ?? key.uppercased()
                        derivedRow(label, value: "+\(value)", color: DarkFantasyTheme.statColor(for: key))
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
                // Always render badge to prevent layout jump — hide via opacity
                StatPointsBadge(points: max(vm.availablePoints, 0), style: .banner)
                    .opacity(vm.availablePoints > 0 ? 1 : 0)
                    .animation(MotionConstants.snappy, value: vm.availablePoints > 0)

                // Grouped Stats
                ForEach(StatGroup.allCases, id: \.self) { group in
                    VStack(spacing: LayoutConstants.spaceSM) {
                        // Section header with ornamental lines
                        StatGroupHeader(group.rawValue.uppercased())

                        ForEach(group.stats, id: \.self) { stat in
                            statCell(stat, vm: vm, char: char)
                        }
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            // Extra bottom padding — always reserve when stat points exist to prevent scroll jump
            .padding(.bottom, (appState.currentCharacter?.statPoints ?? 0) > 0 ? 80 : 0)

            // Respec Stats — directly after stat list
            respecStatsCard(vm: vm)

            // Buy Stat Points — navigate to dedicated screen
            buyStatPointsButton()

            GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

            // Derived Stats
            VStack(spacing: LayoutConstants.spaceSM) {
                Text("DERIVED STATS")
                    .font(DarkFantasyTheme.body)
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

            // PvP Stats — unified full widget
            PvPStatsWidget(.full, data: char)
                .padding(.horizontal, LayoutConstants.screenPadding)

            // Equipment bonuses
            equipmentBonusesCard(inventoryVM?.items.filter { $0.isEquipped == true } ?? [])

            // Session Stats — opens the session summary screen
            sessionStatsButton(charId: char.id)

        }
    }

    // MARK: - Session Stats Button

    @ViewBuilder
    private func sessionStatsButton(charId: String) -> some View {
        Button {
            HapticManager.light()
            appState.mainPath.append(AppRoute.sessionSummary(characterId: charId))
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-leaderboard")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text("SESSION STATS")
                    .font(DarkFantasyTheme.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.caption)
            }
            .foregroundStyle(DarkFantasyTheme.gold)
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.gold.opacity(0.04),
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.2), lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 12, thickness: 1.5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.scalePress(0.95))
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Stat Cell (icon-left layout, no GeometryReader)

    @ViewBuilder
    private func statCell(_ stat: StatType, vm: CharacterViewModel, char: Character) -> some View {
        let value = vm.currentValue(for: stat)
        let delta = vm.pendingChanges[stat] ?? 0
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)
        let hasPoints = (appState.currentCharacter?.statPoints ?? 0) > 0
        let isClassPrimary = StatType.primaryStats(for: char.characterClass).contains(stat)

        HStack(alignment: .center, spacing: LayoutConstants.spaceMD) {
            // ── Left: Large icon ──
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)

            // ── Right: Name row + bar + derived ──
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {

                // ── Row 1: Name + Info + Badge + Spacer + [-] Value [+] ──
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(stat.fullName.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Button {
                        withAnimation(MotionConstants.snappy) {
                            tooltipStat = tooltipStat == stat ? nil : stat
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(stat.fullName) info")

                    if isClassPrimary {
                        Text(char.characterClass.displayName.uppercased())
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                    }

                    Spacer(minLength: 4)

                    // Minus button — always reserves space to prevent layout shift
                    Button { HapticManager.light(); vm.decrement(stat) } label: {
                        Image(systemName: "minus")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(width: 40, height: 40)
                            .background(DarkFantasyTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .opacity(delta > 0 ? 1 : 0)
                    .disabled(delta <= 0)
                    .animation(.easeOut(duration: MotionConstants.instant), value: delta > 0)
                    .accessibilityLabel("Decrease \(stat.fullName)")
                    .accessibilityHidden(delta <= 0)

                    // Value display — large 28pt
                    NumberTickUpText(
                        value: value,
                        color: delta > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textPrimary,
                        font: DarkFantasyTheme.cinematicTitle
                    )
                    .frame(minWidth: 40, alignment: .trailing)

                    // Plus button — always reserves space when stat points exist
                    Button { HapticManager.selection(); vm.increment(stat) } label: {
                        Image(systemName: "plus")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 40, height: 40)
                            .background(vm.availablePoints > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .opacity(hasPoints ? 1 : 0)
                    .disabled(vm.availablePoints <= 0 || !hasPoints)
                    .accessibilityLabel("Increase \(stat.fullName)")
                    .accessibilityHidden(!hasPoints)
                }

                // ── Row 2: Two-zone progress bar (pure HStack, no GeometryReader) ──
                // Base zone = 0–10, bonus zone = 10–20.
                // Each zone is 50% of total bar width. Fill % within each zone.
                let baseMax: Double = 10
                let basePct = min(Double(value), baseMax) / baseMax   // 0…1 within left half
                let bonusPct = max(0, Double(value) - baseMax) / baseMax // 0…1 within right half

                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)

                    // Two-zone fill
                    HStack(spacing: 0) {
                        // Left half: base zone
                        ZStack(alignment: .leading) {
                            Color.clear
                            if basePct > 0 {
                                LinearGradient(
                                    colors: [DarkFantasyTheme.statBarFill.opacity(0.55), DarkFantasyTheme.statBarFill],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .mask(alignment: .leading) {
                                    Rectangle()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .scaleEffect(x: basePct, anchor: .leading)
                                }
                            }
                        }

                        // Separator
                        Rectangle()
                            .fill(DarkFantasyTheme.bgAbyss.opacity(value >= 10 ? 0.9 : 0.35))
                            .frame(width: 1.5)

                        // Right half: bonus zone
                        ZStack(alignment: .leading) {
                            Color.clear
                            if bonusPct > 0 {
                                LinearGradient(
                                    colors: [DarkFantasyTheme.statBoosted.opacity(0.65), DarkFantasyTheme.statBoosted],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .mask(alignment: .leading) {
                                    Rectangle()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .scaleEffect(x: bonusPct, anchor: .leading)
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
                    .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                }
                .frame(height: LayoutConstants.spaceSM)
                .drawingGroup() // Flatten to Metal texture — prevents layout reflow on fill change
                .animation(.easeOut(duration: MotionConstants.tickUpShort), value: value)

                // ── Row 3: Derived stat + benefit pills ──
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(vm.primaryDerivedLabel(for: stat))
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)

                    if hasPoints {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            ForEach(vm.perPointBenefits(for: stat), id: \.self) { hint in
                                Text(hint)
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                    .foregroundStyle(DarkFantasyTheme.textSuccess)
                                    .padding(.horizontal, LayoutConstants.spaceXS)
                                    .padding(.vertical, LayoutConstants.space2XS)
                                    .background(DarkFantasyTheme.success.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // ── Row 4: Tooltip (conditional, on info tap) ──
                if tooltipStat == stat {
                    Text(stat.description)
                        .font(DarkFantasyTheme.body)
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
        }
        .padding(LayoutConstants.spaceMS)
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
        .compositingGroup()
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
                    .frame(height: LayoutConstants.iconMD)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Button("RESET") { vm.resetChanges() }
                        .buttonStyle(.ghost)
                        .frame(maxWidth: .infinity)

                    Button {
                        vm.saveStats()
                    } label: {
                        Text("SAVE STATS")
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
    }

    // MARK: - Stat Group Header (uses shared StatGroupHeader component)

    // MARK: - Derived Stat Row

    @ViewBuilder
    private func derivedRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.body)
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
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showRespecConfirm {
                VStack(spacing: LayoutConstants.spaceSM) {
                    Text("Reset all stat points to base values? You will get all spent points back.")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Button("CANCEL") {
                            showRespecConfirm = false
                        }
                        .buttonStyle(.ghost)

                        Button {
                            vm.respecStats()
                            showRespecConfirm = false
                        } label: {
                            if vm.isRespeccing {
                                HexPulseLoader.onGold()
                            } else {
                                HStack(spacing: LayoutConstants.spaceXS) {
                                    Text("CONFIRM")
                                    Text("(\(gemCost)")
                                    Image("icon-gems")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                    Text(")")
                                }
                                .font(DarkFantasyTheme.body)
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(!canAfford || vm.isRespeccing)
                    }
                }
            } else {
                Button {
                    if canAfford {
                        showRespecConfirm = true
                    } else {
                        HapticManager.light()
                        appState.showToast("Not enough gems", subtitle: "Respec costs \(gemCost) gems. Buy gems in the shop!", type: .error, actionLabel: "Shop") {
                            appState.mainPath.append(AppRoute.currencyPurchase())
                        }
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(DarkFantasyTheme.body.bold())
                        Text("RESPEC STATS")
                            .font(DarkFantasyTheme.body)
                        Spacer()
                        HStack(spacing: LayoutConstants.space2XS) {
                            Text("\(gemCost)")
                                .font(DarkFantasyTheme.body)
                            Image("icon-gems")
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
                    .compositingGroup()
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Buy Stat Points Button

    @ViewBuilder
    private func buyStatPointsButton() -> some View {
        Button {
            HapticManager.light()
            appState.mainPath.append(AppRoute.buyStatPoints)
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "plus.circle.fill")
                    .font(DarkFantasyTheme.body.bold())
                Text("BUY STAT POINTS")
                    .font(DarkFantasyTheme.body)
                Spacer()
                Image("icon-gems")
                    .resizable()
                    .frame(width: 14, height: 14)
                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.caption)
            }
            .foregroundStyle(DarkFantasyTheme.cyan)
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.cyan.opacity(0.04),
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.cyan.opacity(0.2), lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 12, thickness: 1.5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        }
        .buttonStyle(.scalePress(0.95))
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - PvP Section (moved to PvPStatsWidget)


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

        if lowHP {
            if hasHealthPotion {
                lowResourceBanner(
                    icon: "health_potion_small",
                    sfFallback: "heart.fill",
                    title: "Health is low",
                    subtitle: "You have a health potion — use it!",
                    accentColor: DarkFantasyTheme.hpBlood,
                    ctaText: "Heal"
                ) {
                    Task { await useHealthPotion() }
                }
            } else {
                lowResourceBanner(
                    icon: "health_potion_small",
                    sfFallback: "heart.fill",
                    title: "Health is low",
                    subtitle: "Buy a health potion to restore HP",
                    accentColor: DarkFantasyTheme.hpBlood,
                    ctaText: "Get Potions"
                ) {
                    appState.shopInitialTab = 3
                    appState.mainPath.append(AppRoute.shop)
                }
            }
        }

        if lowStamina && !hasStaminaPotion {
            lowResourceBanner(
                icon: "stamina_potion_small",
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
        VStack(spacing: LayoutConstants.spaceMS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: sfFallback)
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(accentColor)
                        .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(title)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(accentColor)
                    Text(subtitle)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            // CTA — proper ButtonStyle from design system
            Button(action: action) {
                Text(ctaText)
            }
            .buttonStyle(.secondary)
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
        .compositingGroup()
        .shadow(color: accentColor.opacity(0.1), radius: 4, y: 1)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Repair Equipment Widget

    @ViewBuilder
    private func repairEquipmentWidget(_ equippedItems: [Item], char: Character) -> some View {
        let damagedItems = equippedItems.filter { item in
            guard let dur = item.durability, let maxDur = item.maxDurability else { return false }
            return dur < maxDur
        }

        if !damagedItems.isEmpty {
            let totalCost = damagedItems.reduce(0) { $0 + (($1.maxDurability ?? 0) - ($1.durability ?? 0)) * 2 }
            let playerGold = char.gold
            let canAfford = playerGold >= totalCost

            VStack(spacing: LayoutConstants.spaceMS) {
                // Header row
                HStack {
                    Image("icon-strength")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

                    Text("REPAIR EQUIPMENT")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    Spacer()
                }

                // Info row: count + cost
                HStack(spacing: LayoutConstants.spaceMD) {
                    // Damaged count
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.stamina)
                        Text("\(damagedItems.count) damaged")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }

                    Spacer()

                    // Total cost
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Cost:")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        CurrencyDisplay(gold: totalCost, size: .compact)
                    }
                }

                // Not enough gold warning
                if !canAfford {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "xmark.circle.fill")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.danger)
                        Text("Not enough gold")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.danger)
                        Spacer()
                    }
                }

                // Repair All button
                Button {
                    let _ = Task { await repairAllDamagedItems() }
                } label: {
                    Text("Repair All")
                }
                .buttonStyle(.secondary)
                .disabled(!canAfford)
                .opacity(canAfford ? 1.0 : 0.5)
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
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 12, thickness: 1.5)
            .compositingGroup()
            .cardShadow()
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // ========================================
    // MARK: - Stamina Inline Label (⚡ 120/120)

    @ViewBuilder
    private func staminaInlineLabel(_ char: Character) -> some View {
        let isLow = char.maxStamina > 0 && Double(char.currentStamina) / Double(char.maxStamina) < 0.15
        // Match CurrencyDisplay .standard size: icon 36, font .title, spacing .spaceXS
        HStack(spacing: LayoutConstants.spaceXS) {
            Image("icon-stamina")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            Text("\(char.currentStamina)/\(char.maxStamina)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(isLow ? DarkFantasyTheme.danger : DarkFantasyTheme.stamina)
                .monospacedDigit()
        }
    }

    // MARK: - INVENTORY (inline in Equipment tab)
    // ========================================

    @ViewBuilder
    private func inventoryInlineContent(_ vm: InventoryViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Header + count
            HStack(spacing: LayoutConstants.spaceSM) {
                CurrencyDisplay(
                    gold: vm.gold,
                    gems: appState.currentCharacter?.gems ?? 0,
                    animated: false
                )

                // Stamina inline (number display)
                if let char = appState.currentCharacter {
                    staminaInlineLabel(char)
                }

                Spacer()
                Text("\(vm.items.count) items")
                    .font(DarkFantasyTheme.body)
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
                // Cache computed properties once to avoid O(n log n) per cell.
                //
                // BUG-61 (2026-04-11): grid MUST use stable identity
                // (`InventorySlot.id` — item.id for filled slots, "empty_N"
                // for empty ones). Previously this was `ForEach(0..<count, id: \.self)`,
                // which identified cells by POSITION. On any equip/unequip,
                // `sortedItems` shrinks by 1 and every item shifts left —
                // SwiftUI diffs this as "cell 0 changed from A to B, cell 1
                // from B to C, …" and re-renders the entire grid, making
                // items visually "jump" between inventory and equipment.
                // With stable IDs, SwiftUI correctly recognises "item A
                // removed, others unchanged" and does a single clean diff.
                let equipped = vm.equippedBySlot
                let slots = vm.gridSlots
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
                    spacing: LayoutConstants.inventoryGap
                ) {
                    ForEach(slots) { slot in
                        if let item = slot.item {
                            ItemCardView(
                                item: item,
                                context: .inventory(equippedItem: equipped[item.equipSlot])
                            ) {
                                vm.selectItem(item)
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
                        vm.expandInventory()
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
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                TextField("", text: Binding(
                    get: { vm.searchText },
                    set: { vm.searchText = $0 }
                ))
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .placeholder(when: vm.searchText.isEmpty) {
                    Text("Search items...")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(DarkFantasyTheme.body)
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
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
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
