import SwiftUI

struct StanceSelectorDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: StanceSelectorViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: LayoutConstants.sectionGap) {
                        // Summary
                        stanceSummary(vm)

                        // Attack Zone
                        zoneSection(title: "ATTACK ZONE", selectedZone: vm.attackZone) { zone in
                            vm.attackZone = zone
                        }

                        GoldDivider()
                            .padding(.horizontal, LayoutConstants.screenPadding)

                        // Defense Zone
                        zoneSection(title: "DEFENSE ZONE", selectedZone: vm.defenseZone) { zone in
                            vm.defenseZone = zone
                        }

                        // Save Button
                        if vm.hasChanges {
                            Button {
                                Task { await vm.saveStance() }
                            } label: {
                                if vm.isSaving {
                                    ProgressView()
                                        .tint(DarkFantasyTheme.textOnGold)
                                } else {
                                    Text("SAVE STANCE")
                                }
                            }
                            .buttonStyle(.primary)
                            .disabled(vm.isSaving)
                            .padding(.horizontal, LayoutConstants.screenPadding)
                        }

                        Spacer().frame(height: LayoutConstants.spaceLG)
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

    // MARK: - Summary

    @ViewBuilder
    private func stanceSummary(_ vm: StanceSelectorViewModel) -> some View {
        StanceDisplayView(
            attack: vm.attackZone,
            defense: vm.defenseZone
        )
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
    }

    // MARK: - Zone Section

    @ViewBuilder
    private func zoneSection(title: String, selectedZone: String, onSelect: @escaping (String) -> Void) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(StanceSelectorViewModel.zoneAsset(for: selectedZone))
                    .resizable().scaledToFit().frame(width: 20, height: 20)
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutConstants.screenPadding)

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(StanceSelectorViewModel.zones, id: \.self) { zone in
                    zoneButton(zone: zone, isSelected: selectedZone == zone) {
                        onSelect(zone)
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    @ViewBuilder
    private func zoneButton(zone: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let color = StanceSelectorViewModel.zoneColor(for: zone)

        Button(action: action) {
            VStack(spacing: LayoutConstants.spaceXS) {
                Image(StanceSelectorViewModel.zoneAsset(for: zone))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .colorMultiply(isSelected ? .white : DarkFantasyTheme.textSecondary)
                Text(zone.uppercased())
            }
        }
        .buttonStyle(.colorToggle(isActive: isSelected, color: color, height: 80))
    }
}
