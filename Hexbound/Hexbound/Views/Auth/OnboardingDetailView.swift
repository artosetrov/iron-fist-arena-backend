import SwiftUI

struct OnboardingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator bar — no animation on position
                stepIndicatorBar
                    .padding(.top, LayoutConstants.spaceSM)
                    .animation(nil, value: vm.step)

                // Step content — fills available space so top/bottom stay pinned
                Group {
                    switch vm.step {
                    case 0: ClassSelectionStepView(vm: vm)
                    case 1: AppearanceStepView(vm: vm)
                    case 2: NameStepView(vm: vm)
                    default: EmptyView()
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                // Error
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)
                }

                // Navigation buttons — no animation on position
                bottomButton
                    .animation(nil, value: vm.step)
            }
            // BUG-08: hero creation overlay was moved to HexboundApp root so
            // it survives the cross-fade to `.loreIntro` / `.characterSelect`.
            // See `HeroForgeOverlayView` and `appState.isForgingHero`.
        }
        .navigationBarHidden(true)
        .onAppear {
            if vm.selectedClass == nil {
                vm.selectedClass = .warrior
            }
            AudioManager.shared.playBGM("main-theme.mp3")
        }
        .onDisappear {
            AudioManager.shared.stopBGM()
        }
        .task {
            if vm.allSkins.isEmpty {
                vm.fetchSkins()
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
                    subtitle: nil,
                    isActive: vm.step == i,
                    isCompleted: vm.step > i
                )
                .onTapGesture {
                    if i < vm.step {
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.smooth) {
                            vm.step = i
                        }
                    } else if i == vm.step + 1 && vm.canProceed {
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.smooth) {
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

        HStack(spacing: LayoutConstants.spaceXS) {
            ZStack {
                Circle()
                    .fill(isActive ? DarkFantasyTheme.gold : (isCompleted ? DarkFantasyTheme.goldDim : DarkFantasyTheme.bgTertiary))
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold)) // keep — SF Symbol icon
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                } else {
                    Text("\(number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded)) // keep — rounded design
                        .foregroundStyle(isActive ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(isActive ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let subtitle {
                    Text(subtitle)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(bgColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(borderColor, lineWidth: isActive ? 1.5 : 1)
        )
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceMD) {
                Button {
                    SFXManager.shared.play(.uiBack)
                    if vm.step == 0 {
                        if !appState.authPath.isEmpty {
                            appState.authPath.removeLast()
                        }
                    } else {
                        vm.prevStep()
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("ui-arrow-left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        Text("BACK")
                    }
                }
                .buttonStyle(.secondary)

                Button {
                    if vm.step == OnboardingViewModel.totalSteps - 1 {
                        SFXManager.shared.play(.uiConfirm)
                        Task { await vm.createCharacter(appState: appState, cache: cache) }
                    } else {
                        SFXManager.shared.play(.uiTap)
                        vm.nextStep()
                    }
                } label: {
                    if vm.isCreating {
                        HexPulseLoader.onGold()
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

    // BUG-08: Hero forge overlay moved to `HeroForgeOverlayView` and
    // mounted at app root in `HexboundApp`. Do not reintroduce an inline
    // overlay here — it will be torn down with this view mid-transition.
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
