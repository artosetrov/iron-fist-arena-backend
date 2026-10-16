import SwiftUI
import AuthenticationServices

// MARK: - Launch (cold start)
//
// The launch IS the title screen: there is no separate splash. On a cold
// start the system launch screen is plain `launch-background` ink (Info.plist
// UILaunchScreen), the title art comes up out of it, the crest forms in the
// spot it keeps, and a loader stands where the sign-in actions will be.
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

    // Launch intro: the scene comes up out of the dark, then the crest forms
    // and one pass of light crosses it.
    @State private var sceneRevealed = false
    @State private var crestRevealed = false
    @State private var sheenPhase: CGFloat = 0

    private var isBooting: Bool { bootStage != nil }
    /// Held back only until the launch intro has played; any other visit
    /// shows the screen at once.
    private var sceneVisible: Bool { !isBooting || sceneRevealed }
    private var crestVisible: Bool { !isBooting || crestRevealed }

    private static let crestWidth: CGFloat = 280

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

    private var crestImage: some View {
        Image("hexbound-logo")
            .resizable()
            .scaledToFit()
            .frame(width: Self.crestWidth)
    }

    private var crest: some View {
        ZStack {
            // Warm light pooled behind the crest — drawn here, never baked
            // into the PNG (ART_STYLE_GUIDE: "AI paints, code rules").
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.gold.opacity(0.18),
                            DarkFantasyTheme.goldDim.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: Self.crestWidth * 0.68
                    )
                )
                .frame(width: Self.crestWidth * 1.36, height: Self.crestWidth * 1.36)

            crestImage
                .overlay { sheen }
        }
        .frame(width: Self.crestWidth, height: Self.crestWidth)
        .opacity(crestVisible ? 1 : 0)
        .blur(radius: crestVisible || reduceMotion ? 0 : 10)
        .offset(y: crestVisible || reduceMotion ? 0 : MotionConstants.cardSlideDistance)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hexbound. Forge your fate.")
        .accessibilityAddTraits(.isHeader)
    }

    /// One pass of storm light across the crest as it forms (the same cold
    /// white as the lightning). The band sits off the art at phase 0 and 1,
    /// and the crest's own alpha masks it.
    private var sheen: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.vfxLightningCore.opacity(0.35), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.2, height: geo.size.height * 1.6)
            .rotationEffect(.degrees(18))
            .offset(
                x: geo.size.width * (-0.8 + 2.2 * sheenPhase),
                y: -geo.size.height * 0.3
            )
        }
        .mask(crestImage)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func playLaunchIntro() {
        guard isBooting, !sceneRevealed else { return }
        if reduceMotion {
            // A plain fade: no blur, no drift, no sheen.
            withAnimation(.easeInOut(duration: MotionConstants.normal)) {
                sceneRevealed = true
                crestRevealed = true
            }
            return
        }
        withAnimation(.easeOut(duration: MotionConstants.epic)) {
            sceneRevealed = true
        }
        withAnimation(.easeOut(duration: MotionConstants.reward).delay(MotionConstants.ceremonyPhase1)) {
            crestRevealed = true
        }
        withAnimation(.easeInOut(duration: MotionConstants.epic).delay(MotionConstants.ceremonyPhase3)) {
            sheenPhase = 1
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
