import SwiftUI

// MARK: - Onboarding Slide Data

private struct OnboardingSlide {
    let backgroundAsset: String
    let accentColor: Color
    let title: String
    let body: String
    let footnote: String?
    /// Cinematic letterbox bars height ratio (0 = no bars, 0.08 = heavy)
    let letterbox: CGFloat
}

// MARK: - OnboardingCinematicView
// Full-screen cinematic onboarding with purpose-made illustrations.
// 10 slides telling the Hexbound story through custom art.
// Full-bleed backgrounds, ember particles, parallax, typewriter text.

struct OnboardingCinematicView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var currentSlide = 0
    @State private var slideOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var bgOpacity: Double = 0
    @State private var bgScale: CGFloat = 1.05
    @State private var titleOpacity: Double = 0
    @State private var titleOffsetY: CGFloat = 20
    @State private var bodyOpacity: Double = 0
    @State private var footnoteOpacity: Double = 0
    @State private var curtainOpacity: Double = 1
    @State private var particlePhase: CGFloat = 0
    @State private var isEntering = false
    @State private var letterboxReveal: CGFloat = 0
    @State private var typewriterText: String = ""
    @State private var typewriterTask: Task<Void, Never>?
    @State private var dragOffset: CGFloat = 0

    private let heroName: String

    init(heroName: String) {
        self.heroName = heroName
    }

    // MARK: - Slide Definitions

    private var slides: [OnboardingSlide] {
        [
            OnboardingSlide(
                backgroundAsset: "onboarding-city-panorama",
                accentColor: DarkFantasyTheme.gold,
                title: "WELCOME TO HEXBOUND",
                body: "A city of blades and ambition. Danger lurks in every shadow — and glory awaits those brave enough to claim it.",
                footnote: "Your legend begins here.",
                letterbox: 0.06
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-merchant-meet",
                accentColor: DarkFantasyTheme.goldBright,
                title: "MERCHANTS & OUTCASTS",
                body: "The roads are full of wanderers selling everything from rusty swords to suspicious potions. Trust no one — but buy from everyone.",
                footnote: nil,
                letterbox: 0.04
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-tavern-keeper",
                accentColor: DarkFantasyTheme.classMage,
                title: "THE TAVERN",
                body: "A skeleton in a purple hood serves mystery meat and potions of questionable origin. The regulars don't ask questions.",
                footnote: "What doesn't kill you… might still give you a rash.",
                letterbox: 0.04
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-arena-battle",
                accentColor: DarkFantasyTheme.danger,
                title: "THE ARENA AWAITS",
                body: "Warriors clash for gold, glory, and bragging rights. The crowd roars. The sand runs red. It's Tuesday.",
                footnote: "Every legend started with a first fight.",
                letterbox: 0.06
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-defeat",
                accentColor: DarkFantasyTheme.textSecondary,
                title: "DEFEAT IS A TEACHER",
                body: "You will fall. Everyone does. But the ones who get back up — they become dangerous.",
                footnote: nil,
                letterbox: 0.05
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-victory",
                accentColor: DarkFantasyTheme.gold,
                title: "VICTORY TASTES SWEET",
                body: "Gold rains from the sky. Your enemies lie broken. The crowd chants your name. This is what you came for.",
                footnote: "And it only gets better from here.",
                letterbox: 0.05
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-dungeon-gate",
                accentColor: DarkFantasyTheme.classMage,
                title: "THINGS BELOW\nWANT YOU DEAD",
                body: "The dungeon gate opens. Stone demons watch with glowing eyes. Bones crunch underfoot. Something moves in the dark.",
                footnote: nil,
                letterbox: 0.06
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-dungeon-charge",
                accentColor: DarkFantasyTheme.danger,
                title: "INTO THE FIRE",
                body: "A wall of flame. A horde of goblins. One hero with nothing to lose. This is where cowards turn back.",
                footnote: "You're not a coward, are you?",
                letterbox: 0.06
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-dungeon-victory",
                accentColor: DarkFantasyTheme.goldBright,
                title: "CLAIM YOUR SPOILS",
                body: "Gems cascade. Gold piles high. The dungeon is conquered — and you stand atop it all.",
                footnote: nil,
                letterbox: 0.05
            ),
            OnboardingSlide(
                backgroundAsset: "onboarding-blacksmith",
                accentColor: DarkFantasyTheme.gold,
                title: "TIME TO RISE,\n\(heroName.uppercased())",
                body: "The blacksmith offers your first real blade. Take it. Sharpen it. Use it to carve your name into history.",
                footnote: "Hexbound doesn't care where you're from.\nOnly where you're going.",
                letterbox: 0.04
            ),
        ]
    }

    private var isLastSlide: Bool { currentSlide == slides.count - 1 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Abyss base
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()

            // Full-bleed illustration with parallax
            backgroundLayer

            // Ember particles
            particleCanvas

            // Cinematic letterbox bars
            letterboxBars

            // Bottom gradient for text readability
            bottomGradient

            // Content
            VStack(spacing: 0) {
                skipButton
                Spacer()
                textContent
                    .padding(.bottom, LayoutConstants.spaceLG)
                bottomSection
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)

            // Cinematic curtain
            curtainView
        }
        .ignoresSafeArea()
        .gesture(swipeGesture)
        .onAppear {
            AudioManager.shared.playBGM("main-theme.mp3")
            animateSlideIn()
            // Fade curtain out dramatically
            withAnimation(.easeOut(duration: MotionConstants.epic)) {
                curtainOpacity = 0
            }
            // Start particle loop
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }
            // Letterbox reveal
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                letterboxReveal = 1
            }
        }
    }

    // MARK: - Background Layer (Full-Bleed + Parallax)

    private var backgroundLayer: some View {
        GeometryReader { geo in
            Image(slides[currentSlide].backgroundAsset)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: geo.size.width * 1.1,
                    height: geo.size.height * 1.1
                )
                .scaleEffect(bgScale)
                // Parallax on drag
                .offset(x: dragOffset * 0.15)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .opacity(0.85 * bgOpacity)
                .animation(.easeInOut(duration: MotionConstants.reward), value: currentSlide)
        }
        .ignoresSafeArea()
    }

    // MARK: - Particle Canvas (Embers)

    private var particleCanvas: some View {
        Canvas { ctx, size in
            let count = 40
            for i in 0..<count {
                let seed = Double(i) * 137.508
                let phase = Double(particlePhase)

                // Float upward slowly
                let x = (sin(seed) * 0.5 + 0.5) * size.width + sin(phase * .pi * 2 + seed * 0.5) * 30
                let baseY = size.height - (((phase * size.height * 0.7) + seed * 13).truncatingRemainder(dividingBy: size.height))
                let y = baseY + sin(phase * .pi * 4 + seed) * 15

                // Flicker
                let alpha = sin(phase * .pi * 3 + seed * 0.7) * 0.25 + 0.35
                let pSize = CGFloat(1.0 + sin(seed * 0.3) * 1.5)

                let rect = CGRect(x: x - pSize / 2, y: y - pSize / 2, width: pSize, height: pSize)
                let accentColor = slides[currentSlide].accentColor
                ctx.fill(Ellipse().path(in: rect), with: .color(accentColor.opacity(alpha)))

                // Some embers have a glow halo
                if i % 4 == 0 {
                    let glowRect = CGRect(x: x - pSize * 2, y: y - pSize * 2, width: pSize * 4, height: pSize * 4)
                    ctx.fill(Ellipse().path(in: glowRect), with: .color(accentColor.opacity(alpha * 0.15)))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Cinematic Letterbox Bars

    private var letterboxBars: some View {
        let barHeight = slides[currentSlide].letterbox
        return ZStack {
            // Top bar
            VStack {
                DarkFantasyTheme.bgAbyss
                    .frame(height: UIScreen.main.bounds.height * barHeight * letterboxReveal)
                Spacer()
            }

            // Bottom bar
            VStack {
                Spacer()
                DarkFantasyTheme.bgAbyss
                    .frame(height: UIScreen.main.bounds.height * barHeight * letterboxReveal)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.5), value: currentSlide)
    }

    // MARK: - Bottom Gradient (Text Readability)

    private var bottomGradient: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [
                    Color.clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.5),
                    DarkFantasyTheme.bgAbyss.opacity(0.85),
                    DarkFantasyTheme.bgAbyss.opacity(0.95),
                ],
                startPoint: .init(x: 0.5, y: 0),
                endPoint: .init(x: 0.5, y: 1)
            )
            .frame(height: UIScreen.main.bounds.height * 0.45)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Curtain

    private var curtainView: some View {
        DarkFantasyTheme.bgAbyss
            .ignoresSafeArea()
            .opacity(curtainOpacity)
            .allowsHitTesting(false)
    }

    // MARK: - Skip Button

    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                HapticManager.light()
                SFXManager.shared.play(.uiTap)
                enterGame()
            } label: {
                Text("SKIP")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .tracking(0.8)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.bgAbyss.opacity(0.5))
                            .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Text Content (Typewriter Effect)

    private var textContent: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Title — dramatic reveal
            Text(slides[currentSlide].title)
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(slides[currentSlide].accentColor)
                .tracking(3)
                .multilineTextAlignment(.center)
                .shadow(color: slides[currentSlide].accentColor.opacity(0.5), radius: 16)
                .shadow(color: DarkFantasyTheme.bgAbyss, radius: 8)
                .opacity(titleOpacity)
                .offset(y: titleOffsetY)

            // Ornamental divider
            ScrollworkDivider(
                color: DarkFantasyTheme.borderMedium,
                accentColor: slides[currentSlide].accentColor
            )
            .padding(.horizontal, LayoutConstants.spaceXL)
            .opacity(contentOpacity)

            // Body text — typewriter
            Text(typewriterText)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .opacity(bodyOpacity)
                .fixedSize(horizontal: false, vertical: true)

            // Footnote
            if let footnote = slides[currentSlide].footnote {
                Text(footnote)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .opacity(footnoteOpacity)
            }
        }
        .offset(x: slideOffset)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Progress dots
            progressDots

            // CTA Button
            if isLastSlide {
                Button {
                    HapticManager.heavy()
                    SFXManager.shared.play(.uiConfirm)
                    enterGame()
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        if isEntering {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.8)
                        }
                        Text(isEntering ? "ENTERING..." : "ENTER HEXBOUND")
                            .font(DarkFantasyTheme.buttonLabel)
                            .tracking(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.primary)
                .disabled(isEntering)
                .transition(.opacity.combined(with: .offset(y: 20)))
            } else {
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    advanceSlide()
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(1)
                        Image(systemName: "chevron.right")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.neutral)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: MotionConstants.fast), value: isLastSlide)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(0..<slides.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentSlide
                            ? slides[currentSlide].accentColor
                            : DarkFantasyTheme.borderSubtle.opacity(0.5)
                    )
                    .frame(
                        width: index == currentSlide ? 24 : 6,
                        height: 6
                    )
                    .shadow(
                        color: index == currentSlide
                            ? slides[currentSlide].accentColor.opacity(0.5)
                            : Color.clear,
                        radius: 4
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentSlide)
            }
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                dragOffset = 0
                let dx = value.translation.width
                if dx < -40 && currentSlide < slides.count - 1 {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    advanceSlide()
                } else if dx > 40 && currentSlide > 0 {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    retreatSlide()
                }
            }
    }

    // MARK: - Navigation

    private func advanceSlide() {
        guard currentSlide < slides.count - 1 else { return }
        typewriterTask?.cancel()
        animateSlideOut(direction: -1) {
            currentSlide += 1
            animateSlideIn()
        }
    }

    private func retreatSlide() {
        guard currentSlide > 0 else { return }
        typewriterTask?.cancel()
        animateSlideOut(direction: 1) {
            currentSlide -= 1
            animateSlideIn()
        }
    }

    private func enterGame() {
        guard !isEntering else { return }
        isEntering = true
        typewriterTask?.cancel()

        // Dramatic fade to black before entering
        withAnimation(.easeIn(duration: 0.6)) {
            curtainOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            let initService = GameInitService(appState: appState, cache: cache)
            await initService.loadGameData()
            appState.currentScreen = .game
        }
    }

    // MARK: - Animations

    private func animateSlideIn() {
        // Reset states
        titleOpacity = 0
        titleOffsetY = 20
        contentOpacity = 0
        bodyOpacity = 0
        footnoteOpacity = 0
        bgOpacity = 0
        bgScale = 1.08
        slideOffset = 0
        typewriterText = ""

        // Background: fade in + slow zoom (Ken Burns)
        withAnimation(.easeOut(duration: 0.6)) {
            bgOpacity = 1
        }
        withAnimation(.easeOut(duration: 8)) {
            bgScale = 1.0
        }

        // Title: dramatic rise
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
            titleOpacity = 1
            titleOffsetY = 0
        }

        // Divider
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            contentOpacity = 1
        }

        // Body: typewriter effect
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            bodyOpacity = 1
        }
        startTypewriter(text: slides[currentSlide].body, delay: 0.5)

        // Footnote: gentle fade
        if slides[currentSlide].footnote != nil {
            withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
                footnoteOpacity = 1
            }
        }
    }

    private func animateSlideOut(direction: CGFloat, completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.2)) {
            slideOffset = direction * 60
            titleOpacity = 0
            contentOpacity = 0
            bodyOpacity = 0
            footnoteOpacity = 0
            bgOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            slideOffset = -direction * 60
            completion()
        }
    }

    // MARK: - Typewriter

    private func startTypewriter(text: String, delay: Double) {
        typewriterTask?.cancel()
        typewriterText = ""

        typewriterTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            for char in text {
                guard !Task.isCancelled else {
                    typewriterText = text // Show full text if cancelled
                    return
                }
                typewriterText.append(char)
                // Variable speed: punctuation gets a longer pause
                let ms: UInt64 = char == "." || char == "," || char == "—" ? 60 : 25
                try? await Task.sleep(nanoseconds: ms * 1_000_000)
            }
        }
    }
}
