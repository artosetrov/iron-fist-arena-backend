import SwiftUI

extension DungeonRushDetailView {
    @ViewBuilder
    func rushView(vm: DungeonRushViewModel) -> some View {
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
        .clipped()
    }

    // MARK: - Per-Room Background

    @ViewBuilder
    func roomBackground(for type: String) -> some View {
        ZStack {
            switch type {
            case "combat":
                Image("bg-rush-combat")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea()
                    .opacity(0.22)
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
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea()
                    .opacity(0.18)
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
    func rushHUD(vm: DungeonRushViewModel) -> some View {
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
    func xpPill(value: Int) -> some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image("icon-xp")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text("\(value)")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.purple)
                .monospacedDigit()
        }
    }

    // MARK: - Room Progress Strip (asset nodes)

    @ViewBuilder
    func roomProgressStrip(vm: DungeonRushViewModel) -> some View {
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
                                    .font(DarkFantasyTheme.body.weight(.semibold))
                                    .foregroundStyle(
                                        isCurrent
                                            ? DarkFantasyTheme.gold
                                            : DarkFantasyTheme.textTertiary
                                    )
                            }

                            if isResolved {
                                Image(systemName: "checkmark")
                                    .font(DarkFantasyTheme.body.bold())
                                    .foregroundStyle(DarkFantasyTheme.success)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(LayoutConstants.space2XS)
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
    func buffRow(buffs: [RushBuff]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(buffs, id: \.id) { buff in
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image(buffAssetName(for: buff.stat))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("+\(buff.value) \(buff.stat.uppercased())")
                            .font(DarkFantasyTheme.body.weight(.semibold))
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
    func roomContentView(vm: DungeonRushViewModel, room: RushRoom) -> some View {
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
    func enemyShowcase(vm: DungeonRushViewModel, roomType: String) -> some View {
        let accentColor = roomType == "miniboss" ? DarkFantasyTheme.purple
                        : roomType == "elite"    ? DarkFantasyTheme.stamina
                        : DarkFantasyTheme.danger

        VStack(spacing: 0) {
            // Room label
            Text("ROOM \(vm.currentFloor) / \(vm.totalRooms) · \(roomType.uppercased())")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(accentColor.opacity(0.7))
                .tracking(2)
                .padding(.bottom, LayoutConstants.spaceSM)

            // Full-art enemy image — constrained to screen width
            Image(enemyAssetName(for: vm.enemyName))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: UIScreen.main.bounds.width - LayoutConstants.screenPadding * 2, maxHeight: 320)
                .clipped()
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
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(1.5)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Level \(vm.enemyLevel)")
                        .font(DarkFantasyTheme.body)
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
    func roomArtView(assetName: String, title: String, description: String, accentColor: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .shadow(color: accentColor.opacity(0.45), radius: 28)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 10, y: 6)

            VStack(spacing: LayoutConstants.spaceXS) {
                Text(title)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(accentColor)
                    .tracking(1.5)
                Text(description)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Type Badge

    @ViewBuilder
    func typeBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.body)
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
    func roomActionsView(vm: DungeonRushViewModel) -> some View {
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
                        HexPulseLoader.onGold()
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
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.stamina)
            }
            .buttonStyle(.secondary)
            .disabled(vm.isFighting || vm.isLoading)
        }
    }

    // MARK: - Shop Overlay (large item cards)

    @ViewBuilder
    func shopOverlay(vm: DungeonRushViewModel) -> some View {
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
                                .font(DarkFantasyTheme.cardTitle)
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
                    .cardShadow()
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
                            HexPulseLoader.onGold()
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
    func shopItemLargeRow(vm: DungeonRushViewModel, item: RushShopItem) -> some View {
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
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(0.5)
                Text(item.description)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Price / Sold
            Group {
                if item.purchased {
                    Text("SOLD")
                        .font(DarkFantasyTheme.body)
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
    func eventOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Image("rush-event-blessing")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: DarkFantasyTheme.purple.opacity(0.45), radius: 24)

                Text(vm.eventResultTitle)
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(vm.eventResultDescription)
                    .font(DarkFantasyTheme.body)
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
    func treasureOverlay(vm: DungeonRushViewModel) -> some View {
        TreasureRewardOverlay(
            gold: vm.treasureGold,
            buff: vm.treasureBuff,
            buffAssetName: vm.treasureBuff.map { buffAssetName(for: $0.stat) },
            onDismiss: { vm.dismissTreasureResult() }
        )
    }

    // MARK: - Abandon Overlay

    @ViewBuilder
    func abandonConfirmOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            DarkFantasyTheme.bgBackdrop.ignoresSafeArea()
                .onTapGesture { vm.showAbandonConfirm = false }

            VStack(spacing: LayoutConstants.spaceMD) {
                Image(systemName: "door.left.hand.open")
                    .font(DarkFantasyTheme.cinematicTitle) // SF Symbol decorative — 40pt
                    .foregroundStyle(DarkFantasyTheme.stamina)
                    .frame(width: 56, height: 56)
                    .shadow(color: DarkFantasyTheme.stamina.opacity(0.4), radius: 16)

                Text("Escape the Rush?")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("You'll keep all rewards earned so far. The run cannot be resumed.")
                    .font(DarkFantasyTheme.body)
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

}
