import SwiftUI

extension ItemDetailSheet {
    @ViewBuilder
    var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if viewMode {
                Button("CLOSE") { onClose() }
                    .buttonStyle(.secondary)
            } else if let shop = shopMode {
                shopBuySection(shop)
            } else if showUpgradeConfirm {
                upgradeConfirmPanel
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
                        if canUpgrade {
                            Button("UPGRADE") { HapticManager.medium(); showUpgradeConfirm = true }
                                .buttonStyle(.primary)
                        }
                    }
                } else {
                    // BUG-63: reason line shown ABOVE the button row when the
                    // item can't currently be equipped (level too low, wrong
                    // class, or broken). Mirrors the shop's "Requires Level X"
                    // warning so players know WHY the button is greyed out.
                    if let reason = equipBlockedReason {
                        Text(reason)
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Cannot equip: \(reason)")
                    }

                    HStack(spacing: LayoutConstants.spaceSM) {
                        if !isBroken {
                            Button("EQUIP") {
                                HapticManager.medium()
                                SFXManager.shared.play(equipSFX)
                                onEquip()
                            }
                            .buttonStyle(.secondary)
                            // BUG-63: SwiftUI `.disabled()` greys the button
                            // via the standard disabled environment — matches
                            // the shop's "can't buy" state for visual parity.
                            .disabled(!canEquipNow)
                        }
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

                        // Deposit to stash (only for unequipped items)
                        if let onDeposit, item.isEquipped != true {
                            Button {
                                HapticManager.light()
                                onDeposit()
                            } label: {
                                HStack(spacing: LayoutConstants.spaceXS) {
                                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                                    Text("STASH")
                                }
                            }
                            .buttonStyle(.secondary)
                        }
                    }
                    if canUpgrade {
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

    /// Bug #20: hard cap for a single purchase. Even if the player has 100k
    /// gold, one tap shouldn't let them buy 500 potions.
    private static let maxPurchaseQuantity: Int = 99

    /// Bug #20: compute the maximum quantity the player can afford in a single
    /// purchase of this consumable. Gem purchases always return 1 (single-buy).
    func maxAffordableQuantity(_ shop: ShopContext) -> Int {
        guard shop.isConsumable, !shop.isGemPurchase, shop.price > 0 else { return 1 }
        let affordable = shop.playerGold / shop.price
        let clamped = max(1, min(affordable, Self.maxPurchaseQuantity))
        return clamped
    }

    @ViewBuilder
    func shopBuySection(_ shop: ShopContext) -> some View {
        let showStepper = shop.isConsumable && !shop.isGemPurchase && shop.meetsLevel
        let maxQty = maxAffordableQuantity(shop)
        let effectiveQty = showStepper ? min(purchaseQuantity, max(1, maxQty)) : 1
        let totalPrice = shop.price * effectiveQty

        VStack(spacing: LayoutConstants.spaceSM) {
            // Quantity stepper (Bug #20) — only for stackable consumables
            if showStepper {
                quantityStepper(shop: shop, maxQty: maxQty)
            }

            // Price display — dynamically multiplied by quantity
            CurrencyDisplay(
                gold: shop.isGemPurchase ? 0 : totalPrice,
                gems: shop.isGemPurchase ? totalPrice : nil,
                size: .compact,
                currencyType: shop.isGemPurchase ? .gems : .gold,
                animated: false
            )

            // Warnings
            if !shop.meetsLevel {
                Text("Requires Level \(shop.requiredLevel) (You: Level \(playerLevel))")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
            if !shop.canAfford {
                Text(shop.isGemPurchase ? "Not enough gems" : "Not enough gold")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }

            // BUY button — asset icons, no emoji
            Button {
                shop.onBuy(effectiveQty)
            } label: {
                if shop.isBuying {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if showStepper && effectiveQty > 1 {
                            Text("BUY \(effectiveQty)×")
                        } else {
                            Text("BUY")
                        }
                        CurrencyDisplay(
                            gold: shop.isGemPurchase ? 0 : totalPrice,
                            gems: shop.isGemPurchase ? totalPrice : nil,
                            size: .mini,
                            currencyType: shop.isGemPurchase ? .gems : .gold,
                            animated: false,
                            textColorOverride: DarkFantasyTheme.textOnGold
                        )
                    }
                }
            }
            .buttonStyle(.primary)
            .disabled(!shop.canAfford || !shop.meetsLevel || shop.isBuying)
            .opacity(shop.canAfford && shop.meetsLevel ? 1.0 : 0.5)
        }
        .onAppear {
            // Reset quantity whenever the sheet opens for a new consumable.
            purchaseQuantity = 1
        }
    }

    /// Bug #20: compact quantity stepper for stackable consumables.
    /// Layout: [−]  Qty × label  [+]  with quick x5/x10 preset chips.
    @ViewBuilder
    func quantityStepper(shop: ShopContext, maxQty: Int) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceMD) {
                Button {
                    if purchaseQuantity > 1 {
                        HapticManager.light()
                        purchaseQuantity -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .fill(DarkFantasyTheme.bgTertiary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(purchaseQuantity <= 1)
                .opacity(purchaseQuantity <= 1 ? 0.4 : 1.0)
                .accessibilityLabel("Decrease quantity")

                VStack(spacing: 0) {
                    Text("×\(min(purchaseQuantity, max(1, maxQty)))")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("max \(maxQty)")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .frame(minWidth: 72)
                .accessibilityLabel("Quantity: \(min(purchaseQuantity, maxQty)), maximum \(maxQty)")

                Button {
                    if purchaseQuantity < maxQty {
                        HapticManager.light()
                        purchaseQuantity += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .fill(DarkFantasyTheme.bgTertiary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(purchaseQuantity >= maxQty)
                .opacity(purchaseQuantity >= maxQty ? 0.4 : 1.0)
                .accessibilityLabel("Increase quantity")
            }

            // Quick preset chips — only useful when player can afford them
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(quantityPresets(maxQty: maxQty), id: \.self) { preset in
                    quantityPresetChip(preset, maxQty: maxQty)
                }
            }
        }
    }

    /// Bug #20: compute unique, sorted preset quantities capped at maxQty.
    func quantityPresets(maxQty: Int) -> [Int] {
        let base = [1, 5, 10]
        var presets = base.filter { $0 <= maxQty }
        if maxQty > 10 && !presets.contains(maxQty) {
            presets.append(maxQty)
        }
        // Dedup + sort
        return Array(Set(presets)).sorted()
    }

    @ViewBuilder
    func quantityPresetChip(_ value: Int, maxQty: Int) -> some View {
        let isSelected = purchaseQuantity == value
        let label = (value == maxQty && value > 10) ? "MAX" : "×\(value)"
        Button {
            HapticManager.light()
            purchaseQuantity = min(value, maxQty)
        } label: {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(isSelected ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(DarkFantasyTheme.gold.opacity(isSelected ? 0.0 : 0.3), lineWidth: 1)
                )
        }
        .accessibilityLabel("Set quantity to \(value)")
    }

    // MARK: - Upgrade Confirm Panel

    @ViewBuilder
    var upgradeConfirmPanel: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("+\(currentUpgradeLevel) → +\(currentUpgradeLevel + 1)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                Text("\(upgradeChance)% chance")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(upgradeChance == 100 ? DarkFantasyTheme.success : DarkFantasyTheme.textSecondary)
            }

            upgradeStatsPreview

            if currentUpgradeLevel >= 5 {
                Toggle(isOn: $useProtection) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "shield")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                            Text("Protection Scroll")
                        }
                        .font(DarkFantasyTheme.body)
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
    var upgradeStatsPreview: some View {
        let stats = item.effectiveStats
        let upgradeIncrement = item.upgradeIncrementPerStat
        if !stats.isEmpty {
            VStack(spacing: LayoutConstants.spaceXS) {
                ForEach(stats.sorted(by: { $0.key < $1.key }), id: \.key) { key, currentValue in
                    HStack {
                        Text(Item.statLabels[key] ?? key.uppercased())
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                        Spacer()
                        Text("\(currentValue)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        Text("→")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("\(currentValue + upgradeIncrement)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("(+\(upgradeIncrement))")
                            .font(DarkFantasyTheme.body)
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

    func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(title)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.2)
        }
    }

    var sectionDivider: some View {
        EtchedGroove()
            .padding(.horizontal, LayoutConstants.cardPadding)
    }

    func badgePill(_ text: String, style: BadgeStyle) -> some View {
        let textColor: Color = {
            switch style {
            case .rarity: return rarityColor
            case .twoHanded: return DarkFantasyTheme.stamina
            case .secondary: return DarkFantasyTheme.textSecondary
            }
        }()
        let fillColor: Color = {
            switch style {
            case .rarity: return rarityColor.opacity(0.15)
            case .twoHanded: return DarkFantasyTheme.stamina.opacity(0.12)
            case .secondary: return DarkFantasyTheme.bgTertiary
            }
        }()
        let strokeColor: Color = {
            switch style {
            case .rarity: return rarityColor.opacity(0.4)
            case .twoHanded: return DarkFantasyTheme.stamina.opacity(0.35)
            case .secondary: return DarkFantasyTheme.borderSubtle
            }
        }()

        return HStack(spacing: LayoutConstants.space2XS) {
            if style == .twoHanded {
                Image(systemName: "arrow.left.arrow.right")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(textColor)
            }
            Text(text)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            Capsule()
                .fill(fillColor)
        )
        .overlay(
            Capsule()
                .stroke(strokeColor, lineWidth: 1)
        )
    }

    enum BadgeStyle { case secondary, rarity, twoHanded }
}
