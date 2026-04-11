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
    @State private var heroToDelete: Character?

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

                    // Currency bar — hidden for guests (no real ownership + removes competing gold accent)
                    if let selected = vm.selectedCharacter, !appState.isGuest {
                        currencyBar(for: selected)
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceSM)
                    }

                    // Single gating point for guests — replaces inline guestBanner
                    if appState.isGuest {
                        GuestGateCTA(
                            variant: .prominent,
                            hasProgress: vm.characters.contains { $0.level >= 2 },
                            onSignUp: {
                                HapticManager.medium()
                                SFXManager.shared.play(.uiTap)
                                appState.authPath.append(AppRoute.register)
                            }
                        )
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
            .toolbar {
                // Back button — only when no heroes (prevents dead-end).
                // Uses the shared HubLogoButton so the arrow style matches Settings
                // and every other screen exactly (same asset, same size, same hit area).
                if !vm.isLoading && vm.characters.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HubLogoButton {
                            HapticManager.light()
                            appState.logout()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { appState.authPath.append(AppRoute.settings) } label: {
                        Image("icon-settings")
                            .resizable()
                            .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .onboarding: OnboardingDetailView()
                case .register: AuthView(initialMode: .signup)
                case .settings: SettingsDetailView()
                case .currencyPurchase(let tab): CurrencyPurchaseView(initialTab: tab)
                default: PlaceholderView()
                }
            }
        }
        .onAppear {
            AudioManager.shared.playBGM("main-theme.mp3")
        }
        .task {
            // Load skins and characters in parallel (no @MainActor on skins task — runs on background thread)
            async let skinsTask: Void = {
                if await cache.skins.isEmpty {
                    if let response: AppearancesResponse = try? await APIClient.shared.get(APIEndpoints.appearances) {
                        await cache.cacheSkins(response.skins)
                    }
                }
            }()
            async let charsTask: Void = vm.loadCharacters(appState: appState)
            _ = await (skinsTask, charsTask)

            // Guest with no heroes → skip empty state, go straight to hero creation
            if appState.isGuest && vm.characters.isEmpty && appState.authPath.isEmpty {
                appState.authPath.append(AppRoute.onboarding)
            }
        }
        .onChange(of: appState.authPath.count) { oldCount, newCount in
            // Refresh character list when returning from onboarding (new hero created)
            if newCount == 0 && oldCount > 0 {
                vm.selectedCharacterId = nil  // Reset so auto-select picks the new hero
                Task { await vm.loadCharacters(appState: appState) }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text("CHOOSE YOUR HERO")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)

            Text("Select a hero to enter the world")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Currency Bar

    private func currencyBar(for character: Character) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            CurrencyDisplay(
                gold: character.gold,
                gems: character.gems,
                size: .standard,
                currencyType: .both,
                animated: false
            )

            Spacer()

            Button {
                HapticManager.medium()
                SFXManager.shared.play(.uiTap)
                appState.authPath.append(AppRoute.currencyPurchase())
            } label: {
                Image(systemName: "plus")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.compactPrimary)
            .accessibilityLabel("Get currency")
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 0.5)
                )
        )
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
                    let isSelected = character.id == vm.selectedCharacterId
                    ZStack(alignment: .topTrailing) {
                        HeroSelectionCard(
                            character: character,
                            isSelected: isSelected,
                            onSelect: {
                                HapticManager.light()
                                SFXManager.shared.play(.uiTap)
                                vm.selectedCharacterId = character.id
                            }
                        )
                        .staggeredAppear(index: index)

                        // Edit/delete button — appears on active card, outside Button to avoid gesture conflict
                        if isSelected {
                            CardActionButton(icon: "trash", color: DarkFantasyTheme.danger) {
                                HapticManager.light()
                                SFXManager.shared.play(.uiTap)
                                heroToDelete = character
                            }
                            .padding(LayoutConstants.arenaCardPadding - 4)
                            .transition(.opacity)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                        }
                    }
                }

                // Create hero placeholder card
                if vm.canCreateNewHero {
                    createHeroCard
                        .staggeredAppear(index: vm.characters.count)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceLG)
            .padding(.bottom, LayoutConstants.spaceSM)
        }
        .alert(
            "Delete Hero?",
            isPresented: Binding(
                get: { heroToDelete != nil },
                set: { if !$0 { heroToDelete = nil } }
            )
        ) {
            Button("Delete Forever", role: .destructive) {
                guard let hero = heroToDelete else { return }
                heroToDelete = nil
                Task {
                    let success = await vm.deleteCharacter(id: hero.id)
                    if !success {
                        appState.showToast("Failed to delete hero", type: .error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                heroToDelete = nil
            }
        } message: {
            if let hero = heroToDelete {
                Text("\"\(hero.characterName)\" will be permanently deleted. This cannot be undone.")
            }
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
                            .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)
                            )

                        Image(systemName: "plus")
                            .font(DarkFantasyTheme.section.weight(.light))
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }

                    VStack(spacing: LayoutConstants.space2XS) {
                        Text("CREATE HERO")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .tracking(0.8)

                        Text("\(vm.slotsLeft) of 5 slots")
                            .font(DarkFantasyTheme.body)
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
                Group {
                    if enterPressed {
                        Text("ENTERING...")
                    } else if let selected = vm.selectedCharacter {
                        Text("PLAYING AS \(selected.characterName.uppercased())")
                    } else {
                        Text("SELECT A HERO")
                    }
                }
                .font(DarkFantasyTheme.buttonLabel)
                .tracking(1.5)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()

            Image("icon-switch-char")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                .opacity(0.4)

            Text("No Heroes Yet")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Create your first hero and begin\nyour journey in Hexbound")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                appState.authPath.append(AppRoute.onboarding)
            } label: {
                Text("CREATE HERO")
                    .font(DarkFantasyTheme.body)
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
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .buttonStyle(.ghost)
            }

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()
            HexPulseLoader(.compact)
                .tint(DarkFantasyTheme.gold)
                .scaleEffect(1.2)
            Text("Loading heroes...")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Error State

    /// Uses the shared `ErrorStateView` with a full-width retry so the button
    /// matches `bottomCTA` (ENTER GAME) in style, weight, and width.
    /// Back button is hidden here because the toolbar already has a Back
    /// (shown in the same `vm.characters.isEmpty` state).
    private func errorState(_ message: String) -> some View {
        ErrorStateView(
            assetIcon: "rush-ui-combat-skull",
            title: "Failed to Load Heroes",
            message: message,
            retryLabel: "RETRY",
            retryAction: {
                Task { await vm.loadCharacters(appState: appState) }
            },
            retryLayout: .fullWidth,
            showBackButton: false
        )
    }

    // MARK: - Enter Game Overlay

    private var enterGameOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                HexPulseLoader(.standard)

                Text("Entering the Realm...")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("Preparing your adventure...")
                    .font(DarkFantasyTheme.body)
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

                // 3. Gold tint overlay when selected (subtle warmth)
                if isSelected {
                    RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                        .fill(DarkFantasyTheme.gold.opacity(0.05))
                        .allowsHitTesting(false)
                }

                // 4. Content overlay (level badge + bottom info)
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
            // Strong gold glow when selected, subtle when not
            .shadow(color: glowColor.opacity(isSelected ? 0.55 : 0.15), radius: isSelected ? 22 : LayoutConstants.arenaGlowRadius, y: 3)
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
        HStack(alignment: .top) {
            // Level circle — reusable component, always above ACTIVE strip (zIndex in parent)
            CardLevelBadge(level: character.level, accentColor: classColor)

            Spacer()

            // Top-right is reserved for the delete/edit CardActionButton overlay
            // added by the grid parent on the selected card. HP + Energy rings
            // now live horizontally above the stat pills (see bottomInfoStack).
        }
    }

    // MARK: - Bottom Info

    private var isNewHero: Bool {
        character.pvpWins == 0 && character.pvpLosses == 0
    }

    private var bottomInfoStack: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            // Name
            Text(character.characterName)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Class tag pill
            ClassTagView(characterClass: character.characterClass)

            // Rating row with icon
            HStack(spacing: LayoutConstants.spaceXS) {
                if UIImage(named: "icon-pvp-rating") != nil {
                    Image("icon-pvp-rating")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                        .opacity(0.7)
                } else {
                    Image(systemName: "star.fill")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                }

                if isNewHero {
                    Text("NEW")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .tracking(2)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.3), radius: 8)
                } else {
                    Text("\(character.pvpRating)")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .shadow(color: glowColor.opacity(0.4), radius: 12)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 3, y: 1)
                }
            }

            // Character age
            if !character.ageFormatted.isEmpty {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "clock")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    Text(character.ageFormatted)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                }
            }

            // HP + Energy rings, sitting just above the stat pills as part of
            // the "health / energy / attributes" cluster. Right-aligned so the
            // row reads: (space) → rings.
            HStack {
                Spacer()
                PortraitStatRings(
                    hpPercentage: character.hpPercentage,
                    staminaPercentage: character.staminaPercentage,
                    orientation: .horizontal,
                    ringSize: 30
                )
            }

            // Glass stat pills
            HStack(spacing: LayoutConstants.spaceXS) {
                GlassStatPill(value: "\(character.strength ?? 0)", label: "Attack", color: DarkFantasyTheme.danger)
                GlassStatPill(value: "\(character.vitality ?? 0)", label: "Defense", color: DarkFantasyTheme.info)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Glass Stat Pill (uses shared GlassStatPill component)

    // MARK: - Animated Border

    private var animatedBorderGlow: some View {
        Group {
            if isSelected {
                // Solid bright gold border — clearly communicates selection state
                RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DarkFantasyTheme.goldBright,
                                DarkFantasyTheme.gold,
                                DarkFantasyTheme.goldBright,
                                DarkFantasyTheme.gold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .overlay(
                        CornerBracketOverlay(
                            color: DarkFantasyTheme.gold.opacity(0.9),
                            length: 16,
                            thickness: 2.0
                        )
                    )
                    .overlay(
                        CornerDiamondOverlay(
                            color: DarkFantasyTheme.goldBright.opacity(0.8),
                            size: 7
                        )
                    )
            } else {
                // Animated class-colored gradient border for unselected
                RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                glowColor.opacity(0.3),
                                glowColor.opacity(0.1),
                                glowColor.opacity(0.2),
                                glowColor.opacity(0.05),
                                glowColor.opacity(0.3)
                            ],
                            center: .center,
                            startAngle: .degrees(glowPhase),
                            endAngle: .degrees(glowPhase + 360)
                        ),
                        lineWidth: 1.5
                    )
                    .overlay(
                        CornerBracketOverlay(
                            color: classColor.opacity(0.35),
                            length: 14,
                            thickness: 1.5
                        )
                    )
                    .overlay(
                        CornerDiamondOverlay(
                            color: classColor.opacity(0.3),
                            size: 5
                        )
                    )
            }
        }
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
