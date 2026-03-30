import SwiftUI

// MARK: - Lore Slide Data

private struct LoreSlide {
    let backgroundAsset: String
    let assets: [SlideAsset]
    let accentColor: Color
    let title: String
    let body: String
    let footnote: String?

    struct SlideAsset {
        let name: String
        let size: CGFloat
        let offsetY: CGFloat
    }
}

// MARK: - LoreIntroView
// Shown once after first hero creation, before entering the hub.
// 6-slide cinematic presentation about the world of Hexbound.
// Full-bleed background art, real game assets, particle effects.

struct LoreIntroView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var currentSlide = 0
    @State private var slideOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var assetsOpacity: Double = 0
    @State private var assetsOffsetY: CGFloat = 20
    @State private var bgOpacity: Double = 0
    @State private var isEntering = false
    @State private var curtainOpacity: Double = 1
    @State private var particlePhase: CGFloat = 0

    private let heroName: String

    init(heroName: String) {
        self.heroName = heroName
    }

    // MARK: - Slide Definitions

    private var slides: [LoreSlide] {
        [
            LoreSlide(
                backgroundAsset: "bg-hub",
                assets: [
                    .init(name: "building-arena", size: 100, offsetY: 0),
                    .init(name: "building-shop", size: 80, offsetY: 10),
                    .init(name: "building-dungeon", size: 80, offsetY: 10)
                ],
                accentColor: DarkFantasyTheme.gold,
                title: "THE CITY OF HEXBOUND",
                body: "Ancient, ruthless, and frankly — it smells a little.",
                footnote: "Here, power is everything. And weakness costs dearly."
            ),
            LoreSlide(
                backgroundAsset: "bg-arena",
                assets: [
                    .init(name: "building-arena", size: 140, offsetY: 0)
                ],
                accentColor: DarkFantasyTheme.danger,
                title: "THE ARENA RULES ALL",
                body: "Bakers fight. Merchants fight. The local priest fights on weekends and categorically denies it.",
                footnote: "Your rank, your gold, and how people treat you on the street — the Arena decides it all."
            ),
            LoreSlide(
                backgroundAsset: "bg-dungeon",
                assets: [
                    .init(name: "boss-ghoul-brute-portrait", size: 80, offsetY: 0),
                    .init(name: "boss-lich-king-portrait", size: 90, offsetY: -5),
                    .init(name: "boss-banshee-portrait", size: 80, offsetY: 0)
                ],
                accentColor: DarkFantasyTheme.classMage,
                title: "THINGS BELOW\nWANT YOU DEAD",
                body: "The dungeons are full of creatures that were never meant to see sunlight. They're quite upset about it.",
                footnote: "Kill them. Take their stuff. It's the Hexbound way."
            ),
            LoreSlide(
                backgroundAsset: "bg-forge",
                assets: [
                    .init(name: "wpn_flamebrand", size: 72, offsetY: 0),
                    .init(name: "chest_plate_armor", size: 72, offsetY: 0),
                    .init(name: "helm_dragon_visage", size: 72, offsetY: 0),
                    .init(name: "wpn_stormbringer", size: 72, offsetY: 0)
                ],
                accentColor: DarkFantasyTheme.goldBright,
                title: "GEAR UP OR DIE TRYING",
                body: "Legendary weapons, cursed armor, suspicious potions — everything a hero needs to survive.",
                footnote: "The forge doesn't care about your feelings. Only your gold."
            ),
            LoreSlide(
                backgroundAsset: "bg-arena",
                assets: [
                    .init(name: "result-victory", size: 120, offsetY: 0)
                ],
                accentColor: DarkFantasyTheme.classMage,
                title: "EVERY LEGEND\nSTARTED LIKE YOU",
                body: "Broken, confused, and without a coin to their name.",
                footnote: "The difference? They started fighting. Now songs are sung about them. Embarrassing ones, but still."
            ),
            LoreSlide(
                backgroundAsset: "bg-hub",
                assets: [
                    .init(name: "building-ranks", size: 130, offsetY: 0)
                ],
                accentColor: DarkFantasyTheme.gold,
                title: "TIME TO RISE,\n\(heroName.uppercased())",
                body: "Arm yourself. Fight. Claw your way up.",
                footnote: "Hexbound doesn't care where you're from.\nOnly where you're going."
            )
        ]
    }

    private var isLastSlide: Bool { currentSlide == slides.count - 1 }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full-bleed background
            backgroundLayer

            // Particle overlay
            particleCanvas

            // Vignette
            vignetteOverlay

            // Content
            VStack(spacing: 0) {
                skipButton
                Spacer()
                slideContent
                Spacer()
                bottomSection
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)

            // Cinematic curtain (fades out on appear)
            curtainView
        }
        .ignoresSafeArea()
        .gesture(swipeGesture)
        .onAppear {
            animateSlideIn()
            // Fade curtain out
            withAnimation(.easeOut(duration: 1.2)) {
                curtainOpacity = 0
            }
            // Start particle animation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                particlePhase = 1
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()

            // Background art
            Image(slides[currentSlide].backgroundAsset)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.35 * bgOpacity)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentSlide)

            // Accent radial glow
            RadialGradient(
                colors: [
                    slides[currentSlide].accentColor.opacity(0.15),
                    DarkFantasyTheme.bgPrimary.opacity(0.6),
                    DarkFantasyTheme.bgAbyss
                ],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentSlide)
        }
    }

    // MARK: - Particle Canvas

    private var particleCanvas: some View {
        Canvas { ctx, size in
            let count = 30
            for i in 0..<count {
                let seed = Double(i) * 137.508
                let x = (sin(seed) * 0.5 + 0.5) * size.width
                let baseY = (cos(seed * 0.7) * 0.5 + 0.5) * size.height
                let drift = sin(Double(particlePhase) * .pi * 2 + seed * 0.3) * 20
                let y = baseY + drift
                let alpha = (sin(Double(particlePhase) * .pi * 2 + seed) * 0.3 + 0.3)
                let pSize = CGFloat(1.5 + sin(seed * 0.5) * 1.5)

                let rect = CGRect(x: x - pSize / 2, y: y - pSize / 2, width: pSize, height: pSize)
                let color = slides[currentSlide].accentColor.opacity(alpha)
                ctx.fill(Ellipse().path(in: rect), with: .color(color))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Vignette

    private var vignetteOverlay: some View {
        ZStack {
            // Top vignette
            LinearGradient(
                colors: [DarkFantasyTheme.bgAbyss.opacity(0.8), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            // Bottom vignette
            LinearGradient(
                colors: [Color.clear, DarkFantasyTheme.bgAbyss.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
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
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .tracking(0.8)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.bgSecondary.opacity(0.6))
                            .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                    )
            }
        }
    }

    // MARK: - Slide Content

    private var slideContent: some View {
        let slide = slides[currentSlide]
        return VStack(spacing: LayoutConstants.spaceLG) {
            // Asset showcase
            assetRow(slide: slide)

            // Divider
            ScrollworkDivider(
                color: DarkFantasyTheme.borderMedium,
                accentColor: slide.accentColor
            )
            .padding(.horizontal, LayoutConstants.spaceXL)
            .opacity(contentOpacity)

            // Title + Body
            textBlock(slide: slide)
        }
        .offset(x: slideOffset)
    }

    // MARK: - Asset Row

    private func assetRow(slide: LoreSlide) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            ForEach(slide.assets.indices, id: \.self) { index in
                let asset = slide.assets[index]
                assetCell(asset: asset, accentColor: slide.accentColor, index: index)
            }
        }
        .opacity(assetsOpacity)
        .offset(y: assetsOffsetY)
    }

    private func assetCell(asset: LoreSlide.SlideAsset, accentColor: Color, index: Int) -> some View {
        ZStack {
            // Glow behind asset
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: asset.size * 0.6
                    )
                )
                .frame(width: asset.size * 1.2, height: asset.size * 1.2)

            Image(asset.name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: asset.size, height: asset.size)
                .offset(y: asset.offsetY)
                .shadow(color: accentColor.opacity(0.4), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 6, y: 4)
        }
    }

    // MARK: - Text Block

    private func textBlock(slide: LoreSlide) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Text(slide.title)
                .font(DarkFantasyTheme.title)
                .foregroundStyle(slide.accentColor)
                .tracking(2)
                .multilineTextAlignment(.center)
                .shadow(color: slide.accentColor.opacity(0.4), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 4)

            Text(slide.body)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, LayoutConstants.spaceSM)

            if let footnote = slide.footnote {
                Text(footnote)
                    .font(DarkFantasyTheme.body(size: 14))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            }
        }
        .opacity(contentOpacity)
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Progress bar
            progressBar

            // CTA Button
            if isLastSlide {
                Button {
                    HapticManager.heavy()
                    SFXManager.shared.play(.uiConfirm)
                    enterGame()
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        if isEntering {
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.8)
                        }
                        Text(isEntering ? "ENTERING..." : "ENTER HEXBOUND")
                            .font(DarkFantasyTheme.section(size: 16))
                            .tracking(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.primary)
                .disabled(isEntering)
                .transition(.opacity)
            } else {
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    advanceSlide()
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.section(size: 15))
                            .tracking(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.neutral)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLastSlide)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let progress = CGFloat(currentSlide + 1) / CGFloat(slides.count)

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.borderSubtle.opacity(0.4))

                // Fill
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(
                        LinearGradient(
                            colors: [
                                slides[currentSlide].accentColor.opacity(0.7),
                                slides[currentSlide].accentColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: totalWidth * progress)
                    .shadow(color: slides[currentSlide].accentColor.opacity(0.5), radius: 6)
                    .animation(.easeInOut(duration: 0.4), value: currentSlide)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, LayoutConstants.spaceLG)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
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
        animateSlideOut(direction: -1) {
            currentSlide += 1
            animateSlideIn()
        }
    }

    private func retreatSlide() {
        guard currentSlide > 0 else { return }
        animateSlideOut(direction: 1) {
            currentSlide -= 1
            animateSlideIn()
        }
    }

    private func enterGame() {
        guard !isEntering else { return }
        isEntering = true
        Task { @MainActor in
            let initService = GameInitService(appState: appState, cache: cache)
            await initService.loadGameData()
            appState.currentScreen = .game
        }
    }

    // MARK: - Animations

    private func animateSlideIn() {
        assetsOpacity = 0
        assetsOffsetY = 20
        contentOpacity = 0
        bgOpacity = 0
        slideOffset = 0

        withAnimation(.easeOut(duration: 0.5)) {
            bgOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
            assetsOpacity = 1
            assetsOffsetY = 0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            contentOpacity = 1
        }
    }

    private func animateSlideOut(direction: CGFloat, completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.2)) {
            slideOffset = direction * 60
            assetsOpacity = 0
            contentOpacity = 0
            bgOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            slideOffset = -direction * 60
            completion()
        }
    }
}
