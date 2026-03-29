import SwiftUI

struct OnboardingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm = OnboardingViewModel()
    @State private var forgeGlow = false

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
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceSM)
                }

                // Navigation buttons — no animation on position
                bottomButton
                    .animation(nil, value: vm.step)
            }

            // Hero creation overlay
            if vm.isCreating {
                heroCreationOverlay
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
                    subtitle: nil,
                    isActive: vm.step == i,
                    isCompleted: vm.step > i
                )
                .onTapGesture {
                    if i < vm.step {
                        // Go back to a completed step
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.step = i
                        }
                    } else if i == vm.step + 1 && vm.canProceed {
                        // Advance forward if current step is valid
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
                    if vm.step == 0 {
                        if !appState.authPath.isEmpty {
                            appState.authPath.removeLast()
                        }
                    } else {
                        vm.prevStep()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image("ui-arrow-left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("BACK")
                    }
                }
                .buttonStyle(.secondary)

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

    // MARK: - Hero Creation Overlay

    private var heroCreationOverlay: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 48))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .opacity(forgeGlow ? 1.0 : 0.4)
                    .shadow(color: DarkFantasyTheme.gold.opacity(forgeGlow ? 0.6 : 0.1), radius: forgeGlow ? 16 : 4)

                Text("Forging Your Hero...")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("Sharpening swords, polishing armor...")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.gold.opacity(0.15),
                    glowIntensity: 0.5,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: DarkFantasyTheme.gold.opacity(0.1))
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 18, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 6)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                forgeGlow = true
            }
        }
        .onDisappear {
            forgeGlow = false
        }
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
