import SwiftUI
import AuthenticationServices

// MARK: - Launch (cold start)
//
// The launch IS the title screen: there is no separate splash. On a cold
// start the system launch screen is plain `launch-background` ink (Info.plist
// UILaunchScreen), the title art comes up out of it, the layered crest
// assembles in the spot it keeps (HexboundCrest), and a loader stands where
// the sign-in actions will be.
// When the session check is done the actions take the loader's place — or,
// with a saved session, the whole screen cross-fades into the game.

/// What the launch is doing. Owned by `HexboundApp`; `nil` once the launch is
/// over — and on every later visit to the title screen (e.g. after logout).
enum BootStage: Equatable {
    case openingGate     // restoring the saved session
    case summoningHero   // a session came back: loading the hero's world
    case ready           // done — the rail fills, then the hand-over

    /// The loader's line. `.ready` lasts a quarter second, so it keeps the
    /// line of the stage before it (see `TitleBootLoader`).
    var label: String {
        switch self {
        case .openingGate, .ready: return "Opening the gate"
        case .summoningHero: return "Summoning your hero"
        }
    }
}

private struct BootStageKey: EnvironmentKey {
    static let defaultValue: BootStage? = nil
}

extension EnvironmentValues {
    /// Non-nil while the cold launch is in progress (see `BootStage`).
    var bootStage: BootStage? {
        get { self[BootStageKey.self] }
        set { self[BootStageKey.self] = newValue }
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.bootStage) private var bootStage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm = LoginViewModel()

    // Launch intro: the scene comes up out of the dark while the crest
    // assembles itself (HexboundCrest, mode .intro).
    @State private var sceneRevealed = false

    private var isBooting: Bool { bootStage != nil }
    /// Held back only until the launch intro has played; any other visit
    /// shows the screen at once.
    private var sceneVisible: Bool { !isBooting || sceneRevealed }

    private static let crestWidth: CGFloat = 300

    var body: some View {
        ZStack {
            // Same ink as the system launch screen, so a cold start fades up
            // out of it instead of cutting.
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            ZStack {
                AuthBackground()

                // Living storm over the title art: mist, embers, ash, lightning.
                AmbientStormView()
                    .ignoresSafeArea()
            }
            .opacity(sceneVisible ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                // 1. Branding — the crest never moves between launch and menu
                crest

                Spacer()

                // 2. Actions — hug the bottom. During the launch they keep
                // their place (so the crest stays put) under the loader.
                actions
                    .overlay {
                        if let bootStage {
                            TitleBootLoader(stage: bootStage)
                                .transition(.opacity)
                        }
                    }

                // Error
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceMD)
                        .transition(.opacity)
                }
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.setup(appState: appState)
            AudioManager.shared.playBGM("main-theme.mp3")
            playLaunchIntro()
        }
    }

    // MARK: - Crest

    /// The layered crest: it assembles on a cold launch and is simply there on
    /// any later visit. Laid out as a square — the bony hands' fade runs into
    /// the space below without pushing the actions down.
    private var crest: some View {
        HexboundCrest(width: Self.crestWidth, mode: isBooting ? .intro : .still)
            .frame(height: Self.crestWidth, alignment: .top)
    }

    private func playLaunchIntro() {
        guard isBooting, !sceneRevealed else { return }
        withAnimation(.easeOut(duration: reduceMotion ? MotionConstants.normal : MotionConstants.epic)) {
            sceneRevealed = true
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            // PLAY — hero CTA. One tap = in the game.
            Button {
                SFXManager.shared.play(.uiConfirm)
                Task { await vm.guestLogin(appState: appState) }
            } label: {
                Text("PLAY")
            }
            .buttonStyle(.primary(enabled: !vm.isLoading))
            .disabled(vm.isLoading)
            .accessibilityLabel("Play now, no account needed")
            .launchReveal(step: 0, hidden: isBooting)

            // Social divider
            HStack(spacing: LayoutConstants.spaceMD) {
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)
                Text("OR")
                    .font(DarkFantasyTheme.body)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .fixedSize()
                Rectangle()
                    .fill(DarkFantasyTheme.borderSubtle)
                    .frame(height: 1)
            }
            .launchReveal(step: 1, hidden: isBooting)

            // Social auth row — consistent background on both buttons
            HStack(spacing: LayoutConstants.spaceMD) {
                // Apple — programmatic sign in via regular Button
                Button {
                    SFXManager.shared.play(.uiTap)
                    vm.triggerAppleSignIn(appState: appState)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "apple.logo")
                            .font(DarkFantasyTheme.section.weight(.medium))
                        Text("Sign in with Apple")
                            .font(DarkFantasyTheme.cardTitle.weight(.semibold))
                    }
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sign in with Apple")

                // Google
                Button {
                    SFXManager.shared.play(.uiTap)
                    Task { await vm.handleGoogleSignIn(appState: appState) }
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("G")
                            .font(DarkFantasyTheme.googleLogo)
                        Text("Sign in with Google")
                            .font(DarkFantasyTheme.cardTitle.weight(.semibold))
                    }
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sign in with Google")
            }
            .launchReveal(step: 2, hidden: isBooting)

            // Email auth — text links (sign up / log in). No more duplicate social row.
            VStack(spacing: LayoutConstants.spaceSM) {
                Button("Sign up with email →") {
                    SFXManager.shared.play(.uiTap)
                    appState.authPath.append(AppRoute.register)
                }
                .buttonStyle(.ghost)
                .accessibilityLabel("Sign up with email")

                Button("Already have an account? Log in") {
                    SFXManager.shared.play(.uiTap)
                    appState.authPath.append(AppRoute.login)
                }
                .buttonStyle(.ghost)
                .accessibilityLabel("Log in to existing account")
            }
            .padding(.top, LayoutConstants.spaceXS)
            .launchReveal(step: 3, hidden: isBooting)

            Text("Osetrov Design")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
                .launchReveal(step: 4, hidden: isBooting)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.authBottomInset)
        .allowsHitTesting(!isBooting)
        .accessibilityHidden(isBooting)
    }
}

