import SwiftUI

extension HeroDetailView {
    @ViewBuilder
    func equipmentBonusesCard(_ equippedItems: [Item]) -> some View {
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

    func computeBonuses(from items: [Item]) -> [String: Int] {
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
    func statsTabContent(_ char: Character, vm: CharacterViewModel) -> some View {
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
    func sessionStatsButton(charId: String) -> some View {
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
    func statCell(_ stat: StatType, vm: CharacterViewModel, char: Character) -> some View {
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
    func statsStickyBar(vm: CharacterViewModel) -> some View {
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
    func derivedRow(_ label: String, value: String, color: Color) -> some View {
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
    func respecStatsCard(vm: CharacterViewModel) -> some View {
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
    func buyStatPointsButton() -> some View {
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

}
