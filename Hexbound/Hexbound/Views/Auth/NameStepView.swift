import SwiftUI

/// Onboarding Step 3: Name input with character preview and build summary.
struct NameStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                Text("Choose Your Name")
                    .font(DarkFantasyTheme.title(size: 14))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(1)
                    .padding(.top, LayoutConstants.spaceLG)

                // Unified card: avatar + info + stats
                unifiedCharacterCard

                // Name input with separate dice button
                nameInputSection
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Unified Character Card (avatar + summary merged)

    private var unifiedCharacterCard: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Avatar with level badge
            ZStack {
                if let cls = vm.selectedClass {
                    RoundedRectangle(cornerRadius: LayoutConstants.radius2XL)
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
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radius2XL))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radius2XL)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 3)
                    )
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.2), radius: 20, y: 8)

                    Text("1")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(DarkFantasyTheme.gold))
                        .offset(x: 4, y: 4)
                }
            }

            // Origin + Class row
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

            // Gender
            Text(vm.selectedGender.displayName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)

            // Divider
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceLG)

            // Build summary: hero summary + stat bonuses (name shown only in input field)
            VStack(spacing: LayoutConstants.spaceSM) {
                Text(vm.heroSummary)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                if !vm.combinedBonuses.isEmpty {
                    HStack(spacing: LayoutConstants.spaceMD) {
                        ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                            Text("\(bonus.value > 0 ? "+" : "")\(bonus.value) \(bonus.stat)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                                .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                        }
                    }
                    .padding(.top, 2)
                }
            }
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
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
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
                .buttonStyle(.scalePress(0.85))
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
