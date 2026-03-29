import SwiftUI

struct DungeonRushDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DungeonRushViewModel?
    @State private var portalGlow: Bool = false
    @State private var dustPhase: CGFloat = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                    if vm.errorMessage != nil {
                        ErrorStateView.loadFailed {
                            Task { await vm.checkActiveRush() }
                        }
                    } else if vm.isGameOver {
                        gameOverView(vm: vm)
                    } else if vm.isActive {
                        rushView(vm: vm)
                    } else {
                        startView(vm: vm)
                    }

                    if vm.showShop        { shopOverlay(vm: vm) }
                    if vm.showEventResult { eventOverlay(vm: vm) }
                    if vm.showTreasureResult { treasureOverlay(vm: vm) }
                    if vm.showAbandonConfirm { abandonConfirmOverlay(vm: vm) }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DUNGEON RUSH")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if vm == nil {
                let newVM = DungeonRushViewModel(appState: appState)
                vm = newVM
                Task { await newVM.checkActiveRush() }
            } else {
                vm?.applyPendingResult()
            }
        }
    }

    // MARK: - Start View

    @ViewBuilder
    private func startView(vm: DungeonRushViewModel) -> some View {
        ZStack(alignment: .bottom) {
            // Atmospheric dungeon background — stronger presence
            Image("bg-dungeon")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.45)
                .clipped()

            // Vignette — radial center clarity + edge darkening
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.5),
                    DarkFantasyTheme.bgPrimary.opacity(0.85)
                ]),
                center: .init(x: 0.5, y: 0.28),
                startRadius: 80,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Bottom fade for CTA readability
            LinearGradient(
                colors: [
                    Color.clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.7),
                    DarkFantasyTheme.bgPrimary
                ],
                startPoint: .init(x: 0.5, y: 0.55),
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating dust particles
            dungeonDustOverlay()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.spaceSM)

                    // ── Hero Zone: Portal ──
                    ZStack {
                        // Outer pulsing glow rings
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 220, height: 220)
                            .shadow(color: DarkFantasyTheme.purple.opacity(portalGlow ? 0.25 : 0.08), radius: 60)
                            .shadow(color: DarkFantasyTheme.gold.opacity(portalGlow ? 0.2 : 0.06), radius: 40)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: portalGlow)

                        // Main circle
                        Circle()
                            .fill(RadialGradient(
                                gradient: Gradient(colors: [
                                    DarkFantasyTheme.bgElevated,
                                    DarkFantasyTheme.bgSecondary,
                                    DarkFantasyTheme.bgAbyss.opacity(0.8)
                                ]),
                                center: .init(x: 0.4, y: 0.35),
                                startRadius: 0,
                                endRadius: 95
                            ))
                            .frame(width: 200, height: 200)
                            .overlay(
                                Circle().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.gold.opacity(0.12), lineWidth: 1)
                                    .padding(6)
                            )
                            .shadow(color: DarkFantasyTheme.gold.opacity(portalGlow ? 0.35 : 0.15), radius: 30)
                            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 12, y: 5)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: portalGlow)

                        Image("icon-dungeon-rush")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        // Corner diamonds around portal
                        ForEach([0, 90, 180, 270], id: \.self) { deg in
                            Rectangle()
                                .fill(DarkFantasyTheme.gold.opacity(0.35))
                                .frame(width: 6, height: 6)
                                .rotationEffect(.degrees(45))
                                .offset(y: -108)
                                .rotationEffect(.degrees(Double(deg)))
                        }
                    }

                    // Subtitle only (title is in toolbar)
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text("12 rooms of combat, treasure & mystery")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .multilineTextAlignment(.center)

                        // Reward preview pills
                        rewardPreviewPills()
                    }

                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.spaceXL)

                    // Risk callout (enhanced)
                    riskCallout()

                    // Stats panel (ornamental)
                    statsPanel()

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }

            // Pinned CTA
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary.opacity(0), DarkFantasyTheme.bgPrimary],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 56)
                .allowsHitTesting(false)

                VStack(spacing: LayoutConstants.spaceXS) {
                    Button {
                        Task { await vm.startRush() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("ENTER THE DEPTHS")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isLoading)

                    // Stamina cost indicator
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-stamina")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("3 Stamina")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.stamina)
                    }
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        Capsule().fill(DarkFantasyTheme.stamina.opacity(0.08))
                    )
                    .overlay(
                        Capsule().stroke(DarkFantasyTheme.stamina.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceMD)
                .background(DarkFantasyTheme.bgPrimary)
            }
        }
        .onAppear { portalGlow = true }
        .onDisappear { portalGlow = false }
    }

    // MARK: - Reward Preview Pills (replaced room map)

    @ViewBuilder
    private func rewardPreviewPills() -> some View {
        let rewards: [(String, String, Color)] = [
            ("icon-gold", "Gold", DarkFantasyTheme.gold),
            ("icon-xp", "XP", DarkFantasyTheme.purple),
            ("reward-loot", "Loot", DarkFantasyTheme.cyan),
            ("icon-gems", "Rare+", DarkFantasyTheme.stamina),
        ]

        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(rewards.enumerated()), id: \.offset) { _, reward in
                let (icon, text, color) = reward
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text(text)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(color)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    Capsule().fill(color.opacity(0.06))
                )
                .overlay(
                    Capsule().stroke(color.opacity(0.15), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Dungeon Dust Overlay

    @ViewBuilder
    private func dungeonDustOverlay() -> some View {
        Canvas { context, size in
            let particleCount = 12
            for i in 0..<particleCount {
                let seed = Double(i) * 137.5
                let phase = dustPhase + CGFloat(seed)
                let x = (sin(phase * 0.013 + seed) * 0.5 + 0.5) * size.width
                let y = (cos(phase * 0.009 + seed * 0.7) * 0.5 + 0.5) * size.height
                let particleSize = 2.0 + sin(seed) * 1.5
                let opacity = 0.08 + sin(phase * 0.02 + seed) * 0.12

                let color = i % 3 == 0
                    ? Color(red: 0.83, green: 0.65, blue: 0.22).opacity(opacity)
                    : Color(red: 0.55, green: 0.36, blue: 0.96).opacity(opacity * 0.7)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: particleSize, height: particleSize)),
                    with: .color(color)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            // Use Timer-based approach to avoid withAnimation conflict with .transaction
            Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
                dustPhase += 1
            }
        }
        .onDisappear { dustPhase = 0 }
    }

    // MARK: - Risk Callout (Enhanced)

    @ViewBuilder
    private func riskCallout() -> some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            Image("rush-ui-combat-skull")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .shadow(color: DarkFantasyTheme.danger.opacity(0.3), radius: 8)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("ONE LIFE ONLY")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .shadow(color: DarkFantasyTheme.danger.opacity(0.25), radius: 6)
                Text("Defeat = lose all gold & XP. Escape anytime to keep rewards.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.danger.opacity(0.06),
                glowColor: DarkFantasyTheme.danger.opacity(0.03),
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.04, bottomShadow: 0.08)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(portalGlow ? 0.3 : 0.12), lineWidth: 1)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: portalGlow)
        )
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.danger.opacity(0.08), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Stats Panel (Ornamental)

    @ViewBuilder
    private func statsPanel() -> some View {
        HStack(spacing: 0) {
            statCell(value: "12", label: "ROOMS", icon: "rush-node-combat")
            statDivider()
            statCell(value: "1", label: "SHOP", icon: "rush-dungeon-merchant")
            statDivider()
            statCell(value: "2", label: "BOSSES", icon: "rush-node-miniboss")
            statDivider()
            statCell(value: "2", label: "EVENTS", icon: "rush-node-event")
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.25), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    @ViewBuilder
    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .opacity(0.6)
            Text(value)
                .font(DarkFantasyTheme.title(size: 28))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 8)
                .monospacedDigit()
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    @ViewBuilder
    private func statDivider() -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, DarkFantasyTheme.gold.opacity(0.2), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 1)
            .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Rush View (Active)

    @ViewBuilder
    private func rushView(vm: DungeonRushViewModel) -> some View {
        ZStack {
            // Per-room atmospheric background
            if let room = vm.currentRoom {
                roomBackground(for: room.type)
            }

            VStack(spacing: 0) {
                rushHUD(vm: vm)
                Spacer()
                if let room = vm.currentRoom {
                    roomContentView(vm: vm, room: room)
                }
                Spacer()
                roomActionsView(vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
    }

    // MARK: - Per-Room Background

    @ViewBuilder
    private func roomBackground(for type: String) -> some View {
        ZStack {
            switch type {
            case "combat":
                Image("bg-rush-combat")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.22)
                    .clipped()
                // Red edge vignette
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        DarkFantasyTheme.danger.opacity(0.08)
                    ]),
                    center: .bottom, startRadius: 100, endRadius: 500
                )
                .ignoresSafeArea()

            case "elite":
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.stamina.opacity(0.12),
                        Color.clear
                    ]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 380
                )
                .ignoresSafeArea()

            case "miniboss":
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.purple.opacity(0.18),
                        DarkFantasyTheme.danger.opacity(0.08),
                        Color.clear
                    ]),
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 0, endRadius: 420
                )
                .ignoresSafeArea()

            case "treasure":
                Image("bg-rush-treasure")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.18)
                    .clipped()
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.gold.opacity(0.08),
                        Color.clear
                    ]),
                    center: .init(x: 0.5, y: 0.4),
                    startRadius: 0, endRadius: 350
                )
                .ignoresSafeArea()

            case "event":
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.info.opacity(0.12),
                        DarkFantasyTheme.purple.opacity(0.06),
                        Color.clear
                    ]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 380
                )
                .ignoresSafeArea()

            case "shop":
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [
                        DarkFantasyTheme.cyan.opacity(0.1),
                        DarkFantasyTheme.gold.opacity(0.04),
                        Color.clear
                    ]),
                    center: .init(x: 0.5, y: 0.45),
                    startRadius: 0, endRadius: 380
                )
                .ignoresSafeArea()

            default:
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            }

            // Universal bottom fade
            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgPrimary.opacity(0.55),
                    Color.clear,
                    Color.clear,
                    DarkFantasyTheme.bgPrimary.opacity(0.85),
                    DarkFantasyTheme.bgPrimary
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Rush HUD

    @ViewBuilder
    private func rushHUD(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            roomProgressStrip(vm: vm)

            HStack(spacing: LayoutConstants.spaceSM) {
                HPBarView(
                    currentHp: vm.currentHp,
                    maxHp: vm.maxHp,
                    size: .widget,
                    pulseOnCritical: true
                )
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Health: \(vm.currentHp) of \(vm.maxHp)")

                CurrencyDisplay(
                    gold: vm.accumulatedGold,
                    size: .compact,
                    currencyType: .gold,
                    animated: false
                )
                .layoutPriority(1)
                .accessibilityLabel("Gold earned: \(vm.accumulatedGold)")

                xpPill(value: vm.accumulatedXp)
                    .layoutPriority(1)
                    .accessibilityLabel("XP earned: \(vm.accumulatedXp)")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LayoutConstants.screenPadding)

            if !vm.buffs.isEmpty {
                buffRow(buffs: vm.buffs)
            }
        }
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceXS)
    }

    // MARK: - XP Pill

    @ViewBuilder
    private func xpPill(value: Int) -> some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image("icon-xp")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text("\(value)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.purple)
                .monospacedDigit()
        }
    }

    // MARK: - Room Progress Strip (asset nodes)

    @ViewBuilder
    private func roomProgressStrip(vm: DungeonRushViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.space2XS) {
                    ForEach(0..<vm.rooms.count, id: \.self) { i in
                        let room     = vm.rooms[i]
                        let isCurrent = i == vm.currentRoomIndex
                        let isResolved = room.resolved

                        ZStack {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(
                                    isCurrent
                                        ? DarkFantasyTheme.gold.opacity(0.12)
                                        : isResolved
                                            ? DarkFantasyTheme.bgTertiary.opacity(0.4)
                                            : DarkFantasyTheme.bgSecondary
                                )
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .stroke(
                                    isCurrent ? DarkFantasyTheme.gold : Color.clear,
                                    lineWidth: 1.5
                                )

                            VStack(spacing: 1) {
                                Image(roomNodeAsset(for: room.type))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: isCurrent ? 22 : 16, height: isCurrent ? 22 : 16)
                                    .opacity(isResolved ? 0.35 : isCurrent ? 1.0 : 0.6)
                                Text("\(i + 1)")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                    .foregroundStyle(
                                        isCurrent
                                            ? DarkFantasyTheme.gold
                                            : DarkFantasyTheme.textTertiary
                                    )
                            }

                            if isResolved {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(DarkFantasyTheme.success)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(2)
                            }
                        }
                        .frame(width: isCurrent ? 40 : 30, height: isCurrent ? 48 : 36)
                        .shadow(color: isCurrent ? DarkFantasyTheme.goldGlow : Color.clear, radius: 6)
                        .id(i)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
            .onChange(of: vm.currentRoomIndex) { _, newVal in
                withAnimation { proxy.scrollTo(newVal, anchor: .center) }
            }
        }
    }

    // MARK: - Buff Row

    @ViewBuilder
    private func buffRow(buffs: [RushBuff]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(buffs, id: \.id) { buff in
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image(buffAssetName(for: buff.stat))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("+\(buff.value) \(buff.stat.uppercased())")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.purple)
                    }
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.purple.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .stroke(DarkFantasyTheme.purple.opacity(0.2), lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Room Content

    @ViewBuilder
    private func roomContentView(vm: DungeonRushViewModel, room: RushRoom) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            switch room.type {
            case "combat", "elite", "miniboss":
                enemyShowcase(vm: vm, roomType: room.type)
            case "treasure":
                roomArtView(
                    assetName: "rush-ui-treasure-chest",
                    title: "TREASURE CHEST",
                    description: "A glowing chest awaits. Open it to reveal gold, buffs, or rare items.",
                    accentColor: DarkFantasyTheme.gold
                )
            case "event":
                roomArtView(
                    assetName: "rush-event-blessing",
                    title: "MYSTERIOUS ENCOUNTER",
                    description: "A strange energy fills the room. Step forward to discover what awaits...",
                    accentColor: DarkFantasyTheme.info
                )
            case "shop":
                roomArtView(
                    assetName: "rush-dungeon-merchant",
                    title: "WANDERING MERCHANT",
                    description: "Spend your gold on healing, buffs, and power-ups before the next fight.",
                    accentColor: DarkFantasyTheme.cyan
                )
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Enemy Showcase (full-art, no card)

    @ViewBuilder
    private func enemyShowcase(vm: DungeonRushViewModel, roomType: String) -> some View {
        let accentColor = roomType == "miniboss" ? DarkFantasyTheme.purple
                        : roomType == "elite"    ? DarkFantasyTheme.stamina
                        : DarkFantasyTheme.danger

        VStack(spacing: 0) {
            // Room label
            Text("ROOM \(vm.currentFloor) / \(vm.totalRooms) · \(roomType.uppercased())")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(accentColor.opacity(0.7))
                .tracking(2)
                .padding(.bottom, LayoutConstants.spaceSM)

            // Full-art enemy image
            Image(enemyAssetName(for: vm.enemyName))
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .shadow(color: accentColor.opacity(0.4), radius: 24)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 12, y: 8)
                // Ground glow ellipse
                .overlay(alignment: .bottom) {
                    Ellipse()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 200, height: 20)
                        .blur(radius: 10)
                        .offset(y: 10)
                }

            // Nameplate
            VStack(spacing: LayoutConstants.space2XS) {
                Text(vm.enemyName.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(1.5)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Level \(vm.enemyLevel)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    if roomType != "combat" {
                        typeBadge(
                            text: roomType == "miniboss" ? "FINAL BOSS" : "ELITE",
                            color: accentColor
                        )
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
                    .background(.ultraThinMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium.opacity(0.1), lineWidth: 1)
            )
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Room Art View (treasure / event / shop)

    @ViewBuilder
    private func roomArtView(assetName: String, title: String, description: String, accentColor: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(color: accentColor.opacity(0.45), radius: 28)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 10, y: 6)

            VStack(spacing: LayoutConstants.spaceXS) {
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(accentColor)
                    .tracking(1.5)
                Text(description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Type Badge

    @ViewBuilder
    private func typeBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
            .foregroundStyle(color)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .stroke(color.opacity(0.25), lineWidth: 0.5)
            )
    }

    // MARK: - Room Actions

    @ViewBuilder
    private func roomActionsView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let room = vm.currentRoom {
                Button {
                    Task {
                        switch room.type {
                        case "combat", "elite", "miniboss": await vm.fight()
                        case "shop":                        await vm.openShop()
                        default:                            await vm.resolveRoom()
                        }
                    }
                } label: {
                    if vm.isFighting || vm.isLoading {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text(roomActionLabel(for: room.type))
                    }
                }
                .buttonStyle(.primary)
                .disabled(vm.isFighting || vm.isLoading)
            }

            Button {
                vm.showAbandonConfirm = true
            } label: {
                Text("ESCAPE (Keep Rewards)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.stamina)
            }
            .buttonStyle(.secondary)
            .disabled(vm.isFighting || vm.isLoading)
        }
    }

    // MARK: - Shop Overlay (large item cards)

    @ViewBuilder
    private func shopOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 0) {
                // Header
                VStack(spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image("rush-dungeon-merchant")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                            Text("WANDERING MERCHANT")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                                .foregroundStyle(DarkFantasyTheme.cyan)
                            CurrencyDisplay(
                                gold: vm.accumulatedGold,
                                size: .compact,
                                currencyType: .gold,
                                animated: false
                            )
                        }
                        Spacer()
                    }
                    .padding(LayoutConstants.spaceMD)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.bgTertiary,
                            glowIntensity: 0.4,
                            cornerRadius: LayoutConstants.cardRadius
                        )
                    )
                    .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.cyan.opacity(0.1))
                    .cornerBrackets(color: DarkFantasyTheme.cyan.opacity(0.3), length: 12, thickness: 1.5)
                    .compositingGroup()
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceMD)

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceXL)
                    .padding(.vertical, LayoutConstants.spaceSM)

                // Items
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(vm.shopItems, id: \.slot) { item in
                            shopItemLargeRow(vm: vm, item: item)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }

                Spacer(minLength: 0)

                // Leave button
                VStack(spacing: LayoutConstants.spaceSM) {
                    Button {
                        Task { await vm.leaveShop() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("LEAVE SHOP")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.isLoading)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceMD)
            }
        }
    }

    @ViewBuilder
    private func shopItemLargeRow(vm: DungeonRushViewModel, item: RushShopItem) -> some View {
        let canAfford = vm.accumulatedGold >= item.price
        let accentColor = shopItemAccentColor(for: item.type)

        HStack(spacing: 0) {
            // Image block
            ZStack {
                Rectangle()
                    .fill(accentColor.opacity(0.07))
                Image(shopItemAssetName(for: item))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .shadow(color: accentColor.opacity(0.4), radius: 8)
            }
            .frame(width: 86, height: 86)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.15), Color.clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: 1)
            }

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(item.name.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(0.5)
                Text(item.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Price / Sold
            Group {
                if item.purchased {
                    Text("SOLD")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                } else {
                    Button {
                        Task { await vm.buyShopItem(slot: item.slot) }
                    } label: {
                        CurrencyDisplay(
                            gold: item.price,
                            size: .mini,
                            currencyType: .gold,
                            animated: false
                        )
                    }
                    .buttonStyle(.compactPrimary)
                    .disabled(vm.isProcessingShop || !canAfford)
                    .padding(.trailing, LayoutConstants.spaceSM)
                }
            }
        }
        .frame(height: 86)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    canAfford && !item.purchased
                        ? accentColor.opacity(0.2)
                        : DarkFantasyTheme.borderMedium.opacity(0.08),
                    lineWidth: 1
                )
        )
        .opacity(item.purchased || (!canAfford && !item.purchased) ? 0.5 : 1.0)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.35), radius: 6, y: 3)
    }

    // MARK: - Event Overlay

    @ViewBuilder
    private func eventOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Image("rush-event-blessing")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: DarkFantasyTheme.purple.opacity(0.45), radius: 24)

                Text(vm.eventResultTitle)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(vm.eventResultDescription)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceXL)

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceLG)

                Button { vm.dismissEventResult() } label: { Text("CONTINUE") }
                    .buttonStyle(.primary)
            }
            .padding(LayoutConstants.spaceXL)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.purple.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.purple.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.purple.opacity(0.4), size: 6)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.purple.opacity(0.18), radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Treasure Overlay

    @ViewBuilder
    private func treasureOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Image("rush-ui-treasure-chest")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 24)

                Text("TREASURE!")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                VStack(spacing: LayoutConstants.spaceSM) {
                    if vm.treasureGold > 0 {
                        CurrencyDisplay(
                            gold: vm.treasureGold,
                            size: .compact,
                            currencyType: .gold,
                            animated: false
                        )
                    }
                    if let buff = vm.treasureBuff {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(buffAssetName(for: buff.stat))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(buff.name)
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.purple)
                        }
                    }
                }

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceLG)

                Button { vm.dismissTreasureResult() } label: { Text("CONTINUE") }
                    .buttonStyle(.primary)
            }
            .padding(LayoutConstants.spaceXL)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 6)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.goldGlow, radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Abandon Overlay

    @ViewBuilder
    private func abandonConfirmOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()
                .onTapGesture { vm.showAbandonConfirm = false }

            VStack(spacing: LayoutConstants.spaceMD) {
                Image("rush-ui-escape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .shadow(color: DarkFantasyTheme.stamina.opacity(0.4), radius: 16)

                Text("Escape the Rush?")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("You'll keep all rewards earned so far. The run cannot be resumed.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: LayoutConstants.spaceMD) {
                    CurrencyDisplay(
                        gold: vm.accumulatedGold,
                        size: .compact,
                        currencyType: .gold,
                        animated: false
                    )
                    xpPill(value: vm.accumulatedXp)
                }
                .padding(LayoutConstants.spaceSM)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                )

                HStack(spacing: LayoutConstants.spaceSM) {
                    Button { vm.showAbandonConfirm = false } label: { Text("STAY") }
                        .buttonStyle(.neutral)
                    Button {
                        vm.showAbandonConfirm = false
                        Task { await vm.abandon() }
                    } label: {
                        Text("ESCAPE").foregroundStyle(DarkFantasyTheme.textPrimary)
                    }
                    .buttonStyle(.secondary)
                }
            }
            .padding(LayoutConstants.spaceXL)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.stamina.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.stamina.opacity(0.4), length: 16, thickness: 1.5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Game Over

    @ViewBuilder
    private func gameOverView(vm: DungeonRushViewModel) -> some View {
        let isVictory = vm.rushComplete
        let isEscaped = !vm.rushComplete && vm.lastFightWon
        let isDefeat  = !vm.rushComplete && !vm.lastFightWon
        let accentColor = gameOverAccentColor(vm: vm)

        ZStack {
            // Atmospheric background
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            if isVictory || isEscaped {
                RadialGradient(
                    gradient: Gradient(colors: [accentColor.opacity(0.12), Color.clear]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 420
                )
                .ignoresSafeArea()
            } else {
                RadialGradient(
                    gradient: Gradient(colors: [DarkFantasyTheme.danger.opacity(0.18), Color.clear]),
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0, endRadius: 400
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Central art
                VStack(spacing: LayoutConstants.spaceXS) {
                    Group {
                        if isVictory {
                            Image("result-victory")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.goldGlow, radius: 30)
                                .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 60)
                        } else if isEscaped {
                            Image("rush-ui-victory-banner")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.stamina.opacity(0.4), radius: 24)
                        } else {
                            Image("result-defeat")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .shadow(color: DarkFantasyTheme.danger.opacity(0.55), radius: 28)
                                .shadow(color: DarkFantasyTheme.danger.opacity(0.2), radius: 60)
                        }
                    }

                    Text(isVictory ? "RUSH COMPLETE!" : isEscaped ? "ESCAPED!" : "DEFEATED")
                        .font(DarkFantasyTheme.title(size: 32))
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.4), radius: 12)
                        .tracking(2)

                    Text("Reached Room \(vm.currentFloor) of \(vm.totalRooms)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer().frame(height: LayoutConstants.spaceLG)

                // Rewards or defeat card
                if vm.accumulatedGold > 0 || vm.accumulatedXp > 0 {
                    rewardCard(vm: vm)
                } else if isDefeat {
                    defeatMessage()
                }

                Spacer()

                // Actions
                VStack(spacing: LayoutConstants.spaceSM) {
                    if !appState.pendingLoot.isEmpty {
                        Button("VIEW LOOT") { appState.mainPath.append(AppRoute.loot) }
                            .buttonStyle(.primary)
                    }
                    if isVictory || isEscaped {
                        if appState.pendingLoot.isEmpty {
                            Button { vm.exit() } label: { Text("EXIT") }
                                .buttonStyle(.primary)
                        } else {
                            Button { vm.exit() } label: { Text("EXIT") }
                                .buttonStyle(.secondary)
                        }
                    } else {
                        Button { vm.resetForRetry() } label: { Text("TRY AGAIN") }
                            .buttonStyle(.primary)
                        Button { vm.exit() } label: { Text("EXIT") }
                            .buttonStyle(.secondary)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
    }

    // MARK: - Reward Card

    @ViewBuilder
    private func rewardCard(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("REWARDS")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.5)

            OrnamentalDivider()

            if vm.accumulatedGold > 0 {
                rewardRow(label: "Gold", value: "+\(vm.accumulatedGold)",
                          valueColor: DarkFantasyTheme.goldBright, iconName: "icon-gold")
            }
            if vm.accumulatedXp > 0 {
                rewardRow(label: "Experience", value: "+\(vm.accumulatedXp)",
                          valueColor: DarkFantasyTheme.purple, iconName: "icon-xp")
            }
            if vm.accumulatedItems > 0 {
                HStack {
                    Image("reward-loot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("Items Found")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                    Text("\(vm.accumulatedItems)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .monospacedDigit()
                }
                .padding(.vertical, LayoutConstants.space2XS)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func rewardRow(label: String, value: String, valueColor: Color, iconName: String) -> some View {
        HStack {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                .foregroundStyle(valueColor)
                .monospacedDigit()
        }
        .padding(.vertical, LayoutConstants.space2XS)
    }

    // MARK: - Defeat Message

    @ViewBuilder
    private func defeatMessage() -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("All rewards lost!")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.danger)
            Text("Better luck next time.")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.danger.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Helpers

    /// Derives the full-art asset name from enemy name.
    /// "Cursed Bandit" → "rush-cursed-bandit-full"
    private func enemyAssetName(for name: String) -> String {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "of", with: "")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let candidate = "rush-\(slug)-full"
        // Fallback to portrait, then generic skull
        if UIImage(named: candidate) != nil { return candidate }
        let portrait = "rush-\(slug)-portrait"
        if UIImage(named: portrait) != nil { return portrait }
        return "rush-ui-combat-skull"
    }

    /// Maps room type to node icon asset.
    private func roomNodeAsset(for type: String) -> String {
        switch type {
        case "combat":   return "rush-node-combat"
        case "elite":    return "rush-node-elite"
        case "miniboss": return "rush-node-miniboss"
        case "event":    return "rush-node-event"
        case "treasure": return "rush-node-treasure"
        case "shop":     return "rush-node-shop"
        default:         return "rush-node-combat"
        }
    }

    /// Maps buff stat to asset name.
    private func buffAssetName(for stat: String) -> String {
        switch stat.lowercased() {
        case "str", "strength":   return "rush-buff-strength"
        case "def", "defense":    return "rush-buff-defense"
        case "vit", "vitality":   return "rush-buff-vitality"
        case "agi", "speed":      return "rush-buff-speed"
        case "lck", "fortune":    return "rush-buff-fortune"
        case "per", "perception": return "rush-buff-perception"
        case "poison":            return "rush-buff-poison"
        default:                  return "rush-buff-strength"
        }
    }

    /// Returns accent color for shop item type.
    private func shopItemAccentColor(for type: String) -> Color {
        switch type {
        case "heal":  return DarkFantasyTheme.danger
        case "buff":  return DarkFantasyTheme.stamina
        default:      return DarkFantasyTheme.gold
        }
    }

    /// Derives shop item image asset from item icon string.
    private func shopItemAssetName(for item: RushShopItem) -> String {
        // Item icon may be an SF symbol name or an asset name — try as asset first
        if UIImage(named: item.icon) != nil { return item.icon }
        // Map by item type
        if item.type == "heal" { return "rush-ui-health-potion" }
        return buffAssetName(for: item.name.lowercased())
    }

    private func roomActionLabel(for type: String) -> String {
        switch type {
        case "combat", "elite", "miniboss": return "FIGHT"
        case "treasure":                     return "OPEN CHEST"
        case "event":                        return "EXPLORE"
        case "shop":                         return "ENTER SHOP"
        default:                             return "CONTINUE"
        }
    }

    private func gameOverAccentColor(vm: DungeonRushViewModel) -> Color {
        if vm.rushComplete   { return DarkFantasyTheme.goldBright }
        if vm.lastFightWon   { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }
}
