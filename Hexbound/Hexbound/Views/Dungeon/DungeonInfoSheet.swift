import SwiftUI

/// Full-screen sheet showing dungeon description, lore, and boss list
struct DungeonInfoSheet: View {
    let dungeon: DungeonInfo
    @Environment(\.dismiss) private var dismiss

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

                    // Boss List
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
                    .padding(LayoutConstants.spaceMD)
            }
            .buttonStyle(.scalePress(0.85))
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
            RoundedRectangle(cornerRadius: 12)
                .fill(DarkFantasyTheme.textPrimary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DarkFantasyTheme.textPrimary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Boss List

    @ViewBuilder
    private var bossListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(icon: "shield.fill", title: "BOSSES")

            ForEach(dungeon.bosses) { boss in
                HStack(spacing: 12) {
                    // Boss number
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Text("\(boss.id)")
                            .font(DarkFantasyTheme.section(size: 14))
                            .foregroundStyle(themeColor)
                    }

                    // Boss info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(boss.name)
                                .font(DarkFantasyTheme.section(size: 14))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                            Spacer()
                            Text("Lv. \(boss.level)")
                                .font(DarkFantasyTheme.body(size: 11))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                        Text(boss.description)
                            .font(DarkFantasyTheme.body(size: 11).italic())
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .lineLimit(1)

                        // HP
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(DarkFantasyTheme.danger)
                            Text("\(boss.hp) HP")
                                .font(DarkFantasyTheme.body(size: 11))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if boss.id < dungeon.bosses.count {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                        .padding(.leading, 48)
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
