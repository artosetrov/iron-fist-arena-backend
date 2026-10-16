import SwiftUI

/// Forge Stage, step 1 — origin: race, gender and look.
/// Bonus chips show the server's origin bonuses for the selected race.
struct ForgeOriginPanel: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            bonusRow

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(CharacterOrigin.allCases) { origin in
                    ForgeChoiceTile(
                        asset: origin.iconAsset,
                        title: origin.displayName,
                        isSelected: vm.selectedOrigin == origin,
                        accent: DarkFantasyTheme.gold,
                        height: 76
                    ) {
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.smooth) { vm.selectOrigin(origin) }
                    }
                }
            }

            lookRow

            Button {
                SFXManager.shared.play(.uiTap)
                vm.nextStep()
            } label: {
                Text("NEXT: CLASS")
            }
            .buttonStyle(.primary(enabled: vm.canProceed))
            .disabled(!vm.canProceed)
        }
    }

    private var bonusRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(vm.originBonuses) { bonus in
                ForgeBonusChip(bonus: bonus)
            }
        }
        .frame(minHeight: 32)
        .animation(MotionConstants.snappy, value: vm.originBonuses)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Origin bonuses")
    }

    private var lookRow: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                arrow("ui-arrow-left", label: "Previous look") { vm.prevLook() }

                HStack(spacing: 0) {
                    genderSegment(.male, title: "Male")
                    genderSegment(.female, title: "Female")
                }
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )

                arrow("ui-arrow-right", label: "Next look") { vm.nextLook() }
            }

            Text(vm.lookLabel)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .frame(minHeight: 14)
        }
    }

    private func genderSegment(_ gender: CharacterGender, title: String) -> some View {
        let selected = vm.selectedGender == gender
        return Button {
            SFXManager.shared.play(.uiToggle)
            withAnimation(MotionConstants.smooth) { vm.selectGender(gender) }
        } label: {
            Text(title.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1)
                .foregroundStyle(selected ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.touchMin)
                .background(selected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func arrow(_ asset: String, label: String, action: @escaping () -> Void) -> some View {
        let enabled = vm.availableSkins.count > 1
        return Button {
            SFXManager.shared.play(.uiSlide)
            withAnimation(MotionConstants.smooth) { action() }
        } label: {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                .frame(width: LayoutConstants.touchMin, height: LayoutConstants.touchMin)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
