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
        guard let items = inventoryVM?.items else { return }
        let brokenItems = items.filter { ($0.durability ?? 1) <= 0 && ($0.isEquipped ?? false) }
        let service = ShopService(appState: appState)
        for item in brokenItems {
            let _ = await service.repair(inventoryId: item.id)
        }
        appState.invalidateCache("inventory")
        await inventoryVM?.loadInventory()
        appState.showToast("All gear repaired!", type: .reward)
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
        HStack(spacing: 0) {
            ForEach(HeroTab.allCases, id: \.rawValue) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 4) {
                        Text(tab.label)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                            .foregroundStyle(selectedTab == tab ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)

                        // Stat points available — no dot, full tab gets glow
                        EmptyView()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceSM + 4)
                    .background(
                        selectedTab == tab
                            ? DarkFantasyTheme.bgSecondary
                            : Color.clear
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(selectedTab == tab ? DarkFantasyTheme.gold : Color.clear)
                            .frame(height: 3)
                    }
                    // Shimmer on STATUS tab when stat points available
                    .shimmer(
                        color: DarkFantasyTheme.goldBright,
                        duration: 2.0,
                        isActive: tab == .stats && hasStatPoints && selectedTab != .stats
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(DarkFantasyTheme.bgPrimary)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DarkFantasyTheme.borderSubtle).frame(height: 1)
        }
        .animation(.none, value: selectedTab)
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private func tabContent(_ char: Character) -> some View {
        let equippedItems = inventoryVM?.items.filter { $0.isEquipped == true } ?? []

        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // ── Hero Integrated Card (equipment + portrait + bars + actions) ──
                HeroIntegratedCard(
                    character: char,
                    equippedItems: equippedItems,
                    onTapPortrait: { appState.mainPath.append(AppRoute.appearanceEditor) },
                    onTapSlot: { item in inventoryVM?.selectItem(item) },
                    onEditStance: { appState.mainPath.append(AppRoute.stanceSelector) },
                    onRepairAll: { let _ = Task { await repairAllBrokenItems() } },
                    onAllocateStats: { appState.mainPath.append(AppRoute.character) },
                    onUseHealthPotion: { let _ = Task { await useHealthPotion() } },
                    onRefillStamina: { appState.mainPath.append(AppRoute.shop) }
                )

                // ── Low Resources Widget ──
                lowResourcesWidget(char)

                GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

                // ── Tab selector (scrolls with content) ──
                tabSelector()

                // Active quest banner (under tabs)
                ActiveQuestBanner(questTypes: ["item_upgrade", "consumable_use"])
                    .padding(.horizontal, LayoutConstants.screenPadding)

                // ── Tab-specific content ──
                switch selectedTab {
                case .equipment:
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
        // safeAreaInset removed — HeroIntegratedCard is inside scroll
        .animation(.none, value: selectedTab)
    }

    // ========================================
    // MARK: - EQUIPMENT SECTION (always visible above tabs)
    // ========================================

    @ViewBuilder
    private func equipmentSection(_ char: Character, equippedItems: [Item]) -> some View {
        GeometryReader { geo in
            // cellWidth = same as inventory/shop cells
            let cw = max((geo.size.width - 2 * LayoutConstants.screenPadding - CGFloat(LayoutConstants.inventoryCols - 1) * LayoutConstants.inventoryGap) / CGFloat(LayoutConstants.inventoryCols), 0)
            let portraitSize = 2 * cw + LayoutConstants.inventoryGap
            let colHeight = 3 * cw + 2 * LayoutConstants.inventoryGap

            VStack(spacing: LayoutConstants.spaceMD) {
                // RPG layout: left slots | portrait + bars | right slots
                HStack(alignment: .top, spacing: LayoutConstants.inventoryGap) {
                    // Left column: Helmet, Chest, Legs
                    VStack(spacing: LayoutConstants.inventoryGap) {
                        equipSlot("helmet", from: equippedItems, size: cw)
                        equipSlot("chest", from: equippedItems, size: cw)
                        equipSlot("legs", from: equippedItems, size: cw)
                    }

                    // Center: portrait + HP / XP bars
                    VStack(spacing: LayoutConstants.spaceXS) {
                        heroPortrait(char)
                            .frame(width: portraitSize, height: portraitSize)

                        VStack(spacing: 5) {
                            HStack(spacing: 6) {
                                Text("HP")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    .frame(width: 20, alignment: .leading)

                                HPBarView(currentHp: char.currentHp, maxHp: char.maxHp, height: 10)

                                Text("\(char.currentHp)/\(char.maxHp)")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    .frame(width: 58, alignment: .trailing)
                            }
                            HubStatBar(
                                label: "XP",
                                valueText: "\(Int(char.xpPercentage * 100))%",
                                percentage: char.xpPercentage,
                                color: DarkFantasyTheme.cyan
                            )
                        }
                        .frame(width: portraitSize)
                    }

                    // Right column: Amulet, Gloves, Boots
                    VStack(spacing: LayoutConstants.inventoryGap) {
                        equipSlot("amulet", from: equippedItems, size: cw)
                        equipSlot("gloves", from: equippedItems, size: cw)
                        equipSlot("boots", from: equippedItems, size: cw)
                    }
                }
                .frame(height: colHeight)
                .padding(.horizontal, LayoutConstants.screenPadding)

                // Bottom row 1: Belt, Weapon, Relic, Necklace
                HStack(spacing: LayoutConstants.inventoryGap) {
                    equipSlot("belt", from: equippedItems, size: cw)
                    equipSlot("weapon", from: equippedItems, size: cw)
                    equipSlot("relic", from: equippedItems, size: cw)
                    equipSlot("necklace", from: equippedItems, size: cw)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                // Bottom row 2: Ring, (spacer), (spacer), Ring
                HStack(spacing: LayoutConstants.inventoryGap) {
                    equipSlot("ring", from: equippedItems, size: cw, index: 0)
                    Color.clear.frame(width: cw, height: cw)
                    Color.clear.frame(width: cw, height: cw)
                    equipSlot("ring", from: equippedItems, size: cw, index: 1)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
        .frame(height: {
            let screenW = UIScreen.main.bounds.width
            let cw = max((screenW - 2 * LayoutConstants.screenPadding - CGFloat(LayoutConstants.inventoryCols - 1) * LayoutConstants.inventoryGap) / CGFloat(LayoutConstants.inventoryCols), 0)
            return 3 * cw + 2 * LayoutConstants.inventoryGap   // col height
                + LayoutConstants.spaceMD                       // VStack gap
                + cw                                            // bottom row 1
                + LayoutConstants.spaceMD                       // gap
                + cw                                            // bottom row 2 (rings)
        }())
    }

    // MARK: - Hero Portrait

    @ViewBuilder
    private func heroPortrait(_ char: Character) -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                    )

                AvatarImageView(
                    skinKey: char.avatar,
                    characterClass: char.characterClass,
                    size: side
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius - 4))

                // Name overlay at bottom
                VStack {
                    Spacer()
                    Text(char.characterName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(.bgAbyss.opacity(0.45))
                }
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))

                // Badges (top corners)
                VStack {
                    HStack {
                        // Class icon (top-left)
                        Image(char.characterClass.iconAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(DarkFantasyTheme.bgTertiary))
                            .clipShape(Circle())

                        Spacer()

                        // Level badge (top-right)
                        Text("\(char.level)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption).bold())
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(DarkFantasyTheme.gold))
                    }
                    Spacer()
                }
                .padding(LayoutConstants.spaceSM)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.mainPath.append(AppRoute.appearanceEditor)
        }
    }

    // MARK: - Equipment Slot (Compact)

    private func findEquippedItem(slot: String, from items: [Item], index: Int) -> Item? {
        switch slot {
        case "ring":
            let rings = items.filter { $0.equippedSlot == "ring" || ($0.equippedSlot == nil && $0.itemType == .ring) }
            return index < rings.count ? rings[index] : nil
        case "ring2":
            return items.first { $0.equippedSlot == "ring2" }
        case "belt":
            return items.first { $0.equippedSlot == "belt" || $0.itemType == .belt }
        case "relic":
            return items.first { $0.equippedSlot == "relic" || $0.itemType == .relic }
        case "necklace":
            return items.first { $0.equippedSlot == "necklace" || $0.itemType == .necklace }
        default:
            return items.first { $0.equippedSlot == slot || $0.itemType.rawValue == slot }
        }
    }

    @ViewBuilder
    private func equipSlot(_ slot: String, from items: [Item], size: CGFloat, index: Int = 0) -> some View {
        let item = findEquippedItem(slot: slot, from: items, index: index)
        let assetName = EquipmentViewModel.slotAssets[slot]
        let _ = EquipmentViewModel.slotLabels[slot] ?? slot.capitalized

        let rarityColor = item.map { DarkFantasyTheme.rarityColor(for: $0.rarity) } ?? DarkFantasyTheme.borderSubtle

        Button {
            if let item { inventoryVM?.selectItem(item) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(item != nil ? rarityColor.opacity(0.15) : DarkFantasyTheme.bgTertiary.opacity(0.4))

                if let item {
                    if let key = item.imageKey, UIImage(named: key) != nil {
                        Image(key)
                            .resizable().scaledToFit()
                            .frame(width: size * 0.65, height: size * 0.65)
                    } else if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFit()
                                    .frame(width: size * 0.65, height: size * 0.65)
                            default:
                                itemFallbackIcon(item: item, assetName: assetName, size: size)
                            }
                        }
                    } else {
                        itemFallbackIcon(item: item, assetName: assetName, size: size)
                    }
                } else if let assetName {
                    Image(assetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.5, height: size * 0.5)
                        .foregroundStyle(DarkFantasyTheme.textSecondary.opacity(0.3))
                }
            }
            .overlay(alignment: .bottom) {
                // Upgrade dots
                if let item, let level = item.upgradeLevel, level > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<level, id: \.self) { _ in
                            Circle()
                                .fill(DarkFantasyTheme.goldBright)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity)
                    .background(.bgAbyss.opacity(0.45))
                    .clipShape(.rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: LayoutConstants.cardRadius,
                        bottomTrailingRadius: LayoutConstants.cardRadius,
                        topTrailingRadius: 0
                    ))
                }
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        item != nil ? rarityColor.opacity(0.6) : DarkFantasyTheme.borderSubtle,
                        lineWidth: item != nil ? 2 : 1
                    )
            )
            // Durability ring contour
            .overlay {
                if let item,
                   let maxDur = item.maxDurability, maxDur > 0 {
                    let fraction = Double(item.durability ?? 0) / Double(maxDur)
                    if fraction < 1.0 {
                        DurabilityRingOverlay(
                            fraction: fraction,
                            cornerRadius: LayoutConstants.cardRadius,
                            lineWidth: 2
                        )
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.95))
        .disabled(item == nil)
    }

    @ViewBuilder
    private func itemFallbackIcon(item: Item, assetName: String?, size: CGFloat) -> some View {
        let asset = assetName ?? item.itemType.iconAsset
        if let asset {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.55, height: size * 0.55)
        } else {
            Text(item.itemType.icon)
                .font(.system(size: 22))
        }
    }


    // MARK: - Resource Bar

    @ViewBuilder
    private func resourceBar(_ label: String, current: Int, max: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                .foregroundStyle(color)
                .frame(width: 26, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max > 0 ? geo.size.width * CGFloat(current) / CGFloat(max) : 0)
                }
            }
            .frame(height: 8)

            Text("\(current)/\(max)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(width: 65, alignment: .trailing)
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
            // Base Stats (8 attributes grid)
            VStack(spacing: LayoutConstants.spaceSM) {
                // Stat Points Banner
                if vm.availablePoints > 0 {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("SP: \(vm.availablePoints)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel).bold())
                            .foregroundStyle(DarkFantasyTheme.bgPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DarkFantasyTheme.textSuccess)
                            .clipShape(Capsule())

                        Text("Free points")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Spacer()
                    }
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                              GridItem(.flexible(), spacing: LayoutConstants.spaceSM)],
                    spacing: LayoutConstants.spaceSM
                ) {
                    ForEach(Array(StatType.allCases.enumerated()), id: \.element) { index, stat in
                        statCell(stat, vm: vm)
                            .staggeredAppear(index: index)
                    }
                }

                // Save / Reset (visible when stat changes pending)
                if vm.hasChanges {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Button {
                            Task { await vm.saveStats() }
                        } label: {
                            if vm.isSaving {
                                ProgressView().tint(DarkFantasyTheme.textOnGold)
                            } else {
                                Text("SAVE STATS")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(vm.isSaving)

                        Button("RESET") { vm.resetChanges() }
                            .buttonStyle(.ghost)
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

            // Health
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                Text("HEALTH")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("HP")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.hpBlood)
                    Spacer()
                    Text("\(char.currentHp) / \(char.maxHp)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(DarkFantasyTheme.bgSecondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

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
                    derivedRow("Atk Power", value: "\(char.attackPower) \(char.damageTypeName)", color: DarkFantasyTheme.statSTR)
                    derivedRow("Max HP", value: "\(char.maxHp)", color: DarkFantasyTheme.hpBlood)
                    derivedRow("Armor", value: "\(char.armor ?? 0)", color: DarkFantasyTheme.statEND)
                    derivedRow("Magic Resist", value: "\(char.magicResist ?? 0)", color: DarkFantasyTheme.statWIS)
                    derivedRow("Max Stamina", value: "\(char.maxStamina)", color: DarkFantasyTheme.stamina)
                    derivedRow("Crit Chance", value: String(format: "%.1f%%", char.critChance), color: DarkFantasyTheme.statLUK)
                    derivedRow("Dodge", value: String(format: "%.1f%%", char.dodgeChance), color: DarkFantasyTheme.statAGI)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Equipment bonuses
            equipmentBonusesCard(inventoryVM?.items.filter { $0.isEquipped == true } ?? [])

            GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

            // Respec Stats
            respecStatsCard(vm: vm)

            GoldDivider().padding(.horizontal, LayoutConstants.screenPadding)

            // PvP
            pvpSection(char)

            // Resources
            resourcesSection(char)

        }
    }

    // MARK: - Stat Cell

    @ViewBuilder
    private func statCell(_ stat: StatType, vm: CharacterViewModel) -> some View {
        let value = vm.currentValue(for: stat)
        let delta = vm.pendingChanges[stat] ?? 0
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)
        let hasPoints = (appState.currentCharacter?.statPoints ?? 0) > 0

        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            // Row 1: Icon + Stat name + value + buttons
            HStack(spacing: 6) {
                Image(stat.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(stat.fullName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(color)
                    .lineLimit(1)

                Button {
                    tooltipStat = tooltipStat == stat ? nil : stat
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11)) // SF Symbol icon — keep as is
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 4)

                if delta > 0 {
                    Button { HapticManager.light(); vm.decrement(stat) } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold)) // SF Symbol icon
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(width: 22, height: 22)
                            .background(DarkFantasyTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.scalePress(0.85))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }

                NumberTickUpText(
                    value: value,
                    color: delta > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textPrimary,
                    font: DarkFantasyTheme.section(size: LayoutConstants.textCard)
                )
                .frame(minWidth: 24, alignment: .trailing)

                if hasPoints {
                    Button { HapticManager.selection(); vm.increment(stat) } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold)) // SF Symbol icon
                            .foregroundStyle(.textPrimary)
                            .frame(width: 22, height: 22)
                            .background(vm.availablePoints > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.scalePress(0.85))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(vm.availablePoints <= 0)
                }
            }

            // Row 2: Primary derived stat (updates live)
            Text(vm.primaryDerivedLabel(for: stat))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)

            // Row 2b: Stat description tooltip
            if tooltipStat == stat {
                Text(stat.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .padding(LayoutConstants.spaceXS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DarkFantasyTheme.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            // Row 3: Per-point benefit hints
            if hasPoints {
                HStack(spacing: 4) {
                    ForEach(vm.perPointBenefits(for: stat), id: \.self) { hint in
                        Text(hint)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DarkFantasyTheme.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(delta > 0 ? color.opacity(0.5) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Derived Stat Row

    // MARK: - Stance Summary Card

    @ViewBuilder
    private func stanceSummaryCard(_ char: Character) -> some View {
        let stance = char.combatStance ?? .default

        Button {
            appState.mainPath.append(AppRoute.stanceSelector)
        } label: {
            HStack(spacing: LayoutConstants.spaceLG) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(StanceSelectorViewModel.zoneAsset(for: stance.attack))
                            .resizable().scaledToFit().frame(width: 18, height: 18)
                        Text("ATTACK")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    Text(stance.attack.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.attack))
                }

                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(width: 1, height: 40)

                VStack(spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(StanceSelectorViewModel.zoneAsset(for: stance.defense))
                            .resizable().scaledToFit().frame(width: 18, height: 18)
                        Text("DEFENSE")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    Text(stance.defense.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(StanceSelectorViewModel.zoneColor(for: stance.defense))
                }
            }
            .frame(maxWidth: .infinity)
            .panelCard(highlight: true)
        }
        .buttonStyle(.scalePress(0.97))
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

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
        .background(DarkFantasyTheme.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
                                HStack(spacing: 4) {
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
                        HStack(spacing: 2) {
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
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
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
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
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

    // MARK: - Resources Section

    @ViewBuilder
    private func resourcesSection(_ char: Character) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("RESOURCES")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("\u{1F4B0}").font(.system(size: 18)) // emoji — keep as is
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Gold")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("\(char.gold)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                }
                Spacer()
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("\u{1F48E}").font(.system(size: 18)) // emoji — keep as is
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Gems")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("\(char.gems ?? 0)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                    }
                }
            }
            .padding(LayoutConstants.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
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

                VStack(alignment: .leading, spacing: 2) {
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
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(accentColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
            )
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
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                HStack(spacing: 4) {
                    Image("icon-gold").resizable().frame(width: 14, height: 14)
                    Text("\(vm.gold)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                }
                HStack(spacing: 4) {
                    Image("icon-gems").resizable().frame(width: 14, height: 14)
                    Text("\(appState.currentCharacter?.gems ?? 0)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .monospacedDigit()
                }
                Text("·").foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("\(vm.items.count) items")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Item grid — always show all 28 slots
            if vm.errorMessage != nil {
                ErrorStateView.loadFailed { Task { await vm.loadInventory() } }
            } else if vm.isLoading && vm.items.isEmpty {
                // Loading state
                inventoryLoadingGrid()
            } else if vm.items.isEmpty {
                // Empty state — no items in inventory
                EmptyStateView.generic(
                    title: "No Items Yet",
                    message: "Win battles to collect gear."
                )
                .frame(height: 300)
            } else {
                // Content state
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
                    spacing: LayoutConstants.inventoryGap
                ) {
                    ForEach(0..<max(vm.totalSlots, 28), id: \.self) { index in
                        if index < vm.sortedItems.count {
                            ItemCardView(
                                item: vm.sortedItems[index],
                                equippedItem: vm.equippedBySlot[vm.sortedItems[index].equipSlot]
                            ) {
                                vm.selectItem(vm.sortedItems[index])
                            }
                            .staggeredAppear(index: index)
                        } else {
                            // Empty slot — same structure as SkeletonInventoryItem
                            VStack {
                                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                // Expand inventory button — secondary style, content-width
                if vm.canExpand {
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
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
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )

        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }
}
