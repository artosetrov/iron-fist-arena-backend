import SwiftUI

extension HeroDetailView {
    @ViewBuilder
    func lowResourcesWidget(_ char: Character) -> some View {
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
    func lowResourceBanner(
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
    func repairEquipmentWidget(_ equippedItems: [Item], char: Character) -> some View {
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
    func staminaInlineLabel(_ char: Character) -> some View {
        let isLow = char.maxStamina > 0 && Double(char.currentStamina) / Double(char.maxStamina) < 0.15
        // Match CurrencyDisplay .standard size: icon 36, font .title, spacing .spaceXS
        HStack(spacing: LayoutConstants.spaceXS) {
            Image("icon-stamina")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)

            Text("\(char.currentStamina)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(isLow ? DarkFantasyTheme.danger : DarkFantasyTheme.stamina)
                .monospacedDigit()
        }
    }

    // MARK: - INVENTORY (inline in Equipment tab)
    // ========================================

    @ViewBuilder
    func inventoryInlineContent(_ vm: InventoryViewModel) -> some View {
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
                            // BUG-63: pass `canEquip` so the card dims + gets a
                            // red lock badge for items this character can't yet
                            // wear (level too low / wrong class). Mirror of the
                            // server's equip validation — see InventoryViewModel.
                            ItemCardView(
                                item: item,
                                context: .inventory(
                                    equippedItem: equipped[item.equipSlot],
                                    canEquip: vm.canEquip(item)
                                )
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

    func inventoryLoadingGrid() -> some View {
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
    func inventorySearchBar(_ vm: InventoryViewModel) -> some View {
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
