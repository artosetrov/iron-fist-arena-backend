import SwiftUI

struct OnboardingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // S&F-style step indicator bar
                stepIndicatorBar
                    .padding(.top, LayoutConstants.spaceSM)

                // Content
                switch vm.step {
                case 0: classSelectionStep
                case 1: appearanceStep
                case 2: nameStep
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

                // Continue / Save button
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

    // MARK: - Step Indicator Bar (S&F Style)

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
            // Number badge
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

            // Title + subtitle
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(DarkFantasyTheme.section(size: 10))
                    .foregroundStyle(isActive ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)

                if let subtitle {
                    Text(subtitle)
                        .font(DarkFantasyTheme.body(size: 8))
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

    // MARK: - Step 1: Class Selection (S&F Style)

    private var classSelectionStep: some View {
        VStack(spacing: 0) {
            // Title
            Text("CHOOSE A CLASS")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .padding(.top, LayoutConstants.spaceLG)

            if let selectedClass = vm.selectedClass {
                // Large class showcase area (swipeable)
                classShowcase(selectedClass)
                    .padding(.top, LayoutConstants.spaceMD)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                if value.translation.width < -40 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vm.selectNextClass()
                                    }
                                } else if value.translation.width > 40 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vm.selectPreviousClass()
                                    }
                                }
                            }
                    )

                Spacer(minLength: LayoutConstants.spaceMD)

                // Bottom medallion row with arrows
                classCarousel
                    .padding(.bottom, LayoutConstants.spaceLG + LayoutConstants.spaceMD)
            }
        }
    }

    @ViewBuilder
    private func classShowcase(_ charClass: CharacterClass) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Large icon area (placeholder for character illustration)
            ZStack {
                // Background glow
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.classColor(for: charClass).opacity(0.2),
                                DarkFantasyTheme.bgSecondary.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(height: 340)

                // Class icon
                Image(charClass.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 256, height: 256)
                    .shadow(color: DarkFantasyTheme.classColor(for: charClass).opacity(0.5), radius: 20)
            }

            // Class info panel
            VStack(spacing: LayoutConstants.spaceSM) {
                // Class name
                Text(charClass.sfName)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                // Main attribute
                HStack(spacing: 4) {
                    Text("MAIN ATTRIBUTE")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("–")
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text(charClass.mainAttribute)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                // Description
                Text(charClass.mainAttributeDescription)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // Bonus stats
                Text(charClass.bonuses)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSuccess)
                    .padding(.top, 2)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    private var classCarousel: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Left arrow
            Button { vm.selectPreviousClass() } label: {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 36, height: 36)
            }

            // Class medallions
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(CharacterClass.allCases.enumerated()), id: \.element.id) { index, charClass in
                    classMedallion(charClass, isSelected: vm.selectedClass == charClass)
                        .onTapGesture {
                            vm.selectClass(at: index)
                        }
                }
            }

            // Right arrow
            Button { vm.selectNextClass() } label: {
                Image("ui-arrow-right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    @ViewBuilder
    private func classMedallion(_ charClass: CharacterClass, isSelected: Bool) -> some View {
        let color = DarkFantasyTheme.classColor(for: charClass)

        ZStack {
            // Outer ring
            Circle()
                .fill(isSelected ? color.opacity(0.2) : DarkFantasyTheme.bgSecondary)
                .frame(width: 56, height: 56)

            Circle()
                .stroke(isSelected ? color : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2.5 : 1)
                .frame(width: 56, height: 56)

            // Icon
            Image(charClass.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        }
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Step 2: Appearance (Race + Gender + Avatar) — Single Screen, No Scroll

    private var appearanceStep: some View {
        VStack(spacing: 0) {
            // Title
            Text("CHOOSE YOUR APPEARANCE")
                .font(DarkFantasyTheme.title(size: 16))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)
                .padding(.top, LayoutConstants.spaceMD)

            // Race row
            appearanceRaceRow
                .padding(.top, LayoutConstants.spaceSM)

            // Central avatar area (fills remaining vertical space)
            if vm.selectedOrigin != nil {
                // Thumbnail previews — ABOVE main avatar
                appearanceThumbnailRow
                    .padding(.top, LayoutConstants.spaceMD)

                appearanceAvatarArea
                    .padding(.top, LayoutConstants.spaceSM)

                // Race bonus widget — BELOW avatar, taller
                appearanceRaceBonusWidget
                    .padding(.top, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceLG)
            } else {
                // Empty state
                appearanceEmptyState
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceSM)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: Race Icons Row

    private var appearanceRaceRow: some View {
        VStack(spacing: 4) {
            Text("RACE")
                .font(DarkFantasyTheme.body(size: 10))
                .foregroundStyle(DarkFantasyTheme.textDimLabel)

            HStack(spacing: 6) {
                ForEach(CharacterOrigin.allCases) { origin in
                    appearanceRaceIcon(origin)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func appearanceRaceIcon(_ origin: CharacterOrigin) -> some View {
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
                    .font(DarkFantasyTheme.body(size: 9))
                    .foregroundStyle(isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)
            }
        }
        .buttonStyle(.scalePress(0.95))
    }

    // MARK: Race Bonus Widget

    private var appearanceRaceBonusWidget: some View {
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
                            .font(DarkFantasyTheme.section(size: 16))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text(origin.description)
                            .font(DarkFantasyTheme.body(size: 13))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Text(origin.bonuses)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
                .padding(.horizontal, LayoutConstants.bannerPadding)
            } else {
                Text("Select a race to see avatars")
                    .font(DarkFantasyTheme.body(size: 13))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .frame(height: 88)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedOrigin)
    }

    // MARK: Empty State

    private var appearanceEmptyState: some View {
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
                .font(DarkFantasyTheme.body(size: 12))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Avatar Area (gender + arrows + central avatar + dice)

    private var appearanceAvatarArea: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let sideSize: CGFloat = 64
            let avatarSize: CGFloat = min(geo.size.width - sideSize * 2 - spacing * 4, 220)

            HStack(alignment: .center, spacing: spacing) {
                // Left column: gender toggle (top) + left arrow (bottom)
                VStack(spacing: 0) {
                    appearanceSquareButton(content: AnyView(
                        Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                    ), size: sideSize, bg: DarkFantasyTheme.xpRing.opacity(0.1),
                       border: DarkFantasyTheme.xpRing, shadow: DarkFantasyTheme.xpRing.opacity(0.2)) {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.toggleGender() }
                    }
                    Spacer()
                    appearanceSquareButton(content: AnyView(
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

                // Central avatar
                appearanceCentralAvatar(size: avatarSize)

                // Right column: dice (top) + right arrow (bottom)
                VStack(spacing: 0) {
                    appearanceSquareButton(content: AnyView(
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
                    appearanceSquareButton(content: AnyView(
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

    // MARK: Square Button Helper

    @ViewBuilder
    private func appearanceSquareButton(content: AnyView, size: CGFloat, bg: Color, border: Color, shadow: Color, action: @escaping () -> Void) -> some View {
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

    @ViewBuilder
    private func appearanceCentralAvatar(size: CGFloat) -> some View {
        let skins = vm.availableSkins

        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(DarkFantasyTheme.bgSecondary)

            if vm.avatarIndex < skins.count {
                let skin = skins[vm.avatarIndex]
                appearanceSkinImage(skin)
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

    // MARK: Thumbnail Row (separate row under avatar area)

    private var appearanceThumbnailRow: some View {
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

                        appearanceSkinImage(skin)
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

    // MARK: Skin Image Helper

    @ViewBuilder
    private func appearanceSkinImage(_ skin: AppearanceSkin) -> some View {
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

    // MARK: - Step 3: Name

    private var nameStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                // Title
                Text("CHOOSE YOUR NAME")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.top, LayoutConstants.spaceLG)

                // Character preview
                characterPreviewCard

                // Name input with dice
                nameInputField

                // Build summary with bonuses
                if !vm.characterName.isEmpty && vm.characterName.count >= 3 {
                    buildSummary
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // Large centered character preview — matching step 1/2 visual style
    private var characterPreviewCard: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Large centered avatar with glow
            ZStack {
                // Background glow (like class showcase)
                if let cls = vm.selectedClass {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            RadialGradient(
                                colors: [
                                    DarkFantasyTheme.classColor(for: cls).opacity(0.2),
                                    DarkFantasyTheme.bgSecondary.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                }

                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let skin = vm.selectedSkin, UIImage(named: skin.resolvedImageKey) != nil {
                            Image(skin.resolvedImageKey)
                                .resizable()
                                .scaledToFill()
                        } else if let skin = vm.selectedSkin, let url = skin.resolvedImageURL {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                ProgressView().tint(DarkFantasyTheme.textTertiary)
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 56)) // SF Symbol icon — keep as is
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(DarkFantasyTheme.bgTertiary)
                        }
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 3)
                    )
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 20, y: 8)

                    // Level 1 badge
                    Text("1")
                        .font(DarkFantasyTheme.section(size: 13).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(DarkFantasyTheme.gold))
                        .offset(x: 4, y: 4)
                }
            }

            // Origin + Class row
            HStack(spacing: 8) {
                if let origin = vm.selectedOrigin {
                    Image(origin.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(origin.displayName)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                if let cls = vm.selectedClass {
                    Image(cls.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(cls.sfName)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.classColor(for: cls))
                }
            }

            // Stat bonuses — prominent row
            if !vm.combinedBonuses.isEmpty {
                HStack(spacing: 16) {
                    ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                        VStack(spacing: 2) {
                            Text("\(bonus.value > 0 ? "+" : "")\(bonus.value)")
                                .font(DarkFantasyTheme.section(size: 20).bold())
                                .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                            Text(String(bonus.stat.prefix(3)).uppercased())
                                .font(DarkFantasyTheme.body(size: 10))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
            }

            // Gender
            Text(vm.selectedGender.displayName.uppercased())
                .font(DarkFantasyTheme.body(size: 11))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)
        }
        .padding(.vertical, LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity)
    }

    // Task 16: Name input with real-time availability check
    private var nameInputField: some View {
        let borderColor: Color = {
            if vm.characterName.isEmpty { return DarkFantasyTheme.borderSubtle.opacity(0.5) }
            if vm.characterName.count < 3 { return DarkFantasyTheme.danger }
            switch vm.nameAvailability {
            case .available: return DarkFantasyTheme.success
            case .taken: return DarkFantasyTheme.danger
            case .checking: return DarkFantasyTheme.goldDim
            default: return DarkFantasyTheme.goldDim
            }
        }()

        return VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("YOUR NAME")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            HStack(spacing: 0) {
                TextField("", text: $vm.characterName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(nameTextColor)
                    .placeholder(when: vm.characterName.isEmpty) {
                        Text("Enter hero name...")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCard))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: vm.characterName) { _, newValue in
                        if newValue.count > 16 {
                            vm.characterName = String(newValue.prefix(16))
                        }
                        vm.checkNameAvailability()
                    }

                // Availability indicator
                if vm.characterName.count >= 3 {
                    Group {
                        switch vm.nameAvailability {
                        case .checking:
                            ProgressView()
                                .tint(DarkFantasyTheme.goldDim)
                                .scaleEffect(0.8)
                        case .available:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DarkFantasyTheme.success)
                        case .taken:
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DarkFantasyTheme.danger)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(width: 28)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: vm.nameAvailability == .checking)
                }

                // Dice button for random name
                Button {
                    vm.generateRandomName()
                    vm.checkNameAvailability()
                } label: {
                    Image("ui-dice")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.scalePress(0.85))
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .frame(height: LayoutConstants.inputHeight)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Group {
                    if vm.characterName.isEmpty {
                        RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                            .stroke(
                                borderColor,
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    } else {
                        RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                            .stroke(borderColor, lineWidth: 1.5)
                    }
                }
            )

            // Status messages
            HStack {
                Group {
                    if !vm.characterName.isEmpty && vm.characterName.count < 3 {
                        Text("Name must be at least 3 characters")
                            .foregroundStyle(DarkFantasyTheme.textDanger)
                    } else if vm.nameAvailability == .checking {
                        Text("Checking availability...")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    } else if vm.nameAvailability == .available {
                        Text("Name is available!")
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                    } else if vm.nameAvailability == .taken {
                        Text("Name already taken")
                            .foregroundStyle(DarkFantasyTheme.textDanger)
                    }
                }
                Spacer()
                Text("\(vm.characterName.count)/16")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
        }
    }

    /// Name text color: green if available, red if taken or too short, gold while checking
    private var nameTextColor: Color {
        if vm.characterName.isEmpty { return DarkFantasyTheme.textPrimary }
        if vm.characterName.count < 3 { return DarkFantasyTheme.danger }
        switch vm.nameAvailability {
        case .available: return DarkFantasyTheme.success
        case .taken: return DarkFantasyTheme.danger
        case .checking: return DarkFantasyTheme.goldBright
        default: return DarkFantasyTheme.goldBright
        }
    }

    private var buildSummary: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Hero name — large title like class showcase
            Text(vm.characterName.uppercased())
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)

            // Summary line
            Text(vm.heroSummary.uppercased())
                .font(DarkFantasyTheme.section(size: 12))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .tracking(1)

            // Combined bonuses — styled like class bonuses
            if !vm.combinedBonuses.isEmpty {
                HStack(spacing: LayoutConstants.spaceMD) {
                    ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                        Text("\(bonus.value > 0 ? "+" : "")\(bonus.value) \(bonus.stat)")
                            .font(DarkFantasyTheme.section(size: 12))
                            .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Back + Continue / Save
            HStack(spacing: LayoutConstants.spaceMD) {
                if vm.step > 0 {
                    Button {
                        vm.prevStep()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("BACK")
                        }
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: LayoutConstants.buttonHeightLG)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .fill(DarkFantasyTheme.bgSecondary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                        )
                    }
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
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
                    }
                }
                .foregroundStyle(vm.canProceed ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightLG)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(vm.canProceed ? DarkFantasyTheme.gold : DarkFantasyTheme.bgTertiary)
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                .disabled(!vm.canProceed || vm.isCreating)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceLG)
    }
}

// MARK: - Placeholder Extension

private extension View {
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
