import SwiftUI

/// Character selection — "Gate Deck" (2026-10-17 redesign, canvas page
/// "Hero select", concept G = D "The Gate" + F "Hero Deck").
///
/// The runed gate from the title art fills the screen and glows in the
/// selected hero's class colour. Heroes are a swipeable deck of big cards
/// (neighbours peek at the sides, the last card forges a new hero), mirrored
/// by a strip of medallions for quick jumps. ENTER sends the card flying into
/// the gate, then the hub loads. Rename/delete live behind "…" — no trash can
/// on the card any more.
struct CharacterSelectionView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm = CharacterSelectionViewModel()
    @State private var heroToDelete: Character?
    @State private var deckPosition: String?
    @State private var entering = false
    @State private var gatePulse = false

    private static let forgeCardID = "forge-new-hero"

    var body: some View {
        @Bindable var state = appState
        NavigationStack(path: $state.authPath) {
            ZStack {
                gateBackdrop

                VStack(spacing: 0) {
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
                        .padding(.top, LayoutConstants.spaceSM)
                    }

                    contentArea
                }

                if entering {
                    gateFlash
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .toolbar {
                // Back button — only when no heroes (prevents dead-end).
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
                    .accessibilityLabel("Settings")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .onboarding: OnboardingDetailView()
                case .register: AuthView(initialMode: .signup)
                case .settings: SettingsDetailView()
                case .currencyPurchase(let tab): CurrencyPurchaseView(initialTab: tab)
                default: UnavailableRouteView()
                }
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
                        if success {
                            deckPosition = vm.selectedCharacterId
                        } else {
                            appState.showToast("Failed to delete hero", type: .error)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { heroToDelete = nil }
            } message: {
                if let hero = heroToDelete {
                    Text("\"\(hero.characterName)\" will be permanently deleted. This cannot be undone.")
                }
            }
        }
        .onAppear {
            AudioManager.shared.playBGM("main-theme.mp3")
            if !reduceMotion { gatePulse = true }
        }
        .task {
            async let skinsTask: Void = {
                if await cache.skins.isEmpty {
                    if let response: AppearancesResponse = try? await APIClient.shared.get(APIEndpoints.appearances) {
                        await cache.cacheSkins(response.skins)
                    }
                }
            }()
            async let charsTask: Void = vm.loadCharacters(appState: appState)
            _ = await (skinsTask, charsTask)
            deckPosition = vm.selectedCharacterId

            // Guest with no heroes → skip empty state, go straight to hero creation
            if appState.isGuest && vm.characters.isEmpty && appState.authPath.isEmpty {
                appState.authPath.append(AppRoute.onboarding)
            }
        }
        .onChange(of: appState.authPath.count) { oldCount, newCount in
            // Refresh character list when returning from onboarding (new hero created)
            if newCount == 0 && oldCount > 0 {
                vm.selectedCharacterId = nil
                Task {
                    await vm.loadCharacters(appState: appState)
                    deckPosition = vm.selectedCharacterId
                }
            }
        }
    }

    // MARK: - Derived

    private var isForgeCardSelected: Bool { deckPosition == Self.forgeCardID }

    private var accent: Color {
        guard !isForgeCardSelected, let hero = vm.selectedCharacter else { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.classColor(for: hero.characterClass)
    }

    private var deckIDs: [String] {
        vm.characters.map(\.id) + (vm.canCreateNewHero ? [Self.forgeCardID] : [])
    }

    private func select(_ id: String) {
        guard !entering else { return }
        withAnimation(MotionConstants.smooth) { deckPosition = id }
    }

    // MARK: - Backdrop (the gate)

    private var gateBackdrop: some View {
        GeometryReader { geo in
            ZStack {
                Image("bg-title")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()

                // Rune glow inside the arch — takes the selected class colour.
                RadialGradient(
                    colors: [accent.opacity(0.55), accent.opacity(0.12), .clear],
                    center: UnitPoint(x: 0.5, y: 0.22),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.55
                )
                .blendMode(.screen)
                .opacity(gatePulse ? 1 : 0.6)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                    value: gatePulse
                )
                .animation(MotionConstants.smooth, value: accent)

                LinearGradient(
                    stops: [
                        .init(color: DarkFantasyTheme.bgAbyss.opacity(0.55), location: 0),
                        .init(color: DarkFantasyTheme.bgAbyss.opacity(0.1), location: 0.22),
                        .init(color: DarkFantasyTheme.bgAbyss.opacity(0.35), location: 0.48),
                        .init(color: DarkFantasyTheme.bgAbyss.opacity(0.9), location: 0.74),
                        .init(color: DarkFantasyTheme.bgAbyss, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if !reduceMotion {
                    GateEmbers(color: accent)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
            gateDeck
        }
    }

    // MARK: - Gate deck

    private var gateDeck: some View {
        GeometryReader { geo in
            let cardWidth = min(300, geo.size.width * 0.72)
            let cardHeight = GateHeroCard.height(forWidth: cardWidth)
            VStack(spacing: LayoutConstants.spaceMD) {
                deckHeader
                Spacer(minLength: 0)
                deck(cardWidth: cardWidth, cardHeight: cardHeight, screenWidth: geo.size.width)
                medallions
                Spacer(minLength: 0)
                bottomBar
            }
        }
    }

    private var deckHeader: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text("THE GATE AWAITS")
                .font(DarkFantasyTheme.title)
                .tracking(4)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 8, y: 2)
            Text("Swipe to choose who walks through")
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func deck(cardWidth: CGFloat, cardHeight: CGFloat, screenWidth: CGFloat) -> some View {
        Group {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: LayoutConstants.spaceMD) {
                    ForEach(vm.characters) { hero in
                        GateHeroCard(
                            character: hero,
                            isSelected: deckPosition == hero.id,
                            isEntering: entering && deckPosition == hero.id
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .id(hero.id)
                        .onTapGesture { select(hero.id) }
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.84)
                                .rotationEffect(.degrees(phase.value * 6))
                                .opacity(phase.isIdentity ? 1 : 0.5)
                        }
                    }
                    if vm.canCreateNewHero {
                        GateForgeCard()
                            .frame(width: cardWidth, height: cardHeight)
                            .id(Self.forgeCardID)
                            .onTapGesture { select(Self.forgeCardID) }
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.84)
                                    .rotationEffect(.degrees(phase.value * 6))
                                    .opacity(phase.isIdentity ? 1 : 0.5)
                            }
                    }
                }
                .scrollTargetLayout()
                // Room for the selected card's float, border and glow.
                .padding(.vertical, LayoutConstants.spaceLG)
            }
            .contentMargins(.horizontal, (screenWidth - cardWidth) / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $deckPosition)
            .scrollClipDisabled()
            .scrollDisabled(entering)
        }
        .frame(height: cardHeight + LayoutConstants.spaceLG * 2)
        .onChange(of: deckPosition) { _, newValue in
            guard let newValue else { return }
            if newValue != Self.forgeCardID {
                vm.selectedCharacterId = newValue
            }
            HapticManager.light()
            SFXManager.shared.play(.uiSlide)
        }
    }

    private var medallions: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(vm.characters) { hero in
                let on = deckPosition == hero.id
                Button { select(hero.id) } label: {
                    AvatarImageView(skinKey: hero.avatar, characterClass: hero.characterClass, size: on ? 52 : 44)
                        .frame(width: on ? 52 : 44, height: on ? 52 : 44)
                        .clipShape(Circle())
                        .opacity(on ? 1 : 0.6)
                        .overlay(
                            Circle().stroke(on ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderSubtle,
                                            lineWidth: on ? 2 : 1)
                        )
                        .shadow(color: on ? DarkFantasyTheme.classColor(for: hero.characterClass).opacity(0.85) : .clear,
                                radius: 8)
                        .frame(width: LayoutConstants.touchComfortable, height: LayoutConstants.touchComfortable)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(hero.characterName), level \(hero.level)")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            if vm.canCreateNewHero {
                Button { select(Self.forgeCardID) } label: {
                    Image(systemName: "plus")
                        .font(DarkFantasyTheme.iconMedium)
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(DarkFantasyTheme.goldDim,
                                                  style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        )
                        .frame(width: LayoutConstants.touchComfortable, height: LayoutConstants.touchComfortable)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Forge a new hero")
            }
        }
        .animation(MotionConstants.spring, value: deckPosition)
    }

    private var bottomBar: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if let hero = vm.selectedCharacter, !isForgeCardSelected {
                Menu {
                    Button("Delete hero", systemImage: "trash", role: .destructive) {
                        heroToDelete = hero
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(DarkFantasyTheme.iconMedium)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: LayoutConstants.touchComfortable, height: LayoutConstants.touchComfortable)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .fill(DarkFantasyTheme.bgSecondary.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Hero options")
                .disabled(entering)
            }

            Button(action: primaryAction) {
                Text(ctaTitle)
                    .font(DarkFantasyTheme.buttonLabel)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.touchComfortable)
            }
            .buttonStyle(.primary)
            .disabled(entering || (vm.selectedCharacterId == nil && !isForgeCardSelected))
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceMD)
    }

    private var ctaTitle: String {
        if isForgeCardSelected { return "FORGE A HERO" }
        if let hero = vm.selectedCharacter { return "ENTER AS \(hero.characterName.uppercased())" }
        return "SELECT A HERO"
    }

    private func primaryAction() {
        if isForgeCardSelected {
            HapticManager.medium()
            SFXManager.shared.play(.uiTap)
            appState.authPath.append(AppRoute.onboarding)
            return
        }
        guard let charId = vm.selectedCharacterId else { return }
        HapticManager.heavy()
        SFXManager.shared.play(.uiConfirm)
        withAnimation(.easeIn(duration: reduceMotion ? 0.2 : 0.9)) { entering = true }
        Task {
            // Let the card reach the gate before the hub replaces this screen.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 1100))
            await vm.selectAndEnter(characterId: charId, appState: appState, cache: cache)
        }
    }

    // MARK: - Enter flash

    private var gateFlash: some View {
        ZStack {
            RadialGradient(
                colors: [accent.opacity(0.85), DarkFantasyTheme.bgAbyss.opacity(0.96)],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("THE GATE OPENS")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .tracking(4)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 14)
                if let hero = vm.selectedCharacter {
                    Text("\(hero.characterName) steps into Hexbound…")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            Spacer()

            GateForgeCard()
                .frame(width: 260, height: 340)
                .onTapGesture { appState.authPath.append(AppRoute.onboarding) }

            Text("The gate waits for its first hero.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                appState.authPath.append(AppRoute.onboarding)
            } label: {
                Text("FORGE YOUR HERO")
                    .tracking(1)
                    .frame(maxWidth: 260)
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
            Text("Summoning your heroes...")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        ErrorStateView(
            assetIcon: "rush-ui-combat-skull",
            title: "Failed to Load Heroes",
            message: message,
            retryLabel: "RETRY",
            retryAction: {
                Task {
                    await vm.loadCharacters(appState: appState)
                    deckPosition = vm.selectedCharacterId
                }
            },
            retryLayout: .fullWidth,
            showBackButton: false
        )
    }
}

// MARK: - Hero card

/// One hero in the gate deck: full art, level, class, race line and the
/// numbers that matter — rating, attack, defense — plus one reason to play.
struct GateHeroCard: View {
    let character: Character
    let isSelected: Bool
    var isEntering: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shine: CGFloat = -0.6

    /// Card art is 300×402 pt (generated frames, `CardFrames/card-frame-N`).
    static let aspect: CGFloat = 402.0 / 300.0
    static func height(forWidth w: CGFloat) -> CGFloat { (w * aspect).rounded() }

    private var tier: HeroCardTier { HeroCardTier(level: character.level, prestige: character.prestige ?? 0) }
    private var classColor: Color { DarkFantasyTheme.classColor(for: character.characterClass) }
    private var isNewHero: Bool { character.pvpWins == 0 && character.pvpLosses == 0 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let g = tier.geometry
            let win = CGRect(x: g.windowL * w, y: g.windowT * h,
                             width: (g.windowR - g.windowL) * w, height: (g.windowB - g.windowT) * h)
            // Bottom block (stats + status) has a fixed height, the art takes the rest.
            let bottomBlock: CGFloat = 76
            let artRect = CGRect(x: win.minX, y: win.minY, width: win.width, height: win.height - bottomBlock)

            ZStack(alignment: .topLeading) {
                // 1. Card body under the frame (a little larger than the window so no seam shows).
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgSecondary)
                    .frame(width: win.width + w * 0.04, height: win.height + w * 0.04)
                    .offset(x: win.minX - w * 0.02, y: win.minY - w * 0.02)

                // 2. Art + name, clipped to the art area.
                ZStack(alignment: .bottom) {
                    AvatarImageView(skinKey: character.avatar, characterClass: character.characterClass, size: artRect.width)
                        .frame(width: artRect.width, height: artRect.height)
                        .clipped()
                        .background(
                            RadialGradient(colors: [classColor.opacity(0.45), DarkFantasyTheme.bgAbyss],
                                           center: .center, startRadius: 0, endRadius: artRect.width)
                        )
                    LinearGradient(colors: [.clear, DarkFantasyTheme.bgSecondary],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: artRect.height * 0.42)
                    VStack(spacing: 0) {
                        Text(character.characterName.uppercased())
                            .font(DarkFantasyTheme.title)
                            .tracking(2)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .shadow(color: DarkFantasyTheme.bgAbyss, radius: 4, y: 1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(character.origin.iconAsset)
                                .resizable().scaledToFit()
                                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                            Text("\(character.origin.displayName) \(character.characterClass.displayName)".uppercased())
                                .font(DarkFantasyTheme.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(classColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.bottom, LayoutConstants.spaceXS)
                }
                .frame(width: artRect.width, height: artRect.height)
                .overlay {
                    if isSelected && !reduceMotion {
                        LinearGradient(
                            colors: [.clear, DarkFantasyTheme.goldBright.opacity(0.16), .clear],
                            startPoint: UnitPoint(x: shine, y: 0.2),
                            endPoint: UnitPoint(x: shine + 0.4, y: 0.8)
                        )
                        .allowsHitTesting(false)
                    }
                }
                .clipped()
                .offset(x: artRect.minX, y: artRect.minY)

                // Class icon, top-right of the art window.
                Image(character.characterClass.iconAsset)
                    .resizable().scaledToFit()
                    .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
                    .offset(x: win.maxX - LayoutConstants.iconXL - LayoutConstants.spaceXS,
                            y: win.minY + LayoutConstants.spaceXS)

                // 3. Stats + status: fixed slots, never move.
                VStack(spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        statTile(isNewHero ? "NEW" : "\(character.pvpRating)", "Rating", DarkFantasyTheme.goldBright)
                        statTile("\(character.strength ?? 0)", "Attack", DarkFantasyTheme.danger)
                        statTile("\(character.vitality ?? 0)", "Defense", DarkFantasyTheme.info)
                    }
                    .frame(height: 46)
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Circle().fill(status.color).frame(width: 6, height: 6)
                        Text(status.text)
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(status.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(height: 18)
                }
                .padding(.horizontal, LayoutConstants.spaceXS)
                .frame(width: win.width, height: bottomBlock - LayoutConstants.spaceXS, alignment: .top)
                .offset(x: win.minX, y: artRect.maxY + LayoutConstants.spaceXS)

                // 4. Level socket backing (shows through the open sockets of tiers 3–5).
                Circle()
                    .fill(DarkFantasyTheme.bgAbyss)
                    .frame(width: g.socketR * 2 * w, height: g.socketR * 2 * w)
                    .offset(x: (g.socketX - g.socketR) * w, y: g.socketY * h - g.socketR * w)

                // 5. The frame itself.
                Image(tier.asset)
                    .resizable()
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)

                // 6. Level number in the socket.
                Text("\(character.level)")
                    .font(DarkFantasyTheme.cardTitle.weight(.bold))
                    .foregroundStyle(tier.levelColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .frame(width: g.socketR * 2 * w, height: g.socketR * 2 * w)
                    .offset(x: (g.socketX - g.socketR) * w, y: g.socketY * h - g.socketR * w)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .shadow(color: isSelected ? classColor.opacity(0.55) : .clear, radius: 22)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 12, y: 8)
            // ENTER: the card flies up into the gate and burns out.
            .scaleEffect(isEntering ? 0.15 : 1)
            .offset(y: isEntering ? -h * 0.55 : 0)
            .opacity(isEntering ? 0 : 1)
            .brightness(isEntering ? 0.6 : 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(character.characterName), level \(character.level) \(character.origin.displayName) \(character.characterClass.displayName), \(tier.name) card. \(status.text)"
        )
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: false)) { shine = 1.3 }
        }
    }

    private func statTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.6))
        )
    }

    /// One honest reason to pick this hero, from data the list already has.
    private var status: (text: String, color: Color) {
        let points = (character.statPoints ?? 0)
        if points > 0 {
            return ("\(points) stat point\(points == 1 ? "" : "s") to spend", DarkFantasyTheme.goldBright)
        }
        let age = character.ageFormatted.isEmpty ? "" : " · hero for \(character.ageFormatted)"
        if character.currentStamina >= character.maxStamina {
            return ("Stamina full\(age)", DarkFantasyTheme.success)
        }
        return ("Stamina \(character.currentStamina)/\(character.maxStamina)\(age)", DarkFantasyTheme.textSecondary)
    }
}

