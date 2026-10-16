import SwiftUI

/// Forge Stage, step 3 — name. Live availability check, dice for a random
/// name, FORGE HERO starts the ceremony.
struct ForgeNamePanel: View {
    @Bindable var vm: OnboardingViewModel
    var nameFocused: FocusState<Bool>.Binding
    let onForge: () -> Void

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("WHAT DO THEY CALL YOU?")
                    .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.goldDim)
                Spacer()
                Text("\(vm.characterName.count)/16")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    TextField(
                        "",
                        text: $vm.characterName,
                        prompt: Text("Hero name").foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.6))
                    )
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.done)
                    .focused(nameFocused)
                    .onSubmit { if vm.canProceed { onForge() } }
                    .onChange(of: vm.characterName) { _, newValue in
                        if newValue.count > 16 {
                            vm.characterName = String(newValue.prefix(16))
                        }
                        vm.checkNameAvailability()
                    }
                    .accessibilityLabel("Hero name")

                    statusIcon
                        .frame(width: LayoutConstants.iconLG)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .frame(height: LayoutConstants.touchComfortable)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(borderColor, lineWidth: 1.5)
                        .animation(MotionConstants.snappy, value: vm.nameAvailability)
                )

                Button {
                    SFXManager.shared.play(.uiTap)
                    vm.generateRandomName()
                    vm.checkNameAvailability(immediate: true)
                } label: {
                    Image("ui-dice")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                        .frame(width: LayoutConstants.touchComfortable, height: LayoutConstants.touchComfortable)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .fill(DarkFantasyTheme.gold.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Random name")
            }

            Text(hint)
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(hintColor)
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
                .animation(MotionConstants.snappy, value: vm.nameAvailability)

            Button(action: onForge) {
                if vm.isCreating {
                    HexPulseLoader.onGold()
                } else {
                    Text("FORGE HERO")
                }
            }
            .buttonStyle(.primary(enabled: vm.canProceed))
            .disabled(!vm.canProceed || vm.isCreating)
            .padding(.top, LayoutConstants.spaceXS)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if vm.characterName.count >= 3 {
            switch vm.nameAvailability {
            case .checking:
                HexPulseLoader(.compact)
                    .scaleEffect(0.85)
            case .available:
                Image(systemName: "checkmark.circle.fill")
                    .font(DarkFantasyTheme.iconMedium)
                    .foregroundStyle(DarkFantasyTheme.success)
            case .taken, .invalid:
                Image(systemName: "xmark.circle.fill")
                    .font(DarkFantasyTheme.iconMedium)
                    .foregroundStyle(DarkFantasyTheme.danger)
            case .idle:
                EmptyView()
            }
        }
    }

    private var hint: String {
        let name = vm.characterName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return "3–16 letters or digits. Tap the die for a name worthy of song." }
        if name.count < 3 { return "Too short — at least 3 characters." }
        switch vm.nameAvailability {
        case .invalid: return "Letters and digits only."
        case .taken: return "That name is already taken."
        case .available: return "\(name) is free. The Arena awaits."
        case .checking, .idle: return "Asking the scribes…"
        }
    }

    private var hintColor: Color {
        let name = vm.characterName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return DarkFantasyTheme.textTertiary }
        if name.count < 3 { return DarkFantasyTheme.textDanger }
        switch vm.nameAvailability {
        case .available: return DarkFantasyTheme.success
        case .taken, .invalid: return DarkFantasyTheme.textDanger
        case .checking, .idle: return DarkFantasyTheme.textTertiary
        }
    }

    private var borderColor: Color {
        switch vm.nameAvailability {
        case .available: DarkFantasyTheme.success
        case .taken, .invalid: DarkFantasyTheme.danger
        default: DarkFantasyTheme.borderSubtle
        }
    }
}
