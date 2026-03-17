import SwiftUI

/// Onboarding Step 2: Race + Gender + Avatar selection on a single screen.
struct AppearanceStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("CHOOSE YOUR APPEARANCE")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)
                .padding(.top, LayoutConstants.spaceMD)

            raceRow
                .padding(.top, LayoutConstants.spaceSM)

            if vm.selectedOrigin != nil {
                thumbnailRow
                    .padding(.top, LayoutConstants.spaceMD)

                avatarArea
                    .padding(.top, LayoutConstants.spaceSM)

                raceBonusWidget
                    .padding(.top, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceLG)
            } else {
                emptyState
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceSM)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Race Icons Row

    private var raceRow: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("RACE")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textDimLabel)

            HStack(spacing: 6) {
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
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? DarkFantasyTheme.gold.opacity(0.1) : DarkFantasyTheme.bgDarkPanel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2.5)
                    )
                    .shadow(color: isSelected ? DarkFantasyTheme.gold.opacity(0.3) : .clear, radius: 7)

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
            RoundedRectangle(cornerRadius: 14)
                .fill(DarkFantasyTheme.bgSecondary)
            RoundedRectangle(cornerRadius: 14)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1.5)

            if let origin = vm.selectedOrigin {
                HStack(spacing: 12) {
                    Image(origin.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(origin.displayName)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text(origin.description)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Text(origin.bonuses)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
                .padding(.horizontal, LayoutConstants.bannerPadding)
            } else {
                Text("Select a race to see avatars")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(height: 88)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedOrigin)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Spacer()

            RoundedRectangle(cornerRadius: 16)
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
            let spacing: CGFloat = 8
            let sideSize: CGFloat = 64
            let avatarSize: CGFloat = min(geo.size.width - sideSize * 2 - spacing * 4, 220)

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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(bg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
            RoundedRectangle(cornerRadius: 22)
                .fill(DarkFantasyTheme.bgSecondary)

            if vm.avatarIndex < skins.count {
                let skin = skins[vm.avatarIndex]
                skinImage(skin)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .id(skin.skinKey)
                    .transition(avatarTransition)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(DarkFantasyTheme.gold, lineWidth: 3)
        )
        .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 20, y: 8)
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

        return HStack(spacing: 6) {
            ForEach(Array(skins.enumerated()), id: \.element.id) { index, skin in
                let isSelected = vm.avatarIndex == index

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectAvatar(at: index)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DarkFantasyTheme.bgDarkPanel)

                        skinImage(skin)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? DarkFantasyTheme.gold.opacity(0.25) : .clear, radius: 5)
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
    }

    // MARK: - Skin Image Helper

    @ViewBuilder
    private func skinImage(_ skin: AppearanceSkin) -> some View {
        if UIImage(named: skin.resolvedImageKey) != nil {
            Image(skin.resolvedImageKey)
                .resizable()
                .scaledToFill()
        } else if let url = skin.resolvedImageURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView().tint(DarkFantasyTheme.textTertiary)
            }
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 32))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }
}
