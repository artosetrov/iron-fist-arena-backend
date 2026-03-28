import SwiftUI

/// Onboarding Step 3: Name input with hero preview card.
struct NameStepView: View {
    @Bindable var vm: OnboardingViewModel
    @State private var glowPhase: CGFloat = 0

    private var classColor: Color {
        if let cls = vm.selectedClass {
            return DarkFantasyTheme.classColor(for: cls)
        }
        return DarkFantasyTheme.gold
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                Text("Choose Your Name")
                    .font(DarkFantasyTheme.title(size: 14))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(1)
                    .padding(.top, LayoutConstants.spaceLG)

                // Hero preview card (arena-style)
                heroPreviewCard
                    .frame(maxWidth: 220)
                    .frame(maxWidth: .infinity)

                // Stat bonuses below the card
                if !vm.combinedBonuses.isEmpty {
                    statBonusGrid
                }

                // Name input with separate dice button
                nameInputSection
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                glowPhase = 360
            }
        }
        .onDisappear {
            glowPhase = 0
        }
    }

    // MARK: - Hero Preview Card (Arena-Style)

    private var heroPreviewCard: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 1.4

            ZStack {
                // 1. Full-bleed avatar
                avatarImage(width: width, height: height)

                // 2. Vignette
                vignetteOverlay(width: width, height: height)

                // 3. Content overlay
                VStack {
                    topBadges
                    Spacer()
                    bottomInfoStack
                }
                .padding(LayoutConstants.spaceSM + 2)
                .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .background(DarkFantasyTheme.bgAbyss)
            .overlay(animatedBorderGlow)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
            .shadow(color: classColor.opacity(0.3), radius: LayoutConstants.arenaGlowRadius, y: 3)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        }
        .aspectRatio(1.0 / 1.4, contentMode: .fit)
    }

    // MARK: - Avatar Image

    @ViewBuilder
    private func avatarImage(width: CGFloat, height: CGFloat) -> some View {
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
                    .font(.system(size: 56))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DarkFantasyTheme.bgTertiary)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    // MARK: - Vignette

    private func vignetteOverlay(width: CGFloat, height: CGFloat) -> some View {
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

    private var topBadges: some View {
        HStack {
            // Level circle
            Text("1")
                .font(DarkFantasyTheme.section(size: 12))
                .foregroundStyle(classColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(Circle().stroke(classColor.opacity(0.5), lineWidth: 1.5))
                )

            Spacer()

            // Class pill
            if let cls = vm.selectedClass {
                Text(cls.displayName.uppercased())
                    .font(DarkFantasyTheme.body(size: 10).bold())
                    .foregroundStyle(classColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(classColor.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(classColor.opacity(0.25), lineWidth: 0.5)
                            )
                    )
            }
        }
    }

    // MARK: - Bottom Info

    private var bottomInfoStack: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Build summary
            Text(vm.heroSummary)
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Origin pill
            if let origin = vm.selectedOrigin {
                HStack(spacing: 4) {
                    Image(origin.iconAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text(origin.displayName.uppercased())
                        .font(DarkFantasyTheme.body(size: 10).bold())
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(DarkFantasyTheme.borderSubtle.opacity(0.3), lineWidth: 0.5)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Animated Border Glow

    private var animatedBorderGlow: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        classColor.opacity(0.6),
                        classColor.opacity(0.1),
                        classColor.opacity(0.4),
                        classColor.opacity(0.05),
                        classColor.opacity(0.6)
                    ],
                    center: .center,
                    startAngle: .degrees(glowPhase),
                    endAngle: .degrees(glowPhase + 360)
                ),
                lineWidth: 2
            )
            .overlay(
                CornerBracketOverlay(
                    color: classColor.opacity(0.6),
                    length: 14,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: classColor.opacity(0.5),
                    size: 5
                )
            )
    }

    // MARK: - Stat Bonus Grid

    private var statBonusGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: LayoutConstants.spaceXS
        ) {
            ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                statBonusCell(name: bonus.stat, value: bonus.value)
            }
        }
    }

    // MARK: - Name Input Section (input + dice button)

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("Your Name")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            HStack(spacing: LayoutConstants.spaceSM) {
                // Text field with status icon
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
                                    inputBorderColor,
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                )
                        } else {
                            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                .stroke(inputBorderColor, lineWidth: 1.5)
                        }
                    }
                )

                // Dice button — separate, clearly tappable
                Button {
                    HapticManager.light()
                    SFXManager.shared.play(.uiTap)
                    vm.generateRandomName()
                    vm.checkNameAvailability()
                } label: {
                    Image("ui-dice")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(width: LayoutConstants.inputHeight, height: LayoutConstants.inputHeight)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1.5)
                )
                .buttonStyle(.plain)
            }

            // Status text + counter
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

    // MARK: - Stat Bonus Cell

    @ViewBuilder
    private func statBonusCell(name: String, value: Int) -> some View {
        let statType = StatType.allCases.first(where: { $0.fullName == name })
        let color = value > 0 ? DarkFantasyTheme.statBoosted : DarkFantasyTheme.textDanger

        HStack(spacing: LayoutConstants.spaceXS) {
            if let statType {
                Image(statType.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }

            Text(name)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 2)

            Text("\(value > 0 ? "+" : "")\(value)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel).bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, LayoutConstants.spaceXS + 2)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(value > 0 ? DarkFantasyTheme.gold.opacity(0.25) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var inputBorderColor: Color {
        if vm.characterName.isEmpty { return DarkFantasyTheme.borderSubtle.opacity(0.5) }
        if vm.characterName.count < 3 { return DarkFantasyTheme.danger }
        switch vm.nameAvailability {
        case .available: return DarkFantasyTheme.success
        case .taken: return DarkFantasyTheme.danger
        case .checking: return DarkFantasyTheme.goldDim
        default: return DarkFantasyTheme.goldDim
        }
    }

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
}
