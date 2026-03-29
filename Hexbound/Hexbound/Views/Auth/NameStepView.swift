import SwiftUI

/// Onboarding Step 3: Name input with animated hero card preview.
/// The card features: floating animation, pulsing class aura, shimmer sweep,
/// ember particles, corner diamonds, staggered stat reveals, and level badge glow.
struct NameStepView: View {
    @Bindable var vm: OnboardingViewModel

    // MARK: - Animation States

    /// Y-offset for gentle float (never scale — per project rules)
    @State private var floatOffset: CGFloat = 0
    /// Opacity driver for the class-colored portrait aura
    @State private var glowOpacity: Double = 0.35
    /// X-phase for shimmer sweep across the card (−0.5 → 1.5)
    @State private var shimmerPhase: CGFloat = -0.5
    /// Shadow radius for the level badge gold glow
    @State private var levelGlowRadius: CGFloat = 6
    /// Controls staggered stat cell appearance
    @State private var statCellsVisible = false
    /// Card entry opacity (slide-up, no scale)
    @State private var cardOpacity: Double = 0
    /// Guards TimelineView so particles stop on disappear
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                Text("Choose Your Name")
                    .font(DarkFantasyTheme.title(size: 14))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(1)
                    .padding(.top, LayoutConstants.spaceLG)

                heroCardWithEffects

