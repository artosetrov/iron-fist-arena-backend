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
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                } else {
                    Text("\(number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
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
                // Large class showcase area
                classShowcase(selectedClass)
                    .padding(.top, LayoutConstants.spaceMD)

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
                    .frame(height: 200)

                // Class icon
                Text(charClass.icon)
                    .font(.system(size: 80))
                    .shadow(color: DarkFantasyTheme.classColor(for: charClass).opacity(0.5), radius: 20)

                // Avatar image overlay (if exists)
                if let skin = vm.selectedSkin {
                    if UIImage(named: skin.resolvedImageKey) != nil {
                        Image(skin.resolvedImageKey)
                            .resizable().scaledToFit()
                            .frame(height: 180)
                    } else if let url = skin.resolvedImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(height: 180)
                    }
                }
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.gold)
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.gold)
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
            Text(charClass.icon)
                .font(.system(size: 24))
        }
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Step 2: Appearance (Race + Gender + Avatar)

    private var appearanceStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceLG) {
                // Title
                Text("CHOOSE YOUR APPEARANCE")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.top, LayoutConstants.spaceMD)

                // Race selection (horizontal scroll)
                raceSelector

                // Gender toggle + Dice
                genderAndDiceRow

                // Avatar grid
                avatarGrid

                // Selected skin preview
                if let skin = vm.selectedSkin {
                    selectedSkinPreview(skin)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    private var raceSelector: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text("RACE")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Full-width race rows
            VStack(spacing: 6) {
                ForEach(CharacterOrigin.allCases) { origin in
                    raceRow(origin)
                }
            }

            // Race stats panel (Task 23: prominent stats)
            if let origin = vm.selectedOrigin {
                raceStatsPanel(origin)
            }
        }
    }

    @ViewBuilder
    private func raceRow(_ origin: CharacterOrigin) -> some View {
        let isSelected = vm.selectedOrigin == origin

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedOrigin = origin
                vm.onOriginChanged()
            }
        } label: {
            HStack(spacing: 12) {
                Text(origin.icon)
                    .font(.system(size: 28))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(origin.displayName)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(isSelected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                    Text(origin.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(isSelected ? DarkFantasyTheme.gold.opacity(0.1) : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Task 23: Large, prominent race stats
    @ViewBuilder
    private func raceStatsPanel(_ origin: CharacterOrigin) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: 6) {
                Text(origin.icon)
                    .font(.system(size: 20))
                Text(origin.displayName)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("BONUSES")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            // Parse bonus string into structured display
            let bonusParts = origin.bonuses.components(separatedBy: "  ")
            HStack(spacing: 0) {
                ForEach(Array(bonusParts.enumerated()), id: \.offset) { _, part in
                    let trimmed = part.trimmingCharacters(in: .whitespaces)
                    VStack(spacing: 4) {
                        Text(String(trimmed.prefix(while: { $0 == "+" || $0 == "-" || $0.isNumber })))
                            .font(DarkFantasyTheme.title(size: 24))
                            .foregroundStyle(trimmed.hasPrefix("-") ? DarkFantasyTheme.textDanger : DarkFantasyTheme.textSuccess)
                        Text(String(trimmed.drop(while: { $0 == "+" || $0 == "-" || $0.isNumber || $0 == " " })))
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private var genderAndDiceRow: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Gender icon toggle (Task 20: icons only)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(CharacterGender.allCases) { gender in
                    let isSelected = vm.selectedGender == gender

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.selectedGender = gender
                            vm.onGenderChanged()
                        }
                    } label: {
                        Image(systemName: gender == .male ? "figure.stand" : "figure.stand.dress")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(isSelected ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                    .fill(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.bgSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                                    .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2 : 1)
                            )
                            .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Random dice button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.randomize()
                }
            } label: {
                Image(systemName: "dice.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .fill(DarkFantasyTheme.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var avatarGrid: some View {
        let skins = vm.availableSkins
        let columns = [
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
            GridItem(.flexible(), spacing: LayoutConstants.spaceSM)
        ]

        return LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
            ForEach(skins) { skin in
                skinThumbnail(skin)
            }
        }
    }

    @ViewBuilder
    private func skinThumbnail(_ skin: AppearanceSkin) -> some View {
        let isSelected = vm.selectedSkinKey == skin.skinKey

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedSkinKey = skin.skinKey
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgTertiary)

                // Skin image — prefer local asset
                if UIImage(named: skin.resolvedImageKey) != nil {
                    Image(skin.resolvedImageKey)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(LayoutConstants.panelRadius)
                } else if let url = skin.resolvedImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .clipped()
                            .cornerRadius(LayoutConstants.panelRadius)
                    } placeholder: {
                        ProgressView().tint(DarkFantasyTheme.textTertiary)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text(skin.displayName)
                            .font(DarkFantasyTheme.body(size: 8))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2.5 : 1)
            )
            .shadow(color: isSelected ? DarkFantasyTheme.goldGlow : .clear, radius: 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Task 21: Square centered avatar preview — main visual accent
    @ViewBuilder
    private func selectedSkinPreview(_ skin: AppearanceSkin) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)

                if UIImage(named: skin.resolvedImageKey) != nil {
                    Image(skin.resolvedImageKey)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipped()
                } else if let url = skin.resolvedImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipped()
                    } placeholder: {
                        ProgressView().tint(DarkFantasyTheme.textTertiary)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.gold, lineWidth: 2)
            )
            .shadow(color: DarkFantasyTheme.goldGlow, radius: 12)

            Text(skin.displayName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.goldBright)
        }
        .frame(maxWidth: .infinity)
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

    // Task 24: Full character card like Hub, showing avatar + stats + class/origin
    private var characterPreviewCard: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar — square with gold border
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
                            .font(.system(size: 32))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DarkFantasyTheme.bgTertiary)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 2.5)
                )

                // Level 1 badge
                Text("1")
                    .font(DarkFantasyTheme.section(size: 11).bold())
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(DarkFantasyTheme.gold))
                    .offset(x: 4, y: 4)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Origin + Class
                HStack(spacing: 6) {
                    if let origin = vm.selectedOrigin {
                        Text(origin.icon)
                        Text(origin.displayName)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    if let cls = vm.selectedClass {
                        Text(cls.icon)
                        Text(cls.sfName)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.classColor(for: cls))
                    }
                }

                // Combined bonuses
                if !vm.combinedBonuses.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(vm.combinedBonuses.prefix(4), id: \.stat) { bonus in
                            VStack(spacing: 1) {
                                Text("\(bonus.value > 0 ? "+" : "")\(bonus.value)")
                                    .font(DarkFantasyTheme.section(size: 14).bold())
                                    .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                                Text(String(bonus.stat.prefix(3)).uppercased())
                                    .font(DarkFantasyTheme.body(size: 9))
                                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                            }
                        }
                    }
                }

                // Gender display
                if let gender = vm.selectedGender {
                    Text(gender.displayName)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
        )
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
                    .foregroundStyle(
                        vm.characterName.count >= 3 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textDanger
                    )
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
                    Image(systemName: "dice.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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

    private var buildSummary: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(vm.characterName.uppercased())
                .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.goldBright)

            Text(vm.heroSummary)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Combined bonuses
            if !vm.combinedBonuses.isEmpty {
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(vm.combinedBonuses, id: \.stat) { bonus in
                        Text("\(bonus.value > 0 ? "+" : "")\(bonus.value) \(bonus.stat)")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                            .foregroundStyle(bonus.value > 0 ? DarkFantasyTheme.textSuccess : DarkFantasyTheme.textDanger)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
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
