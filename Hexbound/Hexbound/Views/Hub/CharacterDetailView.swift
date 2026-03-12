import SwiftUI

struct CharacterDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: CharacterViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm = viewModel, let char = appState.currentCharacter {
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceLG) {
                        // Header
                        characterHeader(char)

                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Stat Points Banner
                        if vm.availablePoints > 0 {
                            statPointsBanner(vm)
                        }

                        // Base Stats Grid
                        baseStatsGrid(char, vm: vm)

                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Derived Stats
                        derivedStatsSection(char)

                        // Stance Button
                        Button {
                            appState.mainPath.append(AppRoute.stanceSelector)
                        } label: {
                            HStack {
                                Text("COMBAT STANCE")
                                Spacer()
                                if let stance = char.combatStance {
                                    Text("⚔️ \(stance.attack.capitalized)  |  🛡️ \(stance.defense.capitalized)")
                                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(DarkFantasyTheme.goldDim)
                            }
                        }
                        .buttonStyle(.secondary)
                        .padding(.horizontal, LayoutConstants.screenPadding)

                        // Save Button
                        if vm.hasChanges {
                            VStack(spacing: LayoutConstants.spaceSM) {
                                Button {
                                    Task { await vm.saveStats() }
                                } label: {
                                    if vm.isSaving {
                                        ProgressView()
                                            .tint(DarkFantasyTheme.textOnGold)
                                    } else {
                                        Text("SAVE STATS")
                                    }
                                }
                                .buttonStyle(.primary)
                                .disabled(vm.isSaving)

                                Button("RESET") {
                                    vm.resetChanges()
                                }
                                .buttonStyle(.ghost)
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                        }

                        Spacer().frame(height: LayoutConstants.spaceLG)
                    }
                }
            } else {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("CHARACTER")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = CharacterViewModel(appState: appState)
            }
        }
    }

    // MARK: - Character Header

    @ViewBuilder
    private func characterHeader(_ char: Character) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Avatar — full-width square
            GeometryReader { geo in
                let side = geo.size.width - LayoutConstants.screenPadding * 2
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(DarkFantasyTheme.bgSecondary)

                    AvatarImageView(
                        skinKey: char.avatar,
                        characterClass: char.characterClass,
                        size: side
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius - 2))

                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.borderGold, lineWidth: 2)
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, LayoutConstants.screenPadding)

            Text(char.characterName)
                .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            HStack(spacing: 8) {
                Text(char.characterClass.icon)
                Text(char.characterClass.displayName)
                    .foregroundStyle(DarkFantasyTheme.classColor(for: char.characterClass))
                Text("•")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text(char.origin.icon)
                Text(char.origin.displayName)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))

            // Level & XP
            VStack(spacing: LayoutConstants.space2XS) {
                HStack {
                    Text("Level \(char.level)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Text("\(char.experience ?? 0) / \(char.xpNeeded) XP")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.bgPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.xpGradient)
                            .frame(width: geo.size.width * char.xpPercentage)
                    }
                }
                .frame(height: 10)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Prestige
            if let prestige = char.prestige, prestige > 0 {
                Text("Prestige \(prestige)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).bold())
                    .foregroundStyle(DarkFantasyTheme.stamina)
            }
        }
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Stat Points Banner

    @ViewBuilder
    private func statPointsBanner(_ vm: CharacterViewModel) -> some View {
        HStack {
            Text("⭐ Stat Points: \(vm.availablePoints)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textSuccess)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.success.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                .stroke(DarkFantasyTheme.success.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Base Stats Grid

    @ViewBuilder
    private func baseStatsGrid(_ char: Character, vm: CharacterViewModel) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                      GridItem(.flexible(), spacing: LayoutConstants.spaceSM)],
            spacing: LayoutConstants.spaceSM
        ) {
            ForEach(StatType.allCases, id: \.self) { stat in
                statCell(stat, vm: vm)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func statCell(_ stat: StatType, vm: CharacterViewModel) -> some View {
        let value = vm.currentValue(for: stat)
        let delta = vm.pendingChanges[stat] ?? 0
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)
        let hasPoints = (appState.currentCharacter?.statPoints ?? 0) > 0

        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            HStack(spacing: 6) {
                Image(stat.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text(stat.fullName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(color)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if delta > 0 {
                    Button { vm.decrement(stat) } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(width: 22, height: 22)
                            .background(DarkFantasyTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }

                Text("\(value)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textPrimary)
                    .frame(minWidth: 24, alignment: .trailing)

                if hasPoints {
                    Button { vm.increment(stat) } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(vm.availablePoints > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.availablePoints <= 0)
                }
            }

            Text(vm.primaryDerivedLabel(for: stat))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)

            if hasPoints {
                HStack(spacing: 4) {
                    ForEach(vm.perPointBenefits(for: stat), id: \.self) { hint in
                        Text(hint)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DarkFantasyTheme.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(delta > 0 ? color.opacity(0.5) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Derived Stats

    @ViewBuilder
    private func derivedStatsSection(_ char: Character) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("DERIVED STATS")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: LayoutConstants.spaceSM
            ) {
                derivedStatRow("Atk Power", value: "\(char.attackPower) \(char.damageTypeName)", color: DarkFantasyTheme.statSTR)
                derivedStatRow("Max HP", value: "\(char.maxHp)", color: DarkFantasyTheme.hpBlood)
                derivedStatRow("Armor", value: "\(char.armor ?? 0)", color: DarkFantasyTheme.statEND)
                derivedStatRow("Magic Resist", value: "\(char.magicResist ?? 0)", color: DarkFantasyTheme.statWIS)
                derivedStatRow("Max Stamina", value: "\(char.maxStamina)", color: DarkFantasyTheme.stamina)
                derivedStatRow("Crit Chance", value: String(format: "%.1f%%", char.critChance), color: DarkFantasyTheme.statLUK)
                derivedStatRow("Dodge", value: String(format: "%.1f%%", char.dodgeChance), color: DarkFantasyTheme.statAGI)
                derivedStatRow("PvP Rating", value: "\(char.pvpRating)", color: DarkFantasyTheme.rankColor(for: char.pvpRating))
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func derivedStatRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
