import SwiftUI

/// Session summary — "Victory Ledger" (design 2026-10-15).
///
/// Order is by importance: the verdict (score + W/L run), where the player
/// stands on the ladder now, what they earned, what's left today, and a way
/// straight back into a fight. On-demand (Hero → Session Stats) and shown by
/// itself only after a series of fights (`AppState.leaveCombatToHub`).
struct SessionSummaryView: View {
    let characterId: String
    let onDismiss: () -> Void

    @Environment(AppState.self) private var appState
    @State private var vm: SessionSummaryViewModel?
    @State private var showLoot = false

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
                    .transaction { $0.animation = nil }
            } else {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
        .task {
            let newVM = SessionSummaryViewModel(characterId: characterId)
            vm = newVM
            await newVM.load()
        }
    }

    @ViewBuilder
    private func content(vm: SessionSummaryViewModel) -> some View {
        if vm.isLoading && vm.summary == nil {
            HexPulseLoader(.compact)
                .tint(DarkFantasyTheme.gold)
        } else if let summary = vm.summary {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: LayoutConstants.sectionGap) {
                        verdictHeader(summary)
                            .staggeredAppear(index: 0)
                        if let rating = summary.rating {
                            rankPanel(rating: rating, change: summary.ratingChange)
                                .staggeredAppear(index: 1)
                        }
                        rewardsRow(summary)
                            .staggeredAppear(index: 2)
                        if let quests = summary.quests, !quests.isEmpty {
                            questsPanel(quests)
                                .staggeredAppear(index: 3)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceLG)
                    .padding(.bottom, LayoutConstants.spaceMD)
                }
                actions
            }
            .sheet(isPresented: $showLoot) {
                lootSheet(summary.loot ?? [])
                    .presentationDetents([.medium, .large])
            }
        } else if vm.showsErrorState {
            ErrorStateView.loadFailed(message: vm.errorMessage) {
                Task { await vm.load() }
            }
            .accessibilityLabel("Session summary failed to load")
        }
    }

    // MARK: - Verdict

    private func verdictHeader(_ summary: SessionSummaryData) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("SESSION COMPLETE")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(4)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Text("\(summary.wins) – \(summary.losses)")
                .font(DarkFantasyTheme.combatCalloutLarge)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 14)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)
                .accessibilityLabel("\(summary.wins) wins, \(summary.losses) losses")

            Text(summary.verdict)
                .font(DarkFantasyTheme.section)
                .tracking(6)
                .foregroundStyle(DarkFantasyTheme.gold)

            if let results = summary.results, !results.isEmpty {
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(Array(results.suffix(8).enumerated()), id: \.offset) { _, r in
                        resultPip(isWin: r == "W")
                    }
                }
                .padding(.top, LayoutConstants.spaceXS)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Results: " + results.map { $0 == "W" ? "win" : "loss" }.joined(separator: ", "))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func resultPip(isWin: Bool) -> some View {
        let color = isWin ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        return Text(isWin ? "W" : "L")
            .font(DarkFantasyTheme.buttonLabelCompact)
            .foregroundStyle(isWin ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
            .frame(width: 30, height: 30)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(color.opacity(DarkFantasyTheme.opacityMild))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(color, lineWidth: 1.5)
            )
    }

    // MARK: - Rank

    private func rankPanel(rating: SessionRating, change: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            TierBadge(tierKey: rating.tierKey, division: rating.division, size: .large, label: rating.label)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack(alignment: .firstTextBaseline) {
                    Text(rating.label.uppercased())
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    if change != 0 {
                        Text("\(change > 0 ? "▲ +" : "▼ ")\(change)")
                            .font(DarkFantasyTheme.cardTitle)
                            .foregroundStyle(change > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * max(0.02, min(1, rating.progress)))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(rating.current) rating")
                    Spacer()
                    if let next = rating.nextLabel, let pts = rating.pointsToNext {
                        Text("\(pts) to \(next)")
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                }
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .ledgerPanel(highlighted: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rewards

    private func rewardsRow(_ summary: SessionSummaryData) -> some View {
        let loot = summary.loot ?? []
        return HStack(spacing: LayoutConstants.spaceSM) {
            rewardTile(icon: "icon-gold", value: summary.goldEarned, label: "Gold", color: DarkFantasyTheme.goldBright)
            rewardTile(icon: "icon-xp", value: summary.xpEarned, label: "XP", color: DarkFantasyTheme.textPrimary)

            Button {
                HapticManager.light()
                showLoot = true
            } label: {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-shop")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    Text("\(summary.itemsGained) loot")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text(loot.isEmpty ? "None" : "View ›")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(loot.isEmpty ? DarkFantasyTheme.textTertiaryAA : DarkFantasyTheme.gold)
                }
                .frame(maxWidth: .infinity, minHeight: 96)
                .ledgerPanel(highlighted: !loot.isEmpty)
            }
            .buttonStyle(.plain)
            .disabled(loot.isEmpty)
            .accessibilityLabel("\(summary.itemsGained) items looted")
            .accessibilityHint(loot.isEmpty ? "" : "Shows the items")
        }
    }

    private func rewardTile(icon: String, value: Int, label: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            HStack(spacing: 0) {
                Text("+").font(DarkFantasyTheme.cardTitle).foregroundStyle(color)
                NumberTickUpText(value: value, color: color, font: DarkFantasyTheme.cardTitle)
            }
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .ledgerPanel(highlighted: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Plus \(value) \(label)")
    }

    // MARK: - Quests

    private func questsPanel(_ quests: [SessionQuest]) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            HStack(alignment: .firstTextBaseline) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Spacer()
                Text("\(quests.filter(\.done).count) / \(quests.count)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            ForEach(quests) { quest in
                questRow(quest)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .ledgerPanel(highlighted: false)
    }

    private func questRow(_ quest: SessionQuest) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            ZStack {
                if quest.done {
                    Circle().fill(DarkFantasyTheme.success)
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.iconMini.bold())
                        .foregroundStyle(DarkFantasyTheme.bgPrimary)
                } else {
                    Circle().stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)
                }
            }
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)

            Text(quest.title)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(quest.done && !quest.claimed ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: LayoutConstants.spaceSM)

            if quest.done && !quest.claimed {
                Button("CLAIM") {
                    appState.mainPath.append(AppRoute.dailyQuests)
                }
                .buttonStyle(.primary)
                .frame(width: 96)
                .accessibilityLabel("Claim reward for \(quest.title)")
            } else if quest.claimed {
                Text("Claimed")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
            } else {
                Text("\(quest.progress) / \(quest.target)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .frame(minHeight: 36)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Button {
                // Summary is pushed from the hub root — go straight to the arena.
                appState.mainPath = NavigationPath()
                DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.navigationDelay) {
                    appState.mainPath.append(AppRoute.arena)
                }
            } label: {
                Text("FIGHT AGAIN")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)

            Button {
                onDismiss()
            } label: {
                Text("RETURN TO CITY")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Loot sheet

    private func lootSheet(_ loot: [SessionLoot]) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            Text("LOOT THIS SESSION")
                .font(DarkFantasyTheme.cardTitle)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.gold)
                .padding(.top, LayoutConstants.spaceLG)

            ScrollView {
                VStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(Array(loot.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: LayoutConstants.spaceMS) {
                            ItemImageView(imageKey: item.imageKey, imageUrl: nil)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                        .fill(DarkFantasyTheme.bgTertiary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                        .stroke(item.rarityColor.opacity(0.7), lineWidth: 1.5)
                                )
                            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                                Text(item.name)
                                    .font(DarkFantasyTheme.body)
                                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                                Text(item.rarity.uppercased())
                                    .font(DarkFantasyTheme.body)
                                    .foregroundStyle(item.rarityColor)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DarkFantasyTheme.bgSecondary.ignoresSafeArea())
    }
}

// MARK: - Panel style

private extension View {
    /// Standard ornamental panel; `highlighted` adds the gold rim + glow used
    /// for the rank panel and actionable tiles.
    func ledgerPanel(highlighted: Bool) -> some View {
        self
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: highlighted ? DarkFantasyTheme.bgElevated : DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 2,
                inset: 2,
                color: highlighted ? DarkFantasyTheme.gold.opacity(0.35) : DarkFantasyTheme.borderMedium.opacity(0.15)
            )
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(highlighted ? 0.45 : 0.25), length: 14, thickness: 1.5)
            .compositingGroup()
            .shadow(color: highlighted ? DarkFantasyTheme.gold.opacity(0.18) : .clear, radius: 10)
            .cardShadow()
    }
}
