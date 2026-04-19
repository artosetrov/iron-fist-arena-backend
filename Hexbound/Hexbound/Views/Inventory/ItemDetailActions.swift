import SwiftUI

extension ItemDetailSheet {
    // MARK: - Action Buttons — Orchestrator
    //
    // Contextual rules:
    //   • viewMode           → Close only
    //   • shopMode           → Buy (+ qty stepper for stackable consumables)
    //   • showUpgradeConfirm → Cancel / Upgrade panel
    //   • consumable         → Use (+ Sell)
    //   • isEquipped         → Unequip (+ Upgrade)
    //   • unequipped equippable → Equip (+ Stash / Upgrade / Sell)

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
            } else if item.itemType == .consumable {
                consumableActionRow
            } else if isEquipped {
                equippedActionRow
            } else {
                unequippedActionRow
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

    // MARK: - Row: Consumable (Use + Sell)

    @ViewBuilder
    var consumableActionRow: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Button("USE") {
                HapticManager.medium()
                onUse()
            }
            .buttonStyle(.primary)

            if (item.sellPrice ?? 0) > 0 {
                secondaryActionButton(
                    label: "SELL",
                    icon: nil,
                    trailingPrice: item.sellPrice ?? 0
                ) {
                    HapticManager.light()
                    if item.rarity.tier >= 2 {
                        showSellConfirm = true
                    } else {
                        SFXManager.shared.play(.uiSell)
                        onSell()
                    }
                }
            }
        }
    }

    // MARK: - Row: Equipped (Unequip + Upgrade)

    @ViewBuilder
    var equippedActionRow: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Button("UNEQUIP") {
                HapticManager.light()
                SFXManager.shared.play(.uiUnequip)
                onUnequip()
            }
            .buttonStyle(.primary)

            if canUpgrade {
                secondaryActionButton(
                    label: "UPGRADE",
                    icon: "chart.line.uptrend.xyaxis",
                    trailingPrice: nil
                ) {
                    HapticManager.medium()
                    showUpgradeConfirm = true
                }
            }
        }
    }

    // MARK: - Row: Unequipped Equippable (Equip + Stash/Upgrade/Sell)

    @ViewBuilder
    var unequippedActionRow: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // BUG-63: reason line above the CTA when equip is blocked.
            if let reason = equipBlockedReason {
                equipBlockedPill(reason: reason)
            }

            Button {
                HapticManager.medium()
                SFXManager.shared.play(equipSFX)
                onEquip()
            } label: {
                Text("EQUIP")
            }
            .buttonStyle(.primary)
            .disabled(!canEquipNow)
            .opacity(canEquipNow ? 1 : 0.5)

            secondaryButtonsGrid
        }
    }

    @ViewBuilder
    var secondaryButtonsGrid: some View {
        let slots = secondaryButtonSlots
        if !slots.isEmpty {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                    secondaryActionButton(
                        label: slot.label,
                        icon: slot.icon,
                        trailingPrice: slot.price,
                        action: slot.action
                    )
                }
            }
        }
    }

    /// Build the list of secondary slots (Stash / Upgrade / Sell) in the
    /// order Stash → Upgrade → Sell when all present. Slots hide themselves
    /// when their prerequisite closure/condition is missing.
    private var secondaryButtonSlots: [SecondarySlot] {
        var slots: [SecondarySlot] = []
        if let onDeposit, item.isEquipped != true {
            slots.append(SecondarySlot(
                label: "STASH",
                icon: "shippingbox.and.arrow.backward.fill",
                price: nil,
                action: {
                    HapticManager.light()
                    onDeposit()
                }
            ))
        }
        if canUpgrade {
            slots.append(SecondarySlot(
                label: "UPGRADE",
                icon: "chart.line.uptrend.xyaxis",
                price: nil,
                action: {
                    HapticManager.medium()
                    showUpgradeConfirm = true
                }
            ))
        }
        if (item.sellPrice ?? 0) > 0 {
            let price = item.sellPrice ?? 0
            slots.append(SecondarySlot(
                label: "SELL",
                icon: nil,
                price: price,
                action: {
                    HapticManager.light()
                    if item.rarity.tier >= 2 {
                        showSellConfirm = true
                    } else {
                        SFXManager.shared.play(.uiSell)
                        onSell()
                    }
                }
            ))
        }
        return slots
    }

    struct SecondarySlot {
        let label: String
        let icon: String?
        let price: Int?
        let action: () -> Void
    }

    // MARK: - Secondary Action Button (compact)

    /// Compact button that fits into a 3-up grid. Icon on left, label center,
    /// optional gold price on right. Uses `.secondary` button style chrome.
    @ViewBuilder
    func secondaryActionButton(
        label: String,
        icon: String?,
        trailingPrice: Int?,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: LayoutConstants.space2XS) {
                if let icon {
                    Image(systemName: icon)
                        .font(DarkFantasyTheme.caption.weight(.semibold))
                        .opacity(0.75)
                }
                Text(label)
                if let price = trailingPrice {
                    Text("\(price)")
                        .font(DarkFantasyTheme.caption.weight(.bold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.secondary)
    }

    @ViewBuilder
    func equipBlockedPill(reason: String) -> some View {
        Text(reason)
            .font(DarkFantasyTheme.body.bold())
            .foregroundStyle(DarkFantasyTheme.danger)
            .multilineTextAlignment(.center)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.danger.opacity(DarkFantasyTheme.opacityLight))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(DarkFantasyTheme.danger.opacity(0.3), lineWidth: 1)
            )
            .accessibilityLabel("Cannot equip: \(reason)")
    }

    // MARK: - Shop Buy Section
    //
    // Mockup-compliant: single column stack:
    //   [Qty stepper]   (only for stackable consumables)
    //   [TOTAL row]
    //   [Balance after] (when stepper shown)
    //   [Warnings]
    //   [BUY button]

    /// Bug #20: hard cap per-purchase quantity.
    private static let maxPurchaseQuantity: Int = 99

    /// Bug #20: compute the maximum quantity the player can afford.
    func maxAffordableQuantity(_ shop: ShopContext) -> Int {
        guard shop.isConsumable, !shop.isGemPurchase, shop.price > 0 else { return 1 }
        let affordable = shop.playerGold / shop.price
        return max(1, min(affordable, Self.maxPurchaseQuantity))
    }

    @ViewBuilder
    func shopBuySection(_ shop: ShopContext) -> some View {
        let showStepper = shop.isConsumable && !shop.isGemPurchase && shop.meetsLevel
        let maxQty = maxAffordableQuantity(shop)
        let effectiveQty = showStepper ? min(purchaseQuantity, max(1, maxQty)) : 1
        let totalPrice = shop.price * effectiveQty
        let balanceAfter = max(0, shop.playerGold - totalPrice)

        VStack(spacing: LayoutConstants.spaceSM) {
            if showStepper {
                quantityBlock(shop: shop, maxQty: maxQty)
            }

            totalRow(totalPrice: totalPrice, isGemPurchase: shop.isGemPurchase)

            if showStepper {
                balanceAfterRow(balanceAfter: balanceAfter)
            }

            if !shop.meetsLevel {
                shopWarning("Requires Level \(shop.requiredLevel) (You: Level \(playerLevel))")
            }
            if !shop.canAfford {
                shopWarning(shop.isGemPurchase ? "Not enough gems" : "Not enough gold")
            }

            Button {
                shop.onBuy(effectiveQty)
            } label: {
                if shop.isBuying {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("BUY")
                }
            }
            .buttonStyle(.primary)
            .disabled(!shop.canAfford || !shop.meetsLevel || shop.isBuying)
            .opacity(shop.canAfford && shop.meetsLevel ? 1.0 : 0.5)
        }
        .onAppear { purchaseQuantity = 1 }
    }

    @ViewBuilder
    func shopWarning(_ text: String) -> some View {
        Text(text)
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.danger)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    func totalRow(totalPrice: Int, isGemPurchase: Bool) -> some View {
        HStack {
            Text("TOTAL")
                .font(DarkFantasyTheme.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Spacer()
            CurrencyDisplay(
                gold: isGemPurchase ? 0 : totalPrice,
                gems: isGemPurchase ? totalPrice : nil,
                size: .compact,
                currencyType: isGemPurchase ? .gems : .gold,
                animated: false
            )
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
    }

    @ViewBuilder
    func balanceAfterRow(balanceAfter: Int) -> some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Spacer()
            Text("Balance after:")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            CurrencyDisplay(
                gold: balanceAfter,
                size: .mini,
                currencyType: .gold,
                animated: false
            )
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
    }

    @ViewBuilder
    func quantityBlock(shop: ShopContext, maxQty: Int) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("QUANTITY")
                    .font(DarkFantasyTheme.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
                HStack(spacing: LayoutConstants.space2XS) {
                    Text("max")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("\(maxQty)")
                        .font(DarkFantasyTheme.caption.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceXS)

            HStack(spacing: 0) {
                Button {
                    if purchaseQuantity > 1 {
                        HapticManager.light()
                        purchaseQuantity -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(DarkFantasyTheme.buttonLabel)
                        .foregroundStyle(purchaseQuantity > 1
                            ? DarkFantasyTheme.textPrimary
                            : DarkFantasyTheme.textDisabled)
                        .frame(width: LayoutConstants.buttonHeightMD,
                               height: LayoutConstants.buttonHeightMD)
                }
                .buttonStyle(.scalePress)
                .disabled(purchaseQuantity <= 1)
                .accessibilityLabel("Decrease quantity")

                Text("×\(min(purchaseQuantity, max(1, maxQty)))")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Quantity: \(min(purchaseQuantity, maxQty)), maximum \(maxQty)")

                Button {
                    if purchaseQuantity < maxQty {
                        HapticManager.light()
                        purchaseQuantity += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(DarkFantasyTheme.buttonLabel)
                        .foregroundStyle(purchaseQuantity < maxQty
                            ? DarkFantasyTheme.textPrimary
                            : DarkFantasyTheme.textDisabled)
                        .frame(width: LayoutConstants.buttonHeightMD,
                               height: LayoutConstants.buttonHeightMD)
                }
                .buttonStyle(.scalePress)
                .disabled(purchaseQuantity >= maxQty)
                .accessibilityLabel("Increase quantity")
            }
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(
                cornerRadius: LayoutConstants.panelRadius,
                topHighlight: 0.06,
                bottomShadow: 0.10
            )
            .innerBorder(
                cornerRadius: LayoutConstants.panelRadius - 2,
                inset: 2,
                color: DarkFantasyTheme.borderMedium.opacity(0.15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.4), length: 10, thickness: 1)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)

            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(quantityPresets(maxQty: maxQty), id: \.self) { preset in
                    quantityPresetChip(preset, maxQty: maxQty)
                }
            }
        }
    }

    func quantityPresets(maxQty: Int) -> [Int] {
        let base = [1, 3, 5]
        var presets = base.filter { $0 <= maxQty }
        if maxQty > (base.last ?? 0) && !presets.contains(maxQty) {
            presets.append(maxQty)
        }
        return Array(Set(presets)).sorted()
    }

    @ViewBuilder
    func quantityPresetChip(_ value: Int, maxQty: Int) -> some View {
        let isSelected = purchaseQuantity == value
        let isMax = value == maxQty && value > 5
        let label = isMax ? "MAX" : "×\(value)"
        let chipColor: Color = isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary

        Button {
            HapticManager.light()
            purchaseQuantity = min(value, maxQty)
        } label: {
            Text(label)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.compactOutline(color: chipColor, fillOpacity: isSelected ? 0.18 : 0.04))
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
}
