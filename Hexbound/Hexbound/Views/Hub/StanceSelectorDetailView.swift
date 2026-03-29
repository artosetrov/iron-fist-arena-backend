import SwiftUI

struct StanceSelectorDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: StanceSelectorViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceMS) {
                        // Attack Zone — buttons + inline bonuses
                        zoneSectionCompact(
                            title: "ATTACK ZONE",
                            roleIcon: "bolt.fill",
                            roleColor: DarkFantasyTheme.danger,
                            selectedZone: vm.attackZone,
                            bonusLeft: (
                                icon: "flame.fill",
                                label: "OFF",
                                value: StanceSelectorViewModel.attackBonuses(for: vm.attackZone).offense,
                                color: StanceSelectorViewModel.attackBonuses(for: vm.attackZone).offense > 0
                                    ? DarkFantasyTheme.danger : DarkFantasyTheme.textTertiary
                            ),
                            bonusRight: (
                                icon: "bolt.fill",
                                label: "CRIT",
                                value: StanceSelectorViewModel.attackBonuses(for: vm.attackZone).crit,
                                color: StanceSelectorViewModel.attackBonuses(for: vm.attackZone).crit > 0
                                    ? DarkFantasyTheme.goldBright
                                    : (StanceSelectorViewModel.attackBonuses(for: vm.attackZone).crit < 0
                                       ? DarkFantasyTheme.danger : DarkFantasyTheme.textTertiary)
                            )
                        ) { zone in
                            vm.attackZone = zone
                        }
                        .animation(.easeInOut(duration: 0.2), value: vm.attackZone)

                        EtchedGroove()
                            .padding(.horizontal, LayoutConstants.screenPadding + LayoutConstants.spaceMD)

                        // Defense Zone — buttons + inline bonuses
                        zoneSectionCompact(
                            title: "DEFENSE ZONE",
                            roleIcon: "shield.fill",
                            roleColor: DarkFantasyTheme.info,
                            selectedZone: vm.defenseZone,
                            bonusLeft: (
                                icon: "shield.fill",
                                label: "DEF",
                                value: StanceSelectorViewModel.defenseBonuses(for: vm.defenseZone).defense,
                                color: StanceSelectorViewModel.defenseBonuses(for: vm.defenseZone).defense > 0
                                    ? DarkFantasyTheme.info : DarkFantasyTheme.textTertiary
                            ),
                            bonusRight: (
                                icon: "figure.walk",
                                label: "DODGE",
                                value: StanceSelectorViewModel.defenseBonuses(for: vm.defenseZone).dodge,
                                color: StanceSelectorViewModel.defenseBonuses(for: vm.defenseZone).dodge > 0
                                    ? DarkFantasyTheme.success : DarkFantasyTheme.textTertiary
                            )
                        ) { zone in
                            vm.defenseZone = zone
                        }
                        .animation(.easeInOut(duration: 0.2), value: vm.defenseZone)

                        EtchedGroove()
                            .padding(.horizontal, LayoutConstants.screenPadding + LayoutConstants.spaceMD)

                        // Zone Matching — compact single row
                        zoneMatchingCompact()

                        // Current stance confirmation
                        stanceConfirmation(vm)
                    }
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.space2XL)
                }
                // Sticky Save button pinned to bottom
                .safeAreaInset(edge: .bottom) {
                    if vm.hasChanges {
                        VStack(spacing: 0) {
                            // Top fade
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DarkFantasyTheme.bgPrimary.opacity(0),
                                            DarkFantasyTheme.bgPrimary
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 12)

                            Button {
                                vm.saveStance()
                            } label: {
                                Text("SAVE STANCE")
                            }
                            .buttonStyle(.primary)
                            .disabled(vm.isSaving)
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.bottom, LayoutConstants.spaceSM)
                        }
                        .background(DarkFantasyTheme.bgPrimary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: vm.hasChanges)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("COMBAT STANCE")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StanceSelectorViewModel(appState: appState)
            }
        }
    }

    // MARK: - Compact Zone Section (buttons + inline bonus pills)

    @ViewBuilder
    private func zoneSectionCompact(
        title: String,
        roleIcon: String,
        roleColor: Color,
        selectedZone: String,
        bonusLeft: (icon: String, label: String, value: Int, color: Color),
        bonusRight: (icon: String, label: String, value: Int, color: Color),
        onSelect: @escaping (String) -> Void
    ) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Section header
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: roleIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(roleColor)
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Zone buttons — compact 48pt with horizontal icon+label
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(StanceSelectorViewModel.zones, id: \.self) { zone in
                    zoneButtonCompact(zone: zone, isSelected: selectedZone == zone) {
                        onSelect(zone)
                    }
                }
            }

            // Inline bonus pills
            HStack(spacing: LayoutConstants.spaceSM) {
                inlineBonusPill(
                    icon: bonusLeft.icon,
                    label: bonusLeft.label,
                    value: bonusLeft.value,
                    color: bonusLeft.color
                )
                inlineBonusPill(
                    icon: bonusRight.icon,
                    label: bonusRight.label,
                    value: bonusRight.value,
                    color: bonusRight.color
                )
                Spacer()
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Compact Zone Button (48pt, horizontal layout)

    @ViewBuilder
    private func zoneButtonCompact(zone: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let color = StanceSelectorViewModel.zoneColor(for: zone)

        Button(action: action) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(StanceSelectorViewModel.zoneAsset(for: zone))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .colorMultiply(isSelected ? .white : DarkFantasyTheme.textSecondary)
                Text(zone.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            }
        }
        .buttonStyle(.colorToggle(isActive: isSelected, color: color, height: LayoutConstants.touchMin))
    }

    // MARK: - Inline Bonus Pill (single row: icon + label + value)

    @ViewBuilder
    private func inlineBonusPill(icon: String, label: String, value: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value >= 0 ? "+\(value)%" : "\(value)%")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(color)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Compact Zone Matching (single row)

    @ViewBuilder
    private func zoneMatchingCompact() -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Header
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.gold)
                Text("ZONE MATCHING")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.gold)
            }

            // Two bonuses in a single row
            HStack(spacing: LayoutConstants.spaceMD) {
                // Match bonus
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.success)
                    Text("Match:")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("+15% DEF")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.success)
                }

                // Miss bonus
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.danger)
                    Text("Miss:")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("+5% OFF")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            }
        }
        .padding(LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Stance Confirmation (compact summary below selectors)

    @ViewBuilder
    private func stanceConfirmation(_ vm: StanceSelectorViewModel) -> some View {
        StanceDisplayView(
            attack: vm.attackZone,
            defense: vm.defenseZone
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
    }
}
