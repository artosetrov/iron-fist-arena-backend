import SwiftUI

// MARK: - Comic Panel Data

private struct ComicPanel {
    let area: String          // Grid area name
    let imageAsset: String    // xcassets name
    let caption: String?      // Typewriter text below grid
    let isWide: Bool          // Landscape (16:9+) vs portrait/square
}

private struct ComicPage {
    let title: String
    let accentColor: Color
    let panels: [ComicPanel]
    let finalText: String?    // "YOUR TURN." on last page
    let bgmTrack: String      // AudioManager BGM filename
}

// MARK: - OnboardingCinematicView
// Comic-style 3-page onboarding with mosaic panel layout.
// Panels reveal sequentially with typewriter captions.
// Matches comic-onboarding-prototype-v8.jsx 1:1.

struct OnboardingCinematicView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    private let heroName: String

    init(heroName: String) {
        self.heroName = heroName
    }

    // MARK: - State

    @State private var currentPage = 0
    @State private var revealedCount = 0
    @State private var activeCaption = -1
    @State private var justRevealed = -1
    @State private var showFinal = false
    @State private var finalTypedText = ""
    @State private var finalDone = false
    @State private var transitioning = false
    @State private var isEntering = false

    // Typewriter
    @State private var displayedCaption = ""
    @State private var captionDone = false
    @State private var typewriterTask: Task<Void, Never>?

    // Auto-reveal timer
    @State private var revealTask: Task<Void, Never>?

    // YOUR TURN typewriter
    @State private var finalTask: Task<Void, Never>?

    // MARK: - Pages

    private var pages: [ComicPage] {
        [
            ComicPage(
                title: "WELCOME TO HEXBOUND",
                accentColor: DarkFantasyTheme.gold,
                panels: [
                    ComicPanel(area: "city", imageAsset: "onboarding-city-panorama",
                               caption: "HEXBOUND. A city older than regret.", isWide: true),
                    ComicPanel(area: "street", imageAsset: "onboarding-merchant-meet",
                               caption: "They sell swords, curses, and secondhand potions. No refunds.", isWide: false),
                    ComicPanel(area: "npc", imageAsset: "onboarding-tavern-keeper",
                               caption: "\u{201C}You look like easy money. Welcome.\u{201D}", isWide: false),
                ],
                finalText: nil,
                bgmTrack: "main-theme.mp3"
            ),
            ComicPage(
                title: "BLOOD & GLORY",
                accentColor: DarkFantasyTheme.danger,
                panels: [
                    ComicPanel(area: "arena", imageAsset: "onboarding-arena-battle",
                               caption: "Bakers fight. Priests fight. Even the rats have a ranking.", isWide: true),
                    ComicPanel(area: "victory", imageAsset: "onboarding-victory",
                               caption: "Win, and they sing songs about you.", isWide: false),
                    ComicPanel(area: "defeat", imageAsset: "onboarding-defeat",
                               caption: "Lose, and they sing funnier ones.", isWide: false),
                    ComicPanel(area: "dungeon", imageAsset: "onboarding-dungeon-gate",
                               caption: "Below the city, things get worse. Much worse.", isWide: true),
                ],
                finalText: nil,
                bgmTrack: "arena-pvp.mp3"
            ),
            ComicPage(
                title: "YOUR TURN",
                accentColor: DarkFantasyTheme.gold,
                panels: [
                    ComicPanel(area: "hero", imageAsset: "onboarding-dungeon-charge",
                               caption: "Every legend started broke, confused, and slightly terrified.", isWide: true),
                    ComicPanel(area: "dvictory", imageAsset: "onboarding-dungeon-victory",
                               caption: "The difference? They fought anyway.", isWide: false),
                    ComicPanel(area: "forge", imageAsset: "onboarding-blacksmith",
                               caption: nil, isWide: false),
                ],
                finalText: "YOUR TURN.",
                bgmTrack: "arena-pvp.mp3"
            ),
        ]
    }

    private var page: ComicPage { pages[currentPage] }
    private var totalPanels: Int { page.panels.count }
    private var allRevealed: Bool { revealedCount >= totalPanels }
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    /// Background art asset per page — atmospheric, heavily dimmed
    private var pageBgAsset: String {
        switch currentPage {
        case 0: return "bg-shop"      // City/merchant vibe
        case 1: return "bg-arena"     // Blood & glory
        case 2: return "bg-dungeon"   // Final challenge
        default: return "bg-hub"
        }
    }

    // Page transition
    @State private var curtainOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()

            // Background art — dark, atmospheric, doesn't compete with comic panels
            Image(pageBgAsset)
                .resizable()
                .interpolation(.medium)
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .clipped()
                .ignoresSafeArea()
                .opacity(0.12)
                .blur(radius: 6)
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Vignette overlay to darken edges
            RadialGradient(
                colors: [Color.clear, DarkFantasyTheme.bgAbyss.opacity(0.7), DarkFantasyTheme.bgAbyss],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Page dots — top
                pageDots
                    .padding(.top, LayoutConstants.spaceSM)

                // Centered content area
                Spacer(minLength: LayoutConstants.spaceSM)

                // Page title
                pageTitle
                    .padding(.bottom, LayoutConstants.spaceSM)

                // Comic grid with ornamental frame
                comicGrid
                    .padding(.horizontal, LayoutConstants.spaceMS)

                // Caption area
                captionArea
                    .frame(minHeight: 85)

                Spacer(minLength: LayoutConstants.spaceSM)

                // Bottom buttons
                bottomButtons
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.space2XL)
            }
            .safeAreaPadding(.top)

            // Page transition curtain — dramatic dark fade (not white flash)
            DarkFantasyTheme.bgAbyss
                .ignoresSafeArea()
                .opacity(curtainOpacity)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { handleTap() }
        .gesture(swipeGesture)
        .onAppear {
            AudioManager.shared.playBGM(page.bgmTrack)
            scheduleReveal(delay: 0.6)
        }
        .onDisappear {
            revealTask?.cancel()
            typewriterTask?.cancel()
            finalTask?.cancel()
        }
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(
                        i == currentPage
                            ? page.accentColor
                            : (i < currentPage
                               ? DarkFantasyTheme.textTertiary.opacity(0.3)
                               : DarkFantasyTheme.borderSubtle.opacity(0.3))
                    )
                    .frame(width: i == currentPage ? 20 : 5, height: 5)
                    .shadow(
                        color: i == currentPage ? page.accentColor.opacity(0.4) : .clear,
                        radius: 4
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Page Title

    private var pageTitle: some View {
        Text(page.title)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(page.accentColor)
            .tracking(4)
            .opacity(revealedCount > 0 ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: revealedCount)
    }

    // MARK: - Comic Grid

    private var comicGrid: some View {
        ZStack {
            // Ornamental frame
            ornamentalFrame

            // Grid content
            gridContent
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
        }
        .clipped()
    }

    private var gridContent: some View {
        let gutter: CGFloat = 3
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                DarkFantasyTheme.bgAbyss

                // Layout panels based on current page
                panelLayout(in: CGSize(width: w, height: h), gutter: gutter)
            }
        }
        .aspectRatio(pageAspectRatio, contentMode: .fit)
    }

    /// Computed aspect ratio for the grid based on page layout
    private var pageAspectRatio: CGFloat {
        switch currentPage {
        case 0: return 0.72  // Page 1: city wide + 2 portrait
        case 1: return 0.85  // Page 2: arena + 2 square + dungeon
        case 2: return 0.72  // Page 3: hero wide + 2 below
        default: return 0.75
        }
    }

    // MARK: - Panel Layout

    @ViewBuilder
    private func panelLayout(in size: CGSize, gutter: CGFloat) -> some View {
        let w = size.width
        let h = size.height

        switch currentPage {
        case 0:
            // Page 1: city (wide top), street + npc (bottom row)
            // Rows: 9fr 10fr
            let topH = h * 9 / 19
            let botH = h * 10 / 19
            let halfW = (w - gutter) / 2

            panelView(index: 0, frame: CGRect(x: 0, y: 0, width: w, height: topH - gutter / 2))
            panelView(index: 1, frame: CGRect(x: 0, y: topH + gutter / 2, width: halfW, height: botH - gutter / 2))
            panelView(index: 2, frame: CGRect(x: halfW + gutter, y: topH + gutter / 2, width: halfW, height: botH - gutter / 2))

        case 1:
            // Page 2: arena (wide), victory + defeat (row), dungeon (wide)
            // Rows: 3fr 3.6fr 4fr → total 10.6
            let r1 = h * 3 / 10.6
            let r2 = h * 3.6 / 10.6
            let r3 = h * 4 / 10.6
            let halfW = (w - gutter) / 2

            panelView(index: 0, frame: CGRect(x: 0, y: 0, width: w, height: r1 - gutter / 2))
            panelView(index: 1, frame: CGRect(x: 0, y: r1 + gutter / 2, width: halfW, height: r2 - gutter))
            panelView(index: 2, frame: CGRect(x: halfW + gutter, y: r1 + gutter / 2, width: halfW, height: r2 - gutter))
            panelView(index: 3, frame: CGRect(x: 0, y: r1 + r2 + gutter / 2, width: w, height: r3 - gutter / 2))

        case 2:
            // Page 3: hero (wide top), dvictory + forge (bottom row)
            // Rows: 9fr 10fr
            let topH = h * 9 / 19
            let botH = h * 10 / 19
            let halfW = (w - gutter) / 2

            panelView(index: 0, frame: CGRect(x: 0, y: 0, width: w, height: topH - gutter / 2))
            panelView(index: 1, frame: CGRect(x: 0, y: topH + gutter / 2, width: halfW, height: botH - gutter / 2))
            panelView(index: 2, frame: CGRect(x: halfW + gutter, y: topH + gutter / 2, width: halfW, height: botH - gutter / 2))

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func panelView(index: Int, frame: CGRect) -> some View {
        let visible = index < revealedCount
        let flash = index == justRevealed

        ZStack {
            DarkFantasyTheme.bgPrimary

            if visible {
                Image(page.panels[index].imageAsset)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: frame.width, height: frame.height)
                    .clipped()
                    .brightness(flash ? 0.15 : 0)

                // Vignette
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgAbyss.opacity(0.06),
                        Color.clear,
                        Color.clear,
                        DarkFantasyTheme.bgAbyss.opacity(0.28),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Accent glow on reveal
                if flash {
                    RadialGradient(
                        colors: [page.accentColor.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: frame.width * 0.5
                    )
                    .transition(.opacity)
                }
            }
        }
        .frame(width: frame.width, height: frame.height)
        .clipShape(Rectangle())
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: visible)
        .animation(.easeOut(duration: 0.8), value: flash)
        .position(x: frame.midX, y: frame.midY)
    }

    // MARK: - Ornamental Frame

    private var ornamentalFrame: some View {
        GeometryReader { _ in
            // Outer ornamental stroke
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 2)

            // Inner bevel border
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD + 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            DarkFantasyTheme.borderMedium.opacity(0.35),
                            Color.black.opacity(0.20),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .padding(3)

            // Corner brackets
            CornerBracketOverlay(
                color: page.accentColor,
                length: 18,
                thickness: 2,
                inset: -1
            )

            // Corner diamonds
            CornerDiamondOverlay(
                color: page.accentColor,
                size: 6,
                offset: 3.5
            )

            // Side diamonds
            SideDiamondOverlay(
                color: page.accentColor,
                size: 5
            )
        }
        .aspectRatio(pageAspectRatio, contentMode: .fit)
        .allowsHitTesting(false)
    }

    // MARK: - Caption Area

    private var captionArea: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Ornamental divider line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, page.accentColor.opacity(0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 44, height: 1)
                .opacity(activeCaption >= 0 ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: activeCaption)
                .padding(.top, LayoutConstants.spaceSM)

            // Caption text
            if activeCaption >= 0, activeCaption < totalPanels,
               page.panels[activeCaption].caption != nil {
                HStack(spacing: 0) {
                    Text(displayedCaption)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    // Blinking cursor
                    if !captionDone {
                        Rectangle()
                            .fill(page.accentColor)
                            .frame(width: 2, height: 14)
                            .opacity(captionDone ? 0 : 1)
                            .modifier(BlinkModifier())
                    }
                }
                .frame(maxWidth: 320)
                .transition(.opacity)
            }

            // YOUR TURN final text
            if isLastPage && showFinal {
                Text(finalTypedText)
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(5)
                    .shadow(
                        color: DarkFantasyTheme.gold.opacity(finalDone ? 0.4 : 0.15),
                        radius: finalDone ? 30 : 12
                    )
                    .animation(.easeOut(duration: 0.5), value: finalDone)
                    .padding(.top, LayoutConstants.spaceXS)
            }

            // Tap hint
            if captionDone && !allRevealed {
                Text("tap to reveal")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.4))
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        Group {
            if isLastPage && allRevealed && finalDone {
                // ENTER HEXBOUND — full-width gold CTA
                Button {
                    HapticManager.heavy()
                    SFXManager.shared.play(.uiConfirm)
                    enterGame()
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        if isEntering {
                            HexPulseLoader.onGold()
                        }
                        Text(isEntering ? "ENTERING..." : "ENTER HEXBOUND")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(isEntering)
                .transition(.opacity.combined(with: .offset(y: 20)))
            } else {
                // SKIP + CONTINUE — same height via .secondary + .primary
                HStack(spacing: LayoutConstants.spaceSM) {
                    // Skip — secondary outlined style (matches primary height = 56)
                    Button {
                        HapticManager.light()
                        SFXManager.shared.play(.uiTap)
                        enterGame()
                    } label: {
                        Text("SKIP")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary)

                    // Continue — full primary gold (same height = 56)
                    Button {
                        HapticManager.light()
                        SFXManager.shared.play(.uiTap)
                        handleContinue()
                    } label: {
                        Text("CONTINUE")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                }
            }
        }
        .animation(.easeInOut(duration: MotionConstants.fast), value: isLastPage && allRevealed && finalDone)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 60)
            .onEnded { value in
                let dx = value.translation.width
                if dx < -60 && allRevealed && captionDone {
                    goToPage(direction: 1)
                } else if dx > 60 && currentPage > 0 {
                    goToPage(direction: -1)
                }
            }
    }

    // MARK: - Interaction Logic

    private func handleTap() {
        guard !transitioning else { return }

        if !captionDone && activeCaption >= 0 {
            // Skip current typewriter
            skipTypewriter()
        } else {
            // Reveal next panel
            revealTask?.cancel()
            revealNext()
        }
    }

    private func handleContinue() {
        if allRevealed && captionDone && !isLastPage {
            goToPage(direction: 1)
        } else if allRevealed && captionDone && isLastPage && !showFinal {
            triggerFinalText()
        } else {
            // Fast-forward: reveal remaining panels
            revealTask?.cancel()
            revealNext()
        }
    }

    // MARK: - Reveal Logic

    private func revealNext() {
        guard revealedCount < totalPanels else {
            // All panels revealed
            if isLastPage && page.finalText != nil && !showFinal {
                triggerFinalText()
            } else if !isLastPage && captionDone {
                goToPage(direction: 1)
            }
            return
        }

        let idx = revealedCount

        withAnimation {
            revealedCount = idx + 1
            justRevealed = idx
        }

        SFXManager.shared.play(.uiTap)
        HapticManager.light()

        // Clear flash after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if justRevealed == idx {
                withAnimation { justRevealed = -1 }
            }
        }

        // Start caption after panel settles
        let panel = page.panels[idx]
        if let caption = panel.caption {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activeCaption = idx
                startTypewriter(text: caption)
            }
        } else {
            activeCaption = -1
            displayedCaption = ""
            captionDone = true
            // Auto-continue to next if no caption
            scheduleReveal(delay: 0.5)
        }
    }

    private func scheduleReveal(delay: Double) {
        revealTask?.cancel()
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            revealNext()
        }
    }

    // MARK: - Page Navigation

    private func goToPage(direction: Int) {
        let next = currentPage + direction
        guard next >= 0 && next < pages.count else { return }
        guard !transitioning else { return }

        revealTask?.cancel()
        typewriterTask?.cancel()
        finalTask?.cancel()
        transitioning = true

        HapticManager.medium()

        // Phase 1: dark curtain fades IN (cinematic wipe)
        withAnimation(.easeIn(duration: 0.25)) {
            curtainOpacity = 1
        }

        // Phase 2: swap content while hidden behind curtain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPage = next
            revealedCount = 0
            activeCaption = -1
            displayedCaption = ""
            captionDone = false
            showFinal = false
            finalTypedText = ""
            finalDone = false
            justRevealed = -1

            // Switch BGM if needed
            AudioManager.shared.playBGM(page.bgmTrack)

            // Phase 3: curtain fades OUT — reveals new page
            withAnimation(.easeOut(duration: 0.4)) {
                curtainOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                transitioning = false
                scheduleReveal(delay: 0.5)
            }
        }
    }

    // MARK: - Typewriter

    private func startTypewriter(text: String) {
        typewriterTask?.cancel()
        displayedCaption = ""
        captionDone = false

        typewriterTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))

            for char in text {
                guard !Task.isCancelled else {
                    displayedCaption = text
                    captionDone = true
                    return
                }
                displayedCaption.append(char)

                let ms: UInt64
                if ".!?…".contains(char) { ms = 224 }
                else if ",;:—–".contains(char) { ms = 84 }
                else { ms = 28 }
                try? await Task.sleep(nanoseconds: ms * 1_000_000)
            }
            captionDone = true

            // Auto-reveal next panel after caption finishes
            scheduleReveal(delay: 0.7)
        }
    }

    private func skipTypewriter() {
        typewriterTask?.cancel()
        if activeCaption >= 0, activeCaption < totalPanels,
           let caption = page.panels[activeCaption].caption {
            displayedCaption = caption
        }
        captionDone = true
    }

    // MARK: - Final Text (YOUR TURN.)

    private func triggerFinalText() {
        guard let text = page.finalText else { return }
        showFinal = true
        finalTypedText = ""
        finalDone = false

        SFXManager.shared.play(.uiConfirm)
        HapticManager.medium()

        finalTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            for char in text {
                guard !Task.isCancelled else {
                    finalTypedText = text
                    finalDone = true
                    return
                }
                finalTypedText.append(char)
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
            finalDone = true
            HapticManager.heavy()
        }
    }

    // MARK: - Enter Game

    private func enterGame() {
        guard !isEntering else { return }
        isEntering = true
        revealTask?.cancel()
        typewriterTask?.cancel()
        finalTask?.cancel()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            let initService = GameInitService(appState: appState, cache: cache)
            await initService.loadGameData()
            appState.currentScreen = .game
        }
    }
}

// MARK: - Blink Modifier

private struct BlinkModifier: ViewModifier {
    @State private var visible = true

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
