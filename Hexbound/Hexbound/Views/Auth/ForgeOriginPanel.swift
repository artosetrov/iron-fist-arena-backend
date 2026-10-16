import SwiftUI

/// Onboarding Step 2: Race + Gender + Avatar selection with a hero-card preview.
///
/// The central element is an Arena-style hero card (mirrors NameStepView)
/// — level badge, hero summary, class tag, NEW pill, and combined stat bonuses —
/// flanked by the gender toggle + dice on top and prev/next arrows on the bottom.
/// Arrows swap the avatar *inside* the card via a directional slide transition.
struct AppearanceStepView: View {
    @Bindable var vm: OnboardingViewModel

    // MARK: - Card Animation State

    /// Gentle Y float (no scale — project rule)
    @State private var floatOffset: CGFloat = 0
    /// Rotation phase for angular gradient border glow
    @State private var glowPhase: CGFloat = 0
    /// Shadow radius pulse for level badge
    @State private var levelGlowRadius: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: LayoutConstants.spaceMD) {
                    Text("Choose Your Appearance")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .tracking(1)
                        .padding(.top, LayoutConstants.spaceMD)

                    if vm.selectedOrigin != nil {
                        thumbnailRow

                        Spacer(minLength: LayoutConstants.spaceMD)

                        avatarArea

                        statBonusesRow

                        Spacer(minLength: LayoutConstants.spaceMD)
                    } else {
                        emptyState
                    }

                    raceRow
                        .padding(.bottom, LayoutConstants.spaceLG)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .frame(minHeight: geo.size.height)
            }
        }
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
    }

    // MARK: - Race Icons Row

    private var raceRow: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("Race")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textDimLabel)

            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(CharacterOrigin.allCases) { origin in
                    raceIcon(origin)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func raceIcon(_ origin: CharacterOrigin) -> some View {
        let isSelected = vm.selectedOrigin == origin

        Button {
            SFXManager.shared.play(.uiTap)
            withAnimation(MotionConstants.snappy) {
                vm.selectedOrigin = origin
                vm.onOriginChanged()
            }
        } label: {
            VStack(spacing: LayoutConstants.space2XS) {
                Image(origin.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .frame(width: LayoutConstants.touchComfortable, height: LayoutConstants.touchComfortable)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(isSelected ? DarkFantasyTheme.gold.opacity(0.1) : DarkFantasyTheme.bgDarkPanel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2.5)
                    )
                    .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 7)

                Text(origin.displayName)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)
            }
        }
        .buttonStyle(.scalePress(0.95))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Spacer()

            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                .strokeBorder(DarkFantasyTheme.bgDarkPanelBorder, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .frame(width: 160, height: 160)
                .overlay(
                    Text("?")
                        .font(DarkFantasyTheme.cinematicTitle)
                        .foregroundStyle(DarkFantasyTheme.bgDarkPanelBorder)
                )

            Text("Choose a race above to see available avatars")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Avatar Area (gender + arrows + hero card + dice)

    private var avatarArea: some View {
        let cardWidth: CGFloat = 200
        let cardHeight: CGFloat = cardWidth * 1.4
        let sideSize = LayoutConstants.avatarInnerSize

        return HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            // Left column: gender toggle (top) + left arrow (bottom)
            VStack(spacing: 0) {
                squareButton(
                    content: AnyView(
                        Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                    ),
                    size: sideSize,
                    bg: DarkFantasyTheme.xpRing.opacity(0.1),
                    border: DarkFantasyTheme.xpRing,
                    shadow: DarkFantasyTheme.xpRing.opacity(0.2)
                ) {
                    SFXManager.shared.play(.uiTap)
                    withAnimation(MotionConstants.snappy) { vm.toggleGender() }
                }

                Spacer(minLength: 0)

                squareButton(
                    content: AnyView(
                        Image("ui-arrow-left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.5, height: sideSize * 0.5)
                    ),
                    size: sideSize,
                    bg: DarkFantasyTheme.bgDarkPanel,
                    border: DarkFantasyTheme.bgDarkPanelBorder,
                    shadow: .clear
                ) {
                    SFXManager.shared.play(.uiTap)
                    withAnimation(.easeInOut(duration: MotionConstants.fast)) { vm.prevAvatar() }
                }
            }
            .frame(width: sideSize, height: cardHeight)

            heroCard(width: cardWidth, height: cardHeight)

            // Right column: dice (top) + right arrow (bottom)
            VStack(spacing: 0) {
                squareButton(
                    content: AnyView(
                        Image("ui-dice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                            .rotationEffect(.degrees(vm.diceRotation))
                    ),
                    size: sideSize,
                    bg: DarkFantasyTheme.gold.opacity(0.1),
                    border: DarkFantasyTheme.gold.opacity(0.3),
                    shadow: .clear
                ) {
                    SFXManager.shared.play(.uiTap)
                    withAnimation(MotionConstants.smooth) {
                        vm.diceRotation += 360
                        vm.randomize()
                    }
                }

                Spacer(minLength: 0)

                squareButton(
                    content: AnyView(
                        Image("ui-arrow-right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.5, height: sideSize * 0.5)
                    ),
                    size: sideSize,
                    bg: DarkFantasyTheme.bgDarkPanel,
                    border: DarkFantasyTheme.bgDarkPanelBorder,
                    shadow: .clear
                ) {
                    SFXManager.shared.play(.uiTap)
                    withAnimation(.easeInOut(duration: MotionConstants.fast)) { vm.nextAvatar() }
                }
            }
            .frame(width: sideSize, height: cardHeight)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Square Button Helper

    @ViewBuilder
    private func squareButton(content: AnyView, size: CGFloat, bg: Color, border: Color, shadow: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            content
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(bg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(border, lineWidth: 2)
                )
                .shadow(color: shadow, radius: 5)
        }
        .buttonStyle(.scalePress)
    }

    // MARK: - Hero Card (mirrors NameStepView.creationHeroCard)

    private var cardClassColor: Color {
        guard let cls = vm.selectedClass else { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.classColor(for: cls)
    }

    @ViewBuilder
    private func heroCard(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // 1. Full-bleed avatar with slide transition on change
            if vm.avatarIndex < vm.availableSkins.count {
                let skin = vm.availableSkins[vm.avatarIndex]
                CachedAssetImage(
                    key: skin.resolvedImageKey,
                    url: skin.imageUrl,
                    systemIcon: "person.fill",
                    contentMode: .fill
                )
                .frame(width: width, height: height)
                .clipped()
                .id(skin.skinKey)
                .transition(avatarTransition)
            }

            // 2. Vignette
            heroCardVignette(width: width, height: height)

            // 3. Overlay content
            VStack {
                heroCardTopBadges
                Spacer()
                heroCardBottomInfo
            }
            .padding(LayoutConstants.arenaCardPadding)
            .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
        .background(DarkFantasyTheme.bgAbyss)
        .overlay(heroCardBorderGlow)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
        .shadow(color: cardClassColor.opacity(0.35), radius: 22, y: 3)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        .offset(y: floatOffset)
        .animation(.easeInOut(duration: MotionConstants.fast), value: vm.avatarIndex)
    }

    private func heroCardVignette(width: CGFloat, height: CGFloat) -> some View {
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
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    private var heroCardTopBadges: some View {
        HStack {
            Text("1")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(Circle().stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5))
                )
                .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: levelGlowRadius)

            Spacer()
        }
    }

    private var heroCardBottomInfo: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            // Hero summary: "Female Orc Tank"
            Text(vm.heroSummary)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Class tag
            if let cls = vm.selectedClass {
                Text(cls.displayName.uppercased())
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(cardClassColor)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(cardClassColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                    .stroke(cardClassColor.opacity(0.25), lineWidth: 0.5)
                            )
                    )
            }

            // NEW rating badge
            HStack(spacing: LayoutConstants.spaceXS) {
                if UIImage(named: "icon-pvp-rating") != nil {
                    Image("icon-pvp-rating")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                        .opacity(0.7)
                } else {
                    Image(systemName: "star.fill")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                }
                Text("NEW")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(2)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.3), radius: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stat Bonus Cells (full-name planks, mirrors ClassSelectionStepView)

    @ViewBuilder
    private var statBonusesRow: some View {
        if !vm.combinedBonuses.isEmpty {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
                          GridItem(.flexible(), spacing: LayoutConstants.spaceSM)],
                spacing: LayoutConstants.spaceSM
            ) {
                ForEach(vm.combinedBonuses.prefix(4), id: \.stat) { bonus in
                    statBonusCell(name: bonus.stat, value: bonus.value)
                }
            }
            .animation(MotionConstants.snappy, value: vm.selectedOrigin)
        }
    }

    @ViewBuilder
    private func statBonusCell(name: String, value: Int) -> some View {
        let statType = StatType.allCases.first(where: { $0.fullName == name })
        let accentColor = value > 0 ? DarkFantasyTheme.statBoosted : DarkFantasyTheme.textDanger

        HStack(spacing: LayoutConstants.spaceSM) {
            if let statType {
                Image(statType.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            }

            Text(name)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            Text("\(value > 0 ? "+" : "")\(value)")
                .font(DarkFantasyTheme.cardTitle.bold())
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: accentColor.opacity(0.2), radius: 6, y: 2)
    }

    private var heroCardBorderGlow: some View {
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

    // MARK: - Avatar Transition

    private var avatarTransition: AnyTransition {
        switch vm.slideDirection {
        case .left:
            .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                         removal: .move(edge: .leading).combined(with: .opacity))
        case .right:
            .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                         removal: .move(edge: .trailing).combined(with: .opacity))
        case .none:
            .opacity
        }
    }

    // MARK: - Animation Control

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            floatOffset = -4
        }
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }
        withAnimation(MotionConstants.breathing) {
            levelGlowRadius = 20
        }
    }

    private func stopAnimations() {
        floatOffset = 0
        glowPhase = 0
        levelGlowRadius = 6
    }

    // MARK: - Thumbnail Row

    private var thumbnailRow: some View {
        let skins = vm.availableSkins

        return HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(Array(skins.enumerated()), id: \.element.id) { index, skin in
                let isSelected = vm.avatarIndex == index

                Button {
                    SFXManager.shared.play(.uiTap)
                    withAnimation(MotionConstants.snappy) {
                        vm.selectAvatar(at: index)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgDarkPanel)

                        skinImage(skin)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 5)
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
    }

    // MARK: - Skin Image Helper

    @ViewBuilder
    private func skinImage(_ skin: AppearanceSkin) -> some View {
        CachedAssetImage(
            key: skin.resolvedImageKey,
            url: skin.imageUrl,
            systemIcon: "person.fill"
        )
    }
}
