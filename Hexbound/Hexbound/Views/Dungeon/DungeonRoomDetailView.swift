import SwiftUI

struct DungeonRoomDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DungeonRoomViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                if vm.isLoading {
                    ProgressView().tint(DarkFantasyTheme.gold)
                } else {
                    dungeonMapContent(vm: vm)

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
                    .foregroundStyle(vm?.dungeon?.themeColor ?? DarkFantasyTheme.goldBright)
            }
            // Stamina is now shown in the CompactHeroWidget below the toolbar
        }
        .onAppear {
            vm?.applyPendingResult()
        }
        .task {
            if vm == nil {
                vm = DungeonRoomViewModel(appState: appState)
            }
            await vm?.loadState()
        }
    }

    // MARK: - Map Content

    @ViewBuilder
    private func dungeonMapContent(vm: DungeonRoomViewModel) -> some View {
        VStack(spacing: 0) {
            // Compact hero widget — focused gameplay mode
            if let char = appState.currentCharacter {
                CompactHeroWidget(character: char, showCurrencies: true)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.top, LayoutConstants.spaceSM)
            }

            // Progress header
            progressHeader(vm: vm)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceLG) {
                        // Boss zigzag path
                        bossPath(vm: vm)

                        // Divider
                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Boss detail card
                        if let boss = vm.selectedBoss {
                            bossDetailCard(boss: boss, vm: vm)
                                .id("bossDetail")
                        }
                    }
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.space2XL)
                }
                .onChange(of: vm.selectedBossIndex) { _, _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("bossDetail", anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Progress Header

    @ViewBuilder
    private func progressHeader(vm: DungeonRoomViewModel) -> some View {
        let themeColor = vm.dungeon?.themeColor ?? DarkFantasyTheme.gold
        let total = vm.dungeon?.totalBosses ?? 10

        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("\(vm.defeatedCount) / \(total) DEFEATED")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer()
                if let dungeon = vm.dungeon {
                    Text("Cost \(dungeon.energyCost) ⚡")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.stamina)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            vm.isDungeonComplete
                                ? DarkFantasyTheme.hpHighGradient
                                : LinearGradient(
                                    colors: [themeColor, themeColor.opacity(0.7)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                        )
                        .frame(width: geo.size.width * vm.progressFraction)
                        .animation(.easeOut(duration: 0.5), value: vm.defeatedCount)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
    }

    // MARK: - Boss Zigzag Path

    @ViewBuilder
    private func bossPath(vm: DungeonRoomViewModel) -> some View {
        let bosses = vm.dungeon?.bosses ?? []
        let nodeSize: CGFloat = 52
        let hSpacing: CGFloat = 12

        VStack(spacing: LayoutConstants.spaceSM) {
            // Row 1: bosses 1–5 (left to right)
            HStack(spacing: hSpacing) {
                ForEach(0..<min(5, bosses.count), id: \.self) { i in
                    bossNode(index: i, boss: bosses[i], size: nodeSize, vm: vm)
                }
            }

            // Connector line between rows
            if bosses.count > 5 {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(DarkFantasyTheme.borderMedium)
                        .frame(width: 2, height: 20)
                    Spacer().frame(width: nodeSize / 2 + hSpacing / 2)
                }
            }

            // Row 2: bosses 6–10 (right to left, displayed reversed)
            if bosses.count > 5 {
                HStack(spacing: hSpacing) {
                    ForEach((5..<min(10, bosses.count)).reversed(), id: \.self) { i in
                        bossNode(index: i, boss: bosses[i], size: nodeSize, vm: vm)
                    }
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Boss Node

    @ViewBuilder
    private func bossNode(index: Int, boss: BossInfo, size: CGFloat, vm: DungeonRoomViewModel) -> some View {
        let state = vm.bossState(at: index)
        let isSelected = vm.selectedBossIndex == index
        let themeColor = vm.dungeon?.themeColor ?? DarkFantasyTheme.gold

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectBoss(at: index)
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(nodeBackground(state: state, themeColor: themeColor))
                        .frame(width: size, height: size)

                    // Border
                    Circle()
                        .stroke(
                            nodeBorder(state: state, isSelected: isSelected, themeColor: themeColor),
                            lineWidth: isSelected ? 2.5 : 1.5
                        )
                        .frame(width: size, height: size)

                    // Content
                    switch state {
                    case .defeated:
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.success)

                    case .current:
                        Text(boss.emoji)
                            .font(.system(size: 22))

                    case .locked:
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DarkFantasyTheme.textDisabled)
                    }

                    // Selection ring (pulsing)
                    if isSelected && state == .current {
                        Circle()
                            .stroke(themeColor.opacity(0.5), lineWidth: 2)
                            .frame(width: size + 6, height: size + 6)
                    }
                }

                // Boss number
                Text("\(boss.id)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(
                        state == .locked
                            ? DarkFantasyTheme.textDisabled
                            : state == .current
                                ? themeColor
                                : DarkFantasyTheme.textTertiary
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func nodeBackground(state: BossState, themeColor: Color) -> Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success.opacity(0.12)
        case .current: return themeColor.opacity(0.15)
        case .locked: return DarkFantasyTheme.bgTertiary
        }
    }

    private func nodeBorder(state: BossState, isSelected: Bool, themeColor: Color) -> Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success.opacity(0.4)
        case .current: return isSelected ? themeColor : themeColor.opacity(0.6)
        case .locked: return DarkFantasyTheme.borderSubtle
        }
    }

    // MARK: - Boss Detail Card

    @ViewBuilder
    private func bossDetailCard(boss: BossInfo, vm: DungeonRoomViewModel) -> some View {
        let state = vm.bossState(at: vm.selectedBossIndex)
        let themeColor = vm.dungeon?.themeColor ?? DarkFantasyTheme.gold

        VStack(spacing: LayoutConstants.spaceMD) {
            // Boss header
            HStack {
                Text("Boss \(boss.id) / \(vm.dungeon?.totalBosses ?? 10)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Spacer()

                Text("Lv. \(boss.level)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(themeColor)

                // State badge
                stateBadge(state: state)
            }

            // Boss artwork area
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(
                        LinearGradient(
                            colors: [themeColor.opacity(0.12), DarkFantasyTheme.bgTertiary],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: 180)

                VStack(spacing: LayoutConstants.spaceSM) {
                    Text(boss.emoji)
                        .font(.system(size: 64))
                        .opacity(state == .locked ? 0.3 : 1.0)

                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                        .foregroundStyle(
                            state == .locked
                                ? DarkFantasyTheme.textDisabled
                                : DarkFantasyTheme.textPrimary
                        )
                }
            }

            // HP bar
            VStack(spacing: 2) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                state == .defeated
                                    ? DarkFantasyTheme.hpLowGradient
                                    : DarkFantasyTheme.hpHighGradient
                            )
                            .frame(width: geo.size.width * (state == .defeated ? 0 : 1.0))
                    }
                }
                .frame(height: 14)

                Text(state == .defeated ? "0 / \(boss.hp)" : "\(boss.hp) / \(boss.hp)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .monospacedDigit()
            }

            // Description
            Text(boss.description)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)

            // Loot preview
            if !boss.loot.isEmpty {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    HStack {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                        Text("POSSIBLE LOOT")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }

                    ForEach(boss.loot) { item in
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Text(item.icon)
                                .font(.system(size: 16))
                            Text(item.name)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                            Spacer()
                            Text(item.detail)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
                .padding(LayoutConstants.spaceSM)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
                )
            }

            // Fight button area
            fightButton(state: state, vm: vm)
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(themeColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - State Badge

    @ViewBuilder
    private func stateBadge(state: BossState) -> some View {
        switch state {
        case .defeated:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text("Defeated")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
            }
            .foregroundStyle(DarkFantasyTheme.success)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(DarkFantasyTheme.success.opacity(0.12))
            )

        case .current:
            HStack(spacing: 4) {
                Image(systemName: "scope")
                    .font(.system(size: 12))
                Text("Current")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
            }
            .foregroundStyle(DarkFantasyTheme.stamina)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(DarkFantasyTheme.stamina.opacity(0.12))
            )

        case .locked:
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                Text("Locked")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
            }
            .foregroundStyle(DarkFantasyTheme.textDisabled)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(DarkFantasyTheme.bgTertiary)
            )
        }
    }

    // MARK: - Fight Button

    @ViewBuilder
    private func fightButton(state: BossState, vm: DungeonRoomViewModel) -> some View {
        switch state {
        case .defeated:
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                Text("DEFEATED")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            }
            .foregroundStyle(DarkFantasyTheme.success)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.success.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.success.opacity(0.3), lineWidth: 1)
            )

        case .current:
            let hasEnergy = vm.stamina >= (vm.dungeon?.energyCost ?? 10)

            Button {
                Task { await vm.fight() }
            } label: {
                VStack(spacing: 2) {
                    if vm.isFighting {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                    } else {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image(systemName: "swords")
                                .font(.system(size: 18, weight: .bold))
                            Text("FIGHT BOSS")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        }
                    }

                    if !vm.isFighting {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                            Text("\(vm.dungeon?.energyCost ?? 10) Energy")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        }
                        .opacity(0.7)
                    }
                }
                .foregroundStyle(hasEnergy ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .opacity(hasEnergy ? 0 : 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(DarkFantasyTheme.goldGradient)
                        .opacity(hasEnergy ? 1 : 0)
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.isFighting || !hasEnergy)

            if !hasEnergy {
                Text("Not enough energy — \(vm.stamina)/\(vm.dungeon?.energyCost ?? 10)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.danger)
            }

        case .locked:
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                Text("Defeat Boss \(vm.selectedBossIndex) first")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            }
            .foregroundStyle(DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
            )
        }
    }
}
