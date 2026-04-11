import SwiftUI

/// W2.D2 R2 — Cold-open that bridges character creation and the scripted first fight.
///
/// Flow: characterSelect → **cinematicOpen (this view)** → scriptedTutorial → tutorialVictory → loreIntro → game
///
/// Shown for ~10-15 seconds on the first hero only (see OnboardingViewModel).
/// Purpose: emotional transition from wizard into combat. Zero lore dump.
/// Epic Seven pattern — cinematic lore is earned AFTER the first victory.
///
/// Visuals:
///   - Full-screen dim `bg-arena` with heavy backdrop
///   - Centered opponent silhouette (hex) with gold rim
///   - Typewriter one-liner above silhouette: "A grunt challenges you. End him."
///   - Gold CTA "DRAW STEEL" appears after typewriter completes
///   - Optional tap-to-skip anywhere outside the CTA (re-uses the same continue path)
///
/// Audio:
///   - Ambient: single `.uiConfirm` on appear (no BGM — the real music starts in combat)
///   - Haptic: medium on appear, heavy on "DRAW STEEL"
///
/// Accessibility:
///   - `accessibilityReduceMotion` skips the typewriter; full text is shown instantly
///   - Full screen is one accessibility element with a combined label for VoiceOver
///
/// See: docs/07_ui_ux/W2_D2_REALITY_CHECK.md
struct CombatColdOpenView: View {
    let heroName: String

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Content

    private let fullText = "A grunt challenges you.\nEnd him."

    // MARK: - Animated State

    @State private var visibleCharacterCount: Int = 0
    @State private var typewriterDone: Bool = false
    @State private var ctaOpacity: Double = 0
    @State private var silhouetteOpacity: Double = 0
    @State private var vignetteOpacity: Double = 0
    @State private var typewriterTask: Task<Void, Never>?
    @State private var didAdvance = false

    // MARK: - Tuning

    /// Delay per character during typewriter (seconds)
    private let charDelay: Double = 0.045
    /// Delay before CTA appears after typewriter completes (seconds)
    private let ctaDelay: Double = 0.4

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ── dim arena with heavy vignette
            backgroundLayer

            // Opponent silhouette
            opponentSilhouette
                .opacity(silhouetteOpacity)

            // Content — typewriter text + CTA
            VStack(spacing: LayoutConstants.spaceXL) {
                Spacer()

                typewriterText

                Spacer()

                drawSteelCTA
                    .opacity(ctaOpacity)

                Spacer().frame(height: LayoutConstants.spaceXL)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap anywhere to fast-forward the typewriter. Doesn't advance to the fight —
            // that still requires an explicit CTA tap so the player commits.
            if !typewriterDone {
                typewriterTask?.cancel()
                visibleCharacterCount = fullText.count
                typewriterDone = true
                revealCTA()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(heroName), a grunt challenges you. Tap Draw Steel to fight.")
        .onAppear(perform: startSequence)
        .onDisappear { typewriterTask?.cancel() }
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            Image("bg-arena")
                .resizable()
                .scaledToFill()
                .opacity(0.35)
                .ignoresSafeArea()

            // Vignette — dark radial for drama, animated in on appear
            RadialGradient(
                colors: [.clear, DarkFantasyTheme.bgPrimary.opacity(0.9)],
                center: .center,
                startRadius: 80,
                endRadius: 420,
            )
            .ignoresSafeArea()
            .opacity(vignetteOpacity)
        }
    }

    private var opponentSilhouette: some View {
        // Simple hex-style silhouette — we don't ship an orc art for the cold-open.
        // A dark diamond with a thin gold rim reads as "threat waiting" without
        // committing to an art asset we don't own. Re-used across tutorial opponents.
        ZStack {
            RegularPolygon(sides: 6)
                .fill(Color.black.opacity(0.85))
                .frame(width: 180, height: 180)

            RegularPolygon(sides: 6)
                .stroke(DarkFantasyTheme.gold.opacity(0.8), lineWidth: 2)
                .frame(width: 180, height: 180)

            Image(systemName: "figure.stand")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(DarkFantasyTheme.danger.opacity(0.7))
        }
        .offset(y: -40)
        .accessibilityHidden(true)
    }

    private var typewriterText: some View {
        let displayed = String(fullText.prefix(visibleCharacterCount))
        return Text(displayed)
            .font(DarkFantasyTheme.title)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
            .padding(.horizontal, LayoutConstants.spaceLG)
    }

    private var drawSteelCTA: some View {
        Button {
            advanceToTutorialFight()
        } label: {
            Text("DRAW STEEL")
        }
        .buttonStyle(.primary)
        .accessibilityHint("Starts the tutorial fight")
        .disabled(!typewriterDone)
    }

    // MARK: - Sequence

    private func startSequence() {
        HapticManager.medium()
        SFXManager.shared.play(.uiConfirm)

        // Fade in vignette + silhouette ── opacity only, no scale (per design pref)
        withAnimation(.easeOut(duration: 0.8)) {
            vignetteOpacity = 1
            silhouetteOpacity = 1
        }

        if reduceMotion {
            visibleCharacterCount = fullText.count
            typewriterDone = true
            revealCTA()
            return
        }

        typewriterTask = Task { @MainActor in
            for i in 0...fullText.count {
                if Task.isCancelled { return }
                visibleCharacterCount = i
                try? await Task.sleep(for: .seconds(charDelay))
            }
            typewriterDone = true
            revealCTA()
        }
    }

    private func revealCTA() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(ctaDelay))
            withAnimation(.easeOut(duration: 0.5)) {
                ctaOpacity = 1
            }
        }
    }

    private func advanceToTutorialFight() {
        guard !didAdvance else { return }
        didAdvance = true
        HapticManager.heavy()
        SFXManager.shared.play(.uiConfirm)
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.currentScreen = .scriptedTutorial(heroName: heroName)
        }
    }
}

// MARK: - Regular Polygon Shape

/// Minimal regular polygon shape — used for the opponent silhouette in the cold-open.
/// Kept private/inline here because it's only used by this view.
private struct RegularPolygon: Shape {
    let sides: Int

    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angleStep = 2 * Double.pi / Double(sides)
        for i in 0..<sides {
            let angle = angleStep * Double(i) - Double.pi / 2
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle)),
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
