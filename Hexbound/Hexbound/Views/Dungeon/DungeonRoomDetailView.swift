import SwiftUI

struct DungeonRoomDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @Environment(\.dismiss) private var dismiss
    @State private var vm: DungeonRoomViewModel?

    // Animation states
    @State private var currentNodePulse = false

    // Card entrance animation
    @State private var cardAppeared: Bool = false

    // Boss fight slam overlay states
    @State private var showBossFightSlam = false
    @State private var bossSlamScale: CGFloat = MotionConstants.vsScaleFrom
    @State private var bossSlamOpacity: Double = 0
    @State private var bossSlamBgOpacity: Double = 0

    // Modal states
    @State private var selectedLootItem: LootPreview? = nil
    @State private var showLootDetail = false
    @State private var showDungeonInfo = false
    // confirmation dialog removed — fight triggers directly
    @State private var selectedBossForDetail: BossInfo? = nil

    // Spec colors — from theme tokens
    private let accentOrange = DarkFantasyTheme.arenaRankGold
    private let completedGreen = DarkFantasyTheme.success
    private let lockedGray = DarkFantasyTheme.lockedGray

    var body: some View {
        ZStack {
            // Deep dark gradient background
            DarkFantasyTheme.bgDungeonGradient
            .ignoresSafeArea()

            if let vm {
                Group {
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

                        // 3. Boss cards grid (compact cards, tap for detail)
                        bossCardGrid(vm: vm)
                    }

                    // Victory overlay
                    if vm.showVictory {
                        DungeonVictoryView(vm: vm)
                            .transition(.opacity)
                    }
                }
                }
                .transaction { $0.animation = nil }
            }

            // BOSS FIGHT slam overlay
            if showBossFightSlam {
                bossFightSlamOverlay
            }

            // Loading overlay when fight is starting
            if let vm, vm.isFighting {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    VStack(spacing: LayoutConstants.spaceMD) {
                        ProgressView()
                            .tint(DarkFantasyTheme.gold)
                            .scaleEffect(1.4)
                        Text("Preparing for battle...")
                            .font(DarkFantasyTheme.uiLabel)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .padding(LayoutConstants.spaceLG)
                    .background(
                        RadialGlowBackground(
                            baseColor: DarkFantasyTheme.bgSecondary,
                            glowColor: DarkFantasyTheme.gold.opacity(0.15),
                            glowIntensity: 0.5,
                            cornerRadius: LayoutConstants.modalRadius
                        )
                    )
                    .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
                    .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
                    .compositingGroup()
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: vm?.isFighting)
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
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            vm?.applyPendingResult()
            startNodePulseAnimation()
        }
        // Safety net: if onAppear doesn't fire reliably when combat view is popped,
        // detect the pop via path count change and apply pending result
        .onChange(of: appState.mainPath.count) { oldCount, newCount in
            if newCount < oldCount {
                // A view was popped — check if we have pending fight result
                vm?.applyPendingResult()
            }
        }
        .task {
            if vm == nil {
                vm = DungeonRoomViewModel(appState: appState, cache: cache)
            }
            await vm?.loadState()
        }
        .sheet(isPresented: $showDungeonInfo) {
            if let dungeon = vm?.dungeon {
                DungeonInfoSheet(dungeon: dungeon, defeatedCount: vm?.defeatedCount ?? 0)
            }
        }
        .navigationDestination(item: $selectedBossForDetail) { boss in
            if let vm {
                let bossIdx = (vm.dungeon?.bosses ?? []).firstIndex(where: { $0.id == boss.id }) ?? 0
                BossDetailSheet(
                    boss: boss,
                    state: vm.bossState(at: bossIdx),
                    bossIndex: bossIdx,
                    stamina: vm.stamina,
                    energyCost: vm.dungeon?.energyCost ?? 10,
                    isFighting: vm.isFighting,
                    onFight: {
                        selectedBossForDetail = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            vm.selectBoss(at: bossIdx)
                            triggerBossFightSlam()
                        }
                    },
                    onLootTap: { loot in
                        selectedLootItem = loot
                        withAnimation(.easeOut(duration: 0.2)) {
                            showLootDetail = true
                        }
                    },
                    isNavigationMode: true
                )
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
        // confirmation dialog removed — fight triggers directly from boss detail sheet
    }

    // MARK: - Hero Widget (same as Hub)

    @ViewBuilder
    private var compactHeroWidget: some View {
        if let char = appState.currentCharacter {
            UnifiedHeroWidget(
                character: char,
                context: .dungeon,
                showCurrencies: false,
                onTap: { appState.mainPath.append(AppRoute.hero) }
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

    // MARK: - Boss Card Grid (compact cards)

    @ViewBuilder
    private func bossCardGrid(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let columns = [
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
        ]

        ScrollView {
            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
                ForEach(Array(bosses.enumerated()), id: \.element.id) { index, boss in
                    DungeonBossCard(
                        boss: boss,
                        state: vm.bossState(at: index),
                        bossIndex: index
                    ) {
                        HapticManager.light()
                        SFXManager.shared.play(.uiTap)
                        vm.selectBoss(at: index)
                        selectedBossForDetail = boss
                    }
                    .opacity(cardAppeared ? 1.0 : 0)
                    .offset(y: cardAppeared ? 0 : 20)
                    .animation(
                        .easeOut(duration: MotionConstants.fast)
                            .delay(Double(index) * MotionConstants.cardStagger),
                        value: cardAppeared
                    )
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
        .onAppear {
            cardAppeared = true
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

    // MARK: - Helpers

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
        guard var items = appState.cachedInventory else { return }
        guard let potion = items.first(where: { $0.consumableType?.contains("health_potion") == true }) else {
            appState.showToast("No health potions available", type: .error)
            return
        }

        // Optimistic UI — update cache + HP immediately
        let previousItems = items
        let previousHp = appState.currentCharacter?.currentHp ?? 0
        let maxHp = appState.currentCharacter?.maxHp ?? 1

        if let qty = potion.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == potion.id }
        }
        appState.cachedInventory = items

        let estimatedHeal = max(Int(Double(maxHp) * 0.3), 50)
        let newHp = min(previousHp + estimatedHeal, maxHp)
        appState.currentCharacter?.currentHp = newHp

        HapticManager.success()
        // No success toast — haptic provides feedback

        // Fire API in background
        let potionId = potion.id
        let consumableType = potion.consumableType
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(inventoryId: potionId, consumableType: consumableType)
            if !success {
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    appState.currentCharacter?.currentHp = previousHp
                    appState.showToast("Failed to use potion", type: .error)
                }
            }
        }
    }

    private func useStaminaPotion() async {
        guard var items = appState.cachedInventory else { return }
        guard let potion = items.first(where: { $0.consumableType?.contains("stamina_potion") == true }) else {
            appState.showToast("No stamina potions available", type: .error)
            return
        }

        // Optimistic UI — update cache + stamina immediately
        let previousItems = items
        let previousStamina = appState.currentCharacter?.currentStamina ?? 0

        if let qty = potion.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == potion.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == potion.id }
        }
        appState.cachedInventory = items

        let maxStamina = appState.currentCharacter?.maxStamina ?? 100
        let estimatedRestore = max(Int(Double(maxStamina) * 0.3), 20)
        let newStamina = min(previousStamina + estimatedRestore, maxStamina)
        appState.currentCharacter?.currentStamina = newStamina

        HapticManager.success()
        // No success toast — haptic provides feedback

        // Fire API in background
        let potionId = potion.id
        let consumableType = potion.consumableType
        let service = InventoryService(appState: appState)
        Task {
            let success = await service.useItem(inventoryId: potionId, consumableType: consumableType)
            if !success {
                await MainActor.run {
                    appState.cachedInventory = previousItems
                    appState.currentCharacter?.currentStamina = previousStamina
                    appState.showToast("Failed to use potion", type: .error)
                }
            }
        }
    }
}

