import SwiftUI
import GoogleSignIn

@main
struct HexboundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var appState = AppState()
    @State private var cache = GameDataCache()
    @State private var pushService = PushNotificationService()
    @State private var isCheckingAuth = true
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(isVisible: showSplash)
                } else {
                    switch appState.currentScreen {
                    case .auth:
                        AuthRouterView()
                    case .characterSelect:
                        CharacterSelectionView()
                    case .cinematicOpen(let heroName):
                        CombatColdOpenView(heroName: heroName)
                    case .scriptedTutorial(let heroName):
                        TutorialFightView(heroName: heroName)
                    case .tutorialVictory(let heroName):
                        VictoryOverlayView(heroName: heroName)
                    case .loreIntro(let heroName):
                        OnboardingCinematicView(heroName: heroName)
                    case .game:
                        MainRouterView()
                    }
                }
            }
            .environment(appState)
            .environment(cache)
            .environment(pushService)
            // ── Root overlay stack ───────────────────────────────────────
            // Each `.overlay` is its own stacking context, so a `.zIndex`
            // written inside one is compared against nothing. The order
            // these modifiers appear in IS the stacking order — later is on
            // top — and the numbers that used to sit here (150/170/180/200)
            // decided nothing. See `Theme/ZLayer.swift`.
            //
            // Bottom to top:
            //   banners → ceremonies → toasts → blocking overlays
            //
            // Toasts sit above the ceremonies on purpose: a "Claim failed"
            // notice fired while a reward modal is up used to render behind
            // it and never be seen. Blocking overlays stay on top because
            // while one of them is up nothing else is actionable.

            // Banners — passive, never block input
            .overlay(alignment: .top) { OfflineBannerView() }
            .overlay(alignment: .top) { CelebrationBannerOverlay().environment(appState) }

            // Ceremonies — one at a time, governed by AppState's modal queue
            .overlay { if appState.showLevelUpModal { LevelUpModalView().environment(appState) } }
            .overlay {
                // BUG-53: Daily Login lives at root level so its lifetime is
                // decoupled from HubView's NavigationStack. Pop-backs from
                // Arena/Dungeon no longer re-fire `.task` that used to reopen
                // the modal — there is no `.task` to fire. State is driven
                // purely by `appState.showDailyLoginPopup`, flipped once by
                // `GameInitService.loadGameData()` and only re-flipped on an
                // explicit tile tap in the hub.
                if appState.showDailyLoginPopup {
                    DailyLoginDetailView()
                        .environment(appState)
                        .environment(cache)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .overlay {
                // Boss Reveal ceremony. Driven by AppState.presentBossReveal /
                // dismissBossReveal.
                if appState.isBossRevealing, let reveal = appState.pendingBossReveal {
                    BossRevealOverlayView(data: reveal)
                        .environment(appState)
                        .transition(.opacity)
                }
            }
            .overlay {
                // Above the boss reveal, which is what the old numbers said
                // (180 vs 170) and the old modifier order did not do.
                if let cfg = appState.claimRewardConfig {
                    ClaimRewardModalView(config: cfg) {
                        cfg.onDismiss?()
                        appState.claimRewardConfig = nil
                    }
                    .environment(appState)
                    .transition(.opacity)
                }
            }

            // Toasts — above every ceremony, see the note above
            .overlay(alignment: .bottom) { ToastOverlayView().environment(appState) }

            // Blocking — nothing underneath is actionable while these are up
            .overlay { if appState.isLoading { LoadingOverlay() } }
            .overlay { if appState.showSessionExpiredModal { SessionExpiredModalView().environment(appState) } }
            .overlay {
                // BUG-08: Hero forge loading overlay owned at root so it
                // survives the `.loreIntro` / `.characterSelect` transition.
                // Previously lived inside OnboardingDetailView and was torn
                // down with it mid-cross-fade, leaving a 2–3s black gap
                // while OnboardingCinematicView decoded its backdrop assets.
                if appState.isForgingHero {
                    HeroForgeOverlayView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
            .animation(.easeInOut(duration: 0.3), value: appState.isForgingHero)
            .animation(.easeInOut(duration: 0.3), value: appState.isBossRevealing)
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .task {
                // Crash reporting first, so anything that fails below is
                // actually reported. No-op when no DSN is configured.
                ObservabilityService.start()

                // Wire push service into AppDelegate for token forwarding
                appDelegate.pushService = pushService
                appDelegate.routeHandler = { route in
                    appState.handlePushRoute(route)
                }

                // Auth check with minimum 2s splash display
                let splashStart = ContinuousClock.now
                await checkAutoLogin()

                // Wait for remaining time so splash shows at least 2 seconds
                let elapsed = ContinuousClock.now - splashStart
                let remaining = Duration.seconds(2) - elapsed
                if remaining > .zero {
                    try? await Task.sleep(for: remaining)
                }

                // Dismiss splash with fade-out
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }

                // Background asset sync — downloads new/updated assets from Supabase
                // Non-blocking: app works fine with bundle + existing cache while this runs
                Task { await AssetManager.shared.syncWithServer() }
            }
            .onOpenURL { url in
                _ = GoogleSignInHelper.handle(url)
            }
            .onChange(of: scenePhase) { _, phase in
                // Don't lose buffered analytics when the app is suspended.
                if phase == .background || phase == .inactive {
                    AnalyticsService.shared.flush()
                }
            }
            .onChange(of: appState.currentScreen) { oldScreen, screen in
                AnalyticsService.shared.track(.screenView, ["screen": .string(String(describing: screen))])
                if screen == .game {
                    // Entering game — request push, check tutorial
                    Task { await pushService.requestPermissionAndRegister() }
                    checkFTUE()
                    appState.consumePendingPushRouteIfNeeded()
                } else if screen == .auth {
                    // Full logout — unregister push, clear cache
                    Task { await pushService.unregisterToken() }
                    cache.invalidateAll()
                }
                // .characterSelect — don't clear cache or unregister push
                _ = oldScreen // suppress unused warning
            }
        }
    }

    /// Show FTUE tutorial screen if the player hasn't completed or dismissed it.
    /// Navigates to .tutorial route with a small delay so the Hub renders first.
    private func checkFTUE() {
        let tutorial = TutorialManager.shared
        guard tutorial.shouldShowFTUE else { return }

        // Small delay so Hub appears first, then tutorial slides in
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard appState.isAuthenticated else { return }
            appState.mainPath.append(AppRoute.tutorial)
        }
    }

    private func checkAutoLogin() async {
        // Race: auto-login vs 10s timeout — first to finish wins
        let result = await withTaskGroup(of: AutoLoginResult?.self, returning: AutoLoginResult.self) { group in
            group.addTask { @MainActor in
                let authService = AuthService(appState: appState, cache: cache)
                let loginResult = await authService.tryAutoLogin()
                // If exactly one character, auto-select and load game data
                if loginResult == .hasCharacter {
                    let initService = GameInitService(appState: appState, cache: cache)
                    await initService.loadGameData()
                }
                return loginResult
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(10))
                return nil // signal timeout
            }
            // First to complete wins
            let first = await group.next() ?? nil
            group.cancelAll()
            // If timeout fired first (nil), treat as failure
            return first ?? .noTokens
        }

        await MainActor.run {
            isCheckingAuth = false
            switch result {
            case .hasCharacter:
                // Single hero — auto-selected, go straight to game
                appState.currentScreen = .game
            case .multipleCharacters:
                // 2+ heroes — show character selection screen
                appState.currentScreen = .characterSelect
            case .noCharacter:
                // Authenticated but no character — show character selection (empty state with create CTA)
                appState.currentScreen = .characterSelect
            case .noTokens:
                // Show login screen
                appState.currentScreen = .auth
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    let isVisible: Bool
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                Image("hexbound-logo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                    .scaleEffect(1.2)
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                contentOpacity = 1
            }
        }
    }
}
