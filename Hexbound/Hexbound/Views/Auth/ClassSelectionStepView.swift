import SwiftUI

/// Onboarding Step 1: Class selection with showcase + carousel.
struct ClassSelectionStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("CHOOSE A CLASS")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .padding(.top, LayoutConstants.spaceLG)

            if let selectedClass = vm.selectedClass {
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

                classCarousel
                    .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
    }

    // MARK: - Class Showcase (Unified Card)

    @ViewBuilder
    private func classShowcase(_ charClass: CharacterClass) -> some View {
        let accentColor = DarkFantasyTheme.classColor(for: charClass)

        VStack(spacing: LayoutConstants.spaceXS) {
            // Icon — inside the card, slightly larger
            ZStack {
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.25),
                        DarkFantasyTheme.bgSecondary.opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 110
                )

                Image(charClass.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: accentColor.opacity(0.5), radius: 16)
            }
            .frame(height: 170)

            // Class name
            Text(charClass.sfName)
                .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            // Main attribute pill
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("MAIN ATTRIBUTE")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("–")
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text(charClass.mainAttribute)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            Text(charClass.mainAttributeDescription)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(charClass.bonuses)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSuccess)

            // Stat distribution bars
            classStatBars(charClass)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: accentColor.opacity(0.08))
        .cornerBrackets(color: accentColor.opacity(0.3), length: 14, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Class Carousel

    private var classCarousel: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button { vm.selectPreviousClass() } label: {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.scalePress)
            .accessibilityLabel("Previous class")

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(CharacterClass.allCases.enumerated()), id: \.element.id) { index, charClass in
                    classMedallion(charClass, isSelected: vm.selectedClass == charClass)
                        .onTapGesture {
                            vm.selectClass(at: index)
                        }
                }
            }

            Button { vm.selectNextClass() } label: {
                Image("ui-arrow-right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.scalePress)
            .accessibilityLabel("Next class")
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Class Medallion

    @ViewBuilder
    private func classMedallion(_ charClass: CharacterClass, isSelected: Bool) -> some View {
        let color = DarkFantasyTheme.classColor(for: charClass)

        ZStack {
            Circle()
                .fill(isSelected ? color.opacity(0.2) : DarkFantasyTheme.bgSecondary)
                .frame(width: 56, height: 56)

            Circle()
                .stroke(isSelected ? color : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2.5 : 1)
                .frame(width: 56, height: 56)

            Image(charClass.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        }
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        .opacity(isSelected ? 1.0 : 0.6)
    }

    // MARK: - Class Stat Bars

    /// Stat distribution bars showing each class's starting stat profile.
    /// Base stats are 5 for all, with class bonuses (+3, +2) applied.
    @ViewBuilder
    private func classStatBars(_ charClass: CharacterClass) -> some View {
        let stats = classStatProfile(charClass)

        VStack(spacing: 5) {
            ForEach(stats, id: \.name) { stat in
                GeometryReader { geo in
                    let isBoosted = stat.value > 5
                    let fillWidth = geo.size.width * min(1, max(0, CGFloat(stat.value) / 10.0))

                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 5)
                            .fill(DarkFantasyTheme.bgTertiary)

                        // Fill — unified gold gradient
                        RoundedRectangle(cornerRadius: 5)
                            .fill(DarkFantasyTheme.statBarGradient(value: stat.value))
                            .frame(width: fillWidth)
                            .overlay(
                                BarFillHighlight(cornerRadius: 5)
                            )

                        // Stat name inside the bar (left-aligned)
                        // Dark text on gold fill for WCAG AA contrast
                        Text(stat.name)
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                            .foregroundStyle(DarkFantasyTheme.textOnGold)
                            .shadow(color: Color.white.opacity(0.08), radius: 1, x: 0, y: 1)
                            .padding(.leading, 8)

                        // Value on the right — bright for boosted, white for base
                        Text("\(stat.value)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                            .foregroundStyle(isBoosted ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                }
                .frame(height: 22)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.classColor(for: charClass).opacity(0.08)
        )
    }

    // MARK: - Stat Profile Data

    private struct StatEntry: Identifiable {
        let name: String
        let abbreviation: String
        let value: Int
        var id: String { name }
    }

    private func classStatProfile(_ charClass: CharacterClass) -> [StatEntry] {
        // Base 5 for all stats, then apply class bonuses
        let bonuses: [String: Int] = {
            switch charClass {
            case .warrior: return ["STR": 3, "VIT": 2]
            case .rogue:   return ["AGI": 3, "LUK": 2]
            case .mage:    return ["INT": 3, "WIS": 2]
            case .tank:    return ["VIT": 3, "END": 2]
            }
        }()

        let allStats: [(name: String, abbr: String)] = [
            ("Strength",     "STR"),
            ("Agility",      "AGI"),
            ("Vitality",     "VIT"),
            ("Endurance",    "END"),
            ("Intelligence", "INT"),
            ("Wisdom",       "WIS"),
            ("Luck",         "LUK"),
        ]

        return allStats.map { stat in
            let base = 5
            let bonus = bonuses[stat.abbr] ?? 0
            return StatEntry(
                name: stat.name,
                abbreviation: stat.abbr,
                value: base + bonus
            )
        }
    }
}
