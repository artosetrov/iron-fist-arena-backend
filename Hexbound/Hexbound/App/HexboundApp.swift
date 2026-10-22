import SwiftUI
import GoogleSignIn

@main
struct HexboundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var appState = AppState()
    @State private var cache = GameDataCache()
    @State private var pushService = PushNotificationService()
    /// Cold-launch progress. The title screen (WelcomeView) plays the launch
    /// intro and shows it in place of its sign-in actions; `nil` once the
    /// launch has handed over. There is no separate splash screen.
    @State private var bootStage: BootStage? = .openingGate
    @Environment(\.scenePhase) private var scenePhase

    /// The title intro — art up from the dark, crest forms, one sheen —
    /// takes about this long; the launch never hands over before it has played.
    private static let minimumBootDuration: Duration = .seconds(2)

    private static let galleryMode: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-RewardCardGallery")
        #else
        return false
        #endif
    }()

    @ViewBuilder private var galleryView: some View {
        #if DEBUG
        RewardCardGalleryView()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // TEMPORARY (claude/sim-cards): the reward card gallery for CI screenshots.
                if Self.galleryMode {
                    galleryView
                } else {
                // `currentScreen` starts at `.auth`, so a cold start opens on
                // the title screen in its launch state.
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
            .environment(\.bootStage, bootStage)
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
                if let rankUp = appState.activeRankUp {
                    RankUpCeremonyView(
                        oldRank: rankUp.oldRank,
                        newRank: rankUp.newRank,
                        newRating: rankUp.newRating,
                        goldReward: rankUp.goldReward,
                        gemReward: rankUp.gemReward,
                        onDismiss: { appState.dismissRankUp() }
                    )
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
            .task {
                // Crash reporting first, so anything that fails below is
                // actually reported. No-op when no DSN is configured.
                ObservabilityService.start()

                // Latency pass (2026-10-15): warm the tap sounds and the
                // Taptic Engine while the splash is up, so the first button
                // press in the hub pays no file I/O or engine spin-up.
                SFXManager.shared.preloadUI()
                HapticManager.prepareAll()

                // Wire push service into AppDelegate for token forwarding
                appDelegate.pushService = pushService
                appDelegate.routeHandler = { route in
                    appState.handlePushRoute(route)
                }

                // Restore the session while the title screen plays its intro.
                let bootStart = ContinuousClock.now
                let result = await checkAutoLogin()

                // Let the intro finish before handing over.
                let remaining = Self.minimumBootDuration - (ContinuousClock.now - bootStart)
                if remaining > .zero {
                    try? await Task.sleep(for: remaining)
                }

                // Fill the loader's rail, then hand over.
                bootStage = .ready
                try? await Task.sleep(for: .seconds(MotionConstants.fast))
                finishBoot(with: result)

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
                // .characterSelect — keep account-level cache + push, but
                // drop the previous hero's data so screens that now show
                // stale-while-revalidate never flash another hero's state.
                if screen == .characterSelect, oldScreen == .game {
                    cache.invalidateCharacterScoped()
                }
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

    private func checkAutoLogin() async -> AutoLoginResult {
        // Race: auto-login vs 10s timeout — first to finish wins
        await withTaskGroup(of: AutoLoginResult?.self, returning: AutoLoginResult.self) { group in
            group.addTask { @MainActor in
                let authService = AuthService(appState: appState, cache: cache)
                let loginResult = await authService.tryAutoLogin()
                // If exactly one character, auto-select and load game data
                if loginResult == .hasCharacter {
                    bootStage = .summoningHero
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
    }

    /// Leave the title screen for wherever the restored session belongs.
    private func finishBoot(with result: AutoLoginResult) {
        switch result {
        case .hasCharacter:
            // Single hero — auto-selected, go straight to game
            appState.currentScreen = .game
        case .multipleCharacters, .noCharacter:
            // 2+ heroes, or none yet (empty state with a create CTA)
            appState.currentScreen = .characterSelect
        case .noTokens:
            // Already on the title screen — only the launch state changes.
            break
        }

        if result == .noTokens {
            // The sign-in actions rise into the loader's place.
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                bootStage = nil
            }
        } else {
            // The title screen cross-fades out (0.3 s, see `.animation` on
            // `currentScreen`); clear the launch state only once it has gone,
            // so its sign-in actions never flash in on the way out.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(MotionConstants.normal))
                bootStage = nil
            }
        }
    }
}
