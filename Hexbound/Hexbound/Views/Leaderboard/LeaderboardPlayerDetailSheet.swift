import SwiftUI

/// Full opponent profile sheet shown when tapping a leaderboard entry.
/// Fetches complete profile data (stats, equipment, PvP record) and displays
/// a rich card with action buttons (Challenge, Message, Add Friend).
struct LeaderboardPlayerDetailSheet: View {
    let entry: LeaderboardEntry
    let playerCharacter: Character
    let onChallenge: () -> Void
    let onMessage: () -> Void
    let onAddFriend: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(GameDataCache.self) private var cache

    @State private var profile: OpponentProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if isLoading {
                loadingState
            } else if let error = errorMessage {
                errorState(error)
            } else if let profile {
                profileContent(profile)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgPrimary)
        .presentationCornerRadius(20)
        .task {
            await loadProfile()
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ProgressView()
                .tint(DarkFantasyTheme.gold)
                .scaleEffect(1.2)
            Text("Loading profile...")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadProfile() }
            }
            .buttonStyle(.primary)
        }
        .padding(LayoutConstants.screenPadding)
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: OpponentProfile) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Portrait + Name
                portraitSection(profile)

                // HP Bar
                HPBarView(
                    currentHp: profile.currentHp,
                    maxHp: profile.maxHp,
                    size: .large,
                    label: "HP"
                )

                // PvP Section
                pvpSection(profile)

                // Equipment
                if let equipment = profile.equipment, !equipment.isEmpty {
                    equipmentSection(equipment)
                }

                // Base Stats
                baseStatsSection(profile)

                // Derived Stats
                derivedStatsSection(profile)

                // Action Buttons
                actionButtons

                Spacer(minLength: LayoutConstants.spaceLG)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Portrait

    private func portraitSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ZStack(alignment: .bottomTrailing) {
                AvatarImageView(
                    skinKey: profile.avatar,
                    characterClass: profile.characterClass,
                    size: 140
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXL))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                        .stroke(
                            LinearGradient(
                                colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldBright],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 12)

                // Level badge
                Text("Lv.\(profile.level)")
                    .font(DarkFantasyTheme.section(size: 12))
                    .foregroundStyle(DarkFantasyTheme.bgAbyss)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(Capsule().fill(DarkFantasyTheme.goldBright))
                    .offset(x: 4, y: 4)
            }

            Text(profile.characterName)
                .font(DarkFantasyTheme.title(size: 22))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: LayoutConstants.spaceSM) {
                Text(profile.characterClass.displayName.uppercased())
                    .font(DarkFantasyTheme.body(size: 13).bold())
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(1.5)

                if let prestige = profile.prestigeLevel, prestige > 0 {
                    Text("P\(prestige)")
                        .font(DarkFantasyTheme.section(size: 11))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(DarkFantasyTheme.cyan.opacity(0.15))
                                .overlay(Capsule().stroke(DarkFantasyTheme.cyan.opacity(0.3), lineWidth: 1))
                        )
                }
            }

            // Rank badge
            let rank = profile.pvpRank
            HStack(spacing: 4) {
                Text(rank.icon)
                    .font(.system(size: 14))
                Text(rank.rawValue)
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(rank.color)
            }
        }
    }

    // MARK: - PvP Section

    private func pvpSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("PVP")

            HStack(spacing: 0) {
                pvpStatCell(label: "Rating", value: "\(profile.pvpRating)", color: DarkFantasyTheme.gold)
                pvpDivider
                pvpStatCell(label: "Record", value: "\(profile.pvpWins)W / \(profile.pvpLosses)L", color: DarkFantasyTheme.textPrimary)
                pvpDivider
                pvpStatCell(
                    label: "Win Rate",
                    value: profile.pvpWins + profile.pvpLosses > 0
                        ? String(format: "%.0f%%", profile.winRate * 100)
                        : "—",
                    color: profile.winRate >= 0.5 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
                )
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func pvpStatCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: 11))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value)
                .font(DarkFantasyTheme.section(size: 15))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var pvpDivider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderSubtle)
            .frame(width: 1, height: 36)
    }

    // MARK: - Equipment Section

    private func equipmentSection(_ equipment: [Item]) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("EQUIPMENT")

            let columns = [
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
            ]

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceXS) {
                ForEach(equipment) { item in
                    equipmentSlotView(item)
                }
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func equipmentSlotView(_ item: Item) -> some View {
        VStack(spacing: 2) {
            // Item icon
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(height: 56)

                if let imageKey = item.imageKey {
                    Image(imageKey)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                // Rarity border
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(item.rarity.color, lineWidth: 1.5)
            }

            // Item name
            Text(item.displayName)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(item.rarity.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Base Stats

    private func baseStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("BASE STATS")

            let columns = [
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
            ]

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceXS) {
                baseStatRow(.strength, value: profile.strength ?? 0)
                baseStatRow(.agility, value: profile.agility ?? 0)
                baseStatRow(.vitality, value: profile.vitality ?? 0)
                baseStatRow(.endurance, value: profile.endurance ?? 0)
                baseStatRow(.intelligence, value: profile.intelligence ?? 0)
                baseStatRow(.wisdom, value: profile.wisdom ?? 0)
                baseStatRow(.luck, value: profile.luck ?? 0)
                baseStatRow(.charisma, value: profile.charisma ?? 0)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func baseStatRow(_ stat: StatType, value: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)

            Text(stat.fullName)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            Text("\(value)")
                .font(DarkFantasyTheme.section(size: 14))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
        )
    }

    // MARK: - Derived Stats

    private func derivedStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("DERIVED STATS")

            let columns = [
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
                GridItem(.flexible(), spacing: LayoutConstants.spaceXS),
            ]

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceXS) {
                derivedStatCell(
                    label: "Atk Power",
                    value: "\(profile.attackPower) \(profile.damageTypeName)",
                    color: damageTypeColor(profile.damageTypeName)
                )
                derivedStatCell(label: "Armor", value: "\(profile.armor ?? 0)", color: DarkFantasyTheme.textPrimary)
                derivedStatCell(label: "Magic Resist", value: "\(profile.magicResist ?? 0)", color: DarkFantasyTheme.purple)
                derivedStatCell(
                    label: "Crit Chance",
                    value: String(format: "%.1f%%", profile.critChance),
                    color: DarkFantasyTheme.danger
                )
                derivedStatCell(
                    label: "Dodge",
                    value: String(format: "%.1f%%", profile.dodgeChance),
                    color: DarkFantasyTheme.success
                )
            }
        }
        .padding(LayoutConstants.cardPadding)
        .panelCard()
    }

    private func derivedStatCell(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
        )
    }

    private func damageTypeColor(_ type: String) -> Color {
        switch type {
        case "Magical": DarkFantasyTheme.purple
        case "Poison": DarkFantasyTheme.success
        default: DarkFantasyTheme.danger
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            GoldDivider()

            Button(action: onChallenge) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "flame.fill")
                    Text("Challenge")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)

            HStack(spacing: LayoutConstants.spaceSM) {
                Button(action: onMessage) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "bubble.left.fill")
                        Text("Message")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)

                Button(action: onAddFriend) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Friend")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
            Spacer()
        }
    }

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: OpponentProfileResponse = try await APIClient.shared.get(
                APIEndpoints.characterProfile(entry.characterId)
            )
            profile = response.profile
        } catch {
            errorMessage = "Failed to load profile"
        }

        isLoading = false
    }
}
