import SwiftUI

// MARK: - Lore Slide Data

private struct LoreSlide {
    let symbol: String
    let symbolColor: Color
    let accentColor: Color
    let title: String
    let body: String
    let footnote: String?
}

// MARK: - LoreIntroView
// Shown once after first hero creation, before entering the hub.
// 5-slide presentation about the world of Hexbound.
// Quick, punchy, with dark humor.

struct LoreIntroView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var currentSlide = 0
    @State private var slideOffset: CGFloat = 0
    @State private var symbolScale: CGFloat = 0.5
    @State private var symbolOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var isEntering = false

    private let heroName: String

    init(heroName: String) {
        self.heroName = heroName
    }

    // MARK: - Slide Definitions

    private var slides: [LoreSlide] {
        [
            LoreSlide(
                symbol: "building.2.fill",
                symbolColor: DarkFantasyTheme.gold,
                accentColor: DarkFantasyTheme.gold,
                title: "ДОБРО ПОЖАЛОВАТЬ\nВ HEXBOUND",
                body: "Город Hexbound: древний, беспощадный, и, честно говоря, немного воняет.",
                footnote: "Здесь сила — это всё. А слабость стоит очень, очень дорого."
            ),
            LoreSlide(
                symbol: "figure.boxing",
                symbolColor: DarkFantasyTheme.danger,
                accentColor: DarkFantasyTheme.danger,
                title: "ЗДЕСЬ ДЕРУТСЯ ВСЕ",
                body: "Пекари дерутся. Торговцы дерутся. Местный священник дерётся по выходным и категорически это отрицает.",
                footnote: "Арена решает всё: твой ранг, твоё золото, и отношение людей на улице."
            ),
            LoreSlide(
                symbol: "exclamationmark.triangle.fill",
                symbolColor: DarkFantasyTheme.gold,
                accentColor: DarkFantasyTheme.goldBright,
                title: "ТВОЯ ТЕКУЩАЯ\nСИТУАЦИЯ",
                body: "Ты прибыл с: сомнительными решениями, потрёпанной гордостью, и золота — ровно на полбутерброда.",
                footnote: "Город заметил. Город не впечатлён."
            ),
            LoreSlide(
                symbol: "trophy.fill",
                symbolColor: DarkFantasyTheme.classMage,
                accentColor: DarkFantasyTheme.classMage,
                title: "НО ВОТ В ЧЁМ ДЕЛО...",
                body: "Каждая легенда в этом городе начинала точно так же: сломленной, растерянной и без гроша.",
                footnote: "Разница в том, что они начали драться. И теперь о них слагают песни. Стыдные, но всё же."
            ),
            LoreSlide(
                symbol: "flag.fill",
                symbolColor: DarkFantasyTheme.gold,
                accentColor: DarkFantasyTheme.gold,
                title: "ПОРА ПОДНИМАТЬСЯ,\n\(heroName.uppercased())",
                body: "Вооружайся. Сражайся. Карабкайся вверх.",
                footnote: "Hexbound не интересует, откуда ты. Только — куда ты идёшь.\n\nА идёшь ты наверх. Вероятно."
            )
        ]
    }

    private var isLastSlide: Bool { currentSlide == slides.count - 1 }

    // MARK: - Body

    var body: some View {
        ZStack {
            background
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
        }
        .ignoresSafeArea()
        .gesture(swipeGesture)
        .onAppear { animateSlideIn() }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()
            RadialGradient(
                colors: [
                    slides[currentSlide].accentColor.opacity(0.12),
                    DarkFantasyTheme.bgPrimary.opacity(0.8),
                    DarkFantasyTheme.bgAbyss
                ],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentSlide)

            // Subtle rune grid overlay
            Canvas { ctx, size in
                let spacing: CGFloat = 60
                let cols = Int(size.width / spacing) + 1
                let rows = Int(size.height / spacing) + 1
                for col in 0..<cols {
                    for row in 0..<rows {
                        let x = CGFloat(col) * spacing + 10
                        let y = CGFloat(row) * spacing + 10
                        var path = Path()
                        let d: CGFloat = 4
                        path.move(to: CGPoint(x: x, y: y - d))
                        path.addLine(to: CGPoint(x: x + d, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + d))
                        path.addLine(to: CGPoint(x: x - d, y: y))
                        path.closeSubpath()
                        ctx.fill(path, with: .color(DarkFantasyTheme.gold.opacity(0.04)))
                    }
                }
            }
            .ignoresSafeArea()
        }
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
                Text("ПРОПУСТИТЬ")
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
            // Symbol
            symbolView(slide: slide)

            // Divider
            DiamondDividerMotif()
                .padding(.horizontal, LayoutConstants.spaceLG)
                .opacity(textOpacity)

            // Title + Body
            textBlock(slide: slide)
        }
        .offset(x: slideOffset)
    }

    private func symbolView(slide: LoreSlide) -> some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(slide.accentColor.opacity(0.08))
                .frame(width: 112, height: 112)
                .overlay(
                    Circle()
                        .stroke(slide.accentColor.opacity(0.18), lineWidth: 1.5)
                )

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [slide.accentColor.opacity(0.15), DarkFantasyTheme.bgSecondary],
                        center: .center,
                        startRadius: 0,
                        endRadius: 44
                    )
                )
                .frame(width: 88, height: 88)
                .overlay(
                    Circle()
                        .stroke(slide.accentColor.opacity(0.35), lineWidth: 1.5)
                )

            Image(systemName: slide.symbol)
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(slide.symbolColor)
                .shadow(color: slide.accentColor.opacity(0.5), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4)
        }
        .shadow(color: slide.accentColor.opacity(0.2), radius: 20)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 8, y: 4)
        .scaleEffect(symbolScale)
        .opacity(symbolOpacity)
        .compositingGroup()
    }

    private func textBlock(slide: LoreSlide) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Text(slide.title)
                .font(DarkFantasyTheme.title(size: 24))
                .foregroundStyle(slide.accentColor)
                .tracking(2)
                .multilineTextAlignment(.center)
                .shadow(color: slide.accentColor.opacity(0.3), radius: 8)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 4)

            Text(slide.body)
                .font(DarkFantasyTheme.body(size: 16))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, LayoutConstants.spaceSM)

            if let footnote = slide.footnote {
                Text(footnote)
                    .font(DarkFantasyTheme.body(size: 13))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, LayoutConstants.spaceMD)
            }
        }
        .opacity(textOpacity)
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
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.8)
                        }
                        Text(isEntering ? "ВХОДИМ..." : "ВОЙТИ В HEXBOUND")
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
                        Text("ДАЛЕЕ")
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

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(0..<slides.count, id: \.self) { index in
                if index == currentSlide {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: 20, height: 6)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 4)
                } else {
                    Circle()
                        .fill(index < currentSlide
                              ? DarkFantasyTheme.gold.opacity(0.5)
                              : DarkFantasyTheme.borderMedium.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentSlide)
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
        symbolScale = 0.4
        symbolOpacity = 0
        textOpacity = 0
        slideOffset = 0

        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            symbolScale = 1.0
            symbolOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.12)) {
            textOpacity = 1.0
        }
    }

    private func animateSlideOut(direction: CGFloat, completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.2)) {
            slideOffset = direction * 60
            symbolOpacity = 0
            textOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            slideOffset = -direction * 60
            completion()
        }
    }
}
