import SwiftUI

struct DungeonVictoryView: View {
    let vm: DungeonRoomViewModel

    @State private var showTitle = false
    @State private var showRewards = false
    @State private var showProgress = false
    @State private var showButtons = false
    @State private var goldDisplay = 0
    @State private var xpDisplay = 0

    var body: some View {
        ZStack {
            // Dim background
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Victory title
                if showTitle {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "shield.checkered")
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text("VICTORY")
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textCinematic))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        if let boss = vm.dungeon?.bosses[safe: vm.selectedBossIndex - 1] ?? vm.selectedBoss {
                            Text("\(boss.name) Defeated!")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Rewards card
                if showRewards {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        Text("REWARDS")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        // Gold
                        if vm.victoryGold > 0 {
                            rewardRow(
                                icon: "🪙",
                                label: "Gold",
                                value: "+\(goldDisplay)",
                                color: DarkFantasyTheme.goldBright
                            )
                        }

                        // XP
                        if vm.victoryXP > 0 {
                            rewardRow(
                                icon: "⭐",
                                label: "XP",
                                value: "+\(xpDisplay)",
                                color: DarkFantasyTheme.purple
                            )
                        }

                        // Item drops
                        ForEach(Array(vm.victoryItems.enumerated()), id: \.offset) { index, item in
                            let name = item["name"] as? String ?? "Item"
                            let rarity = item["rarity"] as? String ?? "common"
                            let icon = rarityIcon(rarity)
                            let color = rarityColor(rarity)

                            rewardRow(
                                icon: icon,
                                label: "\(rarity.capitalized) \(name)",
                                value: "",
                                color: color
                            )
                        }
                    }
                    .padding(LayoutConstants.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, LayoutConstants.spaceXL)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Progress bar
                if showProgress {
                    VStack(spacing: LayoutConstants.spaceXS) {
                        let total = vm.dungeon?.totalBosses ?? 10
                        HStack {
                            Text("Dungeon Progress")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            Spacer()
                            Text("\(vm.defeatedCount) / \(total)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(
                                    vm.isDungeonComplete
                                        ? DarkFantasyTheme.success
                                        : DarkFantasyTheme.textSecondary
                                )
                                .monospacedDigit()
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DarkFantasyTheme.bgTertiary)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        vm.isDungeonComplete
                                            ? DarkFantasyTheme.hpHighGradient
                                            : DarkFantasyTheme.progressGradient
                                    )
                                    .frame(width: geo.size.width * vm.progressFraction)
                                    .animation(.easeOut(duration: 0.8), value: vm.defeatedCount)
                            }
                        }
                        .frame(height: 10)

                        if vm.isDungeonComplete {
                            Text("DUNGEON CLEARED!")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                                .padding(.top, LayoutConstants.spaceXS)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceXL)
                    .transition(.opacity)
                }

                Spacer()

                // Buttons
                if showButtons {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        if vm.isDungeonComplete {
                            // Dungeon complete — go back
                            Button {
                                withAnimation { vm.dismissVictory() }
                            } label: {
                                HStack(spacing: LayoutConstants.spaceSM) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 18)) // SF Symbol icon — keep
                                    Text("CLAIM & EXIT")
                                }
                            }
                            .buttonStyle(.primary)
                        } else {
                            // Next boss
                            Button {
                                withAnimation { vm.proceedToNextBoss() }
                            } label: {
                                HStack(spacing: LayoutConstants.spaceSM) {
                                    Text("NEXT BOSS")
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold)) // SF Symbol icon — keep
                                }
                            }
                            .buttonStyle(.primary)

                            // Leave
                            Button {
                                withAnimation { vm.dismissVictory() }
                                vm.goBack()
                            } label: {
                                Text("LEAVE DUNGEON")
                            }
                            .buttonStyle(.ghost)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            runAnimationSequence()
        }
    }

    // MARK: - Animation Sequence

    private func runAnimationSequence() {
        // 0.0s — title slams in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showTitle = true
        }

        // 0.5s — rewards appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showRewards = true
            }
            // Start gold roll-up
            rollUp(to: vm.victoryGold, binding: $goldDisplay, duration: 0.6)
            rollUp(to: vm.victoryXP, binding: $xpDisplay, duration: 0.6)
        }

        // 1.2s — progress bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showProgress = true
            }
        }

        // 1.8s — buttons
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showButtons = true
            }
        }
    }

    // MARK: - Number Roll-Up

    private func rollUp(to target: Int, binding: Binding<Int>, duration: Double) {
        guard target > 0 else { return }
        let steps = 20
        let interval = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                binding.wrappedValue = Int(Double(target) * Double(i) / Double(steps))
            }
        }
    }

    // MARK: - Reward Row

    @ViewBuilder
    private func rewardRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Text(icon)
                .font(DarkFantasyTheme.body(size: 20))

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Helpers

    private func rarityIcon(_ rarity: String) -> String {
        switch rarity.lowercased() {
        case "common": return "⚪"
        case "uncommon": return "🟢"
        case "rare": return "🔵"
        case "epic": return "🟣"
        case "legendary": return "🟠"
        default: return "🎁"
        }
    }

    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common": return DarkFantasyTheme.rarityCommon
        case "uncommon": return DarkFantasyTheme.rarityUncommon
        case "rare": return DarkFantasyTheme.rarityRare
        case "epic": return DarkFantasyTheme.rarityEpic
        case "legendary": return DarkFantasyTheme.rarityLegendary
        default: return DarkFantasyTheme.textSecondary
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
