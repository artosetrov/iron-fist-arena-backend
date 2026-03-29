import SwiftUI

struct AppearanceEditorDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: AppearanceEditorViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                if vm.isLoadingSkins && vm.allSkins.isEmpty {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else {
                    VStack(spacing: 0) {
                        // Title
                        Text("CHOOSE YOUR APPEARANCE")
                            .font(DarkFantasyTheme.title(size: 16))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .tracking(2)
                            .padding(.top, LayoutConstants.spaceMD)

                        // Thumbnail previews — ABOVE main avatar
                        editorThumbnailRow(vm: vm)
                            .padding(.top, LayoutConstants.spaceMD)

                        editorAvatarArea(vm: vm)
                            .padding(.top, LayoutConstants.spaceSM)

                        // Race info widget — BELOW avatar (read-only)
                        editorRaceBonusWidget(vm: vm)
                            .padding(.top, LayoutConstants.spaceMD)

                        // Premium avatars button
                        if !vm.premiumSkins.isEmpty {
                            editorPremiumButton(vm: vm)
                                .padding(.top, LayoutConstants.spaceMD)
                        }

                        Spacer(minLength: LayoutConstants.spaceLG)

                        // Error
                        if !vm.errorMessage.isEmpty {
                            Text(vm.errorMessage)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textDanger)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, LayoutConstants.spaceSM)
                        }

