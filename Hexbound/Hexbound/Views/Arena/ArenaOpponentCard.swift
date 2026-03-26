import SwiftUI

/// Premium Arena opponent card — Variant C: full-immersion.
/// Avatar fills the entire card as background. All info overlaid via vignette.
/// Glass-morphism stat pills, corner ornaments, animated glow border, shimmer.
struct ArenaOpponentCard: View {
    let opponent: Opponent
    let playerRating: Int
    let onTap: () -> Void

    // Animation state
    @State private var glowPhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -1.2
    @State private var isAppeared = false

    private var ratingDiff: Int { opponent.pvpRating - playerRating }

    private var difficulty: OpponentDifficulty {
        if ratingDiff < -200 { return .easy }
        if ratingDiff < 200 { return .medium }
        return .hard
    }

    private var classColor: Color {
        DarkFantasyTheme.classColor(for: opponent.characterClass)
    }

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(ArenaCardPressStyle(glowColor: difficulty.glowColor))
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 1.4 // tall portrait ratio

            ZStack {
                // 1. Full-bleed avatar background
                AvatarImageView(
                    skinKey: opponent.avatar,
                    characterClass: opponent.characterClass,
                    size: width
                )
                .frame(width: width, height: height)
                .clipped()

                // 2. Vignette: radial + bottom linear fade
                vignetteOverlay(width: width, height: height)

                // 3. Content: top badges + bottom info stack
                VStack {
                    // Top row: level badge (left) + difficulty badge (right)
                    topBadges

                    Spacer()

                    // Bottom: name → class tag → rating → glass stat pills
                    bottomInfoStack
                }
                .padding(LayoutConstants.arenaCardPadding - 4)
                .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .background(DarkFantasyTheme.bgAbyss) // fallback behind avatar
            .overlay(animatedBorderGlow)
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
            .shadow(color: difficulty.glowColor.opacity(0.25), radius: LayoutConstants.arenaGlowRadius, y: 3)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        }
        .aspectRatio(1.0 / 1.4, contentMode: .fit)
    }

    // MARK: - Vignette Overlay

    private func vignetteOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Radial vignette — darkens edges
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.5)
                ]),
                center: .init(x: 0.5, y: 0.35),
                startRadius: width * 0.25,
                endRadius: width * 0.85
            )

            // Bottom fade — strong, for text readability
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
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
            Text("\(opponent.level)")
                .font(DarkFantasyTheme.section(size: 12))
                .foregroundStyle(classColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(
                            Circle()
                                .stroke(classColor.opacity(0.5), lineWidth: 1.5)
                        )
                )

            Spacer()

            // Difficulty badge
            difficultyBadge
        }
    }

    // MARK: - Bottom Info Stack

    private var bottomInfoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Name
            Text(opponent.characterName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Class tag pill
            Text(opponent.characterClass.displayName.uppercased())
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

            // Rating — dominant
            Text("\(opponent.pvpRating)")
                .font(DarkFantasyTheme.section(size: 32))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .shadow(color: difficulty.glowColor.opacity(0.4), radius: 12)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 3, y: 1)

            // Glass stat pills
            HStack(spacing: 4) {
                glassStatPill(value: "\(opponent.strength ?? 0)", label: "Attack", color: DarkFantasyTheme.danger)
                glassStatPill(value: "\(opponent.vitality ?? 0)", label: "Defense", color: DarkFantasyTheme.info)
                glassStatPill(value: "\(Int(opponent.winRate))%", label: "Winrate", color: DarkFantasyTheme.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Glass Stat Pill

    @ViewBuilder
    private func glassStatPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(DarkFantasyTheme.section(size: 13))
                .foregroundStyle(color)

            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Difficulty Badge

    private var difficultyBadge: some View {
        Text(difficulty.label)
            .font(DarkFantasyTheme.body(size: LayoutConstants.arenaDifficultyFont).bold())
            .foregroundStyle(difficulty.textColor)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(difficulty.textColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(difficulty.textColor.opacity(0.25), lineWidth: 0.5)
                    )
            )
            .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: difficulty.textColor.opacity(0.08))
    }

    // MARK: - Animated Border Glow

    private var animatedBorderGlow: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        difficulty.glowColor.opacity(0.5),
                        difficulty.glowColor.opacity(0.15),
                        difficulty.glowColor.opacity(0.3),
                        difficulty.glowColor.opacity(0.1),
                        difficulty.glowColor.opacity(0.5)
                    ],
                    center: .center,
                    startAngle: .degrees(glowPhase),
                    endAngle: .degrees(glowPhase + 360)
                ),
                lineWidth: 1.5
            )
            .overlay(
                CornerBracketOverlay(
                    color: difficulty.glowColor.opacity(0.5),
                    length: 14,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: difficulty.glowColor.opacity(0.4),
                    size: 5
                )
            )
    }

    // MARK: - Shimmer Overlay

    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        DarkFantasyTheme.arenaShimmerColor,
                        .clear
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0.3),
                    endPoint: UnitPoint(x: shimmerOffset + 0.4, y: 0.7)
                )
            )
            .allowsHitTesting(false)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            shimmerOffset = 1.5
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAppeared = true
        }
    }

    private func stopAnimations() {
        glowPhase = 0
        shimmerOffset = -0.5
    }
}

// MARK: - Arena Card Press Style

/// Custom button style: brightness feedback + lift on press.
struct ArenaCardPressStyle: ButtonStyle {
    var glowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .shadow(
                color: configuration.isPressed ? glowColor.opacity(0.4) : .clear,
                radius: configuration.isPressed ? 20 : 0,
                y: configuration.isPressed ? -2 : 0
            )
            .offset(y: configuration.isPressed ? -4 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Opponent Difficulty

enum OpponentDifficulty {
    case easy, medium, hard

    var label: String {
        switch self {
        case .easy: "EASY"
        case .medium: "MEDIUM"
        case .hard: "HARD"
        }
    }

    var borderColor: Color {
        switch self {
        case .easy: DarkFantasyTheme.difficultyEasy.opacity(0.4)
        case .medium: DarkFantasyTheme.difficultyMedium.opacity(0.4)
        case .hard: DarkFantasyTheme.difficultyHard.opacity(0.4)
        }
    }

    var glowColor: Color {
        switch self {
        case .easy: DarkFantasyTheme.difficultyEasy
        case .medium: DarkFantasyTheme.difficultyMedium
        case .hard: DarkFantasyTheme.difficultyHard
        }
    }

    var textColor: Color {
        switch self {
        case .easy: DarkFantasyTheme.difficultyEasy
        case .medium: DarkFantasyTheme.difficultyMedium
        case .hard: DarkFantasyTheme.difficultyHard
        }
    }
}
