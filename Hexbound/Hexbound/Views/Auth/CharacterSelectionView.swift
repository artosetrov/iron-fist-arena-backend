import SwiftUI

/// Character selection screen — shown after login when user has 2+ heroes.
/// Cards use the same arena-style design as `ArenaOpponentCard`:
/// full-bleed avatar, vignette, level badge, class pill, rating, glass stat pills.
struct CharacterSelectionView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm = CharacterSelectionViewModel()
    @State private var enterPressed = false
    @State private var enterGlow = false

    var body: some View {
        @Bindable var state = appState
        NavigationStack(path: $state.authPath) {
            ZStack {
                // Background — radial glow like hub
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                RadialGradient(
                    colors: [
                        DarkFantasyTheme.bgTertiary.opacity(0.6),
                        DarkFantasyTheme.bgPrimary,
                        DarkFantasyTheme.bgAbyss
                    ],
                    center: .init(x: 0.5, y: 0.15),
                    startRadius: 20,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    DiamondDividerMotif()
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.vertical, LayoutConstants.spaceXS)

                    if appState.isGuest {
                        guestBanner
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceSM)
                    }

                    contentArea
                    bottomCTA
                }

                // Enter Game overlay
                if enterPressed {
                    enterGameOverlay
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .onboarding: OnboardingDetailView()
                case .register: RegisterDetailView()
                default: PlaceholderView()
                }
            }
        }
        .task {
            // Load skins early so AvatarImageView can resolve portraits
            if cache.skins.isEmpty {
                if let response: AppearancesResponse = try? await APIClient.shared.get(APIEndpoints.appearances) {
                    cache.cacheSkins(response.skins)
                }
            }
            await vm.loadCharacters()
        }
        .onChange(of: appState.authPath.count) { oldCount, newCount in
            // Refresh character list when returning from onboarding (new hero created)
            if newCount == 0 && oldCount > 0 {
                Task { await vm.loadCharacters() }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text("CHOOSE YOUR HERO")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)

            Text("Select a hero to enter the world")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if vm.isLoading && vm.characters.isEmpty {
            loadingState
        } else if let error = vm.error, vm.characters.isEmpty {
            errorState(error)
        } else if vm.characters.isEmpty {
            emptyState
        } else {
            heroGrid
        }
    }

    // MARK: - Hero Grid (arena-style 2-column)

    private var heroGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: LayoutConstants.arenaCardGap),
                    GridItem(.flexible(), spacing: LayoutConstants.arenaCardGap)
                ],
                spacing: LayoutConstants.arenaCardGap
            ) {
                ForEach(Array(vm.characters.enumerated()), id: \.element.id) { index, character in
                    HeroSelectionCard(
                        character: character,
                        isSelected: character.id == vm.selectedCharacterId,
                        onSelect: {
                            HapticManager.light()
                            SFXManager.shared.play(.uiTap)
                            vm.selectedCharacterId = character.id
                        }
                    )
                    .staggeredAppear(index: index)
                }

                // Create hero placeholder card
                if vm.canCreateNewHero {
                    createHeroCard
                        .staggeredAppear(index: vm.characters.count)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
    }

    // MARK: - Create Hero Card

    private var createHeroCard: some View {
        Button {
            HapticManager.medium()
            SFXManager.shared.play(.uiTap)
            appState.authPath.append(AppRoute.onboarding)
        } label: {
            GeometryReader { geo in
                let width = geo.size.width
                let height = width * 1.4

                VStack(spacing: LayoutConstants.spaceSM) {
                    ZStack {
                        Circle()
                            .fill(DarkFantasyTheme.bgTertiary)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)
                            )

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }

                    VStack(spacing: 2) {
                        Text("CREATE HERO")
                            .font(DarkFantasyTheme.section(size: 14))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .tracking(0.8)

                        Text("\(vm.slotsLeft) of 5 slots")
                            .font(DarkFantasyTheme.body(size: 11))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                        .foregroundStyle(DarkFantasyTheme.borderMedium)
                )
            }
            .aspectRatio(1.0 / 1.4, contentMode: .fit)
        }
        .buttonStyle(ArenaCardPressStyle(glowColor: DarkFantasyTheme.gold))
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Selected hero name preview
            if let selected = vm.selectedCharacter {
                HStack(spacing: 4) {
                    Text("Playing as")
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(selected.characterName)
                        .font(DarkFantasyTheme.section(size: 13))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }

            Button {
                guard let charId = vm.selectedCharacterId else { return }
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                enterPressed = true
                Task {
                    await vm.selectAndEnter(
                        characterId: charId,
                        appState: appState,
                        cache: cache
                    )
                }
            } label: {
                Text(enterPressed ? "ENTERING..." : "ENTER GAME")
                    .font(DarkFantasyTheme.section(size: 16))
                    .tracking(1.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.primary)
            .disabled(vm.selectedCharacterId == nil || vm.isLoading)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
        .padding(.bottom, LayoutConstants.spaceLG)
        .background(
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.9), DarkFantasyTheme.bgAbyss],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false),
            alignment: .top
        )
    }

    // MARK: - Guest Banner

    private var guestBanner: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.gold.opacity(0.1))
                        .overlay(Circle().stroke(DarkFantasyTheme.gold.opacity(0.2), lineWidth: 1))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("Guest Account")
                    .font(DarkFantasyTheme.section(size: 12))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("Create an account to save progress")
                    .font(DarkFantasyTheme.body(size: 11))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()

            Button {
                HapticManager.medium()
                appState.authPath.append(AppRoute.register)
            } label: {
                Text("SIGN UP")
                    .font(DarkFantasyTheme.section(size: 11))
                    .tracking(0.8)
            }
            .buttonStyle(.compactPrimary)
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.gold.opacity(0.05),
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.1))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()

            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(DarkFantasyTheme.gold.opacity(0.4))

            Text("No Heroes Yet")
                .font(DarkFantasyTheme.title(size: 20))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Create your first hero and begin\nyour journey in Hexbound")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                appState.authPath.append(AppRoute.onboarding)
            } label: {
                Text("CREATE HERO")
                    .font(DarkFantasyTheme.section(size: 15))
                    .tracking(1)
                    .frame(maxWidth: 220)
                    .frame(height: 52)
            }
            .buttonStyle(.primary)

            if appState.isGuest {
                Button {
                    appState.authPath.append(AppRoute.register)
                } label: {
                    Text("Or create an account")
                        .font(DarkFantasyTheme.body(size: 13))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()
            ProgressView()
                .tint(DarkFantasyTheme.gold)
                .scaleEffect(1.2)
            Text("Loading heroes...")
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Button {
                Task { await vm.loadCharacters() }
            } label: {
                Text("RETRY")
                    .font(DarkFantasyTheme.section(size: 14))
                    .tracking(1)
                    .frame(width: 140, height: 44)
            }
            .buttonStyle(.neutral)

            Spacer()
        }
    }

    // MARK: - Enter Game Overlay

    private var enterGameOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 48))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .opacity(enterGlow ? 1.0 : 0.4)
                    .shadow(color: DarkFantasyTheme.gold.opacity(enterGlow ? 0.6 : 0.1), radius: enterGlow ? 16 : 4)

                Text("Entering the Realm...")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("Preparing your adventure...")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.gold.opacity(0.15),
                    glowIntensity: 0.5,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 6)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                enterGlow = true
            }
        }
        .onDisappear {
            enterGlow = false
        }
    }
}