                        // Save button with gold cost
                        Button {
                            Task { await vm.save() }
                        } label: {
                            if vm.isSaving {
                                ProgressView().tint(DarkFantasyTheme.textOnGold)
                            } else {
                                HStack(spacing: LayoutConstants.spaceXS) {
                                    Text("SAVE")
                                    if let cost = vm.costText {
                                        Text("(\(cost))")
                                            .font(DarkFantasyTheme.body(size: 13))
                                            .foregroundStyle(DarkFantasyTheme.goldBright)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.primary(enabled: vm.canSave))
                        .disabled(!vm.canSave)
                        .padding(.bottom, LayoutConstants.spaceLG)
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("APPEARANCE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    appState.mainPath = NavigationPath()
                    appState.currentScreen = .characterSelect
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
        }
        .onAppear {
            if vm == nil {
                let newVM = AppearanceEditorViewModel(appState: appState, cache: cache)
                vm = newVM
                Task { await newVM.fetchSkins() }
            }
        }
        .onChange(of: vm?.didSave ?? false) { _, saved in
            if saved { if !appState.mainPath.isEmpty { appState.mainPath.removeLast() } }
        }
    }

    // MARK: - Race Info Widget (read-only)

    @ViewBuilder
    private func editorRaceBonusWidget(vm: AppearanceEditorViewModel) -> some View {
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
                HStack(spacing: LayoutConstants.spaceMS) {
                    Image(origin.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
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
            }
        }
        .frame(height: 88)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: vm.selectedOrigin)
    }

    // MARK: - Premium Avatars Button

    @ViewBuilder
    private func editorPremiumButton(vm: AppearanceEditorViewModel) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                vm.showPremiumSkins.toggle()
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceMS) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16)) // SF Symbol icon — keep as is
                    .foregroundStyle(DarkFantasyTheme.premiumPink)

                Text("PREMIUM AVATARS")
                    .font(DarkFantasyTheme.section(size: 14))
                    .foregroundStyle(DarkFantasyTheme.premiumPink)

                Spacer()

                Image(systemName: vm.showPremiumSkins ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold)) // SF Symbol icon — keep as is
                    .foregroundStyle(DarkFantasyTheme.premiumPink.opacity(0.6))
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgPremium)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.premiumPink.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.scalePress)

        if vm.showPremiumSkins {
            editorPremiumGrid(vm: vm)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private func editorPremiumGrid(vm: AppearanceEditorViewModel) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM), count: 4)

        LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
            ForEach(vm.premiumSkins) { skin in
                let isSelected = vm.selectedSkinKey == skin.skinKey

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedSkinKey = skin.skinKey
                        vm.slideDirection = .none
                        // Sync avatar index to show in main preview
                        if let idx = vm.availableSkins.firstIndex(where: { $0.skinKey == skin.skinKey }) {
                            vm.avatarIndex = idx
                        }
                    }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                                .fill(DarkFantasyTheme.bgPremiumDeep)

                            editorSkinImage(skin)
                                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                                .stroke(isSelected ? DarkFantasyTheme.premiumPink : DarkFantasyTheme.borderPremium, lineWidth: 2)
                        )

                        // Gem price badge
                        HStack(spacing: LayoutConstants.space2XS) {
                            Image("icon-gems")
                                .resizable()
                                .frame(width: 8, height: 8)
                            Text("\(skin.priceGems)")
                                .font(DarkFantasyTheme.body(size: 10))
                        }
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(
                            Capsule().fill(DarkFantasyTheme.premiumPink.opacity(0.8))
                        )
                        .offset(x: -4, y: -4)
                    }
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Avatar Area (gender + arrows + central avatar + dice)

    @ViewBuilder
    private func editorAvatarArea(vm: AppearanceEditorViewModel) -> some View {
        GeometryReader { geo in
            let spacing: CGFloat = 8
            let sideSize: CGFloat = 64
            let avatarSize: CGFloat = max(min(geo.size.width - sideSize * 2 - spacing * 4, 220), 0)

            HStack(alignment: .center, spacing: spacing) {
                // Left column: gender toggle (top) + left arrow (bottom)
                VStack(spacing: 0) {
                    editorSquareButton(content: AnyView(
                        Image(vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sideSize * 0.6, height: sideSize * 0.6)
                    ), size: sideSize, bg: DarkFantasyTheme.xpRing.opacity(0.1),
                       border: DarkFantasyTheme.xpRing, shadow: DarkFantasyTheme.xpRing.opacity(0.2)) {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.toggleGender() }
                    }
                    Spacer()
                    editorSquareButton(content: AnyView(
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
                editorCentralAvatar(vm: vm, size: avatarSize)

                // Right column: dice (top) + right arrow (bottom)
                VStack(spacing: 0) {
                    editorSquareButton(content: AnyView(
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
                    editorSquareButton(content: AnyView(
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
    private func editorSquareButton(content: AnyView, size: CGFloat, bg: Color, border: Color, shadow: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            content
                .frame(width: size, height: size)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(bg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .stroke(border, lineWidth: 2)
                )
                .shadow(color: shadow, radius: 5)
        }
        .buttonStyle(.scalePress)
    }

    @ViewBuilder
    private func editorCentralAvatar(vm: AppearanceEditorViewModel, size: CGFloat) -> some View {
        let isPremium = vm.selectedSkin.map { !$0.isDefault } ?? false
        let borderColor = isPremium ? DarkFantasyTheme.premiumPink : DarkFantasyTheme.gold

        ZStack {
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radius2XL
            )

            if let skin = vm.selectedSkin {
                editorSkinImage(skin)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radius2XL))
                    .id(skin.skinKey)
                    .transition(editorAvatarTransition(vm: vm))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radius2XL)
                .stroke(borderColor, lineWidth: 3)
        )
        .shadow(color: borderColor.opacity(0.2), radius: 20, y: 8)
        .animation(.easeInOut(duration: 0.25), value: vm.selectedSkinKey)
    }

    private func editorAvatarTransition(vm: AppearanceEditorViewModel) -> AnyTransition {
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

    // MARK: - Thumbnail Row (separate row under avatar area)

    @ViewBuilder
    private func editorThumbnailRow(vm: AppearanceEditorViewModel) -> some View {
        let skins = vm.defaultSkins

        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(Array(skins.enumerated()), id: \.element.id) { index, skin in
                let isSelected = vm.avatarIndex == index

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectAvatar(at: index)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                            .fill(DarkFantasyTheme.bgDarkPanel)

                        editorSkinImage(skin)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? DarkFantasyTheme.gold.opacity(0.25) : .clear, radius: 5)
                }
                .buttonStyle(.scalePress(0.95))
            }
        }
    }

    // MARK: - Skin Image Helper

    private func editorSkinImage(_ skin: AppearanceSkin) -> some View {
        CachedAssetImage(
            key: skin.resolvedImageKey,
            url: skin.imageUrl,
            fallback: "🧑"
        )
    }
}