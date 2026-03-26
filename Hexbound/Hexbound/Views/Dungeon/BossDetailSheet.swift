import SwiftUI

/// Full boss detail modal — opened when tapping a DungeonBossCard.
/// Shows lore, HP, level, possible loot, and fight button.
struct BossDetailSheet: View {
    let boss: BossInfo
    let state: BossState
    let bossIndex: Int
    let stamina: Int
    let energyCost: Int
    let isFighting: Bool
    let onFight: () -> Void
    let onLootTap: (LootPreview) -> Void

    @Environment(\.dismiss) private var dismiss

    private var stateColor: Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success
        case .current: return DarkFantasyTheme.bossBorderPurple
        case .locked: return DarkFantasyTheme.lockedGray
        }
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // Boss portrait header
                    bossPortraitHeader

                    // Lore section
                    loreSection

                    GoldDivider()

                    // Stats section
                    statsSection

                    GoldDivider()

                    // Loot section
                    if !boss.loot.isEmpty {
                        lootSection
                    }

                    Spacer(minLength: LayoutConstants.spaceLG)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, state == .current ? 100 : LayoutConstants.spaceLG)
            }

            // Sticky fight button at bottom (only for current boss)
            if state == .current {
                VStack {
                    Spacer()
                    stickyFightButton
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgPrimary)
        .presentationCornerRadius(20)
    }

    // MARK: - Boss Portrait Header

    private var bossPortraitHeader: some View {
        ZStack(alignment: .bottom) {
            // Boss image
            Group {
                if UIImage(named: boss.fullImage) != nil {
                    Image(boss.fullImage)
                        .resizable()
                        .scaledToFill()
                } else if UIImage(named: boss.portraitImage) != nil {
                    Image(boss.portraitImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        DarkFantasyTheme.bgSecondary
                        Text(boss.emoji)
                            .font(.system(size: 80))
                    }
                }
            }
            .frame(height: 280)
            .frame(maxWidth: .infinity)
            .clipped()
            .opacity(state == .locked ? 0.4 : 1.0)

            // Bottom gradient fade
            LinearGradient(
                colors: [
                    .clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.6),
                    DarkFantasyTheme.bgPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .frame(maxWidth: .infinity)

            // Name + level overlay
            VStack(spacing: LayoutConstants.spaceXS) {
                // Status badge
                statusPill

                Text(boss.name.uppercased())
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(2)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 6)
                    .multilineTextAlignment(.center)

                HStack(spacing: LayoutConstants.spaceSM) {
                    // Boss tag
                    HStack(spacing: 4) {
                        Text("\u{2620}")
                            .font(.system(size: 12))
                        Text("BOSS")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                            .tracking(2)
                    }
                    .foregroundStyle(stateColor)

                    Text("•")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text("Level \(boss.level)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
            .padding(.bottom, LayoutConstants.spaceMD)
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: stateColor.opacity(0.1),
                glowIntensity: 0.3,
                cornerRadius: 0
            )
        )
    }

    @ViewBuilder
    private var statusPill: some View {
        switch state {
        case .defeated:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("DEFEATED")
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(Capsule().fill(DarkFantasyTheme.success))

        case .current:
            Text("READY TO FIGHT")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(Capsule().fill(DarkFantasyTheme.arenaRankGold))

        case .locked:
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                Text("LOCKED")
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(Capsule().fill(DarkFantasyTheme.lockedGray))
        }
    }

    // MARK: - Lore Section

    private var loreSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("LORE")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(boss.extendedLore)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody).italic())
                .foregroundStyle(DarkFantasyTheme.textBossDesc)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: stateColor.opacity(0.08))
                .compositingGroup()
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("BOSS STATS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: LayoutConstants.spaceSM
            ) {
                bossStatRow("Level", value: "\(boss.level)", color: DarkFantasyTheme.gold)
                bossStatRow("Hit Points", value: formatNumber(boss.hp), color: DarkFantasyTheme.danger)
                bossStatRow("Boss #", value: "\(boss.id) / 10", color: stateColor)
                bossStatRow("Drops", value: "\(boss.loot.count) items", color: DarkFantasyTheme.lootGold)
            }

            // HP bar
            VStack(spacing: LayoutConstants.space2XS) {
                HStack {
                    Text("HP")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Text(
                        state == .defeated
                            ? "0 / \(formatNumber(boss.hp))"
                            : "\(formatNumber(boss.hp)) / \(formatNumber(boss.hp))"
                    )
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)

                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.dungeonHpGradient)
                            .frame(width: geo.size.width * (state == .defeated ? 0 : 1.0))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
                .frame(height: 14)
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
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.08))
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
    }

    @ViewBuilder
    private func bossStatRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .monospacedDigit()
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

    // MARK: - Loot Section

    private var lootSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 12))
                    Text("POSSIBLE LOOT")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .tracking(1)
                }
                .foregroundStyle(DarkFantasyTheme.lootGold)

                Spacer()
            }

            // Loot cards — use ItemCardView for consistent look with shop/inventory
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.inventoryGap), count: LayoutConstants.inventoryCols),
                spacing: LayoutConstants.inventoryGap
            ) {
                ForEach(boss.loot) { lootItem in
                    ItemCardView(item: lootItem.toItem(), context: .loot) {
                        onLootTap(lootItem)
                    }
                }
            }
        }
    }

    // MARK: - Sticky Fight Button

    private var stickyFightButton: some View {
        let hasEnergy = stamina >= energyCost

        return VStack(spacing: 0) {
            // Top fade gradient
            LinearGradient(
                colors: [Color.clear, DarkFantasyTheme.bgPrimary.opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 20)

            VStack(spacing: LayoutConstants.spaceXS) {
                Button {
                    HapticManager.heavy()
                    onFight()
                } label: {
                    if isFighting {
                        ProgressView().tint(DarkFantasyTheme.textPrimary)
                    } else {
                        VStack(spacing: LayoutConstants.space2XS) {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Image(systemName: "bolt.shield.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("FIGHT BOSS")
                            }

                            HStack(spacing: LayoutConstants.spaceXS) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                Text("\(energyCost) Energy")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1))
                            }
                            .opacity(0.7)
                        }
                    }
                }
                .buttonStyle(.fight(accent: DarkFantasyTheme.arenaRankGold))
                .disabled(isFighting || !hasEnergy)

                if !hasEnergy {
                    Text("Not enough energy — \(stamina)/\(energyCost)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)
            .background(DarkFantasyTheme.bgPrimary.opacity(0.95))
            .overlay(alignment: .top) {
                FiligreeLine(
                    color: DarkFantasyTheme.gold.opacity(0.3),
                    notchColor: DarkFantasyTheme.gold.opacity(0.5),
                    notchCount: 5,
                    notchSize: 3
                )
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
