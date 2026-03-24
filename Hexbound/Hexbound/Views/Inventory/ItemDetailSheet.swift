import SwiftUI

struct ItemDetailSheet: View {
    let item: Item
    let comparedItem: Item?
    let playerGems: Int
    let upgradeChances: [Int]
    let onEquip: () -> Void
    let onUnequip: () -> Void
    let onSell: () -> Void
    let onUse: () -> Void
    let onUpgrade: (Bool) -> Void
    let onRepair: () -> Void
    let onClose: () -> Void

    // Shop mode (optional)
    var shopMode: ShopContext? = nil
    /// Player's current level — used to show "You: Level X" in shop mode
    var playerLevel: Int = 1

    struct ShopContext {
        let price: Int
        let isGemPurchase: Bool
        let canAfford: Bool
        let meetsLevel: Bool
        let isBuying: Bool
        let requiredLevel: Int
        let onBuy: () -> Void
    }

    @State private var showUpgradeConfirm = false
    @State private var useProtection = false
    @State private var showSellConfirm = false

    private var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: item.rarity)
    }

    private var isEquipped: Bool {
        item.isEquipped ?? false
    }

    private var currentUpgradeLevel: Int { item.upgradeLevel ?? 0 }
    private var canUpgrade: Bool { item.itemType != .consumable && currentUpgradeLevel < 10 && !isBroken }
    private var upgradeCost: Int { (currentUpgradeLevel + 1) * 100 }
    private var upgradeChance: Int {
        guard currentUpgradeLevel < upgradeChances.count else { return 0 }
        return upgradeChances[currentUpgradeLevel]
    }

    private var hasDurability: Bool {
        item.durability != nil && item.maxDurability != nil && item.itemType != .consumable
    }
    private var isBroken: Bool {
        item.durability == 0 && item.maxDurability != nil
    }
    private var isDamaged: Bool {
        guard let dur = item.durability, let maxDur = item.maxDurability else { return false }
        return dur < maxDur
    }
    private var repairCost: Int {
        ((item.maxDurability ?? 0) - (item.durability ?? 0)) * 2
    }
    private var durabilityFraction: Double {
        guard let dur = item.durability, let maxDur = item.maxDurability, maxDur > 0 else { return 0 }
        return Double(dur) / Double(maxDur)
    }
    private var durabilityColor: Color {
        if durabilityFraction > 0.6 { return DarkFantasyTheme.success }
        if durabilityFraction > 0.3 { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }
    private var durabilityGradient: LinearGradient {
        LinearGradient(
            colors: [durabilityColor, durabilityColor.opacity(0.7)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    var body: some View {
        ZStack {
            // Backdrop — tap to close
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // SECTION 1 — Header
                        headerSection
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(LayoutConstants.cardPadding)

                        sectionDivider

                        // SECTION 2 — Stats
                        statsSection

                        // SECTION 2.5 — Durability
                        durabilitySection

                        // SECTION 3 — Comparison
                        comparisonSection

                        // SECTION 4 — Effects
                        effectsSection

                        // SECTION 5 — Economy (hide in shop mode)
                        if shopMode == nil {
                            economySection
                        }

                        // SECTION 6 — Upgrade (hide in shop mode)
                        if shopMode == nil {
                            upgradeInfoSection
                        }

                        // SECTION 7 — Description
                        descriptionSection
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)

                // Action buttons pinned to bottom
                actionButtons
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)
            }
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.08, bottomShadow: 0.14)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: rarityColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(rarityColor.opacity(0.5), lineWidth: 2)
            )
            .cornerBrackets(color: rarityColor.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: rarityColor.opacity(0.4), size: 6)
            .shadow(color: rarityColor.opacity(0.18), radius: 10, y: 0)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Section 1: Header

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            // Item icon — no background, larger
            ItemImageView(
                imageKey: item.imageKey,
                imageUrl: item.imageUrl,
                systemIcon: item.consumableIcon,
                systemIconColor: item.consumableIconColor,
                fallbackIcon: item.itemType.icon
            )
            .frame(width: 104, height: 104)
            .accessibilityLabel("Item icon for \(item.displayName)")
            .accessibilityElement(children: .ignore)

            // Item info
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(item.displayName)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                    .foregroundStyle(rarityColor)
                    .lineLimit(2)
                    .accessibilityLabel("Item name")

                HStack(spacing: LayoutConstants.spaceXS) {
                    badgePill(item.itemType.displayName, style: .secondary)
                    badgePill(item.rarity.displayName, style: .rarity)
                }
                .accessibilityLabel("\(item.itemType.displayName) \(item.rarity.displayName) rarity")
                .accessibilityElement(children: .combine)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Level \(item.itemLevel)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .accessibilityLabel("Item level: \(item.itemLevel)")

                    if let qty = item.quantity, qty > 1 {
                        Text("×\(qty)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .accessibilityLabel("Quantity: \(qty)")
                    }
                }

                if let restriction = item.classRestriction,
                   restriction != "none", !restriction.isEmpty {
                    Text("\(restriction.capitalized) only")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                        .accessibilityLabel("Restricted to \(restriction)")
                }
            }

            Spacer(minLength: 0)

            // Close (X) button
            Button { onClose() } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.closeButton)
            .accessibilityLabel("Close item detail")
        }
    }

    // MARK: - Section 2: Stats (2-column grid)

    private struct StatEntry: Identifiable {
        let id: Int
        let key1: String
        let value1: Int
        let key2: String?
        let value2: Int?
    }

    private var statPairs: [StatEntry] {
        let sorted = item.effectiveStats.sorted(by: { $0.key < $1.key })
        var result: [StatEntry] = []
        var i = 0
        while i < sorted.count {
            let k2: String? = (i + 1 < sorted.count) ? sorted[i + 1].key : nil
            let v2: Int? = (i + 1 < sorted.count) ? sorted[i + 1].value : nil
            result.append(StatEntry(id: i, key1: sorted[i].key, value1: sorted[i].value, key2: k2, value2: v2))
            i += 2
        }
        return result
    }

    @ViewBuilder
    private var statsSection: some View {
        let pairs = statPairs
        let bonus = item.upgradeBonusPerStat
        if !pairs.isEmpty {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "shield.fill", title: "STATS")

                ForEach(pairs) { pair in
                    HStack(spacing: LayoutConstants.spaceMD) {
                        statCell(key: pair.key1, value: pair.value1, bonus: bonus)
                        if let k2 = pair.key2, let v2 = pair.value2 {
                            statCell(key: k2, value: v2, bonus: bonus)
                        } else {
                            Spacer().frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    private func statCell(key: String, value: Int, bonus: Int) -> some View {
        HStack {
            Text(Item.statLabels[key] ?? key.capitalized)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            HStack(spacing: LayoutConstants.space2XS) {
                Text("+\(value)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                if bonus > 0 {
                    Text("(\(bonus))")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section 2.5: Durability

    @ViewBuilder
    private var durabilitySection: some View {
        if hasDurability {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "wrench.fill", title: isBroken ? "DURABILITY — BROKEN" : "DURABILITY")

                HStack(spacing: LayoutConstants.spaceSM) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(DarkFantasyTheme.bgTertiary)
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(durabilityGradient)
                                .frame(width: geo.size.width * durabilityFraction)
                                .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusSM))
                        }
                    }
                    .frame(height: 12)
                    .accessibilityLabel("Durability progress")
                    .accessibilityValue("\(item.durability ?? 0) of \(item.maxDurability ?? 0)")

                    Text("\(item.durability ?? 0)/\(item.maxDurability ?? 0)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(durabilityColor)
                        .monospacedDigit()
                        .accessibilityLabel("Durability: \(item.durability ?? 0) of \(item.maxDurability ?? 0)")
                        .accessibilityElement(children: .ignore)
                }

                if isBroken {
                    Text("This item is broken and cannot be equipped. Repair it first.")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    // MARK: - Section 3: Comparison

    @ViewBuilder
    private var comparisonSection: some View {
        if let compared = comparedItem {
            let itemStats = item.effectiveStats
            let comparedStats = compared.effectiveStats
            let allKeys = Set(itemStats.keys).union(Set(comparedStats.keys))
            let deltas = allKeys.compactMap { key -> (String, Int)? in
                let val = itemStats[key] ?? 0
                let comp = comparedStats[key] ?? 0
                let delta = val - comp
                return delta != 0 ? (key, delta) : nil
            }.sorted(by: { $0.0 < $1.0 })

            if !deltas.isEmpty {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    sectionHeader(icon: "arrow.left.arrow.right", title: "VS. EQUIPPED")

                    ForEach(deltas, id: \.0) { key, delta in
                        HStack {
                            Text(Item.statLabels[key] ?? key.capitalized)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            Spacer()
                            HStack(spacing: LayoutConstants.spaceXS) {
                                Text(delta > 0 ? "▲" : "▼")
                                    .font(.system(size: 10)) // emoji text — keep as is
                                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            }
                            .foregroundStyle(delta > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.cardPadding)
                .padding(.vertical, LayoutConstants.spaceMD)

                sectionDivider
            }
        }
    }

    // MARK: - Section 4: Effects

    @ViewBuilder
    private var effectsSection: some View {
        let hasSpecial = item.specialEffect.map { !$0.isEmpty } ?? false
        let hasPassive = item.uniquePassive.map { !$0.isEmpty } ?? false

        if hasSpecial || hasPassive {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                if let special = item.specialEffect, !special.isEmpty {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                        Text(special)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                }
                if let passive = item.uniquePassive, !passive.isEmpty {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.cyan)
                        Text(passive)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    // MARK: - Section 5: Economy

    @ViewBuilder
    private var economySection: some View {
        let buy = item.buyPrice ?? 0
        let sell = item.sellPrice ?? 0
        if buy > 0 || sell > 0 {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "coins.circle.fill", title: "ECONOMY")

                HStack(spacing: LayoutConstants.spaceLG) {
                    if buy > 0 {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("Buy:")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            CurrencyDisplay(
                                gold: buy,
                                size: .mini,
                                currencyType: .gold,
                                animated: false
                            )
                        }
                    }
                    if sell > 0 {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("Sell:")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            CurrencyDisplay(
                                gold: sell,
                                size: .mini,
                                currencyType: .gold,
                                animated: false
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    // MARK: - Section 6: Upgrade Info

    @ViewBuilder
    private var upgradeInfoSection: some View {
        if canUpgrade {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "chart.line.uptrend.xyaxis", title: "UPGRADE")

                HStack {
                    Text("Max")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text("+10")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.upgradeBlue)
                    Text("(linear)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    if currentUpgradeLevel > 0 {
                        Spacer()
                        Text("Current: +\(currentUpgradeLevel)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    // MARK: - Section 7: Description

    @ViewBuilder
    private var descriptionSection: some View {
        let hasDesc = (item.description ?? "").isEmpty == false
        let hasSet = (item.setName ?? "").isEmpty == false
        let hasCatalogDebug: Bool = {
            #if DEBUG
            return (item.catalogId ?? "").isEmpty == false
            #else
            return false
            #endif
        }()
        if hasDesc || hasSet || hasCatalogDebug {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .italic()
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                if let setName = item.setName, !setName.isEmpty {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 10)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("Set: \(setName)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                }
                #if DEBUG
                if let catalogId = item.catalogId, !catalogId.isEmpty {
                    Text(catalogId)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.5))
                }
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let shop = shopMode {
                shopBuySection(shop)
            } else if showUpgradeConfirm {
                upgradeConfirmPanel
            } else if isBroken {
                repairButton(style: .primary)
            } else {
                if item.itemType == .consumable {
                    Button("USE") { HapticManager.medium(); onUse() }
                        .buttonStyle(.primary)
                } else if isEquipped {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Button("UNEQUIP") {
                            HapticManager.light()
                            SFXManager.shared.play(.uiUnequip)
                            onUnequip()
                        }
                        .buttonStyle(.secondary)
                        if isDamaged {
                            repairButton(style: .primary)
                        } else if canUpgrade {
                            Button("UPGRADE") { HapticManager.medium(); showUpgradeConfirm = true }
                                .buttonStyle(.primary)
                        }
                    }
                } else {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Button("EQUIP") {
                            HapticManager.medium()
                            SFXManager.shared.play(.uiEquip)
                            onEquip()
                        }
                        .buttonStyle(.secondary)
                        // Sell with confirmation for rare+ items
                        Button("SELL") {
                            HapticManager.light()
                            if item.rarity.tier >= 2 {
                                showSellConfirm = true
                            } else {
                                SFXManager.shared.play(.uiSell)
                                onSell()
                            }
                        }
                        .buttonStyle(.secondary)
                    }
                    if isDamaged {
                        repairButton(style: .secondary)
                    } else if canUpgrade {
                        Button("UPGRADE") { HapticManager.medium(); showUpgradeConfirm = true }
                            .buttonStyle(.secondary)
                    }
                }
            }
        }
        .confirmationDialog(
            "SELL \(item.displayName)?",
            isPresented: $showSellConfirm,
            titleVisibility: .visible
        ) {
            Button("Sell for \(item.sellPrice ?? 0) gold", role: .destructive) {
                SFXManager.shared.play(.uiSell)
                onSell()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This \(item.rarity.displayName) item will be lost permanently.")
        }
    }

    /// Reusable repair button with CurrencyDisplay (no emoji)
    @ViewBuilder
    private func repairButton(style: ButtonStyleType) -> some View {
        let label = HStack(spacing: LayoutConstants.spaceXS) {
            Text("REPAIR ·")
            CurrencyDisplay(gold: repairCost, size: .mini, currencyType: .gold, animated: false)
        }
        if style == .primary {
            Button {
                HapticManager.medium()
                onRepair()
            } label: { label }
            .buttonStyle(.primary)
        } else {
            Button {
                HapticManager.medium()
                onRepair()
            } label: { label }
            .buttonStyle(.secondary)
        }
    }

    private enum ButtonStyleType { case primary, secondary }

    @ViewBuilder
    private func shopBuySection(_ shop: ShopContext) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Price display — asset icons, no emoji
            CurrencyDisplay(
                gold: shop.isGemPurchase ? 0 : shop.price,
                gems: shop.isGemPurchase ? shop.price : nil,
                size: .compact,
                currencyType: shop.isGemPurchase ? .gems : .gold,
                animated: false
            )

            // Warnings
            if !shop.meetsLevel {
                Text("Requires Level \(shop.requiredLevel) (You: Level \(playerLevel))")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
            if !shop.canAfford {
                Text(shop.isGemPurchase ? "Not enough gems" : "Not enough gold")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }

            // BUY button — asset icons, no emoji
            Button {
                shop.onBuy()
            } label: {
                if shop.isBuying {
                    ProgressView()
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("BUY")
                        CurrencyDisplay(
                            gold: shop.isGemPurchase ? 0 : shop.price,
                            gems: shop.isGemPurchase ? shop.price : nil,
                            size: .mini,
                            currencyType: shop.isGemPurchase ? .gems : .gold,
                            animated: false
                        )
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(!shop.canAfford || !shop.meetsLevel || shop.isBuying)
            .opacity(shop.canAfford && shop.meetsLevel ? 1.0 : 0.5)
        }
    }

    // MARK: - Upgrade Confirm Panel

    @ViewBuilder
    private var upgradeConfirmPanel: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("+\(currentUpgradeLevel) → +\(currentUpgradeLevel + 1)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                Text("\(upgradeChance)% chance")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(upgradeChance == 100 ? DarkFantasyTheme.success : DarkFantasyTheme.textSecondary)
            }

            upgradeStatsPreview

            if currentUpgradeLevel >= 5 {
                Toggle(isOn: $useProtection) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "shield")
                                .font(.system(size: 10))
                            Text("Protection Scroll")
                        }
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        CurrencyDisplay(gold: 0, gems: 30, size: .mini, currencyType: .gems, animated: false)
                    }
                }
                .disabled(playerGems < 30)
                .tint(DarkFantasyTheme.purple)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                Button("CANCEL") {
                    showUpgradeConfirm = false
                    useProtection = false
                }
                .buttonStyle(.secondary)

                Button {
                    HapticManager.medium()
                    onUpgrade(useProtection)
                    showUpgradeConfirm = false
                    useProtection = false
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("UPGRADE ·")
                        CurrencyDisplay(gold: upgradeCost, size: .mini, currencyType: .gold, animated: false)
                    }
                }
                .buttonStyle(.primary)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Upgrade Stats Preview

    @ViewBuilder
    private var upgradeStatsPreview: some View {
        let stats = item.effectiveStats
        if !stats.isEmpty {
            VStack(spacing: LayoutConstants.spaceXS) {
                ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, currentValue in
                    HStack {
                        Text(Item.statLabels[key] ?? key.uppercased())
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                        Spacer()
                        Text("\(currentValue)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        Text("→")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("\(currentValue + 1)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("(+1)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.success.opacity(0.7))
                    }
                }
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.success.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.success.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Shared Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(.system(size: 12)) // SF Symbol icon — keep as is
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(title)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.2)
        }
    }

    private var sectionDivider: some View {
        EtchedGroove()
            .padding(.horizontal, LayoutConstants.cardPadding)
    }

    private func badgePill(_ text: String, style: BadgeStyle) -> some View {
        Text(text)
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
            .foregroundStyle(style == .rarity ? rarityColor : DarkFantasyTheme.textSecondary)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                Capsule()
                    .fill(style == .rarity ? rarityColor.opacity(0.15) : DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Capsule()
                    .stroke(style == .rarity ? rarityColor.opacity(0.4) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
    }

    private enum BadgeStyle { case secondary, rarity }
}
