import SwiftUI

/// Hero creation — "Forge Stage" (2026-10-16 redesign, concept A).
///
/// One shared stage: the hero's portrait stays centre-screen and reacts to
/// every choice (race / gender / look → portrait, class → aura colour, name →
/// title). Below it a single panel per step: Origin → Class → Name. Pressing
/// FORGE runs the in-view ceremony (`ForgeCeremonyView`) and reveals the hero
/// with the stats the server actually granted.
struct OnboardingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm = OnboardingViewModel()
    @FocusState private var nameFocused: Bool
    @State private var auraPulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                aura(height: geo.size.height)

                switch vm.phase {
                case .editing:
                    editingLayout(height: geo.size.height)
                        .transition(.opacity)
                case .forging, .revealed:
                    ForgeCeremonyView(vm: vm) {
                        SFXManager.shared.play(.uiConfirm)
                        Task { await vm.enterCity(appState: appState, cache: cache) }
                    }
                    .transition(.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AudioManager.shared.playBGM("main-theme.mp3")
            if !reduceMotion { auraPulse = true }
        }
        .onDisappear {
            AudioManager.shared.stopBGM()
        }
        .task {
            if vm.allSkins.isEmpty { vm.fetchSkins() }
            vm.fetchCreationOptions()
        }
    }

    // MARK: - Aura

    private func aura(height: CGFloat) -> some View {
        RadialGradient(
            colors: [
                vm.accentColor.opacity(0.45),
                vm.accentColor.opacity(0.10),
                .clear
            ],
            center: UnitPoint(x: 0.5, y: 0.28),
            startRadius: 0,
            endRadius: height * 0.42
        )
        .opacity(auraPulse ? 1 : 0.7)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
            value: auraPulse
        )
        .animation(MotionConstants.smooth, value: vm.accentColor)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Editing layout

    private func editingLayout(height: CGFloat) -> some View {
        // Portrait shrinks when the keyboard is up so the name field stays visible.
        let portrait = nameFocused ? min(120, height * 0.16) : min(250, max(150, height * 0.29))

        return VStack(spacing: 0) {
            topBar
                .padding(.top, LayoutConstants.spaceSM)

            heroStage(size: portrait)
                .padding(.top, LayoutConstants.spaceSM)
                .animation(MotionConstants.smooth, value: nameFocused)

            Spacer(minLength: LayoutConstants.spaceSM)

            Group {
                switch vm.step {
                case 0: ForgeOriginPanel(vm: vm)
                case 1: ForgeClassPanel(vm: vm)
                default: ForgeNamePanel(vm: vm, nameFocused: $nameFocused) { forge() }
                }
            }
            .id(vm.step)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textDanger)
                    .multilineTextAlignment(.center)
                    .padding(.top, LayoutConstants.spaceSM)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceMD)
    }

    private func forge() {
        guard vm.canProceed else { return }
        nameFocused = false
        SFXManager.shared.play(.uiConfirm)
        Task { await vm.forge() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            circleButton(asset: "ui-arrow-left", label: "Back") {
                SFXManager.shared.play(.uiBack)
                nameFocused = false
                if vm.step == 0 {
                    if !appState.authPath.isEmpty { appState.authPath.removeLast() }
                } else {
                    vm.prevStep()
                }
            }

            Spacer()

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(0..<OnboardingViewModel.totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == vm.step ? DarkFantasyTheme.goldBright
                              : (i < vm.step ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle))
                        .frame(width: i == vm.step ? 34 : 22, height: 4)
                        .shadow(color: i == vm.step ? DarkFantasyTheme.goldGlow : .clear, radius: 4)
                }
            }
            .animation(MotionConstants.spring, value: vm.step)
            .accessibilityElement()
            .accessibilityLabel("Step \(vm.step + 1) of \(OnboardingViewModel.totalSteps)")

            Spacer()

            circleButton(asset: "ui-dice", label: "Random hero") {
                SFXManager.shared.play(.uiTap)
                withAnimation(MotionConstants.smooth) { vm.randomizeHero() }
            }
        }
    }

    private func circleButton(asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                .frame(width: LayoutConstants.touchMin, height: LayoutConstants.touchMin)
                .background(Circle().fill(DarkFantasyTheme.bgSecondary.opacity(0.85)))
                .overlay(Circle().stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Hero stage

    private func heroStage(size: CGFloat) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForgePortrait(skin: vm.selectedSkin, accent: vm.accentColor, size: size)
                .accessibilityLabel("\(vm.heroLine) \(vm.selectedClass?.displayName ?? "")")

            VStack(spacing: LayoutConstants.space2XS) {
                Text(vm.heroLine)
                    .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text(vm.stageTitle)
                    .font(nameFocused ? DarkFantasyTheme.title : DarkFantasyTheme.cinematicTitle)
                    .tracking(5)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: vm.accentColor.opacity(0.75), radius: 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.opacity)
                    .animation(MotionConstants.snappy, value: vm.stageTitle)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Portrait

/// Round hero portrait with a class-coloured halo. Shared by stage and ceremony.
struct ForgePortrait: View {
    let skin: AppearanceSkin?
    let accent: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.bgAbyss)

            if let skin {
                CachedAssetImage(
                    key: skin.resolvedImageKey,
                    url: skin.imageUrl,
                    systemIcon: "person.fill",
                    contentMode: .fill
                )
                .frame(width: size, height: size)
                .clipShape(Circle())
                .id(skin.skinKey)
                .transition(.opacity)
            } else {
                HexPulseLoader(.standard)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(accent.opacity(0.6), lineWidth: 2))
        .shadow(color: accent.opacity(0.45), radius: size * 0.2)
        .animation(MotionConstants.smooth, value: skin?.skinKey)
    }
}

// MARK: - Shared pieces

/// "Strength +3" chip. Negative values read red.
struct ForgeBonusChip: View {
    let bonus: StatBonus

    var body: some View {
        let positive = bonus.value > 0
        HStack(spacing: LayoutConstants.spaceXS) {
            Text(bonus.label)
                .foregroundStyle(positive ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textDanger)
            Text(positive ? "+\(bonus.value)" : "−\(abs(bonus.value))")
                .fontWeight(.bold)
                .foregroundStyle(positive ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textDanger)
        }
        .font(DarkFantasyTheme.uiLabel)
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS + 2)
        .background(
            Capsule().fill((positive ? DarkFantasyTheme.gold : DarkFantasyTheme.danger).opacity(0.12))
        )
        .overlay(
            Capsule().stroke((positive ? DarkFantasyTheme.gold : DarkFantasyTheme.danger).opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Selectable tile used for races and classes.
struct ForgeChoiceTile: View {
    let asset: String
    let title: String
    let isSelected: Bool
    let accent: Color
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.space2XS) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: height * 0.5, height: height * 0.5)
                    .opacity(isSelected ? 1 : 0.7)
                Text(title)
                    .font(DarkFantasyTheme.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(LinearGradient(
                            colors: [accent.opacity(0.28), DarkFantasyTheme.bgSecondary],
                            startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(DarkFantasyTheme.bgSecondary)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderSubtle,
                            lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? accent.opacity(0.45) : .clear, radius: 9)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
