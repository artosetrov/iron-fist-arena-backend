import SwiftUI

extension ItemDetailSheet {
    // MARK: - Section 1: Header

    @ViewBuilder
    var headerSection: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            // Item icon — no background, larger
            ItemImageView(
                imageKey: item.resolvedImageKey,
                imageUrl: item.imageUrl,
                systemIcon: item.consumableIcon,
                systemIconColor: item.consumableIconColor,
                placeholderIcon: item.itemType.icon
            )
            .frame(width: 104, height: 104)
            .accessibilityLabel("Item icon for \(item.displayName)")
            .accessibilityElement(children: .ignore)

            // Item info
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(item.displayName)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(rarityColor)
                    .lineLimit(2)
                    .accessibilityLabel("Item name")

                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    badgePill(item.itemType.displayName, style: .secondary)
                    if item.isTwoHanded == true {
                        badgePill("Two-Handed", style: .twoHanded)
                    }
                    HStack(spacing: LayoutConstants.spaceXS) {
                        badgePill(item.rarity.displayName, style: .rarity)
                        HStack(spacing: 1) {
                            ForEach(0..<(item.rarity.tier + 1), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(DarkFantasyTheme.caption)
                                    .foregroundStyle(rarityColor)
                            }
                        }
                        .accessibilityLabel("\(item.rarity.tier + 1) stars")
                    }
                }
                .accessibilityLabel("\(item.itemType.displayName)\(item.isTwoHanded == true ? " two-handed" : "") \(item.rarity.displayName) rarity")
                .accessibilityElement(children: .combine)

                HStack(spacing: LayoutConstants.spaceXS) {
                    // BUG-63: level text glows red + bold when player level
                    // is below item's required level. Accompanied by the
                    // disabled EQUIP button below.
                    Text("Level \(item.itemLevel)")
                        .font(levelMet ? DarkFantasyTheme.body : DarkFantasyTheme.body.bold())
                        .foregroundStyle(levelMet ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.danger)
                        .shadow(
                            color: levelMet ? Color.clear : DarkFantasyTheme.danger.opacity(0.6),
                            radius: levelMet ? 0 : 4
                        )
                        .accessibilityLabel(levelMet
                            ? "Item level: \(item.itemLevel)"
                            : "Requires level \(item.itemLevel), you are level \(playerLevel)")

                    if let qty = item.quantity, qty > 1 {
                        Text("×\(qty)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .accessibilityLabel("Quantity: \(qty)")
                    }
                }

                // BUG-63: class restriction also turns danger-red + bold when
                // the player's class doesn't match. Kept gold-dim in the
                // "restriction exists but matches" case so players still see
                // what class the item is tagged for.
                if let restriction = item.classRestriction,
                   restriction != "none", !restriction.isEmpty {
                    Text("\(restriction.capitalized) only")
                        .font(classMet ? DarkFantasyTheme.body : DarkFantasyTheme.body.bold())
                        .foregroundStyle(classMet ? DarkFantasyTheme.goldDim : DarkFantasyTheme.danger)
                        .shadow(
                            color: classMet ? Color.clear : DarkFantasyTheme.danger.opacity(0.6),
                            radius: classMet ? 0 : 4
                        )
                        .accessibilityLabel(classMet
                            ? "Restricted to \(restriction)"
                            : "Wrong class: this item is \(restriction) only")
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

    struct StatEntry: Identifiable {
        let id: Int
        let key1: String
        let value1: Int
        let key2: String?
        let value2: Int?
    }

    var statPairs: [StatEntry] {
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
    var statsSection: some View {
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

    func statCell(key: String, value: Int, bonus: Int) -> some View {
        HStack {
            Text(Item.statLabels[key] ?? key.capitalized)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            HStack(spacing: LayoutConstants.space2XS) {
                Text("+\(value)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                if bonus > 0 {
                    Text("(\(bonus))")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Section 2.5: Durability

    @ViewBuilder
    var durabilitySection: some View {
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
                    .frame(height: LayoutConstants.spaceMS)
                    .accessibilityLabel("Durability progress")
                    .accessibilityValue("\(item.durability ?? 0) of \(item.maxDurability ?? 0)")

                    Text("\(item.durability ?? 0)/\(item.maxDurability ?? 0)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(durabilityColor)
                        .monospacedDigit()
                        .accessibilityLabel("Durability: \(item.durability ?? 0) of \(item.maxDurability ?? 0)")
                        .accessibilityElement(children: .ignore)
                }

                if isBroken {
                    Text("This item is broken and cannot be equipped. Repair it first.")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.danger)
                }

                // Repair button — inline, hugs content width
                if isDamaged && shopMode == nil && !viewMode {
                    if isBroken {
                        Button {
                            HapticManager.medium()
                            onRepair()
                        } label: {
                            repairButtonLabel
                        }
                        .buttonStyle(.primary)
                        .fixedSize()
                    } else {
                        Button {
                            HapticManager.medium()
                            onRepair()
                        } label: {
                            repairButtonLabel
                        }
                        .buttonStyle(.secondary)
                        .fixedSize()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    var repairButtonLabel: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(DarkFantasyTheme.body)
            Text("REPAIR")
            Text("·")
            CurrencyDisplay(gold: repairCost, size: .compact, currencyType: .gold, animated: false)
        }
    }

    // MARK: - Section 3: Comparison

    @ViewBuilder
    var comparisonSection: some View {
        let itemStats = item.effectiveStats
        let comparedStats = comparedItem?.effectiveStats ?? [:]
        let showComparison = comparedItem != nil || shopMode != nil
        let allKeys = Set(itemStats.keys).union(Set(comparedStats.keys))
        let deltas = allKeys.compactMap { key -> (String, Int)? in
            let val = itemStats[key] ?? 0
            let comp = comparedStats[key] ?? 0
            let delta = val - comp
            return delta != 0 ? (key, delta) : nil
        }.sorted(by: { $0.0 < $1.0 })

        if showComparison && !deltas.isEmpty {
            let title = comparedItem != nil ? "VS. EQUIPPED" : "STAT BONUS"
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "arrow.left.arrow.right", title: title)

                ForEach(deltas, id: \.0) { key, delta in
                    comparisonStatCell(key: key, delta: delta)
                }
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)

            sectionDivider
        }
    }

    /// Stat comparison cell matching LeaderboardPlayerDetailSheet style:
    /// icon + stat name + delta badge pill + current item value
    func comparisonStatCell(key: String, delta: Int) -> some View {
        let statType = StatType.allCases.first(where: { $0.apiKey == key })
        let deltaColor = delta > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        let arrow = delta > 0 ? "▲" : "▼"
        let label = delta > 0 ? "\(arrow)+\(delta)" : "\(arrow)\(delta)"
        let statName = Item.statLabels[key] ?? key.capitalized
        let itemValue = item.effectiveStats[key] ?? 0

        return HStack(spacing: LayoutConstants.spaceXS) {
            if let statType {
                Image(statType.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }

            Text(statName)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.statColor(for: key))
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(label)
                .font(DarkFantasyTheme.body.bold())
                .foregroundStyle(deltaColor)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(deltaColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(deltaColor.opacity(0.4), lineWidth: 1)
                        )
                )

            Text("+\(itemValue)")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Section 4: Effects

    @ViewBuilder
    var effectsSection: some View {
        // Bug #12: specialEffect for consumables is stale in DB (pre-rebalance
        // copies like "+50 stamina" while description already says "60"), and
        // the description line already communicates the effect. Hide the
        // specialEffect row for consumables to avoid contradiction.
        let hasSpecial = (item.itemType != .consumable)
            && (item.specialEffect.map { !$0.isEmpty } ?? false)
        let hasPassive = item.uniquePassive.map { !$0.isEmpty } ?? false
        let isTwoHanded = item.isTwoHanded == true

        if hasSpecial || hasPassive || isTwoHanded {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                if isTwoHanded {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.stamina)
                        Text("Two-Handed — occupies weapon + off-hand slot")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.stamina)
                    }
                    .accessibilityLabel("Two-handed weapon: occupies both weapon and off-hand slots")
                }
                if let special = item.specialEffect, !special.isEmpty {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "sparkles")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                        Text(special)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                }
                if let passive = item.uniquePassive, !passive.isEmpty {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "bolt.fill")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.cyan)
                        Text(passive)
                            .font(DarkFantasyTheme.body)
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
    var economySection: some View {
        let buy = item.buyPrice ?? 0
        let sell = item.sellPrice ?? 0
        if buy > 0 || sell > 0 {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "coins.circle.fill", title: "ECONOMY")

                // Sell price — primary (this is what matters when you own the item)
                if sell > 0 {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Sell:")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                        CurrencyDisplay(
                            gold: sell,
                            size: .compact,
                            currencyType: .gold,
                            animated: false
                        )
                    }
                }

                // Buy price — secondary/dimmed (already purchased)
                if buy > 0 {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("Buy:")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        CurrencyDisplay(
                            gold: buy,
                            size: .mini,
                            currencyType: .gold,
                            animated: false
                        )
                        .opacity(0.6)
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
    var upgradeInfoSection: some View {
        if canUpgrade {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                sectionHeader(icon: "chart.line.uptrend.xyaxis", title: "UPGRADE")

                HStack {
                    Text("Max")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text("+10")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.upgradeBlue)
                    Text("(linear)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    if currentUpgradeLevel > 0 {
                        Spacer()
                        Text("Current: +\(currentUpgradeLevel)")
                            .font(DarkFantasyTheme.body)
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
    var descriptionSection: some View {
        let hasDesc = (item.description ?? "").isEmpty == false
        let hasSet = (item.setName ?? "").isEmpty == false
        if hasDesc || hasSet {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(DarkFantasyTheme.body)
                        .italic()
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                if let setName = item.setName, !setName.isEmpty {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-gems")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("Set: \(setName)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                }
                // BUG-39 (QA 2026-04-10): debug catalog-key line removed.
                // Previously showed "debug: loot_<uuid>" under item description —
                // unprofessional in simulator/TestFlight builds and leaked the
                // internal data model. Use LLDB `po item.catalogId` if you need it.
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
    }

    // MARK: - Action Buttons

}