// MARK: - Hero Selection Card (Arena-Style)

/// Individual hero card in the character selection grid.
/// Mirrors `ArenaOpponentCard` visual design:
/// full-bleed avatar, vignette, level badge, class tag, rating, glass stat pills.
struct HeroSelectionCard: View {
    let character: Character
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var glowPhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -1.2

    private var classColor: Color {
        DarkFantasyTheme.classColor(for: character.characterClass)
    }

    private var glowColor: Color {
        isSelected ? DarkFantasyTheme.gold : classColor
    }

    private var hpPercent: Double {
        guard character.maxHp > 0 else { return 1 }
        return Double(character.currentHp) / Double(character.maxHp)
    }

    var body: some View {
        Button(action: onSelect) {
            cardContent
        }
        .buttonStyle(ArenaCardPressStyle(glowColor: glowColor))
        .onAppear { startAnimations() }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 1.4

            ZStack {
                // 1. Full-bleed avatar
                AvatarImageView(
                    skinKey: character.avatar,
                    characterClass: character.characterClass,
                    size: width
                )
                .frame(width: width, height: height)
                .clipped()

                // 2. Vignette
                vignetteOverlay(width: width, height: height)

                // 3. Content overlay
                VStack {
                    topBadges
                    Spacer()
                    bottomInfoStack
                }
                .padding(LayoutConstants.arenaCardPadding - 4)
                .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .background(DarkFantasyTheme.bgAbyss)
            .overlay(animatedBorderGlow)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
            .shadow(color: glowColor.opacity(isSelected ? 0.3 : 0.15), radius: LayoutConstants.arenaGlowRadius, y: 3)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        }
        .aspectRatio(1.0 / 1.4, contentMode: .fit)
    }

