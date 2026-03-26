import SwiftUI

/// Compact boss card — ArenaOpponentCard-style full-bleed portrait with vignette overlay.
/// Tap opens BossDetailSheet with full lore, stats, loot, and fight button.
struct DungeonBossCard: View {
    let boss: BossInfo
    let state: BossState
    let bossIndex: Int
    let onTap: () -> Void

    // Animation state
    @State private var glowPhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -1.2

    private var isActive: Bool { state == .current }

    private var stateColor: Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success
        case .current: return DarkFantasyTheme.bossBorderPurple
        case .locked: return DarkFantasyTheme.lockedGray
        }
    }

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(BossCardPressStyle(glowColor: stateColor))
        .opacity(state == .locked ? 0.6 : 1.0)
        .onAppear { startAnimations() }
        .onDisappear { stopAnimations() }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = width * 1.4

            ZStack {
                // 1. Full-bleed boss image background
                bossImageLayer(width: width, height: height)

                // 2. Vignette: radial + bottom linear fade
                vignetteOverlay(width: width, height: height)

                // 3. Content: top badges + bottom info stack
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
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius))
            .compositingGroup()
            .shadow(color: stateColor.opacity(isActive ? 0.25 : 0.1), radius: LayoutConstants.arenaGlowRadius, y: 3)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
        }
        .aspectRatio(1.0 / 1.4, contentMode: .fit)
    }

    // MARK: - Boss Image Layer

    @ViewBuilder
    private func bossImageLayer(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if UIImage(named: boss.fullImage) != nil {
                Image(boss.fullImage)
                    .resizable()
                    .scaledToFill()
            } else if UIImage(named: boss.portraitImage) != nil {
                Image(boss.portraitImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(boss.emoji)
                    .font(.system(size: 60))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .opacity(state == .locked ? 0.3 : 1.0)
    }

    // MARK: - Vignette Overlay

    private func vignetteOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [
                    .clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.5)
                ]),
                center: .init(x: 0.5, y: 0.35),
                startRadius: width * 0.25,
                endRadius: width * 0.85
            )

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
            // Boss number circle
            Text("\(boss.id)")
                .font(DarkFantasyTheme.section(size: 12))
                .foregroundStyle(stateColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                        .overlay(
                            Circle()
                                .stroke(stateColor.opacity(0.5), lineWidth: 1.5)
                        )
                )

            Spacer()

            // Status badge
            statusBadge
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch state {
        case .defeated:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                Text("DEFEATED")
            }
            .font(DarkFantasyTheme.body(size: 10).bold())
            .foregroundStyle(DarkFantasyTheme.success)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.success.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.success.opacity(0.25), lineWidth: 0.5)
                    )
            )
            .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.success.opacity(0.08))

        case .current:
            Text("READY")
                .font(DarkFantasyTheme.body(size: 10).bold())
                .foregroundStyle(DarkFantasyTheme.arenaRankGold)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.arenaRankGold.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(DarkFantasyTheme.arenaRankGold.opacity(0.25), lineWidth: 0.5)
                        )
                )
                .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.arenaRankGold.opacity(0.08))

        case .locked:
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                Text("LOCKED")
            }
            .font(DarkFantasyTheme.body(size: 10).bold())
            .foregroundStyle(DarkFantasyTheme.lockedGray)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.lockedGray.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.lockedGray.opacity(0.25), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - Bottom Info Stack

    private var bottomInfoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Boss name
            Text(boss.name.uppercased())
                .font(DarkFantasyTheme.section(size: LayoutConstants.arenaNameFont))
                .foregroundStyle(
                    state == .locked ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textPrimary
                )
                .lineLimit(1)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

            // Lore tagline
            Text(boss.description)
                .font(DarkFantasyTheme.body(size: 10).italic())
                .foregroundStyle(DarkFantasyTheme.textBossDesc)
                .lineLimit(2)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 4)

            // Level — dominant
            HStack(spacing: 6) {
                Text("Lv. \(boss.level)")
                    .font(DarkFantasyTheme.section(size: 28))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .shadow(color: stateColor.opacity(0.4), radius: 12)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 3, y: 1)

                Spacer()
            }

            // Glass stat pills
            HStack(spacing: 4) {
                glassStatPill(
                    value: formatHP(boss.hp),
                    label: "HP",
                    color: DarkFantasyTheme.hpGreen
                )
                glassStatPill(
                    value: "\(boss.loot.count)",
                    label: "Drops",
                    color: DarkFantasyTheme.lootGold
                )
                glassStatPill(
                    value: boss.loot.first(where: { $0.rarity == .legendary || $0.rarity == .epic })?.rarity.rawValue.prefix(4).uppercased().description ?? "—",
                    label: "Best",
                    color: bestLootColor
                )
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
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Animated Border Glow

    private var animatedBorderGlow: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.arenaCardRadius)
            .stroke(
                isActive
                    ? AngularGradient(
                        colors: [
                            stateColor.opacity(0.5),
                            stateColor.opacity(0.15),
                            DarkFantasyTheme.gold.opacity(0.3),
                            stateColor.opacity(0.15),
                            stateColor.opacity(0.5)
                        ],
                        center: .center,
                        startAngle: .degrees(glowPhase),
                        endAngle: .degrees(glowPhase + 360)
                    )
                    : AngularGradient(
                        colors: [stateColor.opacity(0.3)],
                        center: .center
                    ),
                lineWidth: isActive ? 1.5 : 1
            )
            .overlay(
                CornerBracketOverlay(
                    color: stateColor.opacity(isActive ? 0.5 : 0.3),
                    length: 14,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: stateColor.opacity(isActive ? 0.4 : 0.2),
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
                        isActive ? DarkFantasyTheme.arenaShimmerColor : .clear,
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
        guard isActive else { return }
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            shimmerOffset = 1.5
        }
    }

    private func stopAnimations() {
        glowPhase = 0
        shimmerOffset = -1.2
    }

    // MARK: - Helpers

    private func formatHP(_ hp: Int) -> String {
        if hp >= 1000 {
            return String(format: "%.1fK", Double(hp) / 1000.0)
        }
        return "\(hp)"
    }

    private var bestLootColor: Color {
        if let best = boss.loot.first(where: { $0.rarity == .legendary }) {
            return DarkFantasyTheme.rarityColor(for: best.rarity)
        }
        if let best = boss.loot.first(where: { $0.rarity == .epic }) {
            return DarkFantasyTheme.rarityColor(for: best.rarity)
        }
        if let best = boss.loot.first(where: { $0.rarity == .rare }) {
            return DarkFantasyTheme.rarityColor(for: best.rarity)
        }
        return DarkFantasyTheme.textTertiary
    }
}

// MARK: - Boss Card Press Style

struct BossCardPressStyle: ButtonStyle {
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
