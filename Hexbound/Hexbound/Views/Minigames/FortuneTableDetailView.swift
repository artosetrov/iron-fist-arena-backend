import SwiftUI

/// Fortune's Table — a jackpot wheel for 4–6 seats. Everyone's stake is a
/// slice; one spin decides who takes the pot (minus Fortuna's tithe) and her
/// chest. Phase 1: the other seats are tavern regulars run by the server.
struct FortuneTableDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: FortuneTableViewModel?

    @State private var wheelRotation: Double = 0
    @State private var winnerSeat: Int?
    @State private var showResultModal = false
    @State private var showFairness = false
    @State private var spinTask: Task<Void, Never>?

    var body: some View {
        Group {
            if let vm, vm.showsErrorState {
                ErrorStateView.loadFailed(message: vm.errorMessage) {
                    Task { await vm.loadStatus() }
                }
            } else if let vm, !vm.isLoading {
                mainContent(vm)
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
                Text("FORTUNE'S TABLE")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            AmbientManager.shared.setZone(.tavern)
            guard let vm else { return }
            if vm.phase == .spinning {
                // The draw landed while the screen was away.
                startSpin(vm)
            } else if vm.resultUnseen, let result = vm.round?.result {
                vm.resultUnseen = false
                winnerSeat = result.winnerSeat
                showResultModal = true
            }
            vm.resume()
        }
        .onDisappear {
            spinTask?.cancel()
            vm?.leave()
            AmbientManager.shared.setZone(.hub)
        }
        .task {
            if vm == nil {
                let newVM = FortuneTableViewModel(appState: appState)
                vm = newVM
                await newVM.loadStatus()
            }
        }
        .onChange(of: vm?.phase) { _, phase in
            if phase == .spinning, let vm { startSpin(vm) }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary
            Image("bg-fortune-wheel")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(DarkFantasyTheme.opacityStrong)
            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityMedium),
                    Color.clear,
                    DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityDense),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Layout

    @ViewBuilder
    private func mainContent(_ vm: FortuneTableViewModel) -> some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutConstants.spaceMD) {
                    if vm.phase == .seating {
                        tierPicker(vm)
                    } else {
                        roundHeader(vm)
                    }
                    wheelSection(vm)
                    if let round = vm.round {
                        lobbyClock(vm, round: round)
                        seatList(vm, round: round)
                        fairnessPanel(vm, round: round)
                    } else {
                        rulesPanel(vm)
                    }
                    if !vm.history.isEmpty {
                        historyStrip(vm)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceXS)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                NPCGuideWidget(
                    npcTitle: "LADY FORTUNA",
                    onDismiss: {},
                    npcImageName: NPCSpeaker.fortuna.portrait,
                    plainMessage: vm.npcSpeech,
                    wheelContent: AnyView(controls(vm)),
                    overlapCardPx: 8
                )
            }

            if showResultModal, let round = vm.round, let result = round.result {
                resultModal(vm, round: round, result: result)
            }
        }
    }

    // MARK: - Tier picker

    private func tierPicker(_ vm: FortuneTableViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(vm.tiers) { tier in
                let selected = vm.selectedTierKey == tier.key
                let color = FortuneTableStyle.tierColor(tier.key)
                Button {
                    guard tier.unlocked else {
                        appState.showToast("\(tier.title) table opens at level \(tier.minLevel)", type: .info)
                        return
                    }
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    vm.selectTier(tier.key)
                } label: {
                    VStack(spacing: LayoutConstants.space2XS) {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            if !tier.unlocked {
                                Image(systemName: "lock.fill")
                                    .font(DarkFantasyTheme.body)
                            }
                            Text(tier.title)
                                .font(DarkFantasyTheme.cardTitle)
                                .tracking(1.5)
                        }
                        .foregroundStyle(tier.unlocked ? color : DarkFantasyTheme.textTertiary)
                        Text(tier.unlocked ? "\(tier.minStake.formatted())–\(tier.maxStake.formatted())" : "Level \(tier.minLevel)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .fill(selected ? color.opacity(DarkFantasyTheme.opacityMild) : DarkFantasyTheme.bgSecondary.opacity(DarkFantasyTheme.opacityOpaque))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(selected ? color : DarkFantasyTheme.borderSubtle, lineWidth: selected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .opacity(tier.unlocked ? 1 : DarkFantasyTheme.opacityHeavy)
                .accessibilityLabel(tier.unlocked
                    ? "\(tier.title) table, stakes \(tier.minStake) to \(tier.maxStake) gold"
                    : "\(tier.title) table, opens at level \(tier.minLevel)")
            }
        }
    }

    private func roundHeader(_ vm: FortuneTableViewModel) -> some View {
        let tier = vm.roundTier
        let color = FortuneTableStyle.tierColor(tier?.key ?? "copper")
        return HStack {
            Text("\(tier?.title ?? "") TABLE")
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1.5)
                .foregroundStyle(color)
            Spacer()
            Text("\(vm.round?.seats.count ?? 0) SEATED")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
    }

    // MARK: - Wheel

    private func wheelSection(_ vm: FortuneTableViewModel) -> some View {
        ZStack(alignment: .top) {
            FortuneTableWheel(
                seats: displaySeats(vm),
                pot: vm.round?.pot ?? vm.selectedStake,
                rotation: wheelRotation,
                winnerSeat: winnerSeat,
                playerAvatar: appState.currentCharacter?.avatar,
                playerClass: appState.currentCharacter?.characterClass ?? .warrior
            )
            .padding(.top, LayoutConstants.spaceLG)

            Image("fortune-pointer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 80)
                .rotationEffect(.degrees(-15))
                .depthShadow(.card)
                .offset(y: -LayoutConstants.spaceSM)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
    }

    /// Before sitting down the wheel shows just the player's stake.
    private func displaySeats(_ vm: FortuneTableViewModel) -> [FortuneTableSeat] {
        if let round = vm.round { return round.seats }
        return [FortuneTableSeat(
            seat: 0, isYou: true, name: appState.currentCharacter?.characterName ?? "You",
            portrait: nil, style: "you", stake: max(vm.selectedStake, 1), joinedMs: 0
        )]
    }

    // MARK: - Clock + chance

    private func lobbyClock(_ vm: FortuneTableViewModel, round: FortuneTableRound) -> some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            let total = max(1, Double(round.lobbyMs) / 1000)
            let left = max(0, vm.lockAt?.timeIntervalSince(context.date) ?? 0)
            let open = vm.phase == .lobby && left > 0
            let urgent = open && left < 5
            VStack(spacing: LayoutConstants.spaceSM) {
                HStack(alignment: .firstTextBaseline) {
                    Text(open ? "BETS CLOSE IN" : vm.phase == .result ? "THE WHEEL HAS SPOKEN" : "BETS ARE CLOSED")
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(1.5)
                        .foregroundStyle(open ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)
                    Spacer()
                    if open {
                        Text("\(Int(left.rounded(.up)))s")
                            .font(DarkFantasyTheme.section)
                            .monospacedDigit()
                            .foregroundStyle(urgent ? DarkFantasyTheme.danger : DarkFantasyTheme.goldBright)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DarkFantasyTheme.bgAbyss)
                        Capsule()
                            .fill(urgent ? DarkFantasyTheme.danger : DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * (open ? left / total : 0))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
                .frame(height: 8)
                .accessibilityHidden(true)

                HStack(spacing: LayoutConstants.spaceSM) {
                    statBlock(title: "YOUR CHANCE", value: percent(round.yourChance), color: DarkFantasyTheme.goldBright)
                    statBlock(title: "IF YOU WIN", value: "\(round.payoutIfWin.formatted())", color: DarkFantasyTheme.gold, icon: "icon-gold")
                    statBlock(title: "ITEM IN CHEST", value: percent(round.chestItemChance), color: DarkFantasyTheme.purple)
                }
            }
            .padding(LayoutConstants.spaceMS)
            .background(panelBackground)
            .accessibilityElement(children: .combine)
        }
    }

    private func statBlock(title: String, value: String, color: Color, icon: String? = nil) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(title)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(spacing: LayoutConstants.spaceXS) {
                if let icon {
                    Image(icon)
                        .resizable()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                }
                Text(value)
                    .font(DarkFantasyTheme.section)
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    // MARK: - Seats

    private func seatList(_ vm: FortuneTableViewModel, round: FortuneTableRound) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            ForEach(round.seats) { seat in
                seatRow(seat, pot: round.pot, isWinner: winnerSeat == seat.seat)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(MotionConstants.spring, value: round.seats)
    }

    private func seatRow(_ seat: FortuneTableSeat, pot: Int, isWinner: Bool) -> some View {
        let color = FortuneTableStyle.color(forSeat: seat.seat)
        let chance = pot > 0 ? Double(seat.stake) / Double(pot) : 0
        return HStack(spacing: LayoutConstants.spaceSM) {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(color)
                .frame(width: 4, height: 36)
            Group {
                if seat.isYou {
                    AvatarImageView(
                        skinKey: appState.currentCharacter?.avatar,
                        characterClass: appState.currentCharacter?.characterClass ?? .warrior,
                        size: 40
                    )
                } else if let portrait = seat.portrait {
                    Image(portrait).resizable().interpolation(.high).scaledToFill()
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(color, lineWidth: 2))

            VStack(alignment: .leading, spacing: 0) {
                Text(seat.isYou ? "You" : seat.name)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(seat.isYou ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                if let style = FortuneTableStyle.styleLabel(seat.style) {
                    Text(style)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            Spacer(minLength: LayoutConstants.spaceXS)
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gold")
                        .resizable()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                    Text(seat.stake.formatted())
                        .font(DarkFantasyTheme.cardTitle)
                        .monospacedDigit()
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                Text(percent(chance))
                    .font(DarkFantasyTheme.body)
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(seat.isYou ? DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacitySoft) : DarkFantasyTheme.bgSecondary.opacity(DarkFantasyTheme.opacityOpaque))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(isWinner ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderSubtle, lineWidth: isWinner ? 2 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(seat.isYou ? "You" : seat.name), \(seat.stake) gold, \(percent(chance)) chance\(isWinner ? ", winner" : "")")
    }

    // MARK: - Rules / fairness

    private func rulesPanel(_ vm: FortuneTableViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("HOW THE TABLE WORKS")
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.goldBright)
            ruleLine("person.3.fill", "Up to 6 seats. Regulars join while bets are open.")
            ruleLine("chart.pie.fill", "Your slice of the wheel = your stake ÷ the pot.")
            ruleLine("crown.fill", "The winner takes the pot, minus Fortuna's \(Int((vm.rake * 100).rounded()))% tithe, plus her chest.")
            ruleLine("plus.circle.fill", "Add gold before the timer ends for a bigger slice.")
            ruleLine("checkmark.seal.fill", "Every round is sealed before it starts and can be checked after.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutConstants.spaceMS)
        .background(panelBackground)
    }

    private func ruleLine(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceSM) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconMD)
            Text(text)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fairnessPanel(_ vm: FortuneTableViewModel, round: FortuneTableRound) -> some View {
        // Seed and pointer give the outcome away — only once the wheel stops.
        let revealed = vm.phase == .result && round.isSettled
        let verified = revealed ? FortuneTableFairness.verify(round) : nil
        return VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Button {
                HapticManager.light()
                withAnimation(MotionConstants.smooth) { showFairness.toggle() }
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: verified == false ? "xmark.seal.fill" : "checkmark.seal.fill")
                        .foregroundStyle(verified == false ? DarkFantasyTheme.danger : verified == true ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                    Text(verified == true ? "Verified on your device"
                         : verified == false ? "Check failed — report this round"
                         : "Sealed: \(shortHash(round.commitment))")
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Image(systemName: showFairness ? "chevron.up" : "chevron.down")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .font(DarkFantasyTheme.body)
            }
            .buttonStyle(.plain)

            if showFairness {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    Text("Before anyone sits down, Fortuna writes the round's secret and shows you its seal (SHA-256). After the draw she reveals the secret: it must match the seal, and the pointer's stop is computed from it alone — nobody, not even the server, can change it once sealed.")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Seal: \(round.commitment)")
                        .font(DarkFantasyTheme.body.monospaced())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .textSelection(.enabled)
                    if revealed, let seed = round.seed {
                        Text("Secret: \(seed)")
                            .font(DarkFantasyTheme.body.monospaced())
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .textSelection(.enabled)
                    }
                    if revealed, let result = round.result {
                        Text("Pointer: \(String(format: "%.6f", result.ticket)) of the wheel")
                            .font(DarkFantasyTheme.body.monospaced())
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(panelBackground)
    }

    private func shortHash(_ hash: String) -> String {
        guard hash.count > 12 else { return hash }
        return "\(hash.prefix(6))…\(hash.suffix(6))"
    }

    // MARK: - History

    private func historyStrip(_ vm: FortuneTableViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("RECENT ROUNDS")
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.history) { entry in
                        VStack(spacing: LayoutConstants.space2XS) {
                            Text(entry.won ? "+\(entry.payout.formatted())" : "−\(entry.yourStake.formatted())")
                                .font(DarkFantasyTheme.cardTitle)
                                .monospacedDigit()
                                .foregroundStyle(entry.won ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                            Text(entry.won ? "You won" : (entry.winnerName ?? "Lost"))
                                .font(DarkFantasyTheme.body)
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, LayoutConstants.spaceMS)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                .fill(DarkFantasyTheme.bgSecondary.opacity(DarkFantasyTheme.opacityOpaque))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                .stroke(FortuneTableStyle.tierColor(entry.tier).opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                        )
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    // MARK: - Controls (inside Fortuna's widget)

    @ViewBuilder
    private func controls(_ vm: FortuneTableViewModel) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                    Text("\(vm.roundsRemaining)/\(vm.roundsLimit)")
                }
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(vm.roundsRemaining > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule()
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(Capsule().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
                )
                .accessibilityLabel("\(vm.roundsRemaining) of \(vm.roundsLimit) rounds left today")

                Spacer()

                CurrencyDisplay(
                    gold: vm.gold,
                    gems: appState.currentCharacter?.gems ?? 0,
                    size: .standard,
                    animated: true
                )
            }

            switch vm.phase {
            case .seating:
                seatingControls(vm)
            case .lobby:
                topUpControls(vm)
            case .drawing, .spinning:
                closedLabel(vm.phase == .drawing ? "BETS ARE CLOSED…" : "THE WHEEL TURNS…")
            case .result:
                Button {
                    HapticManager.medium()
                    SFXManager.shared.play(.uiConfirm)
                    showResultModal = false
                    winnerSeat = nil
                    Task { await vm.playAgain() }
                } label: {
                    Text("NEW ROUND")
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightMD)
                }
                .buttonStyle(.primary)
            }
        }
    }

    @ViewBuilder
    private func seatingControls(_ vm: FortuneTableViewModel) -> some View {
        if let tier = vm.selectedTier {
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(tier.stakePresets, id: \.self) { stake in
                    stakeButton(
                        label: stake.formatted(),
                        selected: vm.selectedStake == stake,
                        enabled: vm.gold >= stake && tier.unlocked
                    ) {
                        vm.selectedStake = stake
                    }
                }
            }
            GoldDivider()
            Button {
                guard vm.canJoin else { return }
                HapticManager.heavy()
                SFXManager.shared.play(.uiConfirm)
                Task { await vm.join() }
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "chair.lounge.fill")
                    Text(vm.isBusy ? "TAKING A SEAT…" : "TAKE A SEAT — \(vm.selectedStake.formatted()) GOLD")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightMD)
            }
            .buttonStyle(.primary)
            .disabled(!vm.canJoin)
        }
    }

    private func topUpControls(_ vm: FortuneTableViewModel) -> some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                Text("ADD TO YOUR STAKE")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .tracking(1)
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.roundTier?.topUpSteps ?? [], id: \.self) { amount in
                        stakeButton(
                            label: "+\(amount.formatted())",
                            selected: false,
                            enabled: vm.canTopUp(amount, now: context.date)
                        ) {
                            Task { await vm.topUp(amount) }
                        }
                    }
                }
            }
        }
    }

    private func closedLabel(_ text: String) -> some View {
        Text(text)
            .font(DarkFantasyTheme.cardTitle)
            .tracking(1.5)
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                    )
            )
    }

    private func stakeButton(label: String, selected: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            HapticManager.light()
            SFXManager.shared.play(.uiTap)
            action()
        } label: {
            Text(label)
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(
                    selected ? DarkFantasyTheme.textOnGold
                        : enabled ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textTertiary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(selected
                              ? DarkFantasyTheme.goldGradient
                              : LinearGradient(colors: [DarkFantasyTheme.bgTertiary], startPoint: .top, endPoint: .bottom))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(selected ? DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityHeavy) : DarkFantasyTheme.borderSubtle,
                                lineWidth: selected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : DarkFantasyTheme.opacityStrong)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
            .fill(DarkFantasyTheme.bgSecondary.opacity(DarkFantasyTheme.opacityOpaque))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
            )
            .depthShadow(.card)
    }

    // MARK: - Spin

    /// Turn the wheel so the server's ticket stops under the pointer.
    private func startSpin(_ vm: FortuneTableViewModel) {
        guard let round = vm.round, let result = round.result else {
            vm.finishSpin()
            return
        }
        spinTask?.cancel()
        winnerSeat = nil
        showResultModal = false

        // Wheel angle θ = ticket × 360° clockwise from 12 o'clock; turning the
        // wheel by −θ brings it under the pointer. Count from where it rests.
        let target = 360.0 - result.ticket * 360.0
        let current = wheelRotation.truncatingRemainder(dividingBy: 360.0)
        var delta = (target - current).truncatingRemainder(dividingBy: 360.0)
        if delta < 0 { delta += 360.0 }
        let from = wheelRotation
        let to = from + Double(Int.random(in: 7...9)) * 360.0 + delta
        let boundaries = FortuneTableSliceGeometry.slices(for: round.seats).map(\.start)

        SFXManager.shared.play(.wheelSpin)
        HapticManager.heavy()
        wheelRotation = to

        spinTask = Task { @MainActor in
            await FortuneTableTicker.run(from: from, to: to, boundaries: boundaries)
            guard !Task.isCancelled else { return }
            withAnimation(MotionConstants.smooth) { winnerSeat = result.winnerSeat }
            vm.finishSpin()
            try? await Task.sleep(for: .seconds(MotionConstants.ceremonyPhase3))
            guard !Task.isCancelled else { return }
            showResultModal = true
        }
    }

    // MARK: - Result

    @ViewBuilder
    private func resultModal(_ vm: FortuneTableViewModel, round: FortuneTableRound, result: FortuneTableResult) -> some View {
        let item = result.chest.first
        GameModal(
            accent: MinigameResultAccent.color(isWin: result.won),
            maxWidth: 320,
            onDismiss: { showResultModal = false }
        ) {
            MinigameResultModal(
                isWin: result.won,
                title: result.won ? "THE POT IS YOURS!" : "\((round.winner?.name ?? "A RIVAL").uppercased()) WINS",
                amountText: result.won
                    ? "+\(result.payout.formatted()) Gold" + (item.map { "\n+ \($0.name)" } ?? "")
                    : "−\(round.yourStake.formatted()) Gold",
                amountLineLimit: 2,
                onContinue: { showResultModal = false }
            ) {
                if result.won {
                    if let item, item.shard == nil {
                        ItemImageView(imageKey: item.imageKey, imageUrl: item.imageUrl)
                    } else {
                        Image("icon-chest").resizable().aspectRatio(contentMode: .fit)
                    }
                } else if let portrait = round.winner?.portrait {
                    Image(portrait)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image("icon-fortune-lose").resizable().aspectRatio(contentMode: .fit)
                }
            }
        }
    }
}
