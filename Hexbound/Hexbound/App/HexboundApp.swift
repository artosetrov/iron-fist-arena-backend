import SwiftUI
import GoogleSignIn

@main
struct HexboundApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var appState = AppState()
    @State private var cache = GameDataCache()
    @State private var pushService = PushNotificationService()
    @State private var isCheckingAuth = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    SplashView()
                } else {
                    switch appState.currentScreen {
                    case .auth:
                        AuthRouterView()
                    case .characterSelect:
                        CharacterSelectionView()
                    case .loreIntro(let heroName):
                        LoreIntroView(heroName: heroName)
                    case .game:
                        MainRouterView()
                    }
                }
            }
            .environment(appState)
            .environment(cache)
            .environment(pushService)
            .overlay(alignment: .top) { OfflineBannerView() }
            .overlay(alignment: .top) { CelebrationBannerOverlay().environment(appState) }
            .overlay(alignment: .bottom) { ToastOverlayView().environment(appState) }
            .overlay { if appState.isLoading { LoadingOverlay() } }
            .overlay { if appState.showLevelUpModal { LevelUpModalView().environment(appState) } }
            .overlay { if appState.showSessionExpiredModal { SessionExpiredModalView().environment(appState) } }
            .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
            .animation(.easeInOut(duration: 0.3), value: isCheckingAuth)
            .task {
                // Wire push service into AppDelegate for token forwarding
                appDelegate.pushService = pushService
                await checkAutoLogin()

                // Background asset sync — downloads new/updated assets from Supabase
                // Non-blocking: app works fine with bundle + existing cache while this runs
                Task { await AssetManager.shared.syncWithServer() }
            }
            .onOpenURL { url in
                _ = GoogleSignInHelper.handle(url)
            }
            .onChange(of: appState.currentScreen) { oldScreen, screen in
                if screen == .game {
                    // Entering game — request push, check tutorial
                    Task { await pushService.requestPermissionAndRegister() }
                    checkFTUE()
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
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var spinnerOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgDark.ignoresSafeArea()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.gold.opacity(0.15 * glowOpacity))
                        .frame(width: 340, height: 340)
                        .blur(radius: 60)

                    Image("hexbound-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                }
                .opacity(titleOpacity)
                .scaleEffect(titleScale)

                ProgressView()
                    .tint(DarkFantasyTheme.gold)
                    .padding(.top, 40)
                    .opacity(spinnerOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                titleOpacity = 1
                titleScale = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                subtitleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                spinnerOpacity = 1
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.2).repeatForever(autoreverses: true)) {
                glowOpacity = 1
            }
        }
        .onDisappear {
            glowOpacity = 0
        }
    }
}
