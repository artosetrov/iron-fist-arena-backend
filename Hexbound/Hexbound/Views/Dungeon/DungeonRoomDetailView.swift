import SwiftUI

struct DungeonRoomDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DungeonRoomViewModel?

    // Animation states
    @State private var currentNodePulse = false
    @State private var shinePhase: CGFloat = -0.5

    // Modal states
    @State private var selectedLootItem: LootPreview? = nil
    @State private var showLootDetail = false
    @State private var showDungeonInfo = false
    @State private var showFightConfirmation = false

    // Spec colors — from theme tokens
    private let accentOrange = DarkFantasyTheme.arenaRankGold
    private let bossPurple = DarkFantasyTheme.purple
    private let bossBorderPurple = DarkFantasyTheme.bossBorderPurple
    private let completedGreen = DarkFantasyTheme.success
    private let lockedGray = DarkFantasyTheme.lockedGray
    private let lootGold = DarkFantasyTheme.lootGold

    var body: some View {
        ZStack {
            // Deep dark gradient background
            DarkFantasyTheme.bgDungeonGradient
            .ignoresSafeArea()

            if let vm {
                if vm.isLoading {
                    ProgressView().tint(DarkFantasyTheme.gold)
                } else {
                    VStack(spacing: 0) {
                        // 1. Compact hero widget
                        compactHeroWidget

                        // 2. Progress section with mini-nodes
                        dungeonProgressSection(vm: vm)

                        // 3. Boss cards carousel (swipeable left/right)
                        bossCarousel(vm: vm)
                    }

                    // Victory overlay
                    if vm.showVictory {
                        DungeonVictoryView(vm: vm)
                            .transition(.opacity)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text(vm?.dungeon?.name.uppercased() ?? "DUNGEON")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(accentOrange)
                    .tracking(2)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showDungeonInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
        }
        .onAppear {
            vm?.applyPendingResult()
            startNodePulseAnimation()
        }
        .task {
            if vm == nil {
                vm = DungeonRoomViewModel(appState: appState)
            }
            await vm?.loadState()
        }
        .sheet(isPresented: $showDungeonInfo) {
            if let dungeon = vm?.dungeon {
                DungeonInfoSheet(dungeon: dungeon)
            }
        }
        .overlay {
            if showLootDetail, let loot = selectedLootItem {
                LootPreviewSheet(loot: loot, onClose: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showLootDetail = false
                    }
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .confirmationDialog(
            "FIGHT BOSS",
            isPresented: $showFightConfirmation,
            titleVisibility: .visible
        ) {
            Button("Fight (\(vm?.dungeon?.energyCost ?? 10) Energy)") {
                Task { await vm?.fight() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let boss = vm?.currentBoss {
                Text("Challenge \(boss.name)? This will cost energy.")
            } else {
                Text("Are you ready to fight? This will cost energy.")
            }
        }
    }

    // MARK: - Hero Widget (same as Hub)

    @ViewBuilder
    private var compactHeroWidget: some View {
        if let char = appState.currentCharacter {
            HubCharacterCard(character: char, showChevron: false)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)
        }
    }

    // MARK: - Dungeon Progress Section

    @ViewBuilder
    private func dungeonProgressSection(vm: DungeonRoomViewModel) -> some View {
        let total = vm.dungeon?.totalBosses ?? 10
        let defeated = vm.defeatedCount
        let pctInt = total > 0 ? Int(Double(defeated) / Double(total) * 100) : 0

        VStack(spacing: LayoutConstants.spaceSM) {
            // Progress text + badge + cost
            HStack {
                Text("\(defeated)/\(total)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                if vm.isDungeonComplete {
                    Text("Complete!")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(Capsule().fill(completedGreen))
                } else {
                    Text("\(pctInt)%")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(Capsule().fill(accentOrange))
                }

                Spacer()

                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14)) // SF Symbol icon — keep
                    Text("Cost \(vm.dungeon?.energyCost ?? 10)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                }
                .foregroundStyle(DarkFantasyTheme.stamina)
            }

            // Mini nodes row
            miniNodeRow(vm: vm)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceMS)
    }

    // MARK: - Mini Node Row

    @ViewBuilder
    private func miniNodeRow(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let nodeSize: CGFloat = 28

        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<bosses.count, id: \.self) { i in
                miniNode(index: i, boss: bosses[i], size: nodeSize, vm: vm)
            }
        }
    }

    @ViewBuilder
    private func miniNode(index: Int, boss: BossInfo, size: CGFloat, vm: DungeonRoomViewModel) -> some View {
        let state = vm.bossState(at: index)
        let isCurrent = state == .current
        let isSelected = vm.selectedBossIndex == index

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectBoss(at: index)
            }
        } label: {
            ZStack {
                // Pulsing glow behind current node
                if isCurrent {
                    Circle()
                        .fill(accentOrange.opacity(currentNodePulse ? 0.6 : 0.3))
                        .frame(width: size + 8, height: size + 8)
                        .blur(radius: 5)
                }

                // Node circle
                Circle()
                    .fill(miniNodeBackground(state: state))
                    .frame(width: size, height: size)

                // Node border
                Circle()
                    .stroke(
                        miniNodeBorderColor(state: state),
                        lineWidth: isSelected ? 2.5 : 1
                    )
                    .frame(width: size, height: size)

                // Node content
                switch state {
                case .defeated:
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(completedGreen)
                case .current:
                    Text("\(boss.id)")
                        .font(DarkFantasyTheme.body(size: 10).bold())
                        .foregroundStyle(.white)
                case .locked:
                    Text("\(boss.id)")
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                }
            }
            .frame(width: size + 8, height: size + 8)
        }
        .buttonStyle(.scalePress(0.9))
        .opacity(state == .locked ? 0.5 : 1.0)
    }

    private func miniNodeBackground(state: BossState) -> Color {
        switch state {
        case .defeated: return completedGreen.opacity(0.15)
        case .current: return accentOrange.opacity(0.2)
        case .locked: return DarkFantasyTheme.bgDungeonCard
        }
    }

    private func miniNodeBorderColor(state: BossState) -> Color {
        switch state {
        case .defeated: return completedGreen
        case .current: return accentOrange
        case .locked: return lockedGray
        }
    }

    // MARK: - Boss Card (Main Element)

    // MARK: - Boss Carousel

    @ViewBuilder
    private func bossCarousel(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let selection = Binding<Int>(
            get: { vm.selectedBossIndex },
            set: { newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.selectBoss(at: newIndex)
                }
            }
        )

        GeometryReader { geo in
            let cardWidth = geo.size.width - 2 * LayoutConstants.screenPadding
            let cardHeight: CGFloat = 520

            TabView(selection: selection) {
                ForEach(0..<bosses.count, id: \.self) { index in
                    bossCard(boss: bosses[index], bossIndex: index, vm: vm, cardWidth: cardWidth, cardHeight: cardHeight)
                        .padding(.top, LayoutConstants.spaceSM)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    @ViewBuilder
    private func bossCard(boss: BossInfo, bossIndex: Int, vm: DungeonRoomViewModel, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        let state = vm.bossState(at: bossIndex)
        let borderColor = bossCardBorderColor(state: state)

        ZStack(alignment: .top) {
            // Boss image as card background (fixed 256pt height, shifted up)
            bossImageBackground(boss: boss, state: state)
                .frame(width: cardWidth, height: 256)
                .clipped()
                .frame(width: cardWidth, height: cardHeight, alignment: .top)
                .offset(y: 40)

            // Top + bottom gradients for readability
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [DarkFantasyTheme.bgDungeonPurple, DarkFantasyTheme.bgDungeonPurple.opacity(0.9), DarkFantasyTheme.bgDungeonPurple.opacity(0.5), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: cardHeight * 0.25)

                Spacer(minLength: 0)

                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.bgDungeonPurple.opacity(0.5), DarkFantasyTheme.bgDungeonPurple.opacity(0.9), DarkFantasyTheme.bgDungeonPurple],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: cardHeight * 0.55)
            }
            .frame(width: cardWidth, height: cardHeight)

            // All content on top of image
            VStack(spacing: 0) {
                // Boss name + description at top
                VStack(spacing: LayoutConstants.spaceXS) {
                    // Defeated checkmark
                    if state == .defeated {
                        ZStack {
                            Circle()
                                .fill(completedGreen)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold)) // SF Symbol icon — keep
                                .foregroundStyle(.white)
                        }
                        .padding(.bottom, LayoutConstants.spaceXS)
                    }

                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection - 2))
                        .foregroundStyle(
                            state == .locked
                                ? DarkFantasyTheme.textDisabled
                                : DarkFantasyTheme.textPrimary
                        )
                        .tracking(1)
                        .shadow(color: .black.opacity(0.8), radius: 4)

                    Text(boss.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).italic())
                        .foregroundStyle(DarkFantasyTheme.textBossDesc)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceLG)
                .padding(.bottom, LayoutConstants.spaceSM)

                Spacer()

                // Info section at bottom
                VStack(spacing: LayoutConstants.spaceMS) {
                    // Header: BOSS tag, level, status badge
                    bossCardHeader(boss: boss, state: state, bossIndex: bossIndex, vm: vm)

                    // HP bar
                    bossHPBar(boss: boss, state: state)

                    // Loot section
                    if !boss.loot.isEmpty {
                        lootSection(loot: boss.loot)
                    }

                    // Fight button
                    fightButton(state: state, bossIndex: bossIndex, vm: vm)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceMS)
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius)
                .fill(DarkFantasyTheme.bossCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius)
                .stroke(borderColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius))
        .opacity(state == .locked ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: state == .locked)
    }

    // MARK: - Boss Card Header

    @ViewBuilder
    private func bossCardHeader(boss: BossInfo, state: BossState, bossIndex: Int, vm: DungeonRoomViewModel) -> some View {
        HStack {
            // BOSS tag
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("\u{2620}")
                    .font(.system(size: 12)) // emoji — keep
                Text("BOSS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .tracking(2)
            }
            .foregroundStyle(state == .defeated ? completedGreen : bossPurple)

            Spacer()

            // Level
            Text("Lv. \(boss.level)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Status badge
            bossStatusBadge(state: state, bossIndex: bossIndex, vm: vm)
        }
    }

    @ViewBuilder
    private func bossStatusBadge(state: BossState, bossIndex: Int, vm: DungeonRoomViewModel) -> some View {
        switch state {
        case .defeated:
            Text("Defeated")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1).bold())
                .foregroundStyle(.white)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, 3)
                .background(Capsule().fill(completedGreen))

        case .current:
            Text("Ready")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1).bold())
                .foregroundStyle(.white)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, 3)
                .background(Capsule().fill(accentOrange))

        case .locked:
            let remaining = bossIndex - vm.defeatedCount
            Text("\(remaining) left")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1).bold())
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, 3)
                .background(Capsule().fill(lockedGray))
        }
    }

    // MARK: - Boss Image Background

    @ViewBuilder
    private func bossImageBackground(boss: BossInfo, state: BossState) -> some View {
        let imageColor = state == .defeated ? completedGreen : bossPurple

        Group {
            if UIImage(named: boss.fullImage) != nil {
                Image(boss.fullImage)
                    .resizable()
                    .scaledToFit()
            } else if UIImage(named: boss.portraitImage) != nil {
                Image(boss.portraitImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(boss.emoji)
                    .font(.system(size: 80))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .shadow(color: imageColor.opacity(0.35), radius: 20)
        .opacity(state == .locked ? 0.3 : 1.0)
    }

    // MARK: - Boss HP Bar

    @ViewBuilder
    private func bossHPBar(boss: BossInfo, state: BossState) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            HStack {
                Text("HP")
                    .font(DarkFantasyTheme.body(size: 9))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
                Text(
                    state == .defeated
                        ? "0 / \(formatNumber(boss.hp))"
                        : "\(formatNumber(boss.hp)) / \(formatNumber(boss.hp))"
                )
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(DarkFantasyTheme.bgTertiary)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            DarkFantasyTheme.dungeonHpGradient
                        )
                        .frame(width: geo.size.width * (state == .defeated ? 0 : 1.0))
                        .animation(.easeOut(duration: 0.5), value: state == .defeated)
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Loot Section

    @ViewBuilder
    private func lootSection(loot: [LootPreview]) -> some View {
        // Calculate cell width to match inventory/shop icon size
        let cellWidth = (UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - CGFloat(LayoutConstants.inventoryCols - 1) * LayoutConstants.inventoryGap) / CGFloat(LayoutConstants.inventoryCols)

        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("\u{1F381}")
                        .font(.system(size: 11)) // emoji — keep
                    Text("POSSIBLE LOOT")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .tracking(1)
                }
                .foregroundStyle(lootGold)

                Spacer()
            }

            // Items sized to match inventory/shop cards
            HStack(spacing: LayoutConstants.inventoryGap) {
                ForEach(loot) { item in
                    lootCard(item: item)
                        .frame(width: cellWidth)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func lootCard(item: LootPreview) -> some View {
        let rColor = lootRarityColor(for: item)
        let hasRareBorder = isRareLoot(item.detail)

        Button {
            selectedLootItem = item
            withAnimation(.easeOut(duration: 0.2)) {
                showLootDetail = true
            }
        } label: {
            VStack(spacing: LayoutConstants.spaceXS + 2) {
                // Item image — like shop/inventory cards
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(rColor.opacity(0.15))

                    ItemImageView(
                        imageKey: item.imageKey,
                        imageUrl: item.imageUrl,
                        fallbackIcon: item.icon
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(
                            hasRareBorder ? rColor.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                            lineWidth: 1
                        )
                )
                .shadow(color: hasRareBorder ? rColor.opacity(0.3) : .clear, radius: 6)

                Text(item.name)
                    .font(DarkFantasyTheme.body(size: 9))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)

                Text(item.detail)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(rColor)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.scalePress(0.95))
    }

    private func lootRarityColor(for item: LootPreview) -> Color {
        if item.rarity != .common {
            return DarkFantasyTheme.rarityColor(for: item.rarity)
        }
        return lootDetailColor(for: item.detail)
    }

    // MARK: - Fight Button

    @ViewBuilder
    private func fightButton(state: BossState, bossIndex: Int, vm: DungeonRoomViewModel) -> some View {
        switch state {
        case .defeated:
            // Defeated state — green outline
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18)) // SF Symbol icon — keep
                Text("DEFEATED")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .tracking(2)
            }
            .foregroundStyle(completedGreen)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .fill(completedGreen.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .stroke(completedGreen.opacity(0.3), lineWidth: 2)
            )

        case .current:
            // Ready to fight — orange gradient with shine
            let hasEnergy = vm.stamina >= (vm.dungeon?.energyCost ?? 10)

            Button {
                showFightConfirmation = true
            } label: {
                if vm.isFighting {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack(spacing: LayoutConstants.space2XS) {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 18, weight: .bold)) // SF Symbol icon — keep
                            Text("FIGHT BOSS")
                        }

                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9)) // SF Symbol icon — keep
                            Text("\(vm.dungeon?.energyCost ?? 10) Energy")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1))
                        }
                        .opacity(0.7)
                    }
                }
            }
            .buttonStyle(.fight(accent: accentOrange))
            .disabled(vm.isFighting || !hasEnergy)

            if !hasEnergy {
                Text("Not enough energy — \(vm.stamina)/\(vm.dungeon?.energyCost ?? 10)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }

        case .locked:
            // Locked — dark with remaining count
            let remaining = bossIndex - vm.defeatedCount

            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14)) // SF Symbol icon — keep
                Text("\(remaining) ENEMIES REMAIN")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .tracking(1)
            }
            .foregroundStyle(DarkFantasyTheme.textLocked)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .fill(DarkFantasyTheme.bgDarkPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .stroke(DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2)
            )
        }
    }

    // MARK: - Shine Overlay

    private var shineOverlay: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.12), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.35)
            .offset(x: shinePhase * geo.size.width)
            .onAppear {
                withAnimation(
                    .linear(duration: 3)
                    .repeatForever(autoreverses: false)
                ) {
                    shinePhase = 1.5
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func lootDetailColor(for detail: String) -> Color {
        let d = detail.lowercased()
        if d.contains("legendary") { return DarkFantasyTheme.rarityLegendary }
        if d.contains("epic") { return DarkFantasyTheme.rarityEpic }
        if d.contains("rare") { return DarkFantasyTheme.rarityRare }
        if d.contains("uncommon") { return DarkFantasyTheme.rarityUncommon }
        if d.contains("common") { return DarkFantasyTheme.rarityCommon }
        return DarkFantasyTheme.textPrimary
    }

    private func isRareLoot(_ detail: String) -> Bool {
        let d = detail.lowercased()
        return d.contains("epic") || d.contains("legendary")
    }

    private func bossCardBorderColor(state: BossState) -> Color {
        switch state {
        case .defeated: return DarkFantasyTheme.defeatedGreen
        case .current: return bossBorderPurple
        case .locked: return lockedGray
        }
    }

    private func startNodePulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            currentNodePulse = true
        }
    }
}

