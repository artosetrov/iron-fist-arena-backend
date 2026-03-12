import SwiftUI

struct AppearanceEditorDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: AppearanceEditorViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                if vm.isLoadingSkins && vm.allSkins.isEmpty {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: LayoutConstants.spaceLG) {
                            // Section: What you can change
                            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                                Text("CUSTOMIZE YOUR LOOK")
                                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.goldBright)
                                Text("Choose gender and avatar for your character")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, LayoutConstants.spaceMD)

                            // Gender selector — prominent horizontal pills
                            genderPillSelector(vm: vm)

                            // Large avatar preview
                            largeAvatarPreview(vm: vm)

                            // Avatar grid — all available avatars for current gender
                            avatarGrid(vm: vm)

                            // Race portraits row
                            racePortraitsRow(vm: vm)

                            // Race bonuses
                            if let origin = vm.selectedOrigin {
                                raceBonusBar(origin)
                            }

                            // Cost warning
                            if let cost = vm.costText {
                                HStack(spacing: LayoutConstants.spaceSM) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(DarkFantasyTheme.goldBright)
                                    Text("Changing race costs \(cost)")
                                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                                }
                                .padding(LayoutConstants.spaceSM)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                        .fill(DarkFantasyTheme.gold.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                        .stroke(DarkFantasyTheme.goldDim, lineWidth: 1)
                                )
                            }

                            // Error
                            if !vm.errorMessage.isEmpty {
                                Text(vm.errorMessage)
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                    .foregroundStyle(DarkFantasyTheme.textDanger)
                                    .multilineTextAlignment(.center)
                            }

                            // Save button
                            Button {
                                Task { await vm.save() }
                            } label: {
                                if vm.isSaving {
                                    ProgressView().tint(DarkFantasyTheme.textOnGold)
                                } else {
                                    Text("SAVE")
                                }
                            }
                            .buttonStyle(.primary(enabled: vm.canSave))
                            .disabled(!vm.canSave)
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceLG)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("APPEARANCE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
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

    // MARK: - Race Portraits Row

    @ViewBuilder
    private func racePortraitsRow(vm: AppearanceEditorViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(CharacterOrigin.allCases) { origin in
                    racePortrait(origin, vm: vm)
                }
            }
            .padding(.top, LayoutConstants.spaceMD)
        }
    }

    @ViewBuilder
    private func racePortrait(_ origin: CharacterOrigin, vm: AppearanceEditorViewModel) -> some View {
        let isSelected = vm.selectedOrigin == origin
        let size: CGFloat = 60

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.jumpToOrigin(origin)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)

                Text(origin.icon)
                    .font(.system(size: 28))
            }
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(
                        isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Gender Pill Selector

    @ViewBuilder
    private func genderPillSelector(vm: AppearanceEditorViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(CharacterGender.allCases) { gender in
                let isSelected = vm.selectedGender == gender
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.selectedGender = gender
                        vm.onGenderChanged()
                    }
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Text(gender.icon)
                            .font(.system(size: 20))
                        Text(gender == .male ? "MALE" : "FEMALE")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    }
                    .foregroundStyle(isSelected ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightMD)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2 : 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            // Dice / random
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.randomize()
                }
            } label: {
                Image(systemName: "dice.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .frame(width: LayoutConstants.buttonHeightMD, height: LayoutConstants.buttonHeightMD)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Avatar Grid (all available for current gender)

    @ViewBuilder
    private func avatarGrid(vm: AppearanceEditorViewModel) -> some View {
        let skins = vm.browsableSkins

        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("CHOOSE AVATAR")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            if skins.isEmpty {
                Text("No avatars available")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceLG)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM), count: 4),
                    spacing: LayoutConstants.spaceSM
                ) {
                    ForEach(Array(skins.enumerated()), id: \.element.id) { index, skin in
                        let isSelected = vm.selectedSkinIndex == index
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                vm.selectedSkinIndex = index
                                vm.selectedSkinKey = skin.skinKey
                                if let origin = CharacterOrigin(rawValue: skin.origin) {
                                    vm.selectedOrigin = origin
                                }
                            }
                        } label: {
                            avatarGridCell(skin: skin, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func avatarGridCell(skin: AppearanceSkin, isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(isSelected ? DarkFantasyTheme.bgElevated : DarkFantasyTheme.bgSecondary)

            if let localImage = UIImage(named: "avatar_\(skin.skinKey)") {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius - 2))
            } else if let url = skin.resolvedImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius - 2))
                    default:
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                    lineWidth: isSelected ? 2.5 : 1
                )
        )
        .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 6)
        .overlay(alignment: .bottom) {
            Text(skin.displayName)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.5))
                .clipShape(.rect(
                    topLeadingRadius: 0, bottomLeadingRadius: LayoutConstants.panelRadius,
                    bottomTrailingRadius: LayoutConstants.panelRadius, topTrailingRadius: 0
                ))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Large Avatar Preview

    @ViewBuilder
    private func largeAvatarPreview(vm: AppearanceEditorViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)

                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)

                if let skin = vm.selectedSkin {
                    if let localImage = UIImage(named: "avatar_\(skin.skinKey)") {
                        Image(uiImage: localImage)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .cornerRadius(LayoutConstants.panelRadius)
                    } else if let url = skin.resolvedImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .cornerRadius(LayoutConstants.panelRadius)
                            case .failure:
                                skinPreviewPlaceholder(skin)
                            case .empty:
                                ProgressView()
                                    .tint(DarkFantasyTheme.textTertiary)
                            @unknown default:
                                skinPreviewPlaceholder(skin)
                            }
                        }
                    } else {
                        skinPreviewPlaceholder(skin)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("No skins")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }

                // Gold border overlay for selected feel
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.goldDim, lineWidth: 2)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 200)
            .shadow(color: DarkFantasyTheme.goldGlow.opacity(0.3), radius: 8)

            // Skin name label
            if let skin = vm.selectedSkin {
                Text(skin.displayName.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .lineLimit(1)
            }

            // Skin counter
            if vm.totalBrowsableCount > 0 {
                Text("\(vm.selectedSkinIndex + 1) / \(vm.totalBrowsableCount)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func skinPreviewPlaceholder(_ skin: AppearanceSkin) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(skin.displayName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
        }
    }

    // MARK: - Race Bonus Bar

    @ViewBuilder
    private func raceBonusBar(_ origin: CharacterOrigin) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Text(origin.icon)
                .font(.system(size: 16))
            Text(origin.description)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(2)
            Spacer()
            Text(origin.bonuses)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textSuccess)
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
