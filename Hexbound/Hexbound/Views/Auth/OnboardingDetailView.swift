import SwiftUI

struct OnboardingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator bar
                stepIndicatorBar
                    .padding(.top, LayoutConstants.spaceSM)

                // Step content
                switch vm.step {
                case 0: ClassSelectionStepView(vm: vm)
                case 1: AppearanceStepView(vm: vm)
                case 2: NameStepView(vm: vm)
                default: EmptyView()
                }

                Spacer(minLength: 0)

                // Error
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)
                }

                // Navigation buttons
                bottomButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if vm.selectedClass == nil {
                vm.selectedClass = .warrior
            }
        }
        .task {
            if vm.allSkins.isEmpty {
                await vm.fetchSkins()
            }
        }
    }

    // MARK: - Step Indicator Bar

    private var stepIndicatorBar: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<OnboardingViewModel.totalSteps, id: \.self) { i in
                stepTab(
                    number: i + 1,
                    title: ["CLASS", "APPEARANCE", "NAME"][i],
                    subtitle: i == 0 ? vm.selectedClass?.sfName : nil,
                    isActive: vm.step == i,
                    isCompleted: vm.step > i
                )
                .onTapGesture {
                    if i < vm.step {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.step = i
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func stepTab(number: Int, title: String, subtitle: String?, isActive: Bool, isCompleted: Bool) -> some View {
        let borderColor = isActive ? DarkFantasyTheme.gold : (isCompleted ? DarkFantasyTheme.goldDim : DarkFantasyTheme.borderSubtle)
        let bgColor = isActive ? DarkFantasyTheme.gold.opacity(0.12) : DarkFantasyTheme.bgSecondary

        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? DarkFantasyTheme.gold : (isCompleted ? DarkFantasyTheme.goldDim : DarkFantasyTheme.bgTertiary))
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold)) // SF Symbol icon — keep as is
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                } else {
                    Text("\(number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded)) // rounded design — keep as is
                        .foregroundStyle(isActive ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(isActive ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)

                if let subtitle {
                    Text(subtitle)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isActive ? 1.5 : 1)
        )
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceMD) {
                if vm.step > 0 {
                    Button {
                        vm.prevStep()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("BACK")
                        }
                    }
                    .buttonStyle(.secondary)
                }

                Button {
                    if vm.step == OnboardingViewModel.totalSteps - 1 {
                        Task { await vm.createCharacter(appState: appState, cache: cache) }
                    } else {
                        vm.nextStep()
                    }
                } label: {
                    if vm.isCreating {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Text(vm.step == OnboardingViewModel.totalSteps - 1 ? "SAVE" : "CONTINUE")
                    }
                }
                .buttonStyle(.primary(enabled: vm.canProceed))
                .disabled(!vm.canProceed || vm.isCreating)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceLG)
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
