import SwiftUI

struct DungeonRushDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DungeonRushViewModel?

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

                    // Overlays
                    if vm.showShop {
                        shopOverlay(vm: vm)
                    }
                    if vm.showEventResult {
                        eventOverlay(vm: vm)
                    }
                    if vm.showTreasureResult {
                        treasureOverlay(vm: vm)
                    }
                    if vm.showAbandonConfirm {
                        abandonConfirmOverlay(vm: vm)
                    }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
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
            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.spaceMD)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        DarkFantasyTheme.bgElevated,
                                        DarkFantasyTheme.bgSecondary
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 2)
                            )
                            .shadow(color: DarkFantasyTheme.goldGlow, radius: 20)
                            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 12, y: 4)

                        Image("icon-dungeon-rush")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                    }

                    VStack(spacing: LayoutConstants.spaceXS) {
                        Text("DUNGEON RUSH")
                            .font(DarkFantasyTheme.title(size: 28))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text("12 rooms of combat, treasure & mystery")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.spaceXL)

                    // Room map preview
                    roomMapPreview()

                    // Risk callout
                    riskCallout()

                    // Stats summary
                    statsRow()

                    // Bottom padding for button
                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }

            // Pinned bottom button
            VStack {
                Button {
                    Task { await vm.startRush() }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text("START RUSH")
                    }
                }
                .buttonStyle(.primary)
                .disabled(vm.isLoading)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
            .background(
                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary.opacity(0), DarkFantasyTheme.bgPrimary],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false),
                alignment: .top
            )
        }
    }

    // MARK: - Room Map Preview (Start Screen)

    @ViewBuilder
    private func roomMapPreview() -> some View {
        let roomTypes: [(String, String, Color)] = [
            ("combat", "⚔️", DarkFantasyTheme.danger),
            ("event", "❓", DarkFantasyTheme.purple),
            ("combat", "⚔️", DarkFantasyTheme.danger),
            ("treasure", "📦", DarkFantasyTheme.gold),
            ("elite", "🗡️", DarkFantasyTheme.stamina),
            ("miniboss", "💀", DarkFantasyTheme.danger),
            ("shop", "🏪", DarkFantasyTheme.cyan),
            ("combat", "⚔️", DarkFantasyTheme.danger),
            ("event", "❓", DarkFantasyTheme.purple),
            ("elite", "🗡️", DarkFantasyTheme.stamina),
            ("combat", "⚔️", DarkFantasyTheme.danger),
            ("miniboss", "💀", DarkFantasyTheme.danger),
        ]

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(0..<roomTypes.count, id: \.self) { i in
                    let (_, icon, color) = roomTypes[i]
                    VStack(spacing: 2) {
                        Text(icon)
                            .font(.system(size: 16))
                        Text("\(i + 1)")
                            .font(DarkFantasyTheme.body(size: 9))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .frame(width: 42, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(DarkFantasyTheme.bgTertiary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
    }

    // MARK: - Risk Callout

    @ViewBuilder
    private func riskCallout() -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            Text("☠️")
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("One life only")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.danger)
                Text("Defeat = lose all gold & XP. Escape anytime to keep rewards.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.danger.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.danger.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Stats Row

    @ViewBuilder
    private func statsRow() -> some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            statMini(value: "12", label: "Rooms")
            statMini(value: "1", label: "Shop")
            statMini(value: "2", label: "Bosses")
            statMini(value: "2", label: "Events")
        }
    }

    @ViewBuilder
    private func statMini(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.goldBright)
            Text(label.uppercased())
                .font(DarkFantasyTheme.body(size: 10))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: - Rush View (Active)

    @ViewBuilder
    private func rushView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: 0) {
            // HUD
            rushHUD(vm: vm)

            Spacer()

            // Current room content
            if let room = vm.currentRoom {
                roomContentView(vm: vm, room: room)
            }

            Spacer()

            // Actions
            roomActionsView(vm: vm)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Rush HUD

    @ViewBuilder
    private func rushHUD(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Room progress strip
            roomProgressStrip(vm: vm)

            // HP bar + accumulated rewards
            HStack(spacing: LayoutConstants.spaceSM) {
                HPBarView(
                    currentHp: vm.currentHp,
                    maxHp: vm.maxHp,
                    size: .widget,
                    pulseOnCritical: true
                )
                .accessibilityLabel("Health: \(vm.currentHp) of \(vm.maxHp)")

                CurrencyDisplay(
                    gold: vm.accumulatedGold,
                    size: .compact,
                    currencyType: .gold,
                    animated: false
                )
                .accessibilityLabel("Gold earned: \(vm.accumulatedGold)")

                xpPill(value: vm.accumulatedXp)
                    .accessibilityLabel("XP earned: \(vm.accumulatedXp)")
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Buff badges
            if !vm.buffs.isEmpty {
                buffRow(buffs: vm.buffs)
            }
        }
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceXS)
        .background(
            LinearGradient(
                colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgPrimary.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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

    // MARK: - Room Progress Strip

    @ViewBuilder
    private func roomProgressStrip(vm: DungeonRushViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.space2XS) {
                    ForEach(0..<vm.rooms.count, id: \.self) { i in
                        let room = vm.rooms[i]
                        let isCurrent = i == vm.currentRoomIndex
                        let isResolved = room.resolved

                        VStack(spacing: 1) {
                            Text(roomEmoji(for: room.type))
                                .font(.system(size: isCurrent ? 16 : 12))
                            Text("\(i + 1)")
                                .font(DarkFantasyTheme.body(size: 8))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                        .frame(width: isCurrent ? 38 : 30, height: isCurrent ? 46 : 36)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(isCurrent
                                      ? DarkFantasyTheme.gold.opacity(0.12)
                                      : isResolved
                                          ? DarkFantasyTheme.bgTertiary.opacity(0.5)
                                          : DarkFantasyTheme.bgSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .stroke(isCurrent ? DarkFantasyTheme.gold : Color.clear, lineWidth: 1.5)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if isResolved {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(DarkFantasyTheme.success)
                                    .padding(2)
                            }
                        }
                        .opacity(isResolved ? 0.4 : 1.0)
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
                        Text(buff.icon)
                            .font(.system(size: 12))
                        Text("+\(buff.value) \(buff.stat.uppercased())")
                            .font(DarkFantasyTheme.body(size: 11))
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
            Text("ROOM \(room.index + 1) / \(vm.totalRooms)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .accessibilityLabel("Room \(room.index + 1) of \(vm.totalRooms)")

            switch room.type {
            case "combat", "elite", "miniboss":
                enemyCard(vm: vm, roomType: room.type)
            case "treasure":
                roomCard(
                    icon: "📦",
                    title: "Treasure Chest",
                    description: "A glowing chest awaits. Open it to reveal gold, buffs, or items.",
                    accentColor: DarkFantasyTheme.gold
                )
            case "event":
                roomCard(
                    icon: "❓",
                    title: "Mysterious Encounter",
                    description: "A strange energy fills the room. Step forward to discover what awaits...",
                    accentColor: DarkFantasyTheme.purple
                )
            case "shop":
                roomCard(
                    icon: "🏪",
                    title: "Wandering Merchant",
                    description: "Spend gold on healing, buffs, and power-ups before the next fight.",
                    accentColor: DarkFantasyTheme.cyan
                )
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Enemy Card

    @ViewBuilder
    private func enemyCard(vm: DungeonRushViewModel, roomType: String) -> some View {
        let accentColor = roomType == "miniboss" ? DarkFantasyTheme.danger
                        : roomType == "elite" ? DarkFantasyTheme.stamina
                        : DarkFantasyTheme.borderMedium

        VStack(spacing: LayoutConstants.spaceSM) {
            // Portrait circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                DarkFantasyTheme.bgTertiary,
                                DarkFantasyTheme.bgAbyss
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 44
                        )
                    )
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(accentColor, lineWidth: 2)
                    )
                    .shadow(color: accentColor.opacity(0.2), radius: 12)

                Text(enemyEmoji(name: vm.enemyName))
                    .font(.system(size: 40))
            }

            Text(vm.enemyName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Level \(vm.enemyLevel)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            if roomType == "elite" {
                typeBadge(text: "ELITE", color: DarkFantasyTheme.stamina)
            } else if roomType == "miniboss" {
                typeBadge(text: "BOSS", color: DarkFantasyTheme.danger)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: 300)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: accentColor.opacity(0.15))
        .cornerBrackets(color: accentColor.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: accentColor.opacity(0.15), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }

    // MARK: - Generic Room Card

    @ViewBuilder
    private func roomCard(icon: String, title: String, description: String, accentColor: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(icon)
                .font(.system(size: 52))

            Text(title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            Text(description)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: 300)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: accentColor.opacity(0.08))
        .cornerBrackets(color: accentColor.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
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
                        case "combat", "elite", "miniboss":
                            await vm.fight()
                        case "shop":
                            await vm.openShop()
                        default:
                            await vm.resolveRoom()
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

    // MARK: - Shop Overlay

    @ViewBuilder
    private func shopOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()
                .onTapGesture {}

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.spaceLG)

                    VStack(spacing: LayoutConstants.spaceXS) {
                        Text("🏪")
                            .font(.system(size: 44))

                        Text("SHOP")
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        // Show current gold balance
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text("Your Gold:")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            CurrencyDisplay(
                                gold: vm.accumulatedGold,
                                size: .compact,
                                currencyType: .gold,
                                animated: false
                            )
                        }
                    }

                    GoldDivider()
                        .padding(.horizontal, LayoutConstants.spaceXL)

                    VStack(spacing: LayoutConstants.spaceXS) {
                        ForEach(vm.shopItems, id: \.slot) { item in
                            shopItemRow(vm: vm, item: item)
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
                    .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.cyan.opacity(0.08))
                    .cornerBrackets(color: DarkFantasyTheme.cyan.opacity(0.3), length: 14, thickness: 1.5)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)

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

                    Spacer().frame(height: LayoutConstants.spaceLG)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
    }

    @ViewBuilder
    private func shopItemRow(vm: DungeonRushViewModel, item: RushShopItem) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Icon
            Text(item.icon)
                .font(.system(size: 22))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(item.name)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(item.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if item.purchased {
                Text("SOLD")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
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
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                }
                .buttonStyle(.compactPrimary)
                .disabled(vm.isProcessingShop || vm.accumulatedGold < item.price)
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
        .opacity(item.purchased ? 0.5 : 1.0)
    }

    // MARK: - Event Overlay

    @ViewBuilder
    private func eventOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Text(vm.eventResultIcon)
                    .font(.system(size: 52))

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

                Button {
                    vm.dismissEventResult()
                } label: {
                    Text("CONTINUE")
                }
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
                Text("📦")
                    .font(.system(size: 52))

                Text("TREASURE!")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                VStack(spacing: LayoutConstants.spaceSM) {
                    if vm.treasureGold > 0 {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            CurrencyDisplay(
                                gold: vm.treasureGold,
                                size: .compact,
                                currencyType: .gold,
                                animated: false
                            )
                        }
                    }
                    if let buff = vm.treasureBuff {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text(buff.icon)
                                .font(.system(size: 16))
                            Text(buff.name)
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.purple)
                        }
                    }
                }

                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceLG)

                Button {
                    vm.dismissTreasureResult()
                } label: {
                    Text("CONTINUE")
                }
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
            .shadow(color: DarkFantasyTheme.goldGlow, radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Abandon Confirmation Overlay

    @ViewBuilder
    private func abandonConfirmOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()
                .onTapGesture {
                    vm.showAbandonConfirm = false
                }

            VStack(spacing: LayoutConstants.spaceMD) {
                Text("🏃")
                    .font(.system(size: 36))

                Text("Escape the Rush?")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("You'll keep all rewards earned so far. The run cannot be resumed.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // Reward preview
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
                    Button {
                        vm.showAbandonConfirm = false
                    } label: {
                        Text("STAY")
                    }
                    .buttonStyle(.neutral)

                    Button {
                        vm.showAbandonConfirm = false
                        Task { await vm.abandon() }
                    } label: {
                        Text("ESCAPE")
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
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
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Game Over

    @ViewBuilder
    private func gameOverView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                gameOverAccentColor(vm: vm).opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: gameOverAccentColor(vm: vm).opacity(0.2), radius: 20)

                Text(vm.rushComplete ? "🏆" : vm.lastFightWon ? "🏃" : "💀")
                    .font(.system(size: 48))
            }

            VStack(spacing: LayoutConstants.spaceXS) {
                Text(vm.rushComplete ? "RUSH COMPLETE!" : vm.lastFightWon ? "ESCAPED!" : "DEFEATED")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(gameOverAccentColor(vm: vm))

                Text("Reached Room \(vm.currentFloor) of \(vm.totalRooms)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            // Rewards or defeat message
            if vm.accumulatedGold > 0 || vm.accumulatedXp > 0 {
                rewardCard(vm: vm)
            } else if !vm.lastFightWon {
                defeatMessage()
            }

            Spacer()

            // Actions
            VStack(spacing: LayoutConstants.spaceSM) {
                if !appState.pendingLoot.isEmpty {
                    Button("VIEW LOOT") {
                        appState.mainPath.append(AppRoute.loot)
                    }
                    .buttonStyle(.primary)
                }

                if vm.rushComplete || vm.lastFightWon {
                    if appState.pendingLoot.isEmpty {
                        Button {
                            vm.exit()
                        } label: {
                            Text("EXIT")
                        }
                        .buttonStyle(.primary)
                    } else {
                        Button {
                            vm.exit()
                        } label: {
                            Text("EXIT")
                        }
                        .buttonStyle(.secondary)
                    }
                } else {
                    Button {
                        vm.resetForRetry()
                    } label: {
                        Text("TRY AGAIN")
                    }
                    .buttonStyle(.primary)

                    Button {
                        vm.exit()
                    } label: {
                        Text("EXIT")
                    }
                    .buttonStyle(.secondary)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
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
                rewardRow(label: "Gold", value: "+\(vm.accumulatedGold)", valueColor: DarkFantasyTheme.goldBright, iconName: "icon-gold")
            }
            if vm.accumulatedXp > 0 {
                rewardRow(label: "Experience", value: "+\(vm.accumulatedXp)", valueColor: DarkFantasyTheme.purple, iconName: "icon-xp")
            }
            if vm.accumulatedItems > 0 {
                HStack {
                    Text("🎁")
                        .font(.system(size: 14))
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

    private func roomEmoji(for type: String) -> String {
        switch type {
        case "combat":   return "⚔️"
        case "elite":    return "🗡️"
        case "miniboss": return "💀"
        case "treasure": return "📦"
        case "event":    return "❓"
        case "shop":     return "🏪"
        default:         return "❓"
        }
    }

    private func enemyEmoji(name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("wolf") { return "🐺" }
        if lower.contains("skeleton") || lower.contains("bone") { return "💀" }
        if lower.contains("dragon") { return "🐉" }
        if lower.contains("golem") { return "🗿" }
        if lower.contains("spider") { return "🕷️" }
        if lower.contains("slime") { return "🫧" }
        if lower.contains("demon") { return "👹" }
        if lower.contains("orc") { return "👺" }
        return "⚔️"
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
        if vm.rushComplete { return DarkFantasyTheme.goldBright }
        if vm.lastFightWon { return DarkFantasyTheme.stamina }
        return DarkFantasyTheme.danger
    }
}
