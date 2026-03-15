import SwiftUI

struct ShellGameDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: ShellGameViewModel?

    // Animation state
    @State private var cupOffsets: [CGFloat] = [0, 0, 0]
    @State private var cupLiftOffsets: [CGFloat] = [0, 0, 0]
    @State private var cupScales: [CGFloat] = [1, 1, 1]

    // Game phases
    enum GamePhase { case idle, revealing, shuffling, guessing, result }
    @State private var gamePhase: GamePhase = .idle
    @State private var revealedCup: Int? = nil

    var statusText: String {
        switch gamePhase {
        case .idle:      return "Place your bet and start!"
        case .revealing: return "Remember the cup!"
        case .shuffling: return "Shuffling..."
        case .guessing:  return "Pick a cup!"
        case .result:    return ""
        }
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

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
                            Text("\(vm.gold)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // ─── BET SELECTOR (top) ───────────────────────────────
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text("BET AMOUNT")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        HStack(spacing: LayoutConstants.spaceSM) {
                            ForEach(ShellGameViewModel.bets, id: \.self) { bet in
                                Button {
                                    vm.selectedBet = bet
                                } label: {
                                    Text("\(bet)")
                                }
                                .buttonStyle(.colorToggle(isActive: vm.selectedBet == bet))
                                .disabled(vm.gold < bet || gamePhase != .idle)
                            }
                        }

                        Text("Win = 2x payout")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .opacity(gamePhase == .idle ? 1 : 0.5)

                    Spacer()

                    // ─── STATUS TEXT ──────────────────────────────────────
                    if gamePhase != .result {
                        Text(statusText)
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .animation(.easeInOut(duration: 0.2), value: gamePhase)
                    }

                    // ─── CUPS ─────────────────────────────────────────────
                    HStack(spacing: LayoutConstants.spaceLG) {
                        ForEach(vm.cups, id: \.self) { cup in
                            cupView(cup: cup, vm: vm)
                                .offset(x: cupOffsets[cup])
                                .scaleEffect(cupScales[cup])
                        }
                    }

                    // ─── START BUTTON ─────────────────────────────────────
                    if gamePhase == .idle {
                        Button {
                            Task { await startPressed(vm: vm) }
                        } label: {
                            Text("START")
                        }
                        .buttonStyle(.primary)
                        .disabled(!vm.canPlay)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                    }

                    // ─── RESULT ───────────────────────────────────────────
                    if gamePhase == .result, let result = vm.result {
                        VStack(spacing: LayoutConstants.spaceSM) {
                            Text(result == "win" ? "You Win!" : "Wrong Cup!")
                                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                                .foregroundStyle(result == "win" ? DarkFantasyTheme.success : DarkFantasyTheme.danger)

                            if result == "win" {
                                Text("+\(vm.winAmount) gold")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                            }

                            Button {
                                resetGame(vm: vm)
                            } label: {
                                Text("PLAY AGAIN")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                                    .padding(.horizontal, LayoutConstants.spaceLG)
                                    .frame(height: LayoutConstants.touchMin)
                                    .background(
                                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                            .stroke(DarkFantasyTheme.gold, lineWidth: 1)
                                    )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer()
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

    // MARK: - Cup View

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
            VStack(spacing: LayoutConstants.spaceSM) {
                ZStack(alignment: .bottom) {
                    // Ball — visible before shuffle (reveal) and after guess (result)
                    if showBall {
                        Image("shell_ball")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 46, height: 46)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }

                    // Cup image with lift animation
                    Image("shell_cup")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 66, height: 66)
                        .offset(y: cupLiftOffsets[cup])
                        .opacity(gamePhase == .result && !isWinner ? 0.4 : 1.0)
                        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: cupLiftOffsets[cup])
                }
                .frame(width: 90, height: 100)

                Text("Cup \(cup + 1)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .buttonStyle(.scalePress(0.9))
        .disabled(gamePhase != .guessing)
    }

    // MARK: - Actions

    private func startPressed(vm: ShellGameViewModel) async {
        // Start session on server → get reveal cup
        let revealCup = await vm.startGame()
        guard let revealCup else { return }

        revealedCup = revealCup
        gamePhase = .revealing

        // Lift cup to show ball
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            cupLiftOffsets[revealCup] = -52
        }
        try? await Task.sleep(for: .seconds(1.5))

        // Lower cup (hide ball before shuffle)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            cupLiftOffsets[revealCup] = 0
        }
        try? await Task.sleep(for: .seconds(0.4))

        // Shuffle
        gamePhase = .shuffling
        await performShuffle()

        // Ready for user to pick
        gamePhase = .guessing
    }

    private func performShuffle() async {
        let swapPairs: [(Int, Int)] = [(0, 2), (1, 0), (2, 1), (0, 1), (2, 0), (1, 2)]
        let cupSpacing: CGFloat = 90 + LayoutConstants.spaceLG

        for (a, b) in swapPairs {
            let dist = CGFloat(b - a) * cupSpacing
            withAnimation(.easeInOut(duration: 0.18)) {
                cupOffsets[a] = dist
                cupOffsets[b] = -dist
                cupScales[a] = 0.85
                cupScales[b] = 0.85
            }
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeInOut(duration: 0.12)) {
                cupOffsets[a] = 0
                cupOffsets[b] = 0
                cupScales[a] = 1
                cupScales[b] = 1
            }
            try? await Task.sleep(for: .seconds(0.1))
        }
    }

    private func pickCup(_ cup: Int, vm: ShellGameViewModel) async {
        await vm.guess(cup: cup)

        // Lift winning cup to reveal ball
        if let winCup = vm.winningCup {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                cupLiftOffsets[winCup] = -52
            }
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            gamePhase = .result
        }
    }

    private func resetGame(vm: ShellGameViewModel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            vm.reset()
            cupOffsets = [0, 0, 0]
            cupLiftOffsets = [0, 0, 0]
            cupScales = [1, 1, 1]
            revealedCup = nil
            gamePhase = .idle
        }
    }
}
