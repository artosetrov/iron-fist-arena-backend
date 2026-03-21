import SwiftUI

/// Premium Arena opponent card — animated glow border, shimmer, enlarged avatar,
/// polished typography hierarchy, and tap microinteractions.
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

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(ArenaCardPressStyle(glowColor: difficulty.glowColor))
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Avatar section with breathing room
            avatarSection
                .padding(.top, LayoutConstants.spaceXS)

            // Name — strong
            Text(opponent.characterName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            // Class + Level — secondary
            Text("Lv.\(opponent.level) \(opponent.characterClass.displayName.uppercased())")
                .font(DarkFantasyTheme.body(size: LayoutConstants.arenaClassFont).bold())
                .foregroundStyle(DarkFantasyTheme.classColor(for: opponent.characterClass))
                .lineLimit(1)

            // Rating — dominant
            Text("\(opponent.pvpRating)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaRatingFont))
                .foregroundStyle(DarkFantasyTheme.rankColor(for: opponent.pvpRating))
                .shadow(color: DarkFantasyTheme.rankColor(for: opponent.pvpRating).opacity(0.3), radius: 6)

            // Stats — clean grid
            statsSection
        }
        .padding(.horizontal, LayoutConstants.arenaCardPadding)
        .padding(.top, LayoutConstants.arenaCardPaddingTop)
        .padding(.bottom, LayoutConstants.arenaCardPadding)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(animatedBorderGlow)
        .overlay(shimmerOverlay)
        .overlay(alignment: .topTrailing) { difficultyBadge }
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
        .shadow(color: difficulty.glowColor.opacity(0.25), radius: LayoutConstants.arenaGlowRadius, y: 3)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        AvatarImageView(
            skinKey: opponent.avatar,
            characterClass: opponent.characterClass,
            size: LayoutConstants.arenaAvatarSize
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaAvatarRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.arenaAvatarRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            difficulty.glowColor.opacity(0.6),
                            difficulty.glowColor.opacity(0.2),
                            difficulty.glowColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: difficulty.glowColor.opacity(0.2), radius: 8, y: 2)
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 6) {
            Divider()
                .overlay(DarkFantasyTheme.borderSubtle)

            statRow("Attack", value: opponent.strength ?? 0, color: DarkFantasyTheme.danger)
            statRow("Defense", value: opponent.vitality ?? 0, color: DarkFantasyTheme.info)
            statRow("Win Rate", value: Int(opponent.winRate), color: DarkFantasyTheme.success, suffix: "%")
        }
    }

    @ViewBuilder
    private func statRow(_ label: String, value: Int, color: Color, suffix: String = "") -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.arenaStatLabelFont))
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
            Spacer()
            Text("\(value)\(suffix)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaStatFont))
                .foregroundStyle(color)
        }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        ZStack {
            // Base gradient
            RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                .fill(DarkFantasyTheme.bgArenaCardPremium)

            // Inner top lighting
            RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.arenaCardInnerGlow.opacity(0.4),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
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
    }

    // MARK: - Shimmer Overlay

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let _ = geo.size.width
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
    }

    // MARK: - Difficulty Badge

    private var difficultyBadge: some View {
        Text(difficulty.label)
            .font(DarkFantasyTheme.body(size: LayoutConstants.arenaDifficultyFont).bold())
            .foregroundStyle(difficulty.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(difficulty.textColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(difficulty.textColor.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .padding(LayoutConstants.arenaBadgePadding)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Rotating border glow
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }

        // Shimmer sweep — smooth back-and-forth, no jump
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            shimmerOffset = 1.5
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isAppeared = true
        }
    }
}

// MARK: - Arena Card Press Style

/// Custom button style: on press, the card lifts, uses opacity feedback,
/// and the glow intensifies — feels premium and tactile.
struct ArenaCardPressStyle: ButtonStyle {
    var glowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
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
