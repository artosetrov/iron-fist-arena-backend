import SwiftUI

extension ItemDetailSheet {
    // MARK: - Compact Header (72px icon + title + rarity + meta + class/level)

    @ViewBuilder
    var headerSection: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            headerIcon

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                rarityLabelRow
                titleText
                metaLine
                classLevelLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityHeaderLabel)
    }

    // MARK: Header — Icon (72×72 with rarity glow)

    @ViewBuilder
    var headerIcon: some View {
        ItemImageView(
            imageKey: item.resolvedImageKey,
            imageUrl: item.imageUrl,
            systemIcon: item.consumableIcon,
            systemIconColor: item.consumableIconColor,
            placeholderIcon: item.itemType.icon
        )
        .frame(width: 72, height: 72)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(rarityColor.opacity(0.5), lineWidth: 1)
        )
        .overlay {
            if hasDurability && durabilityFraction < 1.0 {
                DurabilityRingOverlay(
                    fraction: durabilityFraction,
                    cornerRadius: LayoutConstants.radiusMD
                )
            }
        }
        .shadow(color: rarityColor.opacity(0.25), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 4, y: 2)
        .compositingGroup()
        .accessibilityHidden(true)
    }

    // MARK: Header — Rarity label row ("● UNCOMMON")

    @ViewBuilder
    var rarityLabelRow: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Circle()
                .fill(rarityColor)
                .frame(width: 7, height: 7)
                .shadow(color: rarityColor.opacity(0.8), radius: 4)
            Text(item.rarity.displayName)
                .font(DarkFantasyTheme.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(rarityColor)
        }
    }

    // MARK: Header — Title

    @ViewBuilder
    var titleText: some View {
        Text(item.displayName)
            .font(DarkFantasyTheme.cardTitle)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Header — Meta line ("Weapon · Two-Handed")

    var metaLineString: String {
        let typeLabel = item.itemType.displayName
        // Hand info only applies to weapons. For non-weapons the suffix is
        // not meaningful (rings, armor, relics).
        guard item.itemType == .weapon else { return typeLabel }
        let hand = item.isTwoHanded == true ? "Two-Handed" : "One-Handed"
        return "\(typeLabel) · \(hand)"
    }

    @ViewBuilder
    var metaLine: some View {
        Text(metaLineString)
            .font(DarkFantasyTheme.body)
            .italic()
            .foregroundStyle(DarkFantasyTheme.textSecondary)
    }

    // MARK: Header — Class / Level line

    /// Combined class + level line. Colored red when eligibility fails
    /// (mirrors BUG-63 server-side checks so players see WHY equip is greyed out).
    @ViewBuilder
    var classLevelLine: some View {
        let parts = classLevelParts()
        HStack(spacing: 0) {
            Text(parts.text)
                .font(parts.isBlocked ? DarkFantasyTheme.body.bold() : DarkFantasyTheme.body.weight(.medium))
                .foregroundStyle(parts.isBlocked ? DarkFantasyTheme.danger : DarkFantasyTheme.goldDim)
                .shadow(
                    color: parts.isBlocked ? DarkFantasyTheme.danger.opacity(0.5) : Color.clear,
                    radius: parts.isBlocked ? 4 : 0
                )

            if let qty = item.quantity, qty > 1 {
                Text("  ×\(qty)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .padding(.top, 2)
    }

    /// Build the class/level string and determine whether to render it in danger color.
    func classLevelParts() -> (text: String, isBlocked: Bool) {
        let restriction = (item.classRestriction ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hasRestriction = !restriction.isEmpty && restriction != "none"
        let classPart = hasRestriction ? restriction.capitalized : nil
        let levelPart = "Lvl \(item.itemLevel)"
        let text = classPart.map { "\($0) · \(levelPart)" } ?? levelPart
        let blocked = shouldCheckEquipEligibility && (!levelMet || !classMet)
        return (text, blocked)
    }

    var accessibilityHeaderLabel: String {
        let rarity = item.rarity.displayName.lowercased()
        let type = item.itemType.displayName.lowercased()
        let hand = item.itemType == .weapon ? (item.isTwoHanded == true ? "two-handed" : "one-handed") : ""
        let qtyFragment = (item.quantity.map { $0 > 1 ? "quantity \($0)" : nil } ?? nil) ?? ""
        let restriction = item.classRestriction ?? ""
        let classFragment = (restriction.isEmpty || restriction == "none") ? "" : "\(restriction) only"
        return [
            item.displayName,
            rarity,
            type,
            hand,
            "level \(item.itemLevel)",
            classFragment,
            qtyFragment,
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    // MARK: - Effects Pill Row (special effect + unique passive)

    @ViewBuilder
    var effectsPillRow: some View {
        // Bug #12: consumable specialEffect is stale in DB — description is canonical.
        let hasSpecial = (item.itemType != .consumable)
            && (item.specialEffect.map { !$0.isEmpty } ?? false)
        let hasPassive = item.uniquePassive.map { !$0.isEmpty } ?? false

        if hasSpecial || hasPassive {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                if hasSpecial, let special = item.specialEffect {
                    effectPill(
                        icon: "sparkles",
                        text: special,
                        color: DarkFantasyTheme.goldBright
                    )
                }
                if hasPassive, let passive = item.uniquePassive {
                    effectPill(
                        icon: "bolt.fill",
                        text: passive,
                        color: DarkFantasyTheme.cyan
                    )
                }
            }
        }
    }

    @ViewBuilder
    func effectPill(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: LayoutConstants.iconSM)
            Text(text)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(color)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(color.opacity(DarkFantasyTheme.opacityLight))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(color.opacity(DarkFantasyTheme.opacityMild), lineWidth: 1)
        )
    }

    // MARK: - Flavor Section (description + optional set)

    @ViewBuilder
    var flavorSection: some View {
        let desc = (item.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let setName = (item.setName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !desc.isEmpty || !setName.isEmpty {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                if !desc.isEmpty {
                    Text(desc)
                        .font(DarkFantasyTheme.body)
                        .italic()
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !setName.isEmpty {
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image(systemName: "link")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("Set: \(setName)")
                            .font(DarkFantasyTheme.caption.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                    .accessibilityLabel("Part of \(setName) set")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Stats Chip Row (inline + flow)

    @ViewBuilder
    var statChipRow: some View {
        let stats = item.effectiveStats.sorted(by: { $0.key < $1.key })
        if !stats.isEmpty {
            let bonus = item.upgradeBonusPerStat
            let upgradeLevel = item.upgradeLevel ?? 0
            if stats.count <= 3 {
                HStack(alignment: .top, spacing: LayoutConstants.spaceLG) {
                    ForEach(stats, id: \.key) { key, value in
                        statChip(key: key, value: value, bonus: bonus, upgradeLevel: upgradeLevel)
                    }
                    if stats.count < 3 { Spacer(minLength: 0) }
                }
            } else {
                // 4+ stats — fall back to 2-column grid
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    ForEach(statChipPairs(stats), id: \.id) { pair in
                        HStack(alignment: .top, spacing: LayoutConstants.spaceLG) {
                            statChip(key: pair.k1, value: pair.v1, bonus: bonus, upgradeLevel: upgradeLevel)
                            if let k2 = pair.k2, let v2 = pair.v2 {
                                statChip(key: k2, value: v2, bonus: bonus, upgradeLevel: upgradeLevel)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }

    private struct StatChipPair: Identifiable {
        let id: Int
        let k1: String
        let v1: Int
        let k2: String?
        let v2: Int?
    }

    private func statChipPairs(_ stats: [(key: String, value: Int)]) -> [StatChipPair] {
        var result: [StatChipPair] = []
        var i = 0
        while i < stats.count {
            let k2 = i + 1 < stats.count ? stats[i + 1].key : nil
            let v2 = i + 1 < stats.count ? stats[i + 1].value : nil
            result.append(StatChipPair(id: i, k1: stats[i].key, v1: stats[i].value, k2: k2, v2: v2))
            i += 2
        }
        return result
    }

    @ViewBuilder
    func statChip(key: String, value: Int, bonus: Int, upgradeLevel: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            statChipIcon(key: key)
            VStack(alignment: .leading, spacing: 0) {
                Text(Item.statLabels[key] ?? key.capitalized)
                    .font(DarkFantasyTheme.caption.weight(.semibold))
                    .tracking(1.0)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)
                HStack(spacing: 2) {
                    Text("+\(value)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(upgradeLevel > 0 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold)
                        .monospacedDigit()
                    if upgradeLevel > 0 && bonus > 0 {
                        Text("(+\(bonus * upgradeLevel))")
                            .font(DarkFantasyTheme.caption.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.goldDim)
                            .monospacedDigit()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statChipA11y(key: key, value: value, bonus: bonus, upgradeLevel: upgradeLevel))
    }

    @ViewBuilder
    func statChipIcon(key: String) -> some View {
        let box = RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
        if let statType = StatType.allCases.first(where: { $0.apiKey == key }) {
            Image(statType.iconAsset)
                .resizable()
                .scaledToFit()
                .padding(4)
                .frame(width: 28, height: 28)
                .background(box.fill(DarkFantasyTheme.bgTertiary))
                .overlay(box.stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
        } else {
            Image(systemName: derivedStatSFSymbol(for: key))
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: 28, height: 28)
                .background(box.fill(DarkFantasyTheme.bgTertiary))
                .overlay(box.stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
        }
    }

    private func derivedStatSFSymbol(for key: String) -> String {
        switch key {
        case "damageMin", "damageMax": return "bolt.fill"
        case "critChance": return "scope"
        case "attackSpeed": return "speedometer"
        case "defense": return "shield.fill"
        case "hpBonus": return "heart.fill"
        case "manaBonus": return "drop.fill"
        default: return "circle.fill"
        }
    }

    private func statChipA11y(key: String, value: Int, bonus: Int, upgradeLevel: Int) -> String {
        let name = Item.statLabels[key] ?? key.capitalized
        if upgradeLevel > 0 && bonus > 0 {
            return "\(name) plus \(value), upgrade bonus plus \(bonus * upgradeLevel)"
        }
        return "\(name) plus \(value)"
    }

    // MARK: - Twin Meters (Durability | Upgrade)

    @ViewBuilder
    var twinMeters: some View {
        let showDurability = hasDurability
        let showUpgrade = item.itemType != .consumable
        if showDurability || showUpgrade {
            HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                if showDurability { durabilityMeter }
                if showUpgrade { upgradeMeter }
            }
        }
    }

    @ViewBuilder
    var durabilityMeter: some View {
        let dur = item.durability ?? 0
        let maxDur = item.maxDurability ?? 0
        let fraction = maxDur > 0 ? Double(dur) / Double(maxDur) : 0
        let showRepair = isDamaged && shopMode == nil && !viewMode
        meterPanel(
            label: isBroken ? "BROKEN" : "DURABILITY",
            labelColor: isBroken ? DarkFantasyTheme.danger : DarkFantasyTheme.textTertiary,
            valueText: "\(dur)/\(maxDur)",
            valueColor: durabilityColor,
            fraction: fraction,
            barGradient: durabilityGradient,
            barFillColor: durabilityColor,
            trailing: showRepair ? AnyView(repairInlineButton) : AnyView(EmptyView())
        )
        .accessibilityLabel("Durability \(dur) of \(maxDur)\(isBroken ? ", broken" : "")")
    }

    @ViewBuilder
    var upgradeMeter: some View {
        let level = item.upgradeLevel ?? 0
        let maxLevel = 10
        let fraction = min(1, Double(level) / Double(maxLevel))
        meterPanel(
            label: "UPGRADE",
            labelColor: DarkFantasyTheme.textTertiary,
            valueText: "+\(level)/+\(maxLevel)",
            valueColor: DarkFantasyTheme.goldBright,
            fraction: fraction,
            barGradient: LinearGradient(
                colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldBright],
                startPoint: .leading, endPoint: .trailing
            ),
            barFillColor: DarkFantasyTheme.gold,
            trailing: AnyView(EmptyView())
        )
        .accessibilityLabel("Upgrade level plus \(level), maximum plus \(maxLevel)")
    }

    @ViewBuilder
    private func meterPanel(
        label: String,
        labelColor: Color,
        valueText: String,
        valueColor: Color,
        fraction: Double,
        barGradient: LinearGradient,
        barFillColor: Color,
        trailing: AnyView
    ) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            HStack(alignment: .center, spacing: LayoutConstants.space2XS) {
                Text(label)
                    .font(DarkFantasyTheme.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(labelColor)
                Spacer(minLength: LayoutConstants.space2XS)
                Text(valueText)
                    .font(DarkFantasyTheme.caption.weight(.semibold))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                trailing
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgAbyss)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(barGradient)
                        .frame(width: geo.size.width * max(0, min(1, fraction)))
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        .shadow(color: barFillColor.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS + 2)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    /// Small wrench icon inline with the durability value. Tap → onRepair.
    /// Hidden in shop/view modes; visible when item is damaged.
    @ViewBuilder
    var repairInlineButton: some View {
        Button {
            HapticManager.medium()
            SFXManager.shared.play(.uiTap)
            onRepair()
        } label: {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(DarkFantasyTheme.caption.weight(.bold))
                .foregroundStyle(isBroken ? DarkFantasyTheme.danger : DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                .padding(4)
                .background(
                    Circle()
                        .fill((isBroken ? DarkFantasyTheme.danger : DarkFantasyTheme.gold).opacity(0.15))
                )
                .overlay(
                    Circle()
                        .stroke((isBroken ? DarkFantasyTheme.danger : DarkFantasyTheme.gold).opacity(0.4), lineWidth: 1)
                )
        }
        .accessibilityLabel("Repair — costs \(repairCost) gold")
    }

    // MARK: - Shared Helpers

    /// Subtle etched hairline between narrative (title/flavor) and
    /// mechanical (stats/meters) sections. The parent VStack already applies
    /// horizontal padding, so this renders edge-to-edge within that container.
    var sectionDivider: some View {
        EtchedGroove()
    }
}
