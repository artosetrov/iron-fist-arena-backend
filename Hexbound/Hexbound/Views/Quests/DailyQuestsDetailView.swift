import SwiftUI

struct DailyQuestsDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DailyQuestsViewModel?
    @State private var showQuestBurst = false
    @State private var burstQuestId: String?
    @State private var appearCount = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    // Reset timer
                    Text(vm.resetTimeText)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(.top, LayoutConstants.spaceSM)
                        .accessibilityLabel("Daily quests reset: \(vm.resetTimeText)")

                    if vm.errorMessage != nil {
                        ErrorStateView.loadFailed { Task { await vm.loadQuests() } }
                    } else if vm.isLoading && vm.quests.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonQuestCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                    } else if vm.quests.isEmpty {
                        EmptyStateView.questsComplete
                    } else {
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceSM) {
                                // Bonus panel
                                bonusPanel(vm: vm)

                                // Quest cards
                                ForEach(Array(vm.quests.enumerated()), id: \.element.id) { index, quest in
                                    questCard(quest, vm: vm)
                                        .staggeredAppear(index: index)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.vertical, LayoutConstants.spaceSM)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .onAppear {
            if vm == nil { vm = DailyQuestsViewModel(appState: appState) }
            appearCount += 1
        }
        .task(id: appearCount) {
            // Reload quests every time view appears (e.g., after PvP/dungeon)
            guard appearCount > 0 else { return }
            await vm?.loadQuests()
        }
    }

    // MARK: - Helpers

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    // MARK: - Bonus Panel

    @ViewBuilder
    private func bonusPanel(vm: DailyQuestsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Complete All \(vm.quests.count) Quests")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .accessibilityLabel("Daily quest completion challenge")

            // Progress
            HStack(spacing: LayoutConstants.spaceSM) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                            .fill(DarkFantasyTheme.bgTertiary)
                        let fraction = vm.quests.isEmpty ? 0.0 : max(0, min(1, Double(vm.completedCount) / Double(vm.quests.count)))
                        RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                            .fill(DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 8)
                .accessibilityLabel("Quest completion progress")
                .accessibilityValue("\(vm.completedCount) of \(vm.quests.count) quests complete")

                Text("\(vm.completedCount)/\(vm.quests.count)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(width: 30)
                    .accessibilityElement(children: .ignore)
            }

            Text("Bonus: +500 Gold, +10 Gems")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            if vm.bonusClaimedToday {
                VStack(spacing: 4) {
                    Text("✓ Claimed")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.success)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("Next bonus: \(timeUntilReset())")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightSM + 10)
                .background(DarkFantasyTheme.success.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
            } else if vm.canClaimBonus {
                Button {
                    Task { await vm.claimBonus() }
                } label: {
                    if vm.isClaimingBonus {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text("CLAIM BONUS")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isClaimingBonus)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Quest Type → Destination Mapping

    private func destinationRoute(for quest: Quest) -> AppRoute? {
        switch quest.type {
        case "pvp_wins":
            return .arena
        case "dungeons_complete":
            return .dungeonSelect
        case "gold_spent":
            return .shop
        case "consumable_use", "item_upgrade":
            return .hero
        case "shell_game_play":
            return .shellGame
        case "gold_mine_collect":
            return .goldMine
        default:
            return nil
        }
    }

    // MARK: - Quest Card

    @ViewBuilder
    private func questCard(_ quest: Quest, vm: DailyQuestsViewModel) -> some View {
        let isClaiming = vm.claimingQuestId == quest.id
        let destination = destinationRoute(for: quest)

        questCardContent(quest, vm: vm, isClaiming: isClaiming, destination: destination)
        .overlay {
            if showQuestBurst && burstQuestId == quest.id {
                GeometryReader { geo in
                    RewardBurstView(style: .claim, isActive: $showQuestBurst)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Quest Card Content

    /// Separates navigation (outer button) from claim action to avoid button-in-button tap interception.
    /// When quest.canClaim == true, the card body is NOT wrapped in a navigation button —
    /// only the Claim button is interactive. Otherwise, the whole card is a navigation button.
    @ViewBuilder
    private func questCardContent(_ quest: Quest, vm: DailyQuestsViewModel, isClaiming: Bool, destination: AppRoute?) -> some View {
        let cardBody = questCardBody(quest, vm: vm, isClaiming: isClaiming, destination: destination)

        if quest.canClaim || quest.rewardClaimed {
            // No outer navigation button — Claim button handles interaction,
            // or quest is already done (no interaction needed)
            cardBody
        } else if let destination {
            // Quest not yet complete — whole card navigates to relevant screen
            Button {
                if destination == .shop {
                    appState.shopInitialTab = 0
                }
                appState.mainPath.append(destination)
            } label: {
                cardBody
            }
            .buttonStyle(QuestCardButtonStyle())
        } else {
            // No destination, not claimable — static card
            cardBody
        }
    }

    @ViewBuilder
    private func questCardBody(_ quest: Quest, vm: DailyQuestsViewModel, isClaiming: Bool, destination: AppRoute?) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Icon
            Text(quest.icon)
                .font(.system(size: 28)) // emoji text — keep as is
                .frame(width: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(quest.rewardClaimed ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textPrimary)

                Text(quest.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(2)

                // Progress bar
                HStack(spacing: LayoutConstants.spaceSM) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.bgTertiary)
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(quest.completed ? DarkFantasyTheme.success : DarkFantasyTheme.cyan)
                                .frame(width: geo.size.width * max(0, min(1, quest.progressFraction)))
                        }
                    }
                    .frame(height: 6)

                    Text("\(quest.progress)/\(quest.target)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 36, alignment: .trailing)
                }

                // Rewards
                Text("\(quest.rewardGold) Gold  \(quest.rewardXp) XP")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            Spacer(minLength: 4)

            // Right side: Claim button or navigation chevron
            VStack(spacing: 6) {
                if quest.rewardClaimed {
                    Text("Done")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.success)
                } else if quest.canClaim {
                    Button {
                        HapticManager.success()
                        SFXManager.shared.play(.uiQuestComplete)
                        showQuestBurst = true
                        burstQuestId = quest.id
                        Task { await vm.claimQuest(quest) }
                    } label: {
                        if isClaiming {
                            ProgressView().tint(DarkFantasyTheme.textOnGold).scaleEffect(0.8)
                        } else {
                            Text("Claim")
                        }
                    }
                    .buttonStyle(.compactPrimary)
                    .disabled(isClaiming)
                }

                // Navigation chevron — shows destination is tappable
                if destination != nil && !quest.rewardClaimed && !quest.canClaim {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold)) // SF Symbol icon — keep as is
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(quest.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.2)
                    : quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                    : DarkFantasyTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .opacity(quest.rewardClaimed ? 0.7 : 1.0)
        .contentShape(Rectangle())
    }
}

// MARK: - Quest Card Press Style

struct QuestCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}
