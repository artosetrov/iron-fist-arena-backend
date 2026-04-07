import SwiftUI

struct DailyQuestsDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
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
                        .font(DarkFantasyTheme.caption)
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.cyan)
            }
        }
        .onAppear {
            if vm == nil { vm = DailyQuestsViewModel(appState: appState, cache: cache) }
            appearCount += 1
        }
        .task(id: appearCount) {
            // Reload quests every time view appears (e.g., after PvP/dungeon)
            guard appearCount > 0 else { return }
            await vm?.loadQuests()
        }
    }

    // MARK: - Quest Icon Asset

    /// Returns the asset image name for a quest type.
    /// For `item_upgrade` uses the hero's avatar (dynamic).
    private func questIconAsset(for questType: String) -> String {
        switch questType {
        case "pvp_wins":          return "building-arena"
        case "dungeons_complete": return "building-dungeon"
        case "gold_spent":        return "building-shop"
        case "item_upgrade":
            return appState.currentCharacter?.avatar ?? "knight"
        case "consumable_use":    return "health-potion-medium"
        case "shell_game_play":   return "shell-cup"
        case "gold_mine_collect": return "building-gold-mine"
        default:                  return "icon-xp" // safe fallback
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

    // MARK: - Progress Formatting

    /// Compact progress text that never wraps. Uses K suffix for 1000+ values.
    private func progressText(progress: Int, target: Int) -> String {
        "\(compactNumber(progress))/\(compactNumber(target))"
    }

    private func compactNumber(_ n: Int) -> String {
        if n >= 10_000 {
            let k = Double(n) / 1000.0
            return k.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(k))K"
                : String(format: "%.1fK", k)
        }
        return "\(n)"
    }

    /// Reward label with asset icons — consistent across all quest cards.
    private func rewardLabel(gold: Int, xp: Int, gems: Int?) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(gold)")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            if xp > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-xp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(xp)")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            if let gems, gems > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("\(gems)")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.purple)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Bonus Panel

    @ViewBuilder
    private func bonusPanel(vm: DailyQuestsViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Complete All \(vm.quests.count) Quests")
                .font(DarkFantasyTheme.uiLabel)
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
                .frame(height: LayoutConstants.spaceSM)
                .accessibilityLabel("Quest completion progress")
                .accessibilityValue("\(vm.completedCount) of \(vm.quests.count) quests complete")

                Text("\(vm.completedCount)/\(vm.quests.count)")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityElement(children: .ignore)
            }

            Text("Bonus: +500 Gold, +10 Gems")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.goldBright)

            if vm.bonusClaimedToday {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("✓ Claimed")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.success)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("Next bonus: \(timeUntilReset())")
                            .font(DarkFantasyTheme.badge)
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
        .cardShadow()
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
            // Icon — asset image instead of emoji
            Image(questIconAsset(for: quest.type))
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(quest.title)
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(quest.rewardClaimed ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                Text(quest.description)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(2)

                // Progress bar + counter
                HStack(spacing: LayoutConstants.spaceXS) {
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

                    Text(progressText(progress: quest.progress, target: quest.target))
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                // Rewards
                rewardLabel(gold: quest.rewardGold, xp: quest.rewardXp, gems: quest.rewardGems)
            }

            Spacer(minLength: 4)

            // Right side: Claim button or navigation chevron
            VStack(spacing: LayoutConstants.spaceSM) {
                if quest.rewardClaimed {
                    Text("Done")
                        .font(DarkFantasyTheme.caption)
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
                        .font(DarkFantasyTheme.caption.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        // Ornamental card system (was flat RoundedRectangle — widget audit fix)
        .background(
            RadialGlowBackground(
                baseColor: quest.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: quest.rewardClaimed ? 0.2 : 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.12) : DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.2)
                    : quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                    : DarkFantasyTheme.borderSubtle,
                    lineWidth: quest.canClaim ? 1.5 : 1
                )
        )
        .cornerBrackets(
            color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.4)
                : quest.rewardClaimed ? DarkFantasyTheme.success.opacity(0.15)
                : DarkFantasyTheme.borderMedium.opacity(0.25),
            length: 14,
            thickness: 1.5
        )
        .compositingGroup()
        .shadow(color: quest.canClaim ? DarkFantasyTheme.cyan.opacity(0.15) : .clear, radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .brightness(quest.rewardClaimed ? -0.08 : 0)
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