// MARK: - Card tiers

/// Card frame by hero level (generated art, `CardFrames/card-frame-N`, 2026-10-17):
/// 1–9 oak & iron · 10–19 bronze · 20–29 runed silver · 30–39 ruby gold · 40+ (or prestige) obsidian mythic.
enum HeroCardTier: Int {
    case iron = 1, bronze, silver, gold, mythic

    init(level: Int, prestige: Int = 0) {
        if prestige > 0 { self = .mythic; return }
        switch level {
        case ..<10: self = .iron
        case 10..<20: self = .bronze
        case 20..<30: self = .silver
        case 30..<40: self = .gold
        default: self = .mythic
        }
    }

    var asset: String { "card-frame-\(rawValue)" }

    var name: String {
        switch self {
        case .iron: "Iron"
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold: "Gold"
        case .mythic: "Mythic"
        }
    }

    var levelColor: Color {
        switch self {
        case .iron, .bronze: DarkFantasyTheme.goldBright
        case .silver: DarkFantasyTheme.textPrimary
        case .gold: DarkFantasyTheme.goldBright
        case .mythic: DarkFantasyTheme.premiumPink
        }
    }

    /// Measured on the shipped @3x art: the open card window (fractions of
    /// width / height) and the level socket (centre as fractions, radius as a
    /// fraction of width).
    struct Geometry {
        let windowL: CGFloat, windowR: CGFloat, windowT: CGFloat, windowB: CGFloat
        let socketX: CGFloat, socketY: CGFloat, socketR: CGFloat
    }

