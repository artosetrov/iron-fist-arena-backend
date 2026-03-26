import SwiftUI

/// Full-screen sheet showing dungeon description, lore, and boss list with avatars
struct DungeonInfoSheet: View {
    let dungeon: DungeonInfo
    var defeatedCount: Int = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var selectedBoss: BossInfo?

    private var currentStamina: Int {
        appState.currentCharacter?.currentStamina ?? 0
    }

    private var themeColor: Color { dungeon.themeColor }

    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgDungeonGradient
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Divider
                    sectionDivider

                    // Lore / Description
                    loreSection

                    sectionDivider

                    // Dungeon Stats
                    statsSection

                    sectionDivider

                    // Boss List with avatars
                    bossListSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceLG)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .padding(LayoutConstants.space2XL)
            }
            .buttonStyle(.plain)
        }
        .sheet(item: $selectedBoss) { boss in
            BossDetailSheet(
                boss: boss,
                state: bossState(for: boss),
                bossIndex: (dungeon.bosses.firstIndex(where: { $0.id == boss.id }) ?? 0),
                stamina: currentStamina,
                energyCost: dungeon.energyCost,
                isFighting: false,
                onFight: {},
                onLootTap: { _ in }
            )
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(dungeon.icon)
                .font(.system(size: 56))

            Text(dungeon.name.uppercased())
                .font(DarkFantasyTheme.title(size: 28))
                .foregroundStyle(themeColor)
                .tracking(3)
                .multilineTextAlignment(.center)

            // Level range badge
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                    Text("Lv. \(dungeon.minLevel)–\(dungeon.maxLevel)")
                        .font(DarkFantasyTheme.section(size: 14))
                }
                .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text("·")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                    Text("\(dungeon.energyCost) Energy")
                        .font(DarkFantasyTheme.section(size: 14))
                }
                .foregroundStyle(DarkFantasyTheme.stamina)

                Text("·")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)

                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 12))
                    Text("\(dungeon.totalBosses) Bosses")
                        .font(DarkFantasyTheme.section(size: 14))
                }
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Lore

    @ViewBuilder
    private var loreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(icon: "book.fill", title: "LORE")

            Text(dungeon.description)
                .font(DarkFantasyTheme.body(size: 14).italic())
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineSpacing(4)

            // Extended lore based on dungeon
            Text(extendedLore)
                .font(DarkFantasyTheme.body(size: 13))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineSpacing(4)
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(icon: "chart.bar.fill", title: "DUNGEON INFO")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                statCard(label: "Level Range", value: "\(dungeon.minLevel)–\(dungeon.maxLevel)", icon: "arrow.up.right", color: themeColor)
                statCard(label: "Energy Cost", value: "\(dungeon.energyCost)", icon: "bolt.fill", color: DarkFantasyTheme.stamina)
                statCard(label: "Total Bosses", value: "\(dungeon.totalBosses)", icon: "person.3.fill", color: DarkFantasyTheme.textSecondary)
                statCard(label: "Rewards", value: dungeon.rewardIcons.joined(separator: " "), icon: "gift.fill", color: DarkFantasyTheme.goldBright)
            }
        }
    }

    private func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(label)
                    .font(DarkFantasyTheme.body(size: 11))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            Text(value)
                .font(DarkFantasyTheme.section(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(DarkFantasyTheme.textPrimary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .stroke(DarkFantasyTheme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Boss List (with avatars)

    private func bossState(for boss: BossInfo) -> BossState {
        if boss.id <= defeatedCount { return .defeated }
        if boss.id == defeatedCount + 1 { return .current }
        return .locked
    }

    @ViewBuilder
    private var bossListSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            sectionTitle(icon: "shield.fill", title: "BOSSES (\(defeatedCount)/\(dungeon.totalBosses))")

            ForEach(dungeon.bosses) { boss in
                let state = bossState(for: boss)

                HStack(spacing: LayoutConstants.spaceMS) {
                    // Boss avatar (portrait image or fallback)
                    ZStack {
                        if UIImage(named: boss.portraitImage) != nil {
                            Image(boss.portraitImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                        } else {
                            // Fallback: emoji on colored circle
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(themeColor.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(boss.emoji)
                                        .font(.system(size: 22))
                                )
                        }

                        // Defeated overlay
                        if state == .defeated {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(DarkFantasyTheme.bgAbyss.opacity(0.5))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(DarkFantasyTheme.success)
                                )
                        }

                        // Lock overlay
                        if state == .locked {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .fill(DarkFantasyTheme.bgAbyss.opacity(0.4))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                                )
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(
                                state == .current ? DarkFantasyTheme.gold :
                                state == .defeated ? DarkFantasyTheme.success.opacity(0.4) :
                                DarkFantasyTheme.borderSubtle,
                                lineWidth: state == .current ? 2 : 1
                            )
                    )

                    // Boss info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(boss.name)
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                                .foregroundStyle(
                                    state == .defeated ? DarkFantasyTheme.textTertiary :
                                    state == .current ? DarkFantasyTheme.goldBright :
                                    DarkFantasyTheme.textPrimary
                                )
                                .strikethrough(state == .defeated, color: DarkFantasyTheme.textTertiary)

                            Spacer()

                            // State badge
                            if state == .current {
                                Text("CURRENT")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                                    .padding(.horizontal, LayoutConstants.spaceXS)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(DarkFantasyTheme.gold))
                            } else {
                                Text("Lv. \(boss.level)")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                            }
                        }

                        // Lore text (2 lines)
                        Text(boss.description)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).italic())
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .lineLimit(2)

                        // HP bar mini
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(DarkFantasyTheme.danger)
                            Text("\(boss.hp) HP")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
                .padding(LayoutConstants.spaceSM)
                .background(
                    RadialGlowBackground(
                        baseColor: DarkFantasyTheme.bgSecondary,
                        glowColor: state == .current ? themeColor.opacity(0.08) : DarkFantasyTheme.bgTertiary,
                        glowIntensity: 0.3,
                        cornerRadius: LayoutConstants.panelRadius
                    )
                )
                .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
                .innerBorder(
                    cornerRadius: LayoutConstants.panelRadius - 2,
                    inset: 2,
                    color: state == .current ? themeColor.opacity(0.15) : DarkFantasyTheme.borderMedium.opacity(0.10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(
                            state == .current ? themeColor.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                            lineWidth: 1
                        )
                )
                .compositingGroup()
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.2), radius: 2, y: 1)
                .opacity(state == .locked ? 0.6 : 1.0)
                .onTapGesture {
                    if state != .locked {
                        HapticManager.light()
                        selectedBoss = boss
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(themeColor)
            Text(title)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(themeColor)
                .tracking(2)
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderSubtle)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    private var extendedLore: String {
        switch dungeon.id {
        case "training_camp":
            return "Generations of warriors have trained here, their sweat and blood seeping into the very stones. The arena\'s current master, the Arena Warden, tests all who seek to prove themselves worthy of entering the deeper dungeons. Only those who conquer all ten trials may advance to face the true horrors that await below."
        case "desecrated_catacombs":
            return "The catacombs were once a sacred burial ground for the noble houses of the old kingdom. When the Lich King Verath rose from death, he corrupted the sacred wards and turned the dead against the living. Now the tunnels writhe with restless spirits and undead horrors, all serving the will of their skeletal overlord."
        case "volcanic_forge":
            return "Long ago, the dwarven smiths of the Molten Clan built their greatest forge within the heart of an active volcano. When the mountain erupted, the forge absorbed the primal fire, creating a self-sustaining inferno. The creatures within have been tempered by millennia of heat, making them nearly indestructible. At its core, Pyrox the Eternal burns with the fury of creation itself."
        default:
            return "A dangerous place filled with powerful enemies and valuable treasure."
        }
    }
}

