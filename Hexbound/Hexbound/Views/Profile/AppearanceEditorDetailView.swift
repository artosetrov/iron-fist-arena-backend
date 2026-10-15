import SwiftUI

/// Appearance editor — "wardrobe" layout: the selected look on top, every
/// skin of the hero's race + gender in one gallery (free, gold and gem skins
/// alike) with filter chips, and one contextual CTA: Equip / Buy / Equipped.
/// Paid skins go through a confirmation sheet that shows the price and the
/// balance after.
struct AppearanceEditorDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: AppearanceEditorViewModel?

    private static let heroSize: CGFloat = 156
    private static let controlSize: CGFloat = 48
    private static let sheetImageSize: CGFloat = 160
    private static let rarityStripe: CGFloat = 3

    private let galleryColumns = Array(
        repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
        count: 3
    )

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                    if vm.isLoadingSkins && vm.allSkins.isEmpty {
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.gold)
                    } else {
                        VStack(spacing: 0) {
                            VStack(spacing: LayoutConstants.sectionGap) {
                                heroRow(vm: vm)
                                filterRow(vm: vm)
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.top, LayoutConstants.spaceSM)
                            .padding(.bottom, LayoutConstants.spaceMS)

                            ScrollView {
                                galleryGrid(vm: vm)
                                    .padding(.horizontal, LayoutConstants.screenPadding)
                                    .padding(.bottom, LayoutConstants.spaceMD)
                            }

                            bottomBar(vm: vm)
                        }
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
                    .font(DarkFantasyTheme.section)
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
                        .font(DarkFantasyTheme.body.weight(.medium))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .accessibilityLabel("Switch hero")
            }
        }
        .sheet(
            isPresented: Binding(
                get: { vm?.showPurchaseSheet ?? false },
                set: { vm?.showPurchaseSheet = $0 }
            ),
            onDismiss: { vm?.purchaseSheetDismissed() }
        ) {
            if let vm {
                purchaseSheet(vm: vm)
                    .presentationDetents([.height(580), .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(DarkFantasyTheme.bgSecondary)
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

    // MARK: - Hero (selected look + race + gender / dice)

    @ViewBuilder
    private func heroRow(vm: AppearanceEditorViewModel) -> some View {
        let skin = vm.selectedSkin
        let rarityColor = skin.map { DarkFantasyTheme.rarityColor(for: $0.itemRarity) } ?? DarkFantasyTheme.gold

        HStack(alignment: .center, spacing: LayoutConstants.spaceMD) {
            ZStack {
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.radiusXL
                )
                if let skin {
                    editorSkinImage(skin)
                        .id(skin.skinKey)
                        .transition(.opacity)
                }
            }
            .frame(width: Self.heroSize, height: Self.heroSize)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXL))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                    .stroke(rarityColor, lineWidth: Self.rarityStripe)
            )
            .cardShadow()
            .animation(.easeInOut(duration: MotionConstants.fast), value: vm.selectedSkinKey)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                if let skin {
                    rarityBadge(skin)
                    Text(skin.displayName)
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                if let origin = vm.selectedOrigin {
                    HStack(alignment: .top, spacing: LayoutConstants.spaceXS) {
                        Image(origin.iconAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                        Text(origin.bonuses)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                            .lineLimit(2)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(origin.displayName): \(origin.bonuses)")
                }

                HStack(spacing: LayoutConstants.spaceSM) {
                    controlButton(
                        asset: vm.selectedGender == .male ? "ui-gender-male" : "ui-gender-female",
                        tint: DarkFantasyTheme.xpRing,
                        label: vm.selectedGender == .male ? "Switch to female looks" : "Switch to male looks"
                    ) {
                        vm.toggleGender()
                    }
                    controlButton(
                        asset: "ui-dice",
                        tint: DarkFantasyTheme.gold,
                        label: "Random owned look",
                        rotation: vm.diceRotation
                    ) {
                        vm.diceRotation += 360
                        vm.randomize()
                    }
                }
                .padding(.top, LayoutConstants.space2XS)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func rarityBadge(_ skin: AppearanceSkin) -> some View {
        let color = DarkFantasyTheme.rarityColor(for: skin.itemRarity)
        return Text(skin.rarity.uppercased())
            .font(DarkFantasyTheme.body.bold())
            .tracking(1)
            .foregroundStyle(color)
            .badgeCapsule(color: color)
    }

    private func controlButton(
        asset: String,
        tint: Color,
        label: String,
        rotation: Double = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                .rotationEffect(.degrees(rotation))
                .animation(MotionConstants.smooth, value: rotation)
                .frame(width: Self.controlSize, height: Self.controlSize)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(tint.opacity(DarkFantasyTheme.opacityLight))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .stroke(tint.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 2)
                )
        }
        .buttonStyle(.scalePress)
        .accessibilityLabel(label)
    }

    // MARK: - Filter Chips

    @ViewBuilder
    private func filterRow(vm: AppearanceEditorViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(SkinFilter.allCases) { item in
                let isActive = vm.filter == item
                Button {
                    vm.filter = item
                } label: {
                    Text("\(item.title) \(vm.count(for: item))")
                        .lineLimit(1)
                }
                .buttonStyle(.colorToggle(isActive: isActive))
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
    }

    // MARK: - Gallery

    @ViewBuilder
    private func galleryGrid(vm: AppearanceEditorViewModel) -> some View {
        let skins = vm.gallerySkins

        if skins.isEmpty {
            VStack(spacing: LayoutConstants.spaceMS) {
                Text(vm.filter == .owned ? "No owned looks for this hero yet" : "No looks in this filter")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("SHOW ALL") {
                    vm.filter = .all
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.gold))
                .frame(maxWidth: 200)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, LayoutConstants.spaceLG)
        } else {
            LazyVGrid(columns: galleryColumns, spacing: LayoutConstants.spaceSM) {
                ForEach(skins) { skin in
                    skinTile(
                        skin,
                        status: vm.status(of: skin),
                        isSelected: vm.selectedSkinKey == skin.skinKey
                    ) {
                        vm.select(skin)
                    }
                }
            }
        }
    }

    private func skinTile(
        _ skin: AppearanceSkin,
        status: SkinStatus,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let rarityColor = DarkFantasyTheme.rarityColor(for: skin.itemRarity)

        return Button(action: action) {
            VStack(spacing: LayoutConstants.spaceXS) {
                // Square slot first, art overlaid — a .fill image can't stretch the tile.
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay { editorSkinImage(skin) }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(rarityColor)
                            .frame(height: Self.rarityStripe)
                    }
                    .background(DarkFantasyTheme.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))

                statusLabel(status)
                    .frame(height: LayoutConstants.iconMD)
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgDarkPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        isSelected ? DarkFantasyTheme.goldBright : rarityColor.opacity(DarkFantasyTheme.opacityStrong),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            )
        }
        .buttonStyle(.scalePress)
        .accessibilityLabel("\(skin.name), \(skin.rarity), \(statusText(status))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func statusLabel(_ status: SkinStatus) -> some View {
        switch status {
        case .gems(let price):
            CurrencyDisplay(gold: 0, gems: price, size: .mini, currencyType: .gems, animated: false)
        case .gold(let price):
            CurrencyDisplay(gold: price, size: .mini, currencyType: .gold, animated: false)
        case .owned:
            Text("Owned")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        case .equipped:
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "checkmark")
                    .font(DarkFantasyTheme.body.bold())
                Text("Equipped")
                    .font(DarkFantasyTheme.body)
            }
            .foregroundStyle(DarkFantasyTheme.textSuccess)
            .lineLimit(1)
        }
    }

    private func statusText(_ status: SkinStatus) -> String {
        switch status {
        case .gems(let price): "\(price) gems"
        case .gold(let price): "\(price) gold"
        case .owned: "owned"
        case .equipped: "equipped"
        }
    }

    // MARK: - Bottom Bar (balance + contextual CTA)

    @ViewBuilder
    private func bottomBar(vm: AppearanceEditorViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let character = appState.currentCharacter {
                HStack {
                    Text("Balance")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer()
                    CurrencyDisplay(gold: character.gold, gems: character.gems ?? 0, size: .mini)
                }
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textDanger)
                    .multilineTextAlignment(.center)
            }

            Button {
                vm.primaryTapped()
            } label: {
                primaryLabel(vm: vm)
            }
            .buttonStyle(.primary(enabled: vm.primaryEnabled))
            .disabled(!vm.primaryEnabled)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceMD)
        .background(
            DarkFantasyTheme.bgPrimary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderSubtle)
                        .frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func primaryLabel(vm: AppearanceEditorViewModel) -> some View {
        if vm.isSaving {
            HexPulseLoader.onGold()
        } else {
            switch vm.selectedStatus ?? .equipped {
            case .gems(let price):
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("BUY FOR")
                    CurrencyDisplay(
                        gold: 0, gems: price, size: .mini, currencyType: .gems,
                        animated: false, textColorOverride: DarkFantasyTheme.textOnGold
                    )
                }
            case .gold(let price):
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("BUY FOR")
                    CurrencyDisplay(
                        gold: price, size: .mini, currencyType: .gold,
                        animated: false, textColorOverride: DarkFantasyTheme.textOnGold
                    )
                }
            case .owned:
                Text("EQUIP")
            case .equipped:
                Text("EQUIPPED")
            }
        }
    }

    // MARK: - Purchase Sheet

    @ViewBuilder
    private func purchaseSheet(vm: AppearanceEditorViewModel) -> some View {
        if let skin = vm.selectedSkin, let status = vm.selectedStatus {
            let rarityColor = DarkFantasyTheme.rarityColor(for: skin.itemRarity)

            VStack(spacing: LayoutConstants.spaceMD) {
                Text("CONFIRM PURCHASE")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.top, LayoutConstants.spaceLG)

                ZStack {
                    RadialGlowBackground(
                        baseColor: DarkFantasyTheme.bgTertiary,
                        glowColor: DarkFantasyTheme.bgSecondary,
                        glowIntensity: 0.3,
                        cornerRadius: LayoutConstants.radiusXL
                    )
                    editorSkinImage(skin)
                }
                .frame(width: Self.sheetImageSize, height: Self.sheetImageSize)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXL))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                        .stroke(rarityColor, lineWidth: Self.rarityStripe)
                )
                .accessibilityHidden(true)

                VStack(spacing: LayoutConstants.spaceXS) {
                    rarityBadge(skin)
                    Text(skin.displayName)
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text("Cosmetic only — stats don't change")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                VStack(spacing: LayoutConstants.spaceSM) {
                    confirmRow("Price") { priceDisplay(status, balance: nil) }
                    confirmRow("Balance after") { priceDisplay(status, balance: balance(for: status)) }
                }
                .padding(LayoutConstants.spaceMD)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .padding(.horizontal, LayoutConstants.spaceMD)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Button("CANCEL") {
                        vm.showPurchaseSheet = false
                    }
                    .buttonStyle(.ghost)

                    Button("BUY & EQUIP") {
                        vm.confirmPurchase()
                    }
                    .buttonStyle(.primary)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)

                Spacer(minLength: 0)
            }
        }
    }

    private func balance(for status: SkinStatus) -> Int {
        let character = appState.currentCharacter
        switch status {
        case .gems(let price): return (character?.gems ?? 0) - price
        case .gold(let price): return (character?.gold ?? 0) - price
        case .equipped, .owned: return 0
        }
    }

    /// `balance == nil` shows the price; otherwise the remaining balance in the same currency.
    @ViewBuilder
    private func priceDisplay(_ status: SkinStatus, balance: Int?) -> some View {
        switch status {
        case .gems(let price):
            CurrencyDisplay(gold: 0, gems: balance ?? price, size: .mini, currencyType: .gems, animated: false)
        case .gold(let price):
            CurrencyDisplay(gold: balance ?? price, size: .mini, currencyType: .gold, animated: false)
        case .equipped, .owned:
            EmptyView()
        }
    }

    private func confirmRow<Content: View>(_ label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            value()
        }
    }

    // MARK: - Skin Image Helper

    private func editorSkinImage(_ skin: AppearanceSkin) -> some View {
        CachedAssetImage(
            key: skin.resolvedImageKey,
            url: skin.imageUrl,
            systemIcon: "person.fill"
        )
    }
}
