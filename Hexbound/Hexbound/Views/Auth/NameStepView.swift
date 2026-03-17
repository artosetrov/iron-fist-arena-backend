import SwiftUI

/// Onboarding Step 3: Name input with character preview and build summary.
struct NameStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                Text("CHOOSE YOUR NAME")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.top, LayoutConstants.spaceLG)

                characterPreviewCard

                nameInputField

                if !vm.characterName.isEmpty && vm.characterName.count >= 3 {
                    buildSummary
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Character Preview Card

    private var characterPreviewCard: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ZStack {
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

                    Text("1")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel).bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(DarkFantasyTheme.gold))
                        .offset(x: 4, y: 4)
                }
            }

            HStack(spacing: 8) {
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

            if !vm.combinedBonuses.isEmpty {
                HStack(spacing: 16) {
                    ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                        VStack(spacing: 2) {
                            Text("\(bonus.value > 0 ? "+" : "")\(bonus.value)")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textSection).bold())
                                .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                            Text(String(bonus.stat.prefix(3)).uppercased())
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
            }

            Text(vm.selectedGender.displayName.uppercased())
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)
        }
        .padding(.vertical, LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Name Input Field

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

    // MARK: - Build Summary

    private var buildSummary: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(vm.characterName.uppercased())
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)

            Text(vm.heroSummary.uppercased())
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .tracking(1)

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
}
