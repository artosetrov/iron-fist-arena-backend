import SwiftUI

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

    // Cup glow pulse (guessing phase)
    @State private var cupGlowActive = false

    // Result modal
    @State private var showResultModal = false

    // Game phases
    enum GamePhase { case idle, revealing, shuffling, guessing, result }
    @State private var gamePhase: GamePhase = .idle
    @State private var revealedCup: Int? = nil

    var statusText: String {
        switch gamePhase {
        case .idle:      return "PLACE YOUR BET"
        case .revealing: return "WATCH CLOSELY!"
        case .shuffling: return "FOLLOW THE CUP..."
        case .guessing:  return "PICK A CUP!"
        case .result:    return ""
        }
    }

    var body: some View {
        Group {
            if let vm {
                mainContent(vm)
                    .transaction { $0.animation = nil }
            } else {
                HexPulseLoader(.compact)
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .background(backgroundLayer.ignoresSafeArea())
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

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary

            Image("bg-shell-game")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(DarkFantasyTheme.opacityHeavy)

            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityMedium),
                    Color.clear,
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityDense)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Main Content (ZStack pattern — like Fortune Wheel)

    @ViewBuilder
    private func mainContent(_ vm: ShellGameViewModel) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Scrollable content: quest banner + payouts + cups
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        // Payout info card
                        payoutSection()

                        // Active quest banner (below payouts)
                        ActiveQuestBanner(questTypes: ["shell_game_play"])
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Cups stage — moved up, no status text header
                        cupsSection(vm)

                        // Spacer for NPC widget clearance (matches npcAvatarSize)
                        Spacer().frame(height: LayoutConstants.npcAvatarSize)
                    }
                }
            }

            // Loss flash overlay
            Rectangle()
                .fill(DarkFantasyTheme.danger)
                .opacity(lossFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // NPC Widget — fixed at bottom
            npcWidget(vm)

            // Result Modal overlay
            if showResultModal, let result = vm.result {
                resultModal(vm, result: result)
            }
        }
        .offset(x: shakeOffset)
    }

    // MARK: - Payout Section

    private func payoutSection() -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            payoutPill(
                icon: "shell_ball",
                label: "×2",
                subtitle: "FIND IT",
                color: DarkFantasyTheme.goldBright
            )
            payoutPill(
                icon: "shell_cup",
                label: "MISS",
                subtitle: "WRONG",
                color: DarkFantasyTheme.danger
            )
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                )
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    private func payoutPill(icon: String, label: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)

            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(color)

            Text(subtitle)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(color.opacity(DarkFantasyTheme.opacitySoft))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMild), lineWidth: 1)
        )
    }

    // MARK: - Cups Section

    @ViewBuilder
    private func cupsSection(_ vm: ShellGameViewModel) -> some View {
        ZStack {
            HStack(spacing: LayoutConstants.spaceLG) {
                ForEach(vm.cups, id: \.self) { cup in
                    cupView(cup: cup, vm: vm)
                        .offset(x: cupXOffsets[cup])
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: cupXOffsets[cup])
                }
            }
        }
        .frame(height: 170)
        .padding(.top, LayoutConstants.spaceLG)
    }

    // MARK: - Cup View

    @ViewBuilder
    private func cupView(cup: Int, vm: ShellGameViewModel) -> some View {
        let isWinner = vm.winningCup == cup
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
                    .animation(.spring(response: 0.38, dampingFraction: 0.62), value: cupLiftOffsets[cup])
            }
            .frame(width: 110, height: 130)
        }
        .buttonStyle(.plain)
        // NOTE: use allowsHitTesting instead of .disabled — .disabled auto-dims
        // the button and makes the cup look semi-transparent in idle/shuffle phases.
        .allowsHitTesting(gamePhase == .guessing)
        // Pulsing gold glow when cups are pickable
        .shadow(
            color: gamePhase == .guessing
                ? DarkFantasyTheme.gold.opacity(cupGlowActive ? 0.7 : 0.15)
                : Color.clear,
            radius: gamePhase == .guessing ? (cupGlowActive ? 16 : 6) : 0
        )
        .animation(.easeInOut(duration: 1.0), value: cupGlowActive)
        .onChange(of: gamePhase) { _, newPhase in
            if newPhase == .guessing {
                cupGlowActive = false
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    cupGlowActive = true
                }
            } else {
                cupGlowActive = false
            }
        }
    }

    // MARK: - NPC Widget (fixed bottom — like Fortune Wheel)

    private func npcWidget(_ vm: ShellGameViewModel) -> some View {
        NPCGuideWidget(
            npcTitle: "FINCH",
            onDismiss: { /* no dismiss on shell game */ },
            npcImageName: "npc-shell-master",
            plainMessage: vm.npcSpeech,
            wheelContent: AnyView(shellWagerSection(vm)),
            overlapCardPx: 8
        )
    }

    // MARK: - Wager Section (inside NPC Widget wheelContent)

    @ViewBuilder
    private func shellWagerSection(_ vm: ShellGameViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Plays row — badge + currency (mirrors Fortune Wheel spins row)
            HStack {
                // Plays badge
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                    Text("\(vm.playsRemaining)/\(vm.playsLimit)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                }
                .foregroundStyle(vm.playsRemaining > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            Capsule()
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                )

                Spacer()

                // Currency Display
                CurrencyDisplay(
                    gold: vm.gold,
                    gems: appState.currentCharacter?.gems ?? 0,
                    size: .standard,
                    animated: true
                )
            }

            // Bet buttons (5 options — Oswald 18, tracking 2)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(ShellGameViewModel.bets, id: \.self) { bet in
                    let isSelected = vm.selectedBet == bet
                    let canAfford = vm.gold >= bet

                    Button {
                        guard !vm.isPlaying else { return }
                        HapticManager.light()
                        SFXManager.shared.play(.uiTap)
                        vm.selectedBet = bet
                    } label: {
                        Text("\(bet)")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .foregroundStyle(
                                isSelected
                                    ? DarkFantasyTheme.textOnGold
                                    : canAfford
                                        ? DarkFantasyTheme.textPrimary
                                        : DarkFantasyTheme.textTertiary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .fill(
                                        isSelected
                                            ? DarkFantasyTheme.goldGradient
                                            : LinearGradient(colors: [DarkFantasyTheme.bgTertiary], startPoint: .top, endPoint: .bottom)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .stroke(
                                        isSelected
                                            ? DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityHeavy)
                                            : DarkFantasyTheme.borderSubtle,
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isPlaying || !canAfford)
                    .opacity(canAfford ? 1 : DarkFantasyTheme.opacityStrong)
                }
            }

            // Gold Divider before CTA (per Figma State=Wheel pattern)
            GoldDivider()

            // START CTA — Primary button with ornamental styling
            if gamePhase == .result, vm.result == "lose" {
                Button {
                    dismissModal(vm)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "dice.fill")
                            .font(DarkFantasyTheme.cardTitle.bold())
                        Text("PLAY AGAIN")
                    }
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightMD)
                }
                .buttonStyle(.danger)
            } else {
                Button {
                    if gamePhase == .idle {
                        guard vm.canPlay else { return }
                        HapticManager.heavy()
                        SFXManager.shared.play(.uiConfirm)
                        Task { await startPressed(vm: vm) }
                    } else if gamePhase == .result {
                        dismissModal(vm)
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: ctaIcon)
                            .font(DarkFantasyTheme.cardTitle.bold())
                        Text(ctaText(vm))
                    }
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightMD)
                }
                .buttonStyle(.primary)
                .disabled(!ctaEnabled)
            }
        }
    }

    // MARK: - CTA State

    private var ctaIcon: String {
        switch gamePhase {
        case .idle:      return "dice.fill"
        case .revealing: return "eye.fill"
        case .shuffling: return "eye.fill"
        case .guessing:  return "hand.tap.fill"
        case .result:    return "dice.fill"
        }
    }

    private func ctaText(_ vm: ShellGameViewModel) -> String {
        switch gamePhase {
        case .idle:
            return "START — \(vm.selectedBet) GOLD"
        case .revealing, .shuffling:
            return "WATCH THE CUPS..."
        case .guessing:
            return "PICK A CUP!"
        case .result:
            return "PLAY AGAIN"
        }
    }

    private var ctaEnabled: Bool {
        switch gamePhase {
        case .idle:
            return vm?.canPlay ?? false
        case .result:
            return true
        default:
            return false
        }
    }

    // MARK: - Result Modal (ornamental — matches Fortune Wheel)

    @ViewBuilder
    private func resultModal(_ vm: ShellGameViewModel, result: String) -> some View {
        let isWin = result == "win"
        let accentColor = isWin ? DarkFantasyTheme.gold : DarkFantasyTheme.danger

        ZStack {
            // Dimmed background
            DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque)
                .ignoresSafeArea()
                .onTapGesture { dismissModal(vm) }

            // Modal card
            VStack(spacing: 0) {
                // Result icon
                Image(isWin ? "shell_ball" : "shell_cup")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                    .shadow(color: accentColor.opacity(DarkFantasyTheme.opacityStrong), radius: 8)
                    .padding(.bottom, LayoutConstants.spaceMD)

                // Title
                Text(resultTitle(vm))
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                    .padding(.bottom, LayoutConstants.spaceXS)

                // Amount
                Text(resultAmountText(vm))
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .padding(.bottom, LayoutConstants.spaceLG)

                // Win burst
                if isWin {
                    RewardBurstView(style: .claim, isActive: $showWinBurst)
                        .frame(height: 0) // Overlay effect, no layout space
                }

                // Dismiss button
                if isWin {
                    Button {
                        dismissModal(vm)
                    } label: {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightMD)
                    }
                    .buttonStyle(.primary)
                } else {
                    Button {
                        dismissModal(vm)
                    } label: {
                        Text("CONTINUE")
                            .font(DarkFantasyTheme.cardTitle)
                            .tracking(2)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightMD)
                    }
                    .buttonStyle(.danger)
                }
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: DarkFantasyTheme.opacityStrong,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityMild))
            .cornerBrackets(color: accentColor.opacity(DarkFantasyTheme.opacityMedium), length: 18, thickness: 1.5)
            .cornerDiamonds(color: accentColor.opacity(DarkFantasyTheme.opacityStrong), size: 5)
            .compositingGroup()
            .dualShadow(glowColor: accentColor, glowRadius: 12, depth: .modal)
            .frame(maxWidth: 300)
            .opacity(showResultModal ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showResultModal)
        }
        .transition(.opacity)
    }

    private func resultTitle(_ vm: ShellGameViewModel) -> String {
        guard let result = vm.result else { return "" }
        if result == "lose" { return "WRONG CUP!" }
        return "YOU WIN!"
    }

    private func resultAmountText(_ vm: ShellGameViewModel) -> String {
        guard let result = vm.result else { return "" }
        if result == "win" {
            return "+\(vm.winAmount.formatted()) Gold (×2)"
        } else {
            return "-\(vm.selectedBet.formatted()) Gold"
        }
    }

    private func dismissModal(_ vm: ShellGameViewModel) {
        showResultModal = false
        resetGame(vm: vm)
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

        // Shuffle animation
        gamePhase = .shuffling
        SFXManager.shared.play(.shellShuffle)
        let swapCount = 4 + Int.random(in: 0...2) // 4-6 shuffles
        for _ in 0..<swapCount {
            let cup1 = Int.random(in: 0..<3)
            var cup2 = Int.random(in: 0..<3)
            while cup2 == cup1 { cup2 = Int.random(in: 0..<3) }

            let offset: CGFloat = 100
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                cupXOffsets[cup1] = offset
                cupXOffsets[cup2] = -offset
            }
            try? await Task.sleep(for: .seconds(0.45))

            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                cupXOffsets[cup1] = 0
                cupXOffsets[cup2] = 0
            }
            try? await Task.sleep(for: .seconds(0.45))
        }

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

        withAnimation(MotionConstants.smooth) {
            gamePhase = .result
        }

        // NPC speech update
        vm.onResultComplete()

        // Win / Loss feedback
        if vm.result == "win" {
            HapticManager.success()
            // Show modal after short delay
            try? await Task.sleep(for: .seconds(0.8))
            showWinBurst = true
            showResultModal = true
        } else {
            HapticManager.error()
            triggerLossShake()
            // Show modal after shake
            try? await Task.sleep(for: .seconds(0.6))
            showResultModal = true
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
            cupGlowActive = false
            showWinBurst = false
            shakeOffset = 0
            lossFlashOpacity = 0
        }
    }
}