    var geometry: Geometry {
        switch self {
        case .iron:   Geometry(windowL: 0.194, windowR: 0.804, windowT: 0.159, windowB: 0.842, socketX: 0.169, socketY: 0.134, socketR: 0.069)
        case .bronze: Geometry(windowL: 0.167, windowR: 0.832, windowT: 0.157, windowB: 0.877, socketX: 0.165, socketY: 0.121, socketR: 0.059)
        case .silver: Geometry(windowL: 0.137, windowR: 0.864, windowT: 0.127, windowB: 0.876, socketX: 0.165, socketY: 0.125, socketR: 0.061)
        case .gold:   Geometry(windowL: 0.116, windowR: 0.883, windowT: 0.140, windowB: 0.885, socketX: 0.148, socketY: 0.114, socketR: 0.066)
        case .mythic: Geometry(windowL: 0.163, windowR: 0.836, windowT: 0.190, windowB: 0.833, socketX: 0.171, socketY: 0.166, socketR: 0.053)
        }
    }
}

// MARK: - Forge card

/// The last card of the deck: forge another hero.
struct GateForgeCard: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "plus")
                .font(DarkFantasyTheme.iconCinematic)
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: 96, height: 96)
                .overlay(
                    Circle().strokeBorder(DarkFantasyTheme.goldDim, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                )
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 12)
            Text("FORGE A NEW HERO")
                .font(DarkFantasyTheme.section)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.gold)
            Text("Another race, another class.\nSame gold, same gems.")
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                .strokeBorder(DarkFantasyTheme.goldDim, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forge a new hero")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Embers

/// Embers rising from the gate floor, tinted with the selected class colour.
private struct GateEmbers: View {
    let color: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<16 {
                    let seed = Double(i) * 0.613
                    let period = 3.2 + (seed * 1.7).truncatingRemainder(dividingBy: 1.4)
                    let phase = ((t / period) + seed).truncatingRemainder(dividingBy: 1)
                    let x = size.width * ((seed * 5.3).truncatingRemainder(dividingBy: 1))
                        + sin(t * 1.5 + seed * 9) * 8
                    let y = size.height * (0.92 - 0.6 * phase)
                    let alpha = phase < 0.12 ? phase / 0.12 : (1 - phase)
                    let r = 1.2 + 1.6 * (1 - phase)
                    context.opacity = alpha * 0.9
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                 with: .color(color))
                }
            }
        }
    }
}
