import SwiftUI

/// Onboarding Step 3: Name input with animated hero card preview.
/// The card features: floating animation, pulsing class aura, shimmer sweep,
/// ember particles, corner diamonds, staggered stat reveals, and level badge glow.
struct NameStepView: View {
    @Bindable var vm: OnboardingViewModel

    // MARK: - Animation States

    /// Y-offset for gentle float (never scale — per project rules)
    @State private var floatOffset: CGFloat = 0
    /// Rotation phase for animated angular gradient border (0 → 360)
    @State private var glowPhase: CGFloat = 0
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
                    .frame(height: 340)
                    .allowsHitTesting(false)
            }

            creationHeroCard
                .frame(maxWidth: 200)
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

        // Border glow: rotating angular gradient
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }

        // Level badge: shadow radius pulse
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            levelGlowRadius = 22
        }

        // Shimmer: linear sweep, loops endlessly
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false).delay(1.5)) {
            shimmerPhase = 1.5
        }

        // Stat pills: staggered opacity reveal
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
        glowPhase = 0
        levelGlowRadius = 6
        shimmerPhase = -0.5
    }

    // MARK: - Arena-Style Hero Card

    private var cardClassColor: Color {
        guard let cls = vm.selectedClass else { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.classColor(for: cls)
    }

    private var creationHeroCard: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 1.4

            ZStack {
                // 1. Full-bleed avatar
                CachedAssetImage(
                    key: vm.selectedSkin?.resolvedImageKey,
                    url: vm.selectedSkin?.imageUrl,
                    fallback: "🧑",
                    contentMode: .fill
                )
                .frame(width: width, height: height)
                .clipped()

                // 2. Vignette overlays
                creationVignette(width: width, height: height)

                // 3. Content overlay
                VStack {
                    creationTopBadges
                    Spacer()
                    creationBottomInfo
                }
                .padding(LayoutConstants.arenaCardPadding)
                .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .background(DarkFantasyTheme.bgAbyss)
            .overlay(creationBorderGlow)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
            .shadow(color: cardClassColor.opacity(0.35), radius: 22, y: 3)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        }
        .aspectRatio(1.0 / 1.4, contentMode: .fit)
    }

    // MARK: - Vignette

    private func creationVignette(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.5)]),
                center: .init(x: 0.5, y: 0.35),
                startRadius: width * 0.25,
                endRadius: width * 0.85
            )

            LinearGradient(
                colors: [
                    .clear, .clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.4),
                    DarkFantasyTheme.bgAbyss.opacity(0.8),
                    DarkFantasyTheme.bgAbyss.opacity(0.95),
                    DarkFantasyTheme.bgAbyss
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.65)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Top Badges

    private var creationTopBadges: some View {
        HStack {
            // Level circle with pulsing glow
            Text("1")
                .font(DarkFantasyTheme.section(size: 14))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(Circle().stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5))
                )
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: levelGlowRadius)

            Spacer()

            // Origin badge
            if let origin = vm.selectedOrigin {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(origin.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(origin.displayName.uppercased())
                        .font(DarkFantasyTheme.body(size: LayoutConstants.arenaDifficultyFont).bold())
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(DarkFantasyTheme.borderSubtle.opacity(0.3), lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - Bottom Info

    private var creationBottomInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Hero summary line (e.g. "Female Dogfolk Warrior")
            Text(vm.heroSummary)
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Class tag pill
            if let cls = vm.selectedClass {
                Text(cls.displayName.uppercased())
                    .font(DarkFantasyTheme.body(size: 10).bold())
                    .foregroundStyle(cardClassColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(cardClassColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                    .stroke(cardClassColor.opacity(0.25), lineWidth: 0.5)
                            )
                    )
            }

            // "NEW" rating badge
            HStack(spacing: 5) {
                if UIImage(named: "icon-pvp-rating") != nil {
                    Image("icon-pvp-rating")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .opacity(0.7)
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                }
                Text("NEW")
                    .font(DarkFantasyTheme.section(size: 20))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(2)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.3), radius: 8)
            }

            // Glass stat pills — top combined bonuses
            if !vm.combinedBonuses.isEmpty {
                HStack(spacing: 4) {
                    ForEach(Array(vm.combinedBonuses.prefix(3).enumerated()), id: \.element.stat) { index, bonus in
                        creationStatPill(
                            value: "+\(bonus.value)",
                            label: String(bonus.stat.prefix(3)).uppercased(),
                            color: statPillColor(for: index)
                        )
                        .opacity(statCellsVisible ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.4).delay(Double(index) * 0.1),
                            value: statCellsVisible
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statPillColor(for index: Int) -> Color {
        switch index {
        case 0:  return DarkFantasyTheme.danger
        case 1:  return DarkFantasyTheme.info
        default: return DarkFantasyTheme.gold
        }
    }

    // MARK: - Glass Stat Pill (Arena-Style)

    @ViewBuilder
    private func creationStatPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Animated Border Glow

    private var creationBorderGlow: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        cardClassColor.opacity(0.4),
                        DarkFantasyTheme.gold.opacity(0.15),
                        cardClassColor.opacity(0.3),
                        DarkFantasyTheme.gold.opacity(0.1),
                        cardClassColor.opacity(0.4)
                    ],
                    center: .center,
                    startAngle: .degrees(glowPhase),
                    endAngle: .degrees(glowPhase + 360)
                ),
                lineWidth: 2
            )
            .overlay(
                CornerBracketOverlay(
                    color: DarkFantasyTheme.gold.opacity(0.5),
                    length: 16,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: DarkFantasyTheme.gold.opacity(0.5),
                    size: 6
                )
            )
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
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
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

                // Dice button — prominent when name is empty, subdued when filled
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    vm.generateRandomName()
                    vm.checkNameAvailability()
                } label: {
                    Image("ui-dice")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .frame(width: heroInputHeight, height: heroInputHeight)
                }
                .background(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .fill(
                            vm.characterName.isEmpty
                                ? DarkFantasyTheme.gold.opacity(0.15)
                                : DarkFantasyTheme.gold.opacity(0.04)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: heroInputRadius)
                        .stroke(
                            vm.characterName.isEmpty
                                ? DarkFantasyTheme.gold.opacity(0.7)
                                : DarkFantasyTheme.gold.opacity(0.25),
                            lineWidth: vm.characterName.isEmpty ? 2 : 1
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: vm.characterName.isEmpty)
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
