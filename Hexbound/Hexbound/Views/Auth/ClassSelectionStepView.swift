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

    // MARK: - Class Showcase

    @ViewBuilder
    private func classShowcase(_ charClass: CharacterClass) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ZStack {
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

                Image(charClass.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 256, height: 256)
                    .shadow(color: DarkFantasyTheme.classColor(for: charClass).opacity(0.5), radius: 20)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text(charClass.sfName)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("MAIN ATTRIBUTE")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("–")
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text(charClass.mainAttribute)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                Text(charClass.mainAttributeDescription)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Text(charClass.bonuses)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSuccess)
                    .padding(.top, LayoutConstants.space2XS)

                // Stat distribution bars
                classStatBars(charClass)
                    .padding(.top, LayoutConstants.spaceSM)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Class Carousel

    private var classCarousel: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button { vm.selectPreviousClass() } label: {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 36, height: 36)
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
                    .frame(width: 36, height: 36)
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

        VStack(spacing: 4) {
            ForEach(stats, id: \.name) { stat in
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(stat.abbreviation)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(stat.color)
                        .frame(width: 32, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DarkFantasyTheme.bgTertiary)

                            // Fill — proportional to stat value (max 10 for display)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [stat.color.opacity(0.7), stat.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(1, max(0, CGFloat(stat.value) / 10.0)))
                                .overlay(
                                    // Top edge highlight (ornamental)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.08), Color.clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 3)
                                        .frame(maxHeight: .infinity, alignment: .top),
                                    alignment: .top
                                )
                        }
                    }
                    .frame(height: 8)

                    Text("\(stat.value)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(stat.value > 5 ? stat.color : DarkFantasyTheme.textTertiary)
                        .frame(width: 20, alignment: .leading)
                }
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
        let color: Color
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

        let allStats: [(name: String, abbr: String, color: Color)] = [
            ("Strength",     "STR", DarkFantasyTheme.statSTR),
            ("Agility",      "AGI", DarkFantasyTheme.statAGI),
            ("Vitality",     "VIT", DarkFantasyTheme.statVIT),
            ("Endurance",    "END", DarkFantasyTheme.statEND),
            ("Intelligence", "INT", DarkFantasyTheme.statINT),
            ("Wisdom",       "WIS", DarkFantasyTheme.statWIS),
            ("Luck",         "LUK", DarkFantasyTheme.statLUK),
        ]

        return allStats.map { stat in
            let base = 5
            let bonus = bonuses[stat.abbr] ?? 0
            return StatEntry(
                name: stat.name,
                abbreviation: stat.abbr,
                value: base + bonus,
                color: stat.color
            )
        }
    }
}
