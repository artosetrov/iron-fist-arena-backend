import SwiftUI

struct DungeonRushDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DungeonRushViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                if vm.isGameOver {
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
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            Text("🏰")
                .font(.system(size: 64))

            Text("Dungeon Rush")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("12 rooms of combat, treasure & mystery!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("Escape to keep rewards, or lose everything on defeat!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, LayoutConstants.spaceXL)

            // Room preview
            roomPreviewStrip()

            Spacer()

            Button {
                Task { await vm.startRush() }
            } label: {
                if vm.isLoading {
                    ProgressView().tint(DarkFantasyTheme.textOnGold)
                } else {
                    Text("START RUSH")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                }
            }
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(DarkFantasyTheme.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
            .padding(.horizontal, LayoutConstants.screenPadding)
            .disabled(vm.isLoading)

            Spacer().frame(height: LayoutConstants.spaceLG)
        }
    }

    // MARK: - Room Preview Strip (Start Screen)

    @ViewBuilder
    private func roomPreviewStrip() -> some View {
        let types = ["⚔️", "❓", "⚔️", "📦", "🗡️", "👹", "🏪", "⚔️", "❓", "🗡️", "⚔️", "👹"]
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(0..<types.count, id: \.self) { i in
                    Text(types[i])
                        .font(.system(size: 16))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DarkFantasyTheme.bgSecondary)
                        )
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Rush View (Active)

    @ViewBuilder
    private func rushView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: 0) {
            // Top: Progress bar + stats
            VStack(spacing: LayoutConstants.spaceSM) {
                // Room progress strip
                roomProgressStrip(vm: vm)

                // HP bar + rewards
                HStack(spacing: LayoutConstants.spaceSM) {
                    hpBar(percent: vm.currentHpPercent)
                    Spacer()
                    rewardPill(icon: "💰", value: "\(vm.accumulatedGold)")
                    rewardPill(icon: "✨", value: "\(vm.accumulatedXp)")
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                // Buff badges
                if !vm.buffs.isEmpty {
                    buffRow(buffs: vm.buffs)
                }
            }
            .padding(.top, LayoutConstants.spaceSM)

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

    // MARK: - Room Progress Strip

    @ViewBuilder
    private func roomProgressStrip(vm: DungeonRushViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(0..<vm.rooms.count, id: \.self) { i in
                        let room = vm.rooms[i]
                        let isCurrent = i == vm.currentRoomIndex
                        let isResolved = room.resolved

                        Text(room.icon)
                            .font(.system(size: isCurrent ? 20 : 14))
                            .frame(width: isCurrent ? 36 : 26, height: isCurrent ? 36 : 26)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isCurrent
                                          ? DarkFantasyTheme.gold.opacity(0.3)
                                          : isResolved
                                              ? DarkFantasyTheme.bgTertiary.opacity(0.5)
                                              : DarkFantasyTheme.bgSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isCurrent ? DarkFantasyTheme.goldBright : Color.clear, lineWidth: 2)
                            )
                            .opacity(isResolved ? 0.5 : 1.0)
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

    // MARK: - HP Bar

    @ViewBuilder
    private func hpBar(percent: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Text("HP")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DarkFantasyTheme.hpBlood.opacity(percent > 25 ? 0.9 : 0.7))
                        .frame(width: geo.size.width * CGFloat(percent) / 100)
                }
            }
            .frame(width: 80, height: 8)

            Text("\(percent)%")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - Buff Row

    @ViewBuilder
    private func buffRow(buffs: [RushBuff]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(buffs, id: \.id) { buff in
                    HStack(spacing: 2) {
                        Text(buff.icon)
                            .font(.system(size: 12))
                        Text("+\(buff.value)")
                            .font(DarkFantasyTheme.body(size: 10))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DarkFantasyTheme.bgTertiary)
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
            // Room number + type
            Text("ROOM \(room.index + 1) / \(vm.totalRooms)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text(room.icon)
                .font(.system(size: 56))

            Text(room.label.uppercased())
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            // Room-specific info
            switch room.type {
            case "combat", "elite", "miniboss":
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text(vm.enemyName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text("Level \(vm.enemyLevel)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    if room.type == "elite" {
                        Text("ELITE")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.stamina)
                            .padding(.horizontal, LayoutConstants.spaceSM)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DarkFantasyTheme.stamina.opacity(0.15))
                            )
                    } else if room.type == "miniboss" {
                        Text("BOSS")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .padding(.horizontal, LayoutConstants.spaceSM)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DarkFantasyTheme.danger.opacity(0.15))
                            )
                    }
                }

            case "treasure":
                Text("Open the treasure chest!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

            case "event":
                Text("A mysterious encounter awaits...")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

            case "shop":
                Text("Browse wares and prepare for battle")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

            default:
                EmptyView()
            }
        }
    }

    // MARK: - Room Actions

    @ViewBuilder
    private func roomActionsView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let room = vm.currentRoom {
                switch room.type {
                case "combat", "elite", "miniboss":
                    Button {
                        Task { await vm.fight() }
                    } label: {
                        if vm.isFighting {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("FIGHT")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        }
                    }
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(DarkFantasyTheme.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                    .disabled(vm.isFighting)

                case "treasure":
                    Button {
                        Task { await vm.resolveRoom() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("OPEN CHEST")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        }
                    }
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(DarkFantasyTheme.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                    .disabled(vm.isLoading)

                case "event":
                    Button {
                        Task { await vm.resolveRoom() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("EXPLORE")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        }
                    }
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(DarkFantasyTheme.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                    .disabled(vm.isLoading)

                case "shop":
                    Button {
                        Task { await vm.openShop() }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("ENTER SHOP")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        }
                    }
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
                    .background(DarkFantasyTheme.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                    .disabled(vm.isLoading)

                default:
                    EmptyView()
                }
            }

            Button {
                Task { await vm.abandon() }
            } label: {
                Text("ESCAPE (Keep Rewards)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.stamina)
            }
            .disabled(vm.isFighting || vm.isLoading)
        }
    }

    // MARK: - Shop Overlay

    @ViewBuilder
    private func shopOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
                .onTapGesture {} // Block taps

            VStack(spacing: LayoutConstants.spaceLG) {
                Text("🏪")
                    .font(.system(size: 48))

                Text("SHOP")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                VStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.shopItems, id: \.slot) { item in
                        shopItemRow(vm: vm, item: item)
                    }
                }
                .padding(LayoutConstants.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )

                Button {
                    Task { await vm.leaveShop() }
                } label: {
                    if vm.isLoading {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text("LEAVE SHOP")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                    }
                }
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
                .background(DarkFantasyTheme.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                .disabled(vm.isLoading)
            }
            .padding(LayoutConstants.spaceXL)
        }
    }

    @ViewBuilder
    private func shopItemRow(vm: DungeonRushViewModel, item: RushShopItem) -> some View {
        HStack {
            Text(item.icon)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(item.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
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
                    Text("💰 \(item.price)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(DarkFantasyTheme.goldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .disabled(vm.isProcessingShop)
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Event Overlay

    @ViewBuilder
    private func eventOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Text(vm.eventResultIcon)
                    .font(.system(size: 56))

                Text(vm.eventResultTitle)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(vm.eventResultDescription)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceXL)

                Button {
                    vm.dismissEventResult()
                } label: {
                    Text("CONTINUE")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                }
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
                .background(DarkFantasyTheme.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
            }
            .padding(LayoutConstants.spaceXL)
        }
    }

    // MARK: - Treasure Overlay

    @ViewBuilder
    private func treasureOverlay(vm: DungeonRushViewModel) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Text("📦")
                    .font(.system(size: 56))

                Text("TREASURE!")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                VStack(spacing: LayoutConstants.spaceSM) {
                    if vm.treasureGold > 0 {
                        HStack {
                            Text("💰")
                            Text("+\(vm.treasureGold) Gold")
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    }
                    if let buff = vm.treasureBuff {
                        HStack {
                            Text(buff.icon)
                            Text("\(buff.name)")
                                .foregroundStyle(DarkFantasyTheme.purple)
                        }
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    }
                }

                Button {
                    vm.dismissTreasureResult()
                } label: {
                    Text("CONTINUE")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                }
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
                .background(DarkFantasyTheme.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
            }
            .padding(LayoutConstants.spaceXL)
        }
    }

    // MARK: - Game Over

    @ViewBuilder
    private func gameOverView(vm: DungeonRushViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            Text(vm.rushComplete ? "🏆" : vm.lastFightWon ? "🏃" : "💀")
                .font(.system(size: 64))

            Text(vm.rushComplete ? "Rush Complete!" : vm.lastFightWon ? "Escaped!" : "Defeated!")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                .foregroundStyle(vm.lastFightWon || vm.rushComplete ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)

            Text("Reached Room \(vm.currentFloor) of \(vm.totalRooms)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Rewards
            if vm.accumulatedGold > 0 || vm.accumulatedXp > 0 {
                VStack(spacing: LayoutConstants.spaceSM) {
                    Text("REWARDS")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    if vm.accumulatedGold > 0 {
                        HStack {
                            Text("💰 Gold")
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            Spacer()
                            Text("+\(vm.accumulatedGold)")
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    }
                    if vm.accumulatedXp > 0 {
                        HStack {
                            Text("✨ XP")
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            Spacer()
                            Text("+\(vm.accumulatedXp)")
                                .foregroundStyle(DarkFantasyTheme.purple)
                        }
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    }
                    if vm.accumulatedItems > 0 {
                        HStack {
                            Text("🎁 Items")
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            Spacer()
                            Text("\(vm.accumulatedItems)")
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    }
                }
                .padding(LayoutConstants.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .padding(.horizontal, LayoutConstants.spaceXL)
            } else if !vm.lastFightWon {
                Text("All rewards lost!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }

            Spacer()

            VStack(spacing: LayoutConstants.spaceSM) {
                if !appState.pendingLoot.isEmpty {
                    Button("VIEW LOOT") {
                        appState.mainPath.append(AppRoute.loot)
                    }
                    .buttonStyle(.primary)
                }

                Button {
                    vm.exit()
                } label: {
                    Text("EXIT")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        .foregroundStyle(appState.pendingLoot.isEmpty ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                        .background(appState.pendingLoot.isEmpty ? DarkFantasyTheme.goldGradient : LinearGradient(colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(DarkFantasyTheme.borderOrnament, lineWidth: appState.pendingLoot.isEmpty ? 0 : 1)
                        )
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Reward Pill

    @ViewBuilder
    private func rewardPill(icon: String, value: String) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Text(icon)
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}
