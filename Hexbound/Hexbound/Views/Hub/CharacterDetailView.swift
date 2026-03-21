import SwiftUI

struct CharacterDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: CharacterViewModel?
    @State private var tooltipStat: StatType?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm = viewModel, let char = appState.currentCharacter {
                ScrollView {
                    VStack(spacing: LayoutConstants.sectionGap) {
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
                                    HStack(spacing: LayoutConstants.spaceXS) {
                                        Image(StanceSelectorViewModel.zoneAsset(for: stance.attack))
                                            .resizable().scaledToFit().frame(width: 16, height: 16)
                                        Text(stance.attack.capitalized)
                                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                                        Text("|")
                                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                                        Image(StanceSelectorViewModel.zoneAsset(for: stance.defense))
                                            .resizable().scaledToFit().frame(width: 16, height: 16)
                                        Text(stance.defense.capitalized)
                                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                                    }
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
                let side = max(geo.size.width - LayoutConstants.screenPadding * 2, 0)
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
                Image(char.origin.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
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
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Stat Points: \(vm.availablePoints)")
            }
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
                    .accessibilityLabel("\(stat.fullName) icon")
                    .accessibilityElement(children: .ignore)

                Text(stat.fullName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .accessibilityLabel("\(stat.fullName) statistic")

                Button {
                    tooltipStat = tooltipStat == stat ? nil : stat
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11)) // SF Symbol icon
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show information for \(stat.fullName)")

                Spacer(minLength: 4)

                if delta > 0 {
                    Button {
                        HapticManager.selection()
                        vm.decrement(stat)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .frame(width: 22, height: 22)
                            .background(DarkFantasyTheme.danger.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.scalePress(0.85))
                    .accessibilityLabel("Decrease \(stat.fullName)")
                    .accessibilityAddTraits(.isButton)
                }

                Text("\(value)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textPrimary)
                    .frame(minWidth: 24, alignment: .trailing)
                    .accessibilityLabel("\(stat.fullName): \(value)")

                if hasPoints {
                    Button {
                        HapticManager.selection()
                        vm.increment(stat)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.textPrimary)
                            .frame(width: 22, height: 22)
                            .background(vm.availablePoints > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.scalePress(0.85))
                    .disabled(vm.availablePoints <= 0)
                    .accessibilityLabel("Increase \(stat.fullName)")
                    .accessibilityAddTraits(.isButton)
                }
            }

            Text(vm.primaryDerivedLabel(for: stat))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(delta > 0 ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)

            if tooltipStat == stat {
                Text(stat.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .padding(LayoutConstants.spaceXS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DarkFantasyTheme.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

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
