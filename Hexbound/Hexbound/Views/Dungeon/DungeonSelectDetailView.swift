import SwiftUI

struct DungeonSelectDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: DungeonSelectViewModel?
    @State private var isEnteringDungeon = false

    var body: some View {
        ZStack {
            // Background image with dark overlay
            GeometryReader { geo in
                Image("bg-dungeon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            if let vm {
                Group {
                if vm.isLoading && vm.dungeonProgress.isEmpty {
                    // Skeleton loading state
                    VStack(spacing: 0) {
                        staminaBar(vm: vm)
                        ScrollView {
                            LazyVStack(spacing: LayoutConstants.spaceMD) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonDungeonCard()
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.top, LayoutConstants.spaceSM)
                            .padding(.bottom, LayoutConstants.space2XL)
                        }
                    }
                } else if vm.errorMessage != nil {
                    ErrorStateView.loadFailed {
                        Task { await vm.loadProgress() }
                    }
                } else if vm.dungeons.isEmpty {
                    EmptyStateView.dungeonLocked
                } else {
                    dungeonWorldContent(vm: vm)
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
                Text("DUNGEONS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil { vm = DungeonSelectViewModel(appState: appState, cache: cache) }
            await vm?.loadProgress()
        }
        .overlay {
            if isEnteringDungeon {
                LoadingOverlay(message: "ENTERING DUNGEON")
            }
        }
    }

    // MARK: - World Content

    @ViewBuilder
    private func dungeonWorldContent(vm: DungeonSelectViewModel) -> some View {
        VStack(spacing: 0) {
            // Stamina bar
            staminaBar(vm: vm)

            // Dungeon cards (vertical scroll)
            ScrollView {
                LazyVStack(spacing: LayoutConstants.spaceMD) {
                    // Active quest banner
                    ActiveQuestBanner(questTypes: ["dungeons_complete"])
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    ForEach(Array(vm.dungeons.enumerated()), id: \.element.id) { index, dungeon in
                        dungeonCard(dungeon, vm: vm)
                            .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)
                .padding(.bottom, LayoutConstants.space2XL)
            }

            // Return to Hub button
            returnToHubButton
        }
    }

    // MARK: - Return to Hub

    @ViewBuilder
    private var returnToHubButton: some View {
        Button {
            HapticManager.selection()
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                Text("RETURN TO HUB")
            }
        }
        .buttonStyle(.primary)
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceMD)
    }

    // MARK: - Stamina Bar

    @ViewBuilder
    private func staminaBar(vm: DungeonSelectViewModel) -> some View {
        let current = vm.stamina
        let max = vm.maxStamina
        let fraction = max > 0 ? Double(current) / Double(max) : 0

        Button {
            vm.goToShop()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.stamina)
                    .accessibilityLabel("Stamina icon")
                    .accessibilityElement(children: .ignore)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(DarkFantasyTheme.staminaGradient)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 14)
                .accessibilityLabel("Stamina remaining")
                .accessibilityValue("\(current) of \(max)")

                Text("\(current)/\(max)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.stamina)
                    .monospacedDigit()
                    .accessibilityElement(children: .ignore)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .accessibilityLabel("Tap to purchase stamina")
                    .accessibilityElement(children: .ignore)
            }
            .padding(.horizontal, LayoutConstants.cardPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.stamina.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.stamina.opacity(0.3), lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.stamina.opacity(0.3), length: 12, thickness: 1.5)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.scalePress(0.97))
        .contentShape(Rectangle())
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceSM)
        .accessibilityLabel("Stamina bar, currently \(current) of \(max)")
        .accessibilityHint("Double tap to purchase stamina")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Dungeon Card

    @ViewBuilder
    private func dungeonCard(_ dungeon: DungeonInfo, vm: DungeonSelectViewModel) -> some View {
        let state = vm.stateFor(dungeon)
        let isLocked: Bool = {
            if case .locked = state { return true }
            return false
        }()
        let isCompleted: Bool = {
            if case .completed = state { return true }
            return false
        }()

        Button {
            if !isLocked && !isEnteringDungeon {
                HapticManager.selection()
                isEnteringDungeon = true
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    await MainActor.run {
                        vm.enterDungeon(dungeon)
                        isEnteringDungeon = false
                    }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Top section: artwork area with energy badge
                ZStack(alignment: .topLeading) {
                    // Artwork placeholder (gradient background)
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [
                                    dungeon.themeColor.opacity(isLocked ? 0.08 : 0.25),
                                    DarkFantasyTheme.bgSecondary,
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 140)
                        .overlay {
                            // Dungeon icon large
                            Text(dungeon.icon)
                                .font(.system(size: 56))
                                .opacity(isLocked ? 0.3 : 0.8)
                        }
                        .overlay(alignment: .topTrailing) {
                            // Completed badge
                            if isCompleted {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("COMPLETED")
                                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                                }
                                .foregroundStyle(DarkFantasyTheme.success)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .padding(.vertical, LayoutConstants.spaceXS)
                                .background(
                                    Capsule()
                                        .fill(DarkFantasyTheme.success.opacity(0.15))
                                )
                                .padding(LayoutConstants.spaceSM)
                            }
                        }

                    // Energy cost badge
                    if !isLocked {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(dungeon.energyCost)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        }
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            Capsule()
                                .fill(DarkFantasyTheme.bgAbyss.opacity(0.8))
                        )
                        .padding(LayoutConstants.spaceSM)
                    }

                    // Lock overlay
                    if isLocked {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(DarkFantasyTheme.bgScrim)
                            .frame(height: 140)
                            .overlay {
                                VStack(spacing: LayoutConstants.spaceSM) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                                    if case .locked(let req) = state {
                                        Text(req)
                                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                            .foregroundStyle(DarkFantasyTheme.stamina)
                                    }
                                }
                            }
                    }
                }

                // Bottom section: info
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    // Name + level
                    HStack {
                        Text(dungeon.name.uppercased())
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                            .foregroundStyle(isLocked ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textPrimary)
                            .accessibilityLabel("Dungeon: \(dungeon.name)")

                        Spacer()

                        Text("Lv. \(dungeon.minLevel)–\(dungeon.maxLevel)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .accessibilityLabel("Difficulty: Level \(dungeon.minLevel) to \(dungeon.maxLevel)")
                    }

                    // Description
                    Text(dungeon.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(2)

                    // Progress bar
                    progressRow(dungeon: dungeon, state: state, vm: vm)

                    // Reward icons
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Rewards:")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        ForEach(dungeon.rewardIcons, id: \.self) { icon in
                            Text(icon)
                                .font(.system(size: 16))
                                .opacity(isLocked ? 0.4 : 1.0)
                        }
                    }
                }
                .padding(LayoutConstants.cardPadding)
            }
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        isCompleted
                            ? DarkFantasyTheme.success.opacity(0.3)
                            : isLocked
                                ? DarkFantasyTheme.borderSubtle
                                : dungeon.themeColor.opacity(0.4),
                        lineWidth: isLocked ? 1 : 1.5
                    )
            )
            .cornerBrackets(color: isCompleted ? DarkFantasyTheme.success.opacity(0.3) : isLocked ? DarkFantasyTheme.borderSubtle.opacity(0.3) : dungeon.themeColor.opacity(0.3), length: 14, thickness: 1.5)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 8, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.97))
        .disabled(isLocked)
    }

    // MARK: - Progress Row

    @ViewBuilder
    private func progressRow(dungeon: DungeonInfo, state: DungeonState, vm: DungeonSelectViewModel) -> some View {
        let defeated = vm.defeatedCount(for: dungeon)
        let total = dungeon.totalBosses
        let fraction = total > 0 ? Double(defeated) / Double(total) : 0

        HStack(spacing: LayoutConstants.spaceSM) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(
                            fraction >= 1.0
                                ? DarkFantasyTheme.canonicalHpGradient(percentage: 1.0)
                                : DarkFantasyTheme.progressGradient
                        )
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeOut(duration: 0.5), value: defeated)
                }
            }
            .frame(height: 10)

            // Label
            Text("\(defeated)/\(total)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(
                    fraction >= 1.0
                        ? DarkFantasyTheme.success
                        : DarkFantasyTheme.textSecondary
                )
                .monospacedDigit()
        }
    }

}