                nameInputSection
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
    }

    // MARK: - Hero Card + Particle Wrapper

    private var heroCardWithEffects: some View {
        ZStack {
            // Ember particles behind card (removed from hierarchy on disappear)
            if isVisible {
                EmberParticlesView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 480)
                    .allowsHitTesting(false)
            }

            unifiedCharacterCard
                .offset(y: floatOffset)
                .opacity(cardOpacity)
        }
    }

    // MARK: - Animation Control

    private func startAnimations() {
        isVisible = true

        // Card entry: opacity + Y slide (NO scale per project rules)
        withAnimation(.easeOut(duration: 0.5)) {
            cardOpacity = 1
        }

        // Float: gentle Y oscillation — reset on disappear to stop
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatOffset = -6
        }

        // Portrait aura: opacity pulse only — never scale
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.5)) {
            glowOpacity = 1.0
        }

        // Level badge: shadow radius pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            levelGlowRadius = 22
        }

        // Shimmer: linear sweep, loops endlessly
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false).delay(1.5)) {
            shimmerPhase = 1.5
        }

        // Stat cells: staggered opacity reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.4)) {
                statCellsVisible = true
            }
        }
    }

    private func stopAnimations() {
        // Reset all drivers — SwiftUI stops associated repeatForever animations
        isVisible = false
        floatOffset = 0
        glowOpacity = 0.35
        levelGlowRadius = 6
        shimmerPhase = -0.5
    }

    // MARK: - Unified Character Card

    private var unifiedCharacterCard: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            portraitSection

            originClassRow

            Text(vm.selectedGender.displayName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)

            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceLG)

            buildSummarySection
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.gold.opacity(0.10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.45), lineWidth: 1.5)
        )
        .overlay(shimmerOverlay)
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.45), length: 16, thickness: 1.5)
        .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.65), size: 7)
        .compositingGroup()
        // Dual shadow: gold glow + abyss depth
        .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 16)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.55), radius: 10, y: 5)
    }

    // MARK: - Portrait Section

    @ViewBuilder
    private var portraitSection: some View {
        ZStack {
            // Class-colored radial aura — opacity pulse, never scale
            if let cls = vm.selectedClass {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.classColor(for: cls).opacity(0.30),
                                DarkFantasyTheme.gold.opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .opacity(glowOpacity)
                    .allowsHitTesting(false)
            }

            // Soft gold ring — pulses with aura opacity
            Circle()
                .stroke(DarkFantasyTheme.gold.opacity(0.10 * glowOpacity), lineWidth: 1.5)
                .frame(width: 210, height: 210)
                .allowsHitTesting(false)

            ZStack(alignment: .bottomTrailing) {
                // Portrait image
                portraitImage
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radius2XL))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radius2XL)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                    )
                    // Bottom vignette
                    .overlay(
                        LinearGradient(
                            colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.45)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radius2XL))
                        .allowsHitTesting(false)
                    )
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.28), radius: 16)

                // Level badge with pulsing gold shadow
                Text("1")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel).bold())
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.goldDim],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 15
                                )
                            )
                    )
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.75), radius: levelGlowRadius)
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var portraitImage: some View {
        CachedAssetImage(
            key: vm.selectedSkin?.resolvedImageKey,
            url: vm.selectedSkin?.imageUrl,
            fallback: "🧑"
        )
    }

    // MARK: - Origin + Class Row

    @ViewBuilder
    private var originClassRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if let origin = vm.selectedOrigin {
                Image(origin.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(origin.displayName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            if let cls = vm.selectedClass {
                Image(cls.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(cls.sfName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.classColor(for: cls))
            }
        }
    }

    // MARK: - Build Summary + Stat Grid

    @ViewBuilder
    private var buildSummarySection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(vm.heroSummary)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            if !vm.combinedBonuses.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: LayoutConstants.spaceXS
                ) {
                    ForEach(Array(vm.combinedBonuses.enumerated()), id: \.element.stat) { index, bonus in
                        statBonusCell(name: bonus.stat, value: bonus.value)
                            .opacity(statCellsVisible ? 1 : 0)
                            .offset(y: statCellsVisible ? 0 : 8)
                            .animation(
                                .easeOut(duration: 0.4).delay(Double(index) * 0.07),
                                value: statCellsVisible
                            )
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Shimmer Overlay

    private var shimmerOverlay: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: DarkFantasyTheme.gold.opacity(0.08), location: 0.42),
                .init(color: DarkFantasyTheme.goldBright.opacity(0.06), location: 0.5),
                .init(color: DarkFantasyTheme.gold.opacity(0.08), location: 0.58),
                .init(color: .clear, location: 1),
            ],
            startPoint: UnitPoint(x: shimmerPhase - 0.4, y: 0.0),
            endPoint: UnitPoint(x: shimmerPhase + 0.4, y: 1.0)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .allowsHitTesting(false)
    }

    // MARK: - Name Input Section

    private let heroInputHeight: CGFloat = 76
    private let heroInputRadius: CGFloat = 14

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("YOUR NAME")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
                    .tracking(2)
                Spacer()
                Text("\(vm.characterName.count)/16")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ZStack(alignment: .leading) {
                    if vm.characterName.isEmpty {
                        Text("Enter hero name...")
                            .font(DarkFantasyTheme.title(size: 20))
                            .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.6))
                            .padding(.horizontal, LayoutConstants.spaceMD)
                    }

                    HStack(spacing: LayoutConstants.spaceSM) {
                        TextField("", text: $vm.characterName)
                            .font(DarkFantasyTheme.title(size: 22))
                            .foregroundStyle(nameTextColor)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: vm.characterName) { _, newValue in
                                if newValue.count > 16 {
                                    vm.characterName = String(newValue.prefix(16))
                                }
                                vm.checkNameAvailability()
                            }

                        if vm.characterName.count >= 3 {
                            Group {
                                switch vm.nameAvailability {
                                case .checking:
                                    ProgressView()
                                        .tint(DarkFantasyTheme.goldDim)
                                        .scaleEffect(0.85)
                                case .available:
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(DarkFantasyTheme.success)
                                case .taken:
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(DarkFantasyTheme.danger)
                                default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 32)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            .animation(.spring(response: 0.3), value: vm.nameAvailability)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                }
                .frame(height: heroInputHeight)
                .background(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .stroke(inputBorderColor, lineWidth: vm.characterName.isEmpty ? 1.5 : 2)
                        .animation(.easeInOut(duration: 0.2), value: vm.nameAvailability)
                )
                .shadow(
                    color: vm.nameAvailability == .available
                        ? DarkFantasyTheme.success.opacity(0.2)
                        : (vm.nameAvailability == .taken
                            ? DarkFantasyTheme.danger.opacity(0.2)
                            : DarkFantasyTheme.gold.opacity(vm.characterName.isEmpty ? 0 : 0.12)),
                    radius: 8
                )

                // Dice button
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    vm.generateRandomName()
                    vm.checkNameAvailability()
                } label: {
                    VStack(spacing: 4) {
                        Image("ui-dice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text("RND")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.goldDim)
                    }
                    .frame(width: heroInputHeight, height: heroInputHeight)
                }
                .background(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .fill(DarkFantasyTheme.gold.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1.5)
                )
                .buttonStyle(.scalePress(0.95))
            }

            Group {
                if !vm.characterName.isEmpty && vm.characterName.count < 3 {
                    Text("Name must be at least 3 characters")
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                } else if vm.nameAvailability == .checking {
                    Text("Checking availability...")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                } else if vm.nameAvailability == .available {
                    Text("✓ Name is available!")
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                } else if vm.nameAvailability == .taken {
                    Text("Name already taken — try another")
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                } else {
                    Text(" ")
                }
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
            .animation(.easeInOut(duration: 0.2), value: vm.nameAvailability)
        }
    }

    // MARK: - Stat Bonus Cell

    @ViewBuilder
    private func statBonusCell(name: String, value: Int) -> some View {
        let statType = StatType.allCases.first(where: { $0.fullName == name })
        let accentColor = value > 0 ? DarkFantasyTheme.statBoosted : DarkFantasyTheme.textDanger

        HStack(spacing: LayoutConstants.spaceSM) {
            if let statType {
                Image(statType.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }

            Text(name)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text("\(value > 0 ? "+" : "")\(value)")
                .font(DarkFantasyTheme.section(size: 20).bold())
                .foregroundStyle(value > 0 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textDanger)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(value > 0 ? DarkFantasyTheme.gold.opacity(0.5) : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.2), radius: 6, y: 2)
    }

    // MARK: - Helpers

    private var inputBorderColor: Color {
        if vm.characterName.isEmpty { return DarkFantasyTheme.borderSubtle.opacity(0.5) }
        if vm.characterName.count < 3 { return DarkFantasyTheme.danger }
        switch vm.nameAvailability {
        case .available: return DarkFantasyTheme.success
        case .taken:     return DarkFantasyTheme.danger
        case .checking:  return DarkFantasyTheme.goldDim
        default:         return DarkFantasyTheme.goldDim
        }
    }

    private var nameTextColor: Color {
        if vm.characterName.isEmpty { return DarkFantasyTheme.textPrimary }
        if vm.characterName.count < 3 { return DarkFantasyTheme.danger }
        switch vm.nameAvailability {
        case .available: return DarkFantasyTheme.success
        case .taken:     return DarkFantasyTheme.danger
        case .checking:  return DarkFantasyTheme.goldBright
        default:         return DarkFantasyTheme.goldBright
        }
    }
}

