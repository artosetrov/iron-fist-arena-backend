import SwiftUI

/// Onboarding Step 2: Race + Gender + Avatar selection on a single screen.
struct AppearanceStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Choose Your Appearance")
                .font(DarkFantasyTheme.title(size: 14))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(1)
                .padding(.top, LayoutConstants.spaceMD)

            if vm.selectedOrigin != nil {
                raceBonusWidget
                    .padding(.top, LayoutConstants.spaceSM)

                thumbnailRow
                    .padding(.top, LayoutConstants.spaceSM)

                avatarArea
                    .padding(.top, LayoutConstants.spaceMD)
            } else {
                emptyState
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceSM)
            }

            raceRow
                .padding(.top, LayoutConstants.spaceMD)
                .padding(.bottom, LayoutConstants.spaceLG)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Race Icons Row

    private var raceRow: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("Race")
                .font(DarkFantasyTheme.body(size: 14))
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
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedOrigin = origin
                vm.onOriginChanged()
            }
        } label: {
            VStack(spacing: 3) {
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
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)
            }
        }
        .buttonStyle(.scalePress(0.95))
    }

    // MARK: - Race Bonus Widget

    private var raceBonusWidget: some View {
        ZStack {
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.buttonRadiusLG
            )
            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1.5)

            if let origin = vm.selectedOrigin {
                VStack(spacing: LayoutConstants.spaceXS) {
                    HStack(spacing: LayoutConstants.spaceMS) {
                        Image(origin.iconAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(origin.displayName)
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.goldBright)

                            Text(origin.description)
                                .font(DarkFantasyTheme.body(size: 12))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }

                    // Stat bonuses inline
                    if !vm.originBonuses.isEmpty {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            ForEach(vm.originBonuses, id: \.stat) { bonus in
                                statBonusCell(name: bonus.stat, value: bonus.value)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.bannerPadding)
                .padding(.vertical, LayoutConstants.spaceXS)
            } else {
                Text("Select a race to see avatars")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedOrigin)
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
                        .font(DarkFantasyTheme.title(size: 48))
                        .foregroundStyle(DarkFantasyTheme.bgDarkPanelBorder)
                )

            Text("Choose a race above to see available avatars")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Avatar Area (gender + arrows + central avatar + dice)

    private var avatarArea: some View {
        GeometryReader { geo in
            let spacing = LayoutConstants.spaceSM
            let sideSize = LayoutConstants.avatarInnerSize
            let avatarSize: CGFloat = max(min(geo.size.width - sideSize * 2 - spacing * 4, 220), 0)

            HStack(alignment: .center, spacing: spacing) {
                // Left column: gender toggle (top) + left arrow (bottom)
                VStack(spacing: 0) {
                    squareButton(content: AnyView(
                        Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                    ), size: sideSize, bg: DarkFantasyTheme.xpRing.opacity(0.1),
                       border: DarkFantasyTheme.xpRing, shadow: DarkFantasyTheme.xpRing.opacity(0.2)) {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.toggleGender() }
                    }
                    Spacer()
                    squareButton(content: AnyView(
                        Image("ui-arrow-left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.5, height: sideSize * 0.5)
                    ), size: sideSize, bg: DarkFantasyTheme.bgDarkPanel,
                       border: DarkFantasyTheme.bgDarkPanelBorder, shadow: .clear) {
                        withAnimation(.easeInOut(duration: 0.25)) { vm.prevAvatar() }
                    }
                }
                .frame(width: sideSize, height: avatarSize)

                centralAvatar(size: avatarSize)

                // Right column: dice (top) + right arrow (bottom)
                VStack(spacing: 0) {
                    squareButton(content: AnyView(
                        Image("ui-dice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                            .rotationEffect(.degrees(vm.diceRotation))
                    ), size: sideSize, bg: DarkFantasyTheme.gold.opacity(0.1),
                       border: DarkFantasyTheme.gold.opacity(0.3), shadow: .clear) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.diceRotation += 360
                            vm.randomize()
                        }
                    }
                    Spacer()
                    squareButton(content: AnyView(
                        Image("ui-arrow-right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.5, height: sideSize * 0.5)
                    ), size: sideSize, bg: DarkFantasyTheme.bgDarkPanel,
                       border: DarkFantasyTheme.bgDarkPanelBorder, shadow: .clear) {
                        withAnimation(.easeInOut(duration: 0.25)) { vm.nextAvatar() }
                    }
                }
                .frame(width: sideSize, height: avatarSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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

    // MARK: - Central Avatar

    @ViewBuilder
    private func centralAvatar(size: CGFloat) -> some View {
        let skins = vm.availableSkins

        ZStack {
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.radius2XL
            )

            if vm.avatarIndex < skins.count {
                let skin = skins[vm.avatarIndex]
                skinImage(skin)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radius2XL))
                    .id(skin.skinKey)
                    .transition(avatarTransition)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radius2XL)
                .stroke(DarkFantasyTheme.gold, lineWidth: 3)
        )
        .shadow(color: DarkFantasyTheme.goldGlow, radius: 20, y: 8)
        .animation(.easeInOut(duration: 0.25), value: vm.avatarIndex)
    }

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

    // MARK: - Thumbnail Row

    private var thumbnailRow: some View {
        let skins = vm.availableSkins

        return HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(Array(skins.enumerated()), id: \.element.id) { index, skin in
                let isSelected = vm.avatarIndex == index

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
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

    // MARK: - Stat Bonus Cell (matches NameStepView style)

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

    // MARK: - Skin Image Helper

    @ViewBuilder
    private func skinImage(_ skin: AppearanceSkin) -> some View {
        CachedAssetImage(
            key: skin.resolvedImageKey,
            url: skin.imageUrl,
            fallback: "🧑"
        )
    }
}
