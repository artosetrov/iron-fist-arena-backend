import SwiftUI

struct DungeonRoomDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @Environment(\.dismiss) private var dismiss
    @State private var vm: DungeonRoomViewModel?

    // Animation states
    @State private var currentNodePulse = false
    @State private var shinePhase: CGFloat = -0.5

    // Boss card juice animations
    @State private var borderGlowPhase: Bool = false
    @State private var bossBreathing: Bool = false
    @State private var cardAppeared: Bool = false
    @State private var borderRotation: Double = 0
    @State private var juiceStarted: Bool = false

    // Boss fight slam overlay states
    @State private var showBossFightSlam = false
    @State private var bossSlamScale: CGFloat = MotionConstants.vsScaleFrom
    @State private var bossSlamOpacity: Double = 0
    @State private var bossSlamBgOpacity: Double = 0

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
                } else if vm.errorMessage != nil {
                    ErrorStateView.loadFailed {
                        Task { await vm.loadState() }
                    }
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

            // BOSS FIGHT slam overlay
            if showBossFightSlam {
                bossFightSlamOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("ui-arrow-left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .frame(minWidth: LayoutConstants.touchMin, minHeight: LayoutConstants.touchMin)
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
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            vm?.applyPendingResult()
            startNodePulseAnimation()
        }
        .task {
            if vm == nil {
                vm = DungeonRoomViewModel(appState: appState, cache: cache)
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
                triggerBossFightSlam()
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
            UnifiedHeroWidget(
                character: char,
                context: .dungeon,
                showCurrencies: false,
                onUseHealthPotion: {
                    Task { await useHealthPotion() }
                },
                onUseStaminaPotion: {
                    Task { await useStaminaPotion() }
                }
            )
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
                HStack(spacing: 0) {
                    NumberTickUpText(
                        value: defeated,
                        color: DarkFantasyTheme.textPrimary,
                        font: DarkFantasyTheme.section(size: LayoutConstants.textBody)
                    )
                    Text("/\(total)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }

                if vm.isDungeonComplete {
                    Text("Complete!")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(Capsule().fill(completedGreen))
                } else {
                    Text("\(pctInt)%")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
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
                    .staggeredAppear(index: i)
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
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
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
            let cardWidth = max(geo.size.width - 2 * LayoutConstants.screenPadding, 0)
            let cardHeight: CGFloat = 520

            TabView(selection: selection) {
                ForEach(0..<bosses.count, id: \.self) { index in
                    bossCard(boss: bosses[index], bossIndex: index, vm: vm, cardWidth: cardWidth, cardHeight: cardHeight)
                        .padding(.top, LayoutConstants.spaceSM)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                guard !juiceStarted else { return }
                juiceStarted = true
                // Start looping animations once
                borderGlowPhase = true
                bossBreathing = true
                cardAppeared = true
                // Rotating border animation
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    borderRotation = 360
                }
            }
        }
    }

    @ViewBuilder
    private func bossCard(boss: BossInfo, bossIndex: Int, vm: DungeonRoomViewModel, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        let state = vm.bossState(at: bossIndex)
        let borderColor = bossCardBorderColor(state: state)
        let isActive = state == .current

        ZStack(alignment: .top) {
            // Boss image as full-width card background with breathing
            bossImageBackground(boss: boss, state: state)
                .frame(width: cardWidth, height: cardHeight * 0.6)
                .clipped()
                .frame(width: cardWidth, height: cardHeight, alignment: .center)
                .offset(y: -cardHeight * 0.05)

            // Bottom fade gradient for UI readability over image
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                LinearGradient(
                    colors: [
                        .clear,
                        DarkFantasyTheme.bgDungeonPurple.opacity(0.3),
                        DarkFantasyTheme.bgDungeonPurple.opacity(0.7),
                        DarkFantasyTheme.bgDungeonPurple.opacity(0.95),
                        DarkFantasyTheme.bgDungeonPurple
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: cardHeight * 0.45)
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
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                        }
                        .padding(.bottom, LayoutConstants.spaceXS)
                    }

                    // Boss name with glow effect for active bosses
                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection - 2))
                        .foregroundStyle(
                            state == .locked
                                ? DarkFantasyTheme.textDisabled
                                : DarkFantasyTheme.textPrimary
                        )
                        .tracking(1)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 4)
                        .shadow(
                            color: isActive ? bossBorderPurple.opacity(borderGlowPhase ? 0.8 : 0.2) : .clear,
                            radius: borderGlowPhase ? 12 : 4
                        )
                        .animation(MotionConstants.glowLoop, value: borderGlowPhase)

                    Text(boss.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).italic())
                        .foregroundStyle(DarkFantasyTheme.textBossDesc)
                        .multilineTextAlignment(.center)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 4)
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
        // Animated rotating gradient border for active boss
        .overlay(
            ZStack {
                // Base border
                RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius)
                    .stroke(borderColor, lineWidth: 2)

                // Animated glow border for active boss
                if isActive {
                    RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    bossBorderPurple.opacity(0.1),
                                    bossBorderPurple.opacity(0.9),
                                    DarkFantasyTheme.gold.opacity(0.6),
                                    bossBorderPurple.opacity(0.9),
                                    bossBorderPurple.opacity(0.1)
                                ],
                                center: .center,
                                angle: .degrees(borderRotation)
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 1)

                    // Outer glow pulse
                    RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius)
                        .stroke(bossBorderPurple.opacity(borderGlowPhase ? 0.5 : 0.15), lineWidth: 4)
                        .blur(radius: 6)
                        .animation(MotionConstants.glowLoop, value: borderGlowPhase)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.bossCardRadius))
        // Shimmer sweep on active boss card
        .shimmer(color: DarkFantasyTheme.gold, duration: 5, isActive: isActive)
        // Card entrance animation (only on first appear of carousel)
        .opacity(cardAppeared ? (state == .locked ? 0.6 : 1.0) : 0)
        .offset(y: cardAppeared ? 0 : 20)
        .animation(.easeOut(duration: MotionConstants.fast).delay(Double(bossIndex) * MotionConstants.cardStagger), value: cardAppeared)
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
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(Capsule().fill(completedGreen))

        case .current:
            Text("Ready")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1).bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(Capsule().fill(accentOrange))

        case .locked:
            let remaining = bossIndex - vm.defeatedCount
            Text("\(remaining) left")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge - 1).bold())
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
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
                    .scaledToFill()
            } else if UIImage(named: boss.portraitImage) != nil {
                Image(boss.portraitImage)
                    .resizable()
                    .scaledToFill()
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
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)

                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
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
        let cellWidth = max((UIScreen.main.bounds.width - 2 * LayoutConstants.screenPadding - CGFloat(LayoutConstants.inventoryCols - 1) * LayoutConstants.inventoryGap) / CGFloat(LayoutConstants.inventoryCols), 0)

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
                HapticManager.heavy()
                showFightConfirmation = true
            } label: {
                if vm.isFighting {
                    ProgressView()
                        .tint(.textPrimary)
                } else {
                    VStack(spacing: LayoutConstants.space2XS) {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 18, weight: .bold)) // SF Symbol icon — keep
                            Text("FIGHT BOSS")
                        }

                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11)) // SF Symbol icon
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

    // MARK: - Boss Fight Slam Overlay

    @ViewBuilder
    private var bossFightSlamOverlay: some View {
        ZStack {
            // Darkened background
            DarkFantasyTheme.bgAbyss
                .opacity(bossSlamBgOpacity)
                .ignoresSafeArea()

            // Boss name + "BOSS FIGHT" slam text
            VStack(spacing: LayoutConstants.spaceSM) {
                if let boss = vm?.currentBoss {
                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(3)
                        .opacity(bossSlamOpacity)
                }

                Text("BOSS FIGHT")
                    .font(DarkFantasyTheme.title(size: 38))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(4)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 12)
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 4)
                    .opacity(bossSlamOpacity)
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerBossFightSlam() {
        // Reset states
        bossSlamScale = MotionConstants.vsScaleFrom
        bossSlamOpacity = 0
        bossSlamBgOpacity = 0
        showBossFightSlam = true

        HapticManager.heavy()

        // Phase 1: Background dims + text slams in (0→0.2s)
        withAnimation(.easeOut(duration: MotionConstants.vsSlamDuration)) {
            bossSlamScale = MotionConstants.vsScaleTo
            bossSlamOpacity = 1
            bossSlamBgOpacity = 0.7
        }

        // Phase 2: Hold for dramatic pause (0.2→0.8s), then fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                bossSlamOpacity = 0
                bossSlamBgOpacity = 0
            }
        }

        // Phase 3: Cleanup + start fight (1.1s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            showBossFightSlam = false
            Task { await vm?.fight() }
        }
    }

    // MARK: - Shine Overlay

    private var shineOverlay: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.borderSubtle, .clear],
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

    // MARK: - Potion Usage

    private func useHealthPotion() async {
        guard let cachedInventory = appState.cachedInventory else { return }
        guard let healthPotion = cachedInventory.first(where: { $0.consumableType?.contains("health_potion") == true }) else {
            appState.showToast("No health potions available", type: .error)
            return
        }

        let service = InventoryService(appState: appState)
        let success = await service.useItem(inventoryId: healthPotion.id, consumableType: healthPotion.consumableType)

        if success {
            appState.invalidateCache("inventory")
            appState.showToast("Health restored!", type: .reward)
        } else {
            appState.showToast("Failed to use health potion", type: .error)
        }
    }

    private func useStaminaPotion() async {
        guard let cachedInventory = appState.cachedInventory else { return }
        guard let staminaPotion = cachedInventory.first(where: { $0.consumableType?.contains("stamina_potion") == true }) else {
            appState.showToast("No stamina potions available", type: .error)
            return
        }

        let service = InventoryService(appState: appState)
        let success = await service.useItem(inventoryId: staminaPotion.id, consumableType: staminaPotion.consumableType)

        if success {
            appState.invalidateCache("inventory")
            appState.showToast("Stamina restored!", type: .reward)
        } else {
            appState.showToast("Failed to use stamina potion", type: .error)
        }
    }
}

