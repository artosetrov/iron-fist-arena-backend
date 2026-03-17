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
                } else if appState.isAuthenticated {
                    MainRouterView()
                } else {
                    AuthRouterView()
                }
            }
            .environment(appState)
            .environment(cache)
            .environment(pushService)
            .overlay(alignment: .top) { OfflineBannerView() }
            .overlay(alignment: .top) { ToastOverlayView() .environment(appState) }
            .overlay { if appState.isLoading { LoadingOverlay() } }
            .overlay { if appState.showLevelUpModal { LevelUpModalView().environment(appState) } }
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: isCheckingAuth)
            .task {
                // Wire push service into AppDelegate for token forwarding
                appDelegate.pushService = pushService
                await checkAutoLogin()
            }
            .onOpenURL { url in
                _ = GoogleSignInHelper.handle(url)
            }
            .onChange(of: appState.isAuthenticated) { _, isAuth in
                if isAuth {
                    // Request push permission after login
                    Task { await pushService.requestPermissionAndRegister() }
                } else {
                    // Unregister push token on logout
                    Task { await pushService.unregisterToken() }
                    cache.invalidateAll()
                }
            }
        }
    }

    private func checkAutoLogin() async {
        // Race: auto-login vs 10s timeout — first to finish wins
        let result = await withTaskGroup(of: AutoLoginResult?.self, returning: AutoLoginResult.self) { group in
            group.addTask { @MainActor in
                let authService = AuthService(appState: appState, cache: cache)
                let loginResult = await authService.tryAutoLogin()
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
                appState.isAuthenticated = true
            case .noCharacter:
                // Authenticated but no character — show AuthRouterView with onboarding
                appState.authPath.append(AppRoute.onboarding)
            case .noTokens:
                // Show login screen
                break
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