// MARK: - Launch loader

/// Stands where the sign-in actions will be: what the launch is doing, and a
/// forged rail for how far along it is.
private struct TitleBootLoader: View {
    let stage: BootStage

    @State private var progress: CGFloat = 0
    @State private var isShown = false
    /// The last stage that was real work; `.ready` keeps its line.
    @State private var lineStage: BootStage = .openingGate

    /// Between real milestones the rail creeps, so a slow network still shows
    /// motion without pretending to be done. Not UI motion tiers — just how
    /// long the creep is stretched over.
    private static let sessionCreepSeconds: Double = 6
    private static let worldCreepSeconds: Double = 8

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            ZStack {
                Text(lineStage.label)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .textCase(.uppercase)
                    .tracking(3)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .id(lineStage)
                    // Old line out first, new line in after — never both at once.
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: MotionConstants.fast).delay(MotionConstants.fast)),
                        removal: .opacity.animation(.easeOut(duration: MotionConstants.fast))
                    ))
            }

            BootProgressRail(progress: progress)
                .frame(width: 220, height: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(isShown ? 1 : 0)
        .onAppear {
            if stage != .ready { lineStage = stage }
            // Comes in once the title art is up, not over the dark.
            withAnimation(.easeOut(duration: MotionConstants.normal).delay(MotionConstants.ceremonyPhase3)) {
                isShown = true
            }
        }
        .onChange(of: stage) { _, newStage in
            guard newStage != .ready else { return }
            withAnimation { lineStage = newStage }
        }
        .task(id: stage) { await advance(for: stage) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lineStage.label)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func advance(for stage: BootStage) async {
        switch stage {
        case .openingGate:
            withAnimation(.easeOut(duration: MotionConstants.reward)) { progress = max(progress, 0.3) }
            try? await Task.sleep(for: .seconds(MotionConstants.reward))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: Self.sessionCreepSeconds)) { progress = max(progress, 0.6) }
        case .summoningHero:
            withAnimation(.easeOut(duration: MotionConstants.normal)) { progress = max(progress, 0.7) }
            try? await Task.sleep(for: .seconds(MotionConstants.normal))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: Self.worldCreepSeconds)) { progress = max(progress, 0.95) }
        case .ready:
            withAnimation(.easeOut(duration: MotionConstants.fast)) { progress = 1 }
        }
    }
}

/// Thin forged rail: a dark groove, a gold fill, a diamond at each end.
private struct BootProgressRail: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .stroke(DarkFantasyTheme.goldDim.opacity(0.6), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldDim, DarkFantasyTheme.gold, DarkFantasyTheme.goldBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, progress)))
                    .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
            }
        }
        .overlay(alignment: .leading) { endDiamond.offset(x: -LayoutConstants.spaceSM) }
        .overlay(alignment: .trailing) { endDiamond.offset(x: LayoutConstants.spaceSM) }
    }

    private var endDiamond: some View {
        Rectangle()
            .fill(DarkFantasyTheme.gold)
            .frame(width: 7, height: 7)
            .rotationEffect(.degrees(45))
    }
}

private extension View {
    /// Hidden under the launch loader; on hand-over it rises into place,
    /// one step after another.
    func launchReveal(step: Int, hidden: Bool) -> some View {
        self
            .opacity(hidden ? 0 : 1)
            .offset(y: hidden ? MotionConstants.cardSlideDistance : 0)
            .animation(
                .easeOut(duration: MotionConstants.fast)
                    .delay(hidden ? 0 : Double(step) * MotionConstants.cardStagger * 1.5),
                value: hidden
            )
    }
}
