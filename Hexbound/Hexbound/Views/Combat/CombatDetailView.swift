import SwiftUI

struct CombatDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: CombatViewModel?
    @State private var screenShake: CGFloat = 0
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            Color(hex: 0x0A0A14).ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    // Round Header
                    roundHeader(vm)

                    // Battle Area with fighters
                    battleArea(vm)

                    // Action Indicators (Attack / Defend zones)
                    if !vm.isFinished {
                        actionIndicators(vm)
                    }

                    // Combat Log
                    combatLogPanel(vm)

                    // Bottom Controls (1X, 2X, SKIP or CONTINUE)
                    bottomBar(vm)
                }
                .offset(x: screenShake)

                // Damage Popups Overlay
                damagePopupsOverlay(vm)

                // Victory/Defeat tint
                if vm.isFinished {
                    Rectangle()
                        .fill(vm.combatData.result.isWin
                              ? DarkFantasyTheme.goldBright.opacity(0.06)
                              : DarkFantasyTheme.danger.opacity(0.06))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            } else {
                preparationView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupCombatIfReady()
        }
        .onChange(of: appState.combatData != nil) { _, hasData in
            if hasData {
                setupCombatIfReady()
            }
        }
    }

    private func triggerScreenShake(isCrit: Bool) {
        let magnitude: CGFloat = isCrit ? 12 : 6
        withAnimation(.linear(duration: 0.05)) { screenShake = magnitude }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) { screenShake = -magnitude * 0.7 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) { screenShake = magnitude * 0.4 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) { screenShake = 0 }
        }
    }

    // MARK: - Setup

    private func setupCombatIfReady() {
        guard let data = appState.combatData, viewModel == nil else { return }
        let vm = CombatViewModel(appState: appState, combatData: data)
        vm.onHit = { [self] isCrit in triggerScreenShake(isCrit: isCrit) }
        viewModel = vm
        Task { await vm.play() }
    }

    // MARK: - Preparation Animation

    @ViewBuilder
    private var preparationView: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Pulsing swords icon
            Text("⚔️")
                .font(.system(size: 72))
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.5), radius: animatePulse ? 20 : 8)
                .scaleEffect(animatePulse ? 1.05 : 0.95)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: animatePulse
                )

            Text("PREPARING BATTLE")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.3), radius: 12)

            // Animated loading dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: 8, height: 8)
                        .opacity(animatePulse ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: animatePulse
                        )
                }
            }

            Spacer()
        }
        .onAppear { animatePulse = true }
        .onDisappear { animatePulse = false }
    }

    // MARK: - Round Header

    @ViewBuilder
    private func roundHeader(_ vm: CombatViewModel) -> some View {
        Text(vm.turnLabel)
            .font(DarkFantasyTheme.title(size: vm.isFinished ? LayoutConstants.textScreen : LayoutConstants.textSection))
            .foregroundStyle(vm.turnLabelColor)
            .shadow(color: vm.turnLabelColor.opacity(0.4), radius: 8)
            .padding(.top, LayoutConstants.spaceLG)
            .padding(.bottom, LayoutConstants.spaceSM)
    }

    // MARK: - Battle Area

    @ViewBuilder
    private func battleArea(_ vm: CombatViewModel) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Player Side
            fighterPanel(
                fighter: vm.combatData.player,
                currentHp: vm.playerHp,
                maxHp: vm.playerMaxHp,
                slideX: vm.playerSlideX,
                isFlashing: vm.playerFlash,
                statuses: vm.playerStatuses,
                isPlayer: true
            )

            // VS label
            Text("VS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .padding(.top, 90)

            // Enemy Side
            fighterPanel(
                fighter: vm.combatData.enemy,
                currentHp: vm.enemyHp,
                maxHp: vm.enemyMaxHp,
                slideX: vm.enemySlideX,
                isFlashing: vm.enemyFlash,
                statuses: vm.enemyStatuses,
                isPlayer: false
            )
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Fighter Panel

    @ViewBuilder
    private func fighterPanel(
        fighter: CombatFighter,
        currentHp: Int,
        maxHp: Int,
        slideX: CGFloat,
        isFlashing: Bool,
        statuses: [StatusEffect],
        isPlayer: Bool
    ) -> some View {
        let borderColor = isPlayer ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        let hpPct = maxHp > 0 ? Double(currentHp) / Double(maxHp) : 0

        VStack(spacing: LayoutConstants.spaceSM) {
            // YOU / ENEMY label
            Text(isPlayer ? "YOU" : "ENEMY")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(borderColor)

            // Avatar box with colored border
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)

                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    AvatarImageView(
                        skinKey: fighter.avatar,
                        characterClass: fighter.characterClass,
                        size: side
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius - 4))
                    .frame(width: side, height: side)
                }
            }
            .frame(width: 130, height: 130)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(borderColor, lineWidth: 2.5)
            )
            .brightness(isFlashing ? 0.8 : 0)
            .offset(x: slideX)

            // Character Name
            Text(fighter.characterName.uppercased())
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            // Level + Class
            Text("Lv.\(fighter.level) \(fighter.characterClass.rawValue.capitalized)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            // HP Bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DarkFantasyTheme.bgPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DarkFantasyTheme.hpGradient(percentage: hpPct))
                            .frame(width: geo.size.width * max(0, hpPct))
                            .animation(.easeInOut(duration: 0.4), value: hpPct)
                    }
                }
                .frame(height: 14)

                Text("\(currentHp)/\(maxHp)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(isPlayer ? DarkFantasyTheme.hpBlood : DarkFantasyTheme.hpBlood)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: currentHp)
            }

            // Status Effects
            if !statuses.isEmpty {
                HStack(spacing: 4) {
                    ForEach(statuses) { status in
                        Text(status.abbreviation)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(status.color.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Indicators

    @ViewBuilder
    private func actionIndicators(_ vm: CombatViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            // Attack zone
            VStack(spacing: 4) {
                Text("Attack")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text(vm.currentAttackZone ?? "—")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(zoneColor(vm.currentAttackZone))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(zoneColor(vm.currentAttackZone).opacity(0.5), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(DarkFantasyTheme.bgSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))

            // Defend zone
            VStack(spacing: 4) {
                Text("Defend")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text(vm.currentDefendZone ?? "—")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(zoneColor(vm.currentDefendZone))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(zoneColor(vm.currentDefendZone).opacity(0.5), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(DarkFantasyTheme.bgSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
    }

    private func zoneColor(_ zone: String?) -> Color {
        switch zone?.uppercased() {
        case "HEAD": DarkFantasyTheme.zoneHead
        case "CHEST": DarkFantasyTheme.zoneChest
        case "LEGS": DarkFantasyTheme.zoneLegs
        default: DarkFantasyTheme.textTertiary
        }
    }

    // MARK: - Combat Log Panel

    @ViewBuilder
    private func combatLogPanel(_ vm: CombatViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("COMBAT LOG")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.danger)
                .padding(.bottom, LayoutConstants.spaceSM)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.visibleLogEntries) { entry in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 4) {
                                    Text(entry.text)
                                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                                    Text("→")
                                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                                    Text(entry.result)
                                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                                        .foregroundStyle(entry.resultColor)

                                    if let label = entry.damageTypeLabel, let color = entry.damageTypeColor {
                                        Text(label)
                                            .font(DarkFantasyTheme.body(size: 8).bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(color.opacity(0.7))
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                }
                                .padding(.vertical, 6)

                                Divider()
                                    .background(DarkFantasyTheme.borderSubtle)
                            }
                            .id(entry.id)
                        }
                    }
                }
                .onChange(of: vm.visibleLogEntries.count) { _, _ in
                    if let last = vm.visibleLogEntries.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private func bottomBar(_ vm: CombatViewModel) -> some View {
        if vm.isFinished {
            Button {
                Task { await vm.goToResult() }
            } label: {
                if vm.isNavigatingToResult {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                        Text("LOADING...")
                    }
                } else {
                    Text("CONTINUE")
                }
            }
            .buttonStyle(.primary)
            .disabled(vm.isNavigatingToResult)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        } else {
            HStack(spacing: LayoutConstants.spaceSM) {
                // 1X button
                Button {
                    if vm.speedMode != 0 { vm.toggleSpeed() }
                } label: {
                    Text("1X")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        .foregroundStyle(vm.speedMode == 0 ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightMD)
                        .background(
                            vm.speedMode == 0
                                ? DarkFantasyTheme.bgTertiary
                                : DarkFantasyTheme.bgSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(vm.speedMode == 0 ? DarkFantasyTheme.borderMedium : DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                }

                // 2X button
                Button {
                    if vm.speedMode != 1 { vm.toggleSpeed() }
                } label: {
                    Text("2X")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        .foregroundStyle(vm.speedMode == 1 ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightMD)
                        .background(
                            vm.speedMode == 1
                                ? DarkFantasyTheme.gold
                                : DarkFantasyTheme.bgSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(vm.speedMode == 1 ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                }

                // SKIP button
                Button {
                    vm.skip()
                } label: {
                    Text("SKIP")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightMD)
                        .background(DarkFantasyTheme.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
    }

    // MARK: - Damage Popups

    @ViewBuilder
    private func damagePopupsOverlay(_ vm: CombatViewModel) -> some View {
        GeometryReader { geo in
            ForEach(vm.damagePopups) { popup in
                DamagePopupBubble(popup: popup)
                    .position(
                        x: popup.onDefender
                            ? geo.size.width * 0.25
                            : geo.size.width * 0.75,
                        y: geo.size.height * 0.3
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Damage Popup Bubble

struct DamagePopupBubble: View {
    let popup: DamagePopup
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        Text(popup.text)
            .font(DarkFantasyTheme.title(size: popup.isCrit ? 36 : 24))
            .foregroundStyle(popup.color)
            .shadow(color: popup.color.opacity(0.5), radius: 4)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                if popup.isCrit {
                    scale = 1.5
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 1.0
                    }
                }
                withAnimation(.easeOut(duration: 0.8)) {
                    offsetY = -70
                }
                withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                    opacity = 0
                }
            }
    }
}
