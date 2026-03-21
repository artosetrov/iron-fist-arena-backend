import SwiftUI

struct ShellGameDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: ShellGameViewModel?

    // Animation state
    @State private var cupLiftOffsets: [CGFloat] = [0, 0, 0]

    // Juice states
    @State private var showWinBurst = false
    @State private var shakeOffset: CGFloat = 0
    @State private var lossFlashOpacity: Double = 0

    // Game phases
    enum GamePhase { case idle, revealing, shuffling, guessing, result }
    @State private var gamePhase: GamePhase = .idle
    @State private var revealedCup: Int? = nil

    var statusText: String {
        switch gamePhase {
        case .idle:      return "Place your bet and start!"
        case .revealing: return "Remember the cup!"
        case .shuffling: return "Watch closely..."
        case .guessing:  return "Pick a cup!"
        case .result:    return ""
        }
    }

    /// Bottom button text depending on phase
    var bottomButtonText: String {
        switch gamePhase {
        case .idle:
            return "START"
        case .revealing, .shuffling, .guessing:
            return "CHOOSE A CUP"
        case .result:
            return "PLAY AGAIN"
        }
    }

    /// Whether the bottom button is enabled
    var bottomButtonEnabled: Bool {
        switch gamePhase {
        case .idle:
            return vm?.canPlay ?? false
        case .result:
            return true
        default:
            return false
        }
    }

    var body: some View {
        ZStack {
            // Background image
            GeometryReader { geo in
                Image("bg-shell-game")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            // Dark overlay for UI readability
            DarkFantasyTheme.bgScrim
                .ignoresSafeArea()

            // Loss flash overlay
            Rectangle()
                .fill(DarkFantasyTheme.danger)
                .opacity(lossFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if let vm {
                VStack(spacing: LayoutConstants.spaceLG) {
                    // Active quest banner
                    ActiveQuestBanner(questTypes: ["shell_game_play"])
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    // Gold display
                    HStack {
                        Spacer()
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("\u{1FA99}")
                            NumberTickUpText(
                                value: vm.gold,
                                color: DarkFantasyTheme.goldBright,
                                font: DarkFantasyTheme.section(size: LayoutConstants.textLabel)
                            )
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // ─── BET SELECTOR WIDGET ────────────────────────────
                    betSelectorWidget(vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    Spacer()

                    // ─── STATUS TEXT ─────────────────────────────────────
                    if gamePhase != .result {
                        Text(statusText)
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .animation(.easeInOut(duration: 0.2), value: gamePhase)
                    }

                    // ─── CUPS (no labels, no horizontal movement) ───────
                    HStack(spacing: LayoutConstants.spaceLG) {
                        ForEach(vm.cups, id: \.self) { cup in
                            cupView(cup: cup, vm: vm)
                        }
                    }
                    .offset(x: shakeOffset)
                    .padding(.top, LayoutConstants.spaceLG)

                    // ─── RESULT ──────────────────────────────────────────
                    if gamePhase == .result, let result = vm.result {
                        VStack(spacing: LayoutConstants.spaceSM) {
                            ZStack {
                                Text(result == "win" ? "You Win!" : "Wrong Cup!")
                                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                                    .foregroundStyle(result == "win" ? DarkFantasyTheme.success : DarkFantasyTheme.danger)

                                if result == "win" {
                                    RewardBurstView(style: .claim, isActive: $showWinBurst)
                                }
                            }

                            if result == "win" {
                                Text("+\(vm.winAmount) gold")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Spacer()

                    // ─── BOTTOM BUTTON (always visible) ─────────────────
                    Button {
                        if gamePhase == .idle {
                            HapticManager.medium()
                            Task { await startPressed(vm: vm) }
                        } else if gamePhase == .result {
                            HapticManager.light()
                            resetGame(vm: vm)
                        }
                    } label: {
                        Text(bottomButtonText)
                    }
                    .buttonStyle(.primary)
                    .disabled(!bottomButtonEnabled)
                    .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.4, isActive: bottomButtonEnabled)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceSM)
                    .animation(.easeInOut(duration: 0.25), value: gamePhase)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("SHELL GAME")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if vm == nil { vm = ShellGameViewModel(appState: appState) }
        }
    }

    // MARK: - Bet Selector Widget

    @ViewBuilder
    private func betSelectorWidget(vm: ShellGameViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("BET AMOUNT")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                Text("Win = 2x payout")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(ShellGameViewModel.bets, id: \.self) { bet in
                    Button {
                        HapticManager.selection()
                        vm.selectedBet = bet
                    } label: {
                        Text("\(bet)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.colorToggle(isActive: vm.selectedBet == bet))
                    .disabled(vm.gold < bet || gamePhase != .idle)
                }
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .opacity(gamePhase == .idle ? 1 : 0.5)
    }

    // MARK: - Cup View (no label, no horizontal offset)

    @ViewBuilder
    private func cupView(cup: Int, vm: ShellGameViewModel) -> some View {
        let isWinner = vm.winningCup == cup
        // Show ball when revealing (before shuffle) or when result shown
        let showBall = (gamePhase == .revealing && revealedCup == cup) ||
                       (gamePhase == .result && isWinner)

        Button {
            if gamePhase == .guessing {
                Task { await pickCup(cup, vm: vm) }
            }
        } label: {
            ZStack(alignment: .bottom) {
                // Ball — visible before shuffle (reveal) and after guess (result)
                if showBall {
                    Image("shell_ball")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }

                // Cup image with lift animation
                Image("shell_cup")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .offset(y: cupLiftOffsets[cup])
                    .opacity(gamePhase == .result && !isWinner ? 0.4 : 1.0)
                    .animation(.spring(response: 0.38, dampingFraction: 0.62), value: cupLiftOffsets[cup])
            }
            .frame(width: 110, height: 130)
        }
        .buttonStyle(.scalePress(0.95))
        .disabled(gamePhase != .guessing)
    }

    // MARK: - Actions

    private func startPressed(vm: ShellGameViewModel) async {
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

        // Skip shuffle — cups stay in place
        // Ready for user to pick
        gamePhase = .guessing
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

        withAnimation(.easeInOut(duration: 0.3)) {
            gamePhase = .result
        }

        // Win / Loss feedback
        if vm.result == "win" {
            HapticManager.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showWinBurst = true
            }
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
            withAnimation(.easeOut(duration: 0.15)) {
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
            revealedCup = nil
            gamePhase = .idle
            showWinBurst = false
            shakeOffset = 0
            lossFlashOpacity = 0
        }
    }
}