    // MARK: - Vignette

    private func vignetteOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.5)]),
                center: .init(x: 0.5, y: 0.35),
                startRadius: width * 0.25,
                endRadius: width * 0.85
            )

            LinearGradient(
                colors: [
                    .clear, .clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.4),
                    DarkFantasyTheme.bgAbyss.opacity(0.8),
                    DarkFantasyTheme.bgAbyss.opacity(0.95),
                    DarkFantasyTheme.bgAbyss
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.65)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Top Badges

    private var topBadges: some View {
        HStack {
            // Level circle
            Text("\(character.level)")
                .font(DarkFantasyTheme.section(size: 12))
                .foregroundStyle(classColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(Circle().stroke(classColor.opacity(0.5), lineWidth: 1.5))
                )

            Spacer()

            // Selected checkmark
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.bgAbyss)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(Circle().stroke(DarkFantasyTheme.bgAbyss.opacity(0.5), lineWidth: 1.5))
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 6)
            } else if hpPercent < 0.5 {
                // Low HP badge (like difficulty badge)
                Text("LOW HP")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.arenaDifficultyFont).bold())
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(DarkFantasyTheme.danger.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .stroke(DarkFantasyTheme.danger.opacity(0.25), lineWidth: 0.5)
                            )
                    )
            }
        }
    }

    // MARK: - Bottom Info

    private var bottomInfoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(character.characterName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Class tag pill
            Text(character.characterClass.displayName.uppercased())
                .font(DarkFantasyTheme.body(size: 10).bold())
                .foregroundStyle(classColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(classColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(classColor.opacity(0.25), lineWidth: 0.5)
                        )
                )

            // Rating (dominant)
            Text("\(character.pvpRating)")
                .font(DarkFantasyTheme.section(size: 32))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .shadow(color: glowColor.opacity(0.4), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 3, y: 1)

            // Glass stat pills
            HStack(spacing: 4) {
                glassStatPill(value: "\(character.strength ?? 0)", label: "ATK", color: DarkFantasyTheme.danger)
                glassStatPill(value: "\(character.vitality ?? 0)", label: "DEF", color: DarkFantasyTheme.info)
                glassStatPill(value: "Lv.\(character.level)", label: "Level", color: DarkFantasyTheme.gold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Glass Stat Pill

    @ViewBuilder
    private func glassStatPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Animated Border

    private var animatedBorderGlow: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        glowColor.opacity(isSelected ? 0.6 : 0.3),
                        glowColor.opacity(0.1),
                        glowColor.opacity(isSelected ? 0.4 : 0.2),
                        glowColor.opacity(0.05),
                        glowColor.opacity(isSelected ? 0.6 : 0.3)
                    ],
                    center: .center,
                    startAngle: .degrees(glowPhase),
                    endAngle: .degrees(glowPhase + 360)
                ),
                lineWidth: isSelected ? 2 : 1.5
            )
            .overlay(
                CornerBracketOverlay(
                    color: glowColor.opacity(isSelected ? 0.6 : 0.35),
                    length: 14,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: glowColor.opacity(isSelected ? 0.5 : 0.3),
                    size: 5
                )
            )
    }

    // MARK: - Shimmer (selected only)

    @ViewBuilder
    private var shimmerOverlay: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.arenaShimmerColor, .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0.3),
                        endPoint: UnitPoint(x: shimmerOffset + 0.4, y: 0.7)
                    )
                )
                .allowsHitTesting(false)
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }
        if isSelected {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                shimmerOffset = 1.5
            }
        }
    }
}
