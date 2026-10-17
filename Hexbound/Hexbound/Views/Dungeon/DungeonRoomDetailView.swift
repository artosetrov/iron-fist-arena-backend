import SwiftUI

/// The dungeon screen: a path of boss medallions across the top and the
/// boss you are about to fight standing full-height on a lit stage below.
/// FIGHT plays a short letterbox intro (`BossIntroOverlay`) and starts the
/// match; the result comes back here as the victory / defeat overlay.
struct DungeonRoomDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @Environment(\.dismiss) private var dismiss
    @State private var vm: DungeonRoomViewModel?

    /// The boss the pre-fight intro is playing for; nil when no intro is up.
    @State private var introBoss: BossInfo?

    /// Navigation depth this screen sits at, to tell a pop from a push.
    @State private var stackDepth: Int?

    // Modal states
    @State private var showDungeonInfo = false
    @State private var selectedBossForDetail: BossInfo? = nil

    // Spec colors — from theme tokens
    private let accentOrange = DarkFantasyTheme.arenaRankGold

    var body: some View {
        ZStack {
            // Deep dark gradient background
            DarkFantasyTheme.bgDungeonGradient
            .ignoresSafeArea()

            if let vm {
                Group {
                if vm.isLoading {
                    HexPulseLoader(.compact)
                } else if vm.errorMessage != nil {
                    ErrorStateView.loadFailed {
                        Task { await vm.loadState() }
                    }
                } else {
                    GeometryReader { geo in
                        // Small phones (SE): a shorter stage floor and no
                        // next-boss teaser, so nothing slides under the bar.
                        let roomy = geo.size.height >= 640
                        VStack(spacing: 0) {
                            // 1. Compact hero widget
                            compactHeroWidget

                            // 2. The dungeon as a path of medallions
                            bossPathSection(vm: vm)

                            // 3. The selected boss on the stage + actions
                            bossStage(vm: vm, roomy: roomy)
                        }
                    }

                    // Victory overlay
                    if vm.showVictory {
                        DungeonVictoryView(vm: vm, onFightNext: { fightNextBoss(vm: vm) })
                            .transition(.opacity)
                    }

                    // Defeat overlay
                    if vm.showDefeat {
                        DungeonDefeatView(vm: vm)
                            .transition(.opacity)
                    }

                    // Boss unlock ceremony — plays after the victory modal
                    // closes (BACK TO CAMP), when a new boss has just become
                    // available in the dungeon. Reuses the same reveal
                    // animation as hub building unlocks (locked → glow → revealed).
                    if let boss = vm.pendingBossUnlock {
                        BossUnlockCeremony(boss: boss) {
                            vm.dismissBossUnlock()
                        }
                        .transition(.opacity)
                        .zIndex(ZLayer.modal)
                    }
                }
                }
                .transaction { $0.animation = nil }
            }

            // Pre-fight intro. Stays up until the battle screen is pushed
            // over it (or the fight could not start), so the dungeon never
            // flashes between the two.
            if let boss = introBoss {
                BossIntroOverlay(boss: boss, stageLabel: introStageLabel(for: boss)) {
                    Task {
                        let depth = appState.mainPath.count
                        await vm?.fight()
                        // Pushed: keep the intro up until the battle screen
                        // has slid over it, so the dungeon never flashes.
                        if appState.mainPath.count > depth {
                            try? await Task.sleep(for: .milliseconds(600))
                        }
                        introBoss = nil
                    }
                }
                .transition(.opacity)
                .zIndex(ZLayer.modal)
            }

            // Loading overlay when fight is starting (the intro covers it
            // while it is up)
            if let vm, vm.isFighting, introBoss == nil {
                ZStack {
                    DarkFantasyTheme.bgAbyss.opacity(0.55)
                        .ignoresSafeArea()
                    VStack(spacing: LayoutConstants.spaceMD) {
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.gold)
                            .scaleEffect(1.4)
                        Text("Preparing for battle...")
                            .font(DarkFantasyTheme.body)
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
        .toolbar(introBoss == nil ? .visible : .hidden, for: .navigationBar)
        .animation(MotionConstants.snappy, value: vm?.isFighting)
        .animation(.easeInOut(duration: 0.2), value: introBoss?.id)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text(vm?.dungeon?.name.uppercased() ?? "DUNGEON")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(accentOrange)
                    .tracking(2)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showDungeonInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dungeon info")
            }
        }
        .onAppear {
            if stackDepth == nil { stackDepth = appState.mainPath.count }
            vm?.applyPendingResult()
            AmbientManager.shared.setZone(.dungeon)
        }
        .onDisappear {
            // Popped back onto the dungeon trail map: it keeps the dungeon
            // ambience. Anything else (hub, battle push) as before.
            let count = appState.mainPath.count
            let backOnTrail = count < (stackDepth ?? 0) && count == appState.dungeonTrailDepth
            if !backOnTrail {
                AmbientManager.shared.setZone(.hub)
            }
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
                        // Latency pass (2026-10-15): the intro starts on the
                        // tap (it plays over the pop of this screen) and the
                        // run start goes out in parallel (`startFight`).
                        selectedBossForDetail = nil
                        startFight(vm: vm, boss: boss)
                    },
                    onLootTap: { _ in },
                    totalStages: vm.dungeon?.totalBosses ?? 10,
                    runActive: vm.hasActiveRun
                )
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
                onTap: { appState.mainPath.append(AppRoute.hero) }
            )
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
        }
    }

    // MARK: - Boss Path

    @ViewBuilder
    private func bossPathSection(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let total = vm.dungeon?.totalBosses ?? bosses.count

        VStack(spacing: LayoutConstants.space2XS) {
            BossPathRow(
                bosses: bosses,
                state: { vm.bossState(at: $0) },
                selectedIndex: vm.selectedBossIndex
            ) { index in
                guard index != vm.selectedBossIndex else { return }
                HapticManager.selection()
                SFXManager.shared.play(.uiTap)
                vm.selectBoss(at: index)
            }

            Text(vm.isDungeonComplete
                 ? "ALL \(total) CLEARED"
                 : "STAGE \(min(vm.defeatedCount + 1, total)) OF \(total)")
                .font(DarkFantasyTheme.body)
                .tracking(1.5)
                .foregroundStyle(vm.isDungeonComplete ? DarkFantasyTheme.success : DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Boss Stage

    @ViewBuilder
    private func bossStage(vm: DungeonRoomViewModel, roomy: Bool) -> some View {
        if let boss = vm.selectedBoss {
            let index = vm.selectedBossIndex
            let state = vm.bossState(at: index)

            VStack(spacing: 0) {
                // The boss, full height, in a pool of light
                ZStack(alignment: .topLeading) {
                    BossStageArt(boss: boss, style: BossArtStyle(state))
                        .id(boss.id)
                        .transition(.opacity)

                    stageBadge(boss: boss, state: state)
                        .padding(.leading, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceSM)
                }
                .frame(maxWidth: .infinity, minHeight: roomy ? 150 : 100, maxHeight: .infinity)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard state != .locked else { return }
                    selectedBossForDetail = boss
                }
                .accessibilityAddTraits(state != .locked ? .isButton : [])
                .accessibilityHint(state != .locked ? Text("Opens the dossier") : Text(""))
                .animation(.easeInOut(duration: 0.25), value: boss.id)

                // Name + hook line
                VStack(spacing: LayoutConstants.space2XS) {
                    Text(state == .locked ? "???" : boss.name.uppercased())
                        .font(DarkFantasyTheme.cinematicTitle)
                        .tracking(1)
                        .foregroundStyle(stageNameColor(state))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(stageSubline(vm: vm, boss: boss, index: index, state: state))
                        .font(state == .current ? DarkFantasyTheme.body.italic() : DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                if state == .current {
                    statChips(boss: boss)
                        .padding(.top, LayoutConstants.spaceMS)
                }

                actionRow(vm: vm, boss: boss, state: state)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceMS)

                if roomy {
                    nextTeaser(vm: vm)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceMS)
                }
            }
            .padding(.bottom, LayoutConstants.spaceMD)
        }
    }

    private func stageNameColor(_ state: BossState) -> Color {
        switch state {
        case .current: return DarkFantasyTheme.goldBright
        case .defeated: return DarkFantasyTheme.textSecondary
        case .locked: return DarkFantasyTheme.textTertiary
        }
    }

    private func stageSubline(vm: DungeonRoomViewModel, boss: BossInfo, index: Int, state: BossState) -> String {
        switch state {
        case .current:
            return boss.hookLine.isEmpty
                ? "Lv \(boss.level) · \(boss.hp) HP"
                : "\u{201C}\(boss.hookLine)\u{201D}"
        case .defeated:
            return "Defeated · Lv \(boss.level)"
        case .locked:
            if let previous = vm.dungeon?.bosses[safe: index - 1] {
                return vm.bossState(at: index - 1) == .locked
                    ? "Stage \(index + 1) · Locked"
                    : "Beat \(previous.name) to reveal"
            }
            return "Stage \(index + 1) · Locked"
        }
    }

    @ViewBuilder
    private func stageBadge(boss: BossInfo, state: BossState) -> some View {
        switch state {
        case .current:
            Text("\(boss.isRealBoss ? "Boss" : "Sparring") · Lv \(boss.level)")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .badgeCapsule(color: DarkFantasyTheme.gold)
        case .defeated:
            Text("Defeated")
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.success)
                .badgeCapsule(color: DarkFantasyTheme.success)
        case .locked:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("icon-padlock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("Locked")
                    .font(DarkFantasyTheme.body.weight(.semibold))
            }
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .badgeCapsule(color: DarkFantasyTheme.textSecondary)
        }
    }

    // MARK: Stat chips

    private func statChips(boss: BossInfo) -> some View {
        let dropIcons: [String] = boss.loot
            .compactMap { $0.resolvedImageKey }
            .filter { UIImage(named: $0) != nil }
            .reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }

        return HStack(spacing: LayoutConstants.spaceSM) {
            stageChip {
                Text("HP")
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("\(boss.hp)")
                    .fontWeight(.semibold)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)

            if !dropIcons.isEmpty {
                stageChip {
                    Text("Drops")
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    ForEach(Array(dropIcons.prefix(3)), id: \.self) { key in
                        Image(key)
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Drops: \(boss.loot.prefix(3).map(\.name).joined(separator: ", "))"))
            }
        }
    }

    private func stageChip<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            content()
        }
        .font(DarkFantasyTheme.body)
        .padding(.horizontal, LayoutConstants.spaceMS)
        .frame(height: LayoutConstants.buttonHeightSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: Actions

    @ViewBuilder
    private func actionRow(vm: DungeonRoomViewModel, boss: BossInfo, state: BossState) -> some View {
        let cost = vm.dungeon?.energyCost ?? 10
        switch state {
        case .current:
            HStack(spacing: LayoutConstants.spaceSM) {
                Button {
                    startFight(vm: vm, boss: boss)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text(boss.isRealBoss ? "FIGHT BOSS" : "FIGHT")
                        // Energy is paid when a run opens; inside a run the
                        // next fight is free, so the cost only shows when due.
                        if !vm.hasActiveRun {
                            HStack(spacing: LayoutConstants.space2XS) {
                                Image("icon-stamina")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                                Text("\(cost)")
                            }
                            .opacity(vm.stamina >= cost ? 1 : 0.6)
                        }
                    }
                }
                .buttonStyle(.primary)
                .disabled(vm.isFighting || introBoss != nil)
                .accessibilityLabel(Text(vm.hasActiveRun
                                         ? "Fight \(boss.name)"
                                         : "Fight \(boss.name), costs \(cost) energy"))

                Button {
                    selectedBossForDetail = boss
                } label: {
                    Image("hud-quests")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
                }
                .buttonStyle(.secondary)
                .frame(width: LayoutConstants.buttonHeightLG)
                .accessibilityLabel(Text("\(boss.name) dossier"))
            }
        case .defeated:
            Button {
                selectedBossForDetail = boss
            } label: {
                Text("OPEN DOSSIER")
            }
            .buttonStyle(.secondary)
        case .locked:
            EmptyView()
        }
    }

    // MARK: Next boss teaser

    @ViewBuilder
    private func nextTeaser(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let nextIndex = vm.currentBossIndex + 1
        if !vm.isDungeonComplete,
           vm.selectedBossIndex == vm.currentBossIndex,
           nextIndex < bosses.count,
           let current = vm.currentBoss {
            HStack(spacing: LayoutConstants.spaceMS) {
                BossArtImage(boss: bosses[nextIndex], kind: .full, style: .silhouette)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Next · Stage \(nextIndex + 1)")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("Beat \(current.name) to reveal")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Fight flow

    /// FIGHT from the stage, the dossier or the victory screen: energy check,
    /// select the boss, start the run in the background, play the intro.
    /// The intro's end calls `vm.fight()`.
    private func startFight(vm: DungeonRoomViewModel, boss: BossInfo) {
        guard introBoss == nil, !vm.isFighting else { return }
        // The server refuses a fight under 30% HP. Soft client check (HP may
        // lag a regen tick) so the player gets a potion, not a dead intro.
        if let char = appState.currentCharacter,
           char.currentHp < Int((Double(char.maxHp) * 0.3).rounded(.up)) {
            HapticManager.error()
            appState.showToast(
                "Not enough health",
                subtitle: "Heal to 30% HP to fight",
                type: .error,
                actionLabel: "Use potion"
            ) {
                Task { await useHealthPotion() }
            }
            return
        }
        let cost = vm.dungeon?.energyCost ?? 10
        guard vm.hasActiveRun || vm.stamina >= cost else {
            HapticManager.error()
            CharacterService.showOutOfStamina(
                appState: appState,
                refillGemCost: cache.gameConfig?.staminaRefillGems
            )
            return
        }
        if let index = vm.dungeon?.bosses.firstIndex(where: { $0.id == boss.id }) {
            vm.selectBoss(at: index)
        }
        guard vm.canFightSelectedBoss else { return }
        vm.prewarmRunIfNeeded()
        introBoss = boss
    }

    /// FIGHT NEXT on the victory screen: straight into the next boss — no
    /// unlock ceremony, the victory screen already revealed it. The intro
    /// fades in over the victory screen, which closes underneath it.
    private func fightNextBoss(vm: DungeonRoomViewModel) {
        guard let next = vm.currentBoss else {
            vm.proceedToNextBoss(ceremony: false)
            return
        }
        startFight(vm: vm, boss: next)
        if introBoss != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                vm.proceedToNextBoss(ceremony: false)
            }
        } else {
            // No energy (the refill toast is up) — just put the boss on stage.
            vm.proceedToNextBoss(ceremony: false)
        }
    }

    private func introStageLabel(for boss: BossInfo) -> String {
        let name = vm?.dungeon?.name.uppercased() ?? "DUNGEON"
        return "\(name) · STAGE \(boss.id)"
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


// MARK: - Pre-fight intro

/// Pre-fight cinematic: letterbox bars, the boss's name huge and faded in
/// the back, the full-body art in a pool of light, then the title card —
/// "SPARRING MATCH" for training partners, "BOSS FIGHT" for real bosses.
/// Opacity-only motion; tap anywhere to skip. Calls `onFinish` once.
/// The run start is already in flight underneath (`prewarmRunIfNeeded`),
/// so the intro costs no network time of its own.
struct BossIntroOverlay: View {
    let boss: BossInfo
    let stageLabel: String
    let onFinish: () -> Void

    @State private var chromeShown = false
    @State private var artShown = false
    @State private var titleShown = false
    @State private var finished = false

    /// Total time on screen before the fight starts on its own.
    private static let holdSeconds: Double = 1.4
    private static let barHeight: CGFloat = 64

    private var fightLabel: String {
        boss.isRealBoss ? "BOSS FIGHT" : "SPARRING MATCH"
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            // Giant faded name in the back — decorative
            Text(boss.name.uppercased())
                .font(DarkFantasyTheme.bossBackdropTitle)
                .foregroundStyle(DarkFantasyTheme.bgTertiary.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.35)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.top, Self.barHeight + LayoutConstants.spaceXL)
                .frame(maxHeight: .infinity, alignment: .top)
                .opacity(chromeShown ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                letterbox(top: true)

                BossStageArt(boss: boss)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, LayoutConstants.spaceXL)
                    .opacity(artShown ? 1 : 0)

                titleBlock
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceLG)
                    .opacity(titleShown ? 1 : 0)

                letterbox(top: false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityAction(named: Text("Skip intro")) { finish() }
        .onAppear { run() }
    }

    private var titleBlock: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Rectangle()
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: 36, height: 1)
                Text(fightLabel)
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(4)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Rectangle()
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: 36, height: 1)
            }
            Text(boss.name.uppercased())
                .font(DarkFantasyTheme.bossNameHero)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("LV \(boss.level) · \(boss.hp) HP")
                .font(DarkFantasyTheme.body)
                .tracking(1)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .accessibilityElement(children: .combine)
    }

    private func letterbox(top: Bool) -> some View {
        ZStack {
            if top {
                Text(stageLabel)
                    .font(DarkFantasyTheme.body)
                    .tracking(3)
                    .foregroundStyle(DarkFantasyTheme.goldDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, LayoutConstants.screenPadding)
            } else {
                Text(finished ? "Entering the ring…" : "Tap to skip")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.barHeight)
        .background(
            DarkFantasyTheme.bgAbyss
                .ignoresSafeArea(edges: top ? .top : .bottom)
        )
        .overlay(alignment: top ? .bottom : .top) {
            Rectangle()
                .fill(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong))
                .frame(height: 1)
        }
        .opacity(chromeShown ? 1 : 0)
    }

    private func run() {
        HapticManager.heavy()
        SFXManager.shared.play(.gongHit)
        AudioManager.shared.duckBGM(for: .ceremony)
        withAnimation(.easeOut(duration: 0.2)) { chromeShown = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.1)) { artShown = true }
        withAnimation(.easeOut(duration: 0.3).delay(0.35)) { titleShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdSeconds) { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        AudioManager.shared.restoreBGM(for: .ceremony)
        onFinish()
    }
}
