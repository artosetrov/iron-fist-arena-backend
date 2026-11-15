import SwiftUI

/// Shell Game — variant A "stage" (2026-11-04): Finch stands behind his
/// table, the cups sit on it, one dock at the bottom carries the bet and the
/// action. No scroll and no result modal: the outcome is said on the stage.
struct ShellGameDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: ShellGameViewModel?
    @State private var shellHint: NPCHint?

    // Animation state
    @State private var cupLiftOffsets: [CGFloat] = [0, 0, 0]
    @State private var cupXOffsets: [CGFloat] = [0, 0, 0]

    // Juice states
    @State private var showWinBurst = false
    @State private var shakeOffset: CGFloat = 0
    @State private var lossFlashOpacity: Double = 0

    @State private var showRules = false
    /// Stake of the round on the table (the bet may change after it).
    @State private var lastStake = 0

    // Game phases
    enum GamePhase { case idle, revealing, shuffling, guessing, result }
    @State private var gamePhase: GamePhase = .idle
    @State private var revealedCup: Int? = nil

    /// `bg-shell-game` is 1920 × 3440; its table's back edge sits 25.46 % down.
    private static let bgHeightPerWidth: CGFloat = 3440.0 / 1920.0
    private static let tableEdge: CGFloat = 0.2546
    /// `tavern-npc-trickster` is 434 × 825.
    private static let finchAspect: CGFloat = 434.0 / 825.0
    /// How far a cup slides during the shuffle.
    private static let shuffleStep: CGFloat = 96

    var body: some View {
        Group {
            if let vm, vm.showsErrorState {
                ErrorStateView.loadFailed(message: vm.errorMessage) {
                    Task { await vm.loadStatus() }
                }
            } else if let vm {
                mainContent(vm)
            } else {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("SHELL GAME")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                MinigameGoldPill(gold: vm?.gold ?? appState.currentCharacter?.gold ?? 0)
            }
        }
        .sheet(isPresented: $showRules) {
            MinigameInfoSheet(
                title: "HOW TO PLAY",
                rows: [(label: "Find the ball", value: "×2 your bet"), (label: "Wrong cup", value: "bet lost")],
                notes: [
                    "Finch shows you the ball, then shuffles the three cups. Tap the cup you think hides it.",
                    "The server decides where the ball ends up; the shuffle on screen is only a show."
                ]
            )
        }
        .contextualHint(shellHint)
        .onAppear {
            AmbientManager.shared.setZone(.tavern)
        }
        .onDisappear {
            AmbientManager.shared.setZone(.hub)
        }
        .task {
            if vm == nil {
                let newVM = ShellGameViewModel(appState: appState)
                vm = newVM
                await newVM.loadStatus()
            }
            let quests = appState.cachedTypedQuests ?? []
            shellHint = ContextualHintProvider.shellGameHint(quests: quests)
        }
    }

    // MARK: - Main Content (stage + dock, no scroll)

    @ViewBuilder
    private func mainContent(_ vm: ShellGameViewModel) -> some View {
        ZStack {
            VStack(spacing: 0) {
                stage(vm)

                MinigameBetDock(
                    bets: ShellGameViewModel.bets,
                    selectedBet: Binding(get: { vm.selectedBet }, set: { vm.selectedBet = $0 }),
                    gold: vm.gold,
                    isLocked: gamePhase != .idle && gamePhase != .result,
                    ctaTitle: ctaText,
                    ctaEnabled: ctaEnabled(vm),
                    remainingText: "\(vm.playsRemaining) of \(vm.playsLimit) games left",
                    remainingIsEmpty: vm.playsRemaining == 0,
                    infoTitle: "How to play",
                    onInfo: { showRules = true },
                    onCTA: { ctaTapped(vm) }
                )
            }

            // Loss flash overlay
            Rectangle()
                .fill(DarkFantasyTheme.danger)
                .opacity(lossFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            RewardBurstView(style: .claim, isActive: $showWinBurst)
                .frame(height: 0) // Overlay effect, no layout space
                .allowsHitTesting(false)
        }
        .offset(x: shakeOffset)
    }

    // MARK: - Stage

    /// The tavern wall, Finch behind his table, the table drawn once more
    /// over his legs (the same picture, masked from the table's edge down, so
    /// the seam is invisible), the cups on top.
    private func stage(_ vm: ShellGameViewModel) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let tableY = h * 0.56
            let bgW = w * 1.44
            let bgH = bgW * Self.bgHeightPerWidth
            let bgTop = tableY - Self.tableEdge * bgH
            let finchH = h * 0.75
            let finchW = finchH * Self.finchAspect
            let finchTop = tableY - finchH * 0.6
            let cup = min(104, (w - LayoutConstants.screenPadding * 2 - LayoutConstants.spaceMD * 2) / 3 - 8)
            let cupsTop = tableY + LayoutConstants.spaceLG
            let rowHeight: CGFloat = 56

            ZStack(alignment: .topLeading) {
                tableScene
                    .frame(width: bgW, height: bgH)
                    .position(x: w / 2, y: bgTop + bgH / 2)

                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary, DarkFantasyTheme.bgPrimary.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: w, height: 110)
                .position(x: w / 2, y: bgTop + 55)
                .allowsHitTesting(false)

                Image("tavern-npc-trickster")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: finchW, height: finchH)
                    .position(x: w * 0.70, y: finchTop + finchH / 2)
                    .accessibilityHidden(true)

                // The table again, from its edge down — it hides Finch's legs.
                tableScene
                    .frame(width: bgW, height: bgH)
                    .mask(alignment: .top) {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: max(0, tableY - bgTop))
                            Color.black
                        }
                    }
                    .position(x: w / 2, y: bgTop + bgH / 2)
                    .allowsHitTesting(false)

                LinearGradient(
                    colors: [Color.clear, DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque)],
                    startPoint: UnitPoint(x: 0.5, y: 0.45),
                    endPoint: .bottom
                )
                .frame(width: w, height: h - tableY)
                .position(x: w / 2, y: tableY + (h - tableY) / 2)
                .allowsHitTesting(false)

                cupsRow(vm, cup: cup)
                    .frame(width: w)
                    .position(x: w / 2, y: cupsTop + cup * 0.6)

                MinigameSpeechBubble(text: bubbleText(vm))
                    .frame(width: min(w * 0.46, 200), alignment: .leading)
                    .padding(.leading, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceMD)
                    .zIndex(3)

                bottomRow(vm)
                    .frame(width: w, height: rowHeight)
                    .position(x: w / 2, y: h - LayoutConstants.spaceMD - rowHeight / 2)
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }

    private var tableScene: some View {
        Image("bg-shell-game")
            .resizable()
            .interpolation(.high)
            .opacity(DarkFantasyTheme.opacityOpaque)
            .accessibilityHidden(true)
    }

    /// Finch narrates the round; between rounds he says his piece.
    private func bubbleText(_ vm: ShellGameViewModel) -> String {
        switch gamePhase {
        case .revealing: return "Watch closely — it's under this one."
        case .shuffling: return "Follow the cup, friend…"
        case .guessing:  return "So? Pick a cup."
        case .idle, .result: return vm.npcSpeech
        }
    }

    @ViewBuilder
    private func bottomRow(_ vm: ShellGameViewModel) -> some View {
        if gamePhase == .result, let result = vm.result {
            let isWin = result == "win"
            MinigameResultPlaque(
                isWin: isWin,
                badge: "×2",
                amount: isWin ? vm.winAmount : lastStake,
                caption: isWin ? "sharp eyes — the gold is yours" : "wrong cup — Finch keeps it"
            )
        } else {
            MinigameStagePill {
                Image("icon-gold")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                Text("Find the ball — win")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text((vm.selectedBet * 2).formatted())
                    .font(DarkFantasyTheme.cardTitle)
                    .monospacedDigit()
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }

    // MARK: - Cups

    private func cupsRow(_ vm: ShellGameViewModel, cup: CGFloat) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            ForEach(vm.cups, id: \.self) { index in
                cupView(index, vm: vm, cup: cup)
                    .offset(x: cupXOffsets[index])
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: cupXOffsets[index])
            }
        }
    }

    @ViewBuilder
    private func cupView(_ index: Int, vm: ShellGameViewModel, cup: CGFloat) -> some View {
        let isWinner = vm.winningCup == index
        let showBall = (gamePhase == .revealing && revealedCup == index) ||
                       (gamePhase == .result && isWinner)
        let cupHeight = cup * 256.0 / 240.0
        let ball = cup * 0.54

        // The whole game is three image-only buttons; without labels VoiceOver
        // announced "Button, Button, Button" (fixed 2026-10-14).
        Button {
            if gamePhase == .guessing {
                Task { await pickCup(index, vm: vm) }
            }
        } label: {
            ZStack(alignment: .bottom) {
                // Shadow on the table
                Ellipse()
                    .fill(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy))
                    .frame(width: cup * 0.88, height: 16)
                    .offset(y: 6)

                // Pickable: a gold ring on the table under each cup (static, no idle glow)
                if gamePhase == .guessing {
                    Ellipse()
                        .stroke(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityOpaque), lineWidth: 2)
                        .frame(width: cup * 0.96, height: 22)
                        .offset(y: 8)
                        .transition(.opacity)
                }

                // Ball — visible before the shuffle (reveal) and after the guess (result)
                if showBall {
                    Image("shell_ball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ball, height: ball)
                        .transition(.opacity)
                }

                // Cup with lift animation
                Image("shell_cup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: cup, height: cupHeight)
                    .depthShadow(.elevated)
                    .offset(y: cupLiftOffsets[index])
                    .animation(.spring(response: 0.38, dampingFraction: 0.62), value: cupLiftOffsets[index])
            }
            .frame(width: cup + 8, height: cupHeight + 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cup \(index + 1)")
        .accessibilityValue(showBall ? "Ball" : "")
        .accessibilityHint(gamePhase == .guessing ? "Double tap to pick this cup" : "")
        // NOTE: use allowsHitTesting instead of .disabled — .disabled auto-dims
        // the button and makes the cup look semi-transparent in idle/shuffle phases.
        .allowsHitTesting(gamePhase == .guessing)
    }

    // MARK: - CTA

    private var ctaText: String {
        switch gamePhase {
        case .idle:                  return "PLAY"
        case .revealing, .shuffling: return "WATCH…"
        case .guessing:              return "PICK A CUP"
        case .result:                return "PLAY AGAIN"
        }
    }

    private func ctaEnabled(_ vm: ShellGameViewModel) -> Bool {
        switch gamePhase {
        case .idle:   return vm.canPlay
        case .result: return vm.gold >= vm.selectedBet && vm.playsRemaining > 0
        default:      return false
        }
    }

    private func ctaTapped(_ vm: ShellGameViewModel) {
        switch gamePhase {
        case .idle:
            guard vm.canPlay else { return }
            HapticManager.heavy()
            SFXManager.shared.play(.uiConfirm)
            Task { await startPressed(vm: vm) }
        case .result:
            // Straight into the next round with the bet on the dock.
            HapticManager.heavy()
            SFXManager.shared.play(.uiConfirm)
            resetGame(vm: vm)
            Task {
                try? await Task.sleep(for: .seconds(0.35))
                guard vm.canPlay else { return }
                await startPressed(vm: vm)
            }
        default:
            break
        }
    }

    // MARK: - Actions

    private func startPressed(vm: ShellGameViewModel) async {
        lastStake = vm.selectedBet
        // Start session on server -> get reveal cup
        let revealCup = await vm.startGame()
        guard let revealCup else { return }

        revealedCup = revealCup
        gamePhase = .revealing

        // Lift cup to show ball
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            cupLiftOffsets[revealCup] = -68
        }
        try? await Task.sleep(for: .seconds(1.5))

        // Lower cup (hide ball)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cupLiftOffsets[revealCup] = 0
        }
        try? await Task.sleep(for: .seconds(0.5))

        // Shuffle animation
        gamePhase = .shuffling
        SFXManager.shared.play(.shellShuffle)
        let swapCount = 4 + Int.random(in: 0...2) // 4-6 shuffles
        for _ in 0..<swapCount {
            let cup1 = Int.random(in: 0..<3)
            var cup2 = Int.random(in: 0..<3)
            while cup2 == cup1 { cup2 = Int.random(in: 0..<3) }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                cupXOffsets[cup1] = Self.shuffleStep
                cupXOffsets[cup2] = -Self.shuffleStep
            }
            try? await Task.sleep(for: .seconds(0.45))

            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                cupXOffsets[cup1] = 0
                cupXOffsets[cup2] = 0
            }
            try? await Task.sleep(for: .seconds(0.45))
        }

        // Ready for user to pick
        withAnimation(MotionConstants.smooth) {
            gamePhase = .guessing
        }
    }

    private func pickCup(_ cup: Int, vm: ShellGameViewModel) async {
        HapticManager.selection()
        await vm.guess(cup: cup)

        // Lift winning cup to reveal ball
        if let winCup = vm.winningCup {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                cupLiftOffsets[winCup] = -68
            }
        }

        // NPC speech update
        vm.onResultComplete()

        withAnimation(MotionConstants.springBouncy) {
            gamePhase = .result
        }

        // Win / Loss feedback, said on the stage
        if vm.result == "win" {
            HapticManager.success()
            SFXManager.shared.play(.coinsJingle)
            showWinBurst = true
        } else {
            HapticManager.error()
            triggerLossShake()
        }
    }

    // MARK: - Juice Helpers

    private func triggerLossShake() {
        // Brief red flash
        withAnimation(.easeIn(duration: 0.05)) {
            lossFlashOpacity = 0.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: MotionConstants.instant)) {
                lossFlashOpacity = 0
            }
        }

        // Screen shake
        let intensity: CGFloat = MotionConstants.shakeLightIntensity
        let cycles = 3
        let cycleDuration = MotionConstants.shakeDuration / Double(cycles)

        for i in 0..<cycles {
            let fraction = 1.0 - (CGFloat(i) / CGFloat(cycles))
            let mag = intensity * fraction
            let delay = Double(i) * cycleDuration

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: cycleDuration * 0.5)) {
                    shakeOffset = mag * (i.isMultiple(of: 2) ? 1 : -1)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + cycleDuration * 0.5) {
                withAnimation(.linear(duration: cycleDuration * 0.5)) {
                    shakeOffset = 0
                }
            }
        }
    }

    private func resetGame(vm: ShellGameViewModel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            vm.reset()
            cupLiftOffsets = [0, 0, 0]
            cupXOffsets = [0, 0, 0]
            revealedCup = nil
            gamePhase = .idle
            showWinBurst = false
            shakeOffset = 0
            lossFlashOpacity = 0
        }
    }
}
