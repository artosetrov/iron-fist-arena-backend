import SwiftUI

/// Forge Stage, step 2 — class. The stage aura takes the class colour; the
/// bonus chips are the server's class bonuses (real since 2026-10-16).
struct ForgeClassPanel: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        let cls = vm.selectedClass ?? .warrior
        let accent = DarkFantasyTheme.classColor(for: cls)

        VStack(spacing: LayoutConstants.spaceMS) {
            Text(cls.mainAttributeDescription)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 22)

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(CharacterClass.allCases) { option in
                    ForgeChoiceTile(
                        asset: option.iconAsset,
                        title: option.displayName,
                        isSelected: vm.selectedClass == option,
                        accent: DarkFantasyTheme.classColor(for: option),
                        height: 84
                    ) {
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.smooth) { vm.selectedClass = option }
                    }
                }
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                infoRow("Playstyle") {
                    Text(Self.playstyle(cls))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                infoRow("Scales with") {
                    Text(ForgeStat.name(vm.mainStatKey).uppercased())
                        .tracking(1)
                        .foregroundStyle(accent)
                }
                infoRow("Difficulty") {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i < Self.difficulty(cls) ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle)
                                .frame(width: 18, height: 6)
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel(["Easy", "Medium", "Hard"][Self.difficulty(cls) - 1])
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.classBonuses) { bonus in
                        ForgeBonusChip(bonus: bonus)
                    }
                }
                .animation(MotionConstants.snappy, value: vm.classBonuses)
            }
            .padding(LayoutConstants.spaceMS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )

            Button {
                SFXManager.shared.play(.uiTap)
                vm.nextStep()
            } label: {
                Text("CHOOSE \(cls.displayName.uppercased())")
            }
            .buttonStyle(.primary(enabled: vm.canProceed))
            .disabled(!vm.canProceed)
        }
    }

    private func infoRow<Value: View>(_ title: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Spacer()
            value()
        }
        .font(DarkFantasyTheme.uiLabel)
        .accessibilityElement(children: .combine)
    }

    static func playstyle(_ cls: CharacterClass) -> String {
        switch cls {
        case .warrior: "Up close · hits hardest"
        case .rogue: "Fast · dodges and crits"
        case .mage: "Spells · burst damage"
        case .tank: "Outlasts everyone"
        }
    }

    static func difficulty(_ cls: CharacterClass) -> Int {
        switch cls {
        case .warrior, .tank: 1
        case .rogue: 2
        case .mage: 3
        }
    }
}