// MARK: - Ember Particles

/// GPU-efficient ambient particles using TimelineView + Canvas.
/// Removed from view hierarchy on disappear via isVisible guard in parent.
private struct EmberParticlesView: View {

    private struct Particle {
        let x: Double
        let startY: Double
        let size: Double
        let speed: Double
        let drift: Double
        let phase: Double
    }

    // Deterministic values — consistent across appear/disappear cycles
    private let particles: [Particle] = (0..<16).map { i in
        let b = Double(i)
        return Particle(
            x:      0.05 + b.truncatingRemainder(dividingBy: 10) / 11.0,
            startY: (b * 0.137).truncatingRemainder(dividingBy: 1.0),
            size:   1.5 + b.truncatingRemainder(dividingBy: 3) * 0.6,
            speed:  0.06 + b.truncatingRemainder(dividingBy: 7) * 0.012,
            drift:  (b.truncatingRemainder(dividingBy: 5) - 2.5) * 0.015,
            phase:  b * 1.1
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let raw      = (p.startY + t * p.speed).truncatingRemainder(dividingBy: 1.0)
                    let progress = raw < 0 ? raw + 1.0 : raw
                    let yPos     = size.height * (1.0 - progress)
                    let xPos     = size.width  * (p.x + sin(t * 0.7 + p.phase) * p.drift)

                    // Fade in near bottom, fade out near top
                    let opacity  = min(progress * 5, 1.0) * min((1.0 - progress) * 5, 1.0) * 0.55

                    let rect = CGRect(x: xPos - p.size / 2, y: yPos - p.size / 2,
                                      width: p.size, height: p.size)
                    let color: Color = p.size > 2.5
                        ? DarkFantasyTheme.gold.opacity(opacity)
                        : DarkFantasyTheme.goldDim.opacity(opacity)
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
        }
    }
}
