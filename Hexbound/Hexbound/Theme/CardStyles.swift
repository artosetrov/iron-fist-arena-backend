import SwiftUI

// MARK: - Panel Card Modifier (AAA Design Doc)

struct PanelCardModifier: ViewModifier {
    var highlight: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: highlight ? DarkFantasyTheme.gold.opacity(0.06) : DarkFantasyTheme.bgTertiary,
                    glowIntensity: highlight ? 0.4 : 0.6,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            // Surface lighting for 3D convexity
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
            // Inner bevel border
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 4,
                inset: 4,
                color: highlight ? DarkFantasyTheme.gold.opacity(0.15) : DarkFantasyTheme.borderMedium.opacity(0.25)
            )
            // Outer frame
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        highlight ? DarkFantasyTheme.borderGold.opacity(0.6) : DarkFantasyTheme.borderSubtle,
                        lineWidth: highlight ? 1.5 : 1
                    )
            )
            // Corner brackets + diamonds
            .cornerBrackets(color: highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderMedium)
            .cornerDiamonds(color: highlight ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderStrong)
            // Dual shadow: type-colored glow + dark depth
            // Flatten ornamental overlays into single GPU texture
            .compositingGroup()
            .shadow(
                color: highlight ? DarkFantasyTheme.goldGlow : .black.opacity(0.3),
                radius: highlight ? 12 : 6,
                y: 2
            )
            .shadow(
                color: DarkFantasyTheme.bgAbyss.opacity(0.5),
                radius: 2,
                y: 1
            )
    }
}

// MARK: - Rarity Card Modifier

struct RarityCardModifier: ViewModifier {
    let rarity: ItemRarity

    private var rarityColor: Color { DarkFantasyTheme.rarityColor(for: rarity) }
    private var isHighRarity: Bool { rarity == .epic || rarity == .legendary }

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgTertiary,
                    glowColor: rarityColor,
                    glowIntensity: rarity == .legendary ? 0.15 : 0.10,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            // Surface lighting — stronger for high rarity
            .surfaceLighting(
                cornerRadius: LayoutConstants.cardRadius,
                topHighlight: isHighRarity ? 0.10 : 0.06,
                bottomShadow: isHighRarity ? 0.15 : 0.10
            )
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 3,
                inset: 3,
                color: rarityColor.opacity(0.18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(rarityColor, lineWidth: 2.5)
            )
            .cornerBrackets(color: rarityColor, length: isHighRarity ? 20 : 18)
            .cornerDiamonds(color: rarityColor, size: isHighRarity ? 7 : 6)
            // Flatten ornamental overlays into single GPU texture
            .compositingGroup()
            // Dual shadow
            .shadow(
                color: DarkFantasyTheme.rarityGlow(for: rarity),
                radius: rarity == .legendary ? 16 : 10,
                y: 2
            )
            .shadow(
                color: DarkFantasyTheme.bgAbyss.opacity(0.5),
                radius: 2,
                y: 1
            )
    }
}

// MARK: - Info Panel Modifier

struct InfoPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgPrimary,
                    glowColor: DarkFantasyTheme.bgSecondary,
                    glowIntensity: 0.5,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(
                cornerRadius: LayoutConstants.panelRadius - 3,
                inset: 3,
                color: DarkFantasyTheme.borderMedium.opacity(0.25)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.borderMedium, length: 14)
            .cornerDiamonds(color: DarkFantasyTheme.borderStrong, size: 5)
            // Flatten ornamental overlays into single GPU texture
            .compositingGroup()
            .shadow(
                color: DarkFantasyTheme.bgAbyss.opacity(0.4),
                radius: 3,
                y: 1
            )
    }
}

// MARK: - Modal Overlay Modifier

struct ModalOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.6,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            // Surface lighting for premium depth
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            // Double border frame
            .doubleBorder(
                outerColor: DarkFantasyTheme.borderOrnament,
                innerColor: DarkFantasyTheme.borderOrnament.opacity(0.4),
                cornerRadius: LayoutConstants.modalRadius,
                gap: 4
            )
            .innerBorder(
                cornerRadius: LayoutConstants.modalRadius - 6,
                inset: 6,
                color: DarkFantasyTheme.gold.opacity(0.10)
            )
            // Ornamental accents
            .cornerBrackets(color: DarkFantasyTheme.goldBright, length: 22, thickness: 2.0)
            .cornerDiamonds(color: DarkFantasyTheme.goldBright, size: 7)
            .sideDiamonds(color: DarkFantasyTheme.borderOrnament)
            // Flatten ornamental overlays into single GPU texture
            .compositingGroup()
            // Dual shadow: ornament glow + deep abyss
            .shadow(color: DarkFantasyTheme.borderOrnament.opacity(0.18), radius: 24)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 32, y: 8)
    }
}

// MARK: - View Extensions

extension View {
    func panelCard(highlight: Bool = false) -> some View {
        modifier(PanelCardModifier(highlight: highlight))
    }

    func rarityCard(_ rarity: ItemRarity) -> some View {
        modifier(RarityCardModifier(rarity: rarity))
    }

    func infoPanel() -> some View {
        modifier(InfoPanelModifier())
    }

    func modalOverlay() -> some View {
        modifier(ModalOverlayModifier())
    }
}

// MARK: - Screen Background

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}

// MARK: - Gold Divider (ornamental gradient + diamond motif)

struct GoldDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.goldDim, DarkFantasyTheme.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            DiamondDividerMotif(
                accentColor: DarkFantasyTheme.gold,
                dotColor: DarkFantasyTheme.goldDim,
                accentSize: 8,
                dotSize: 5
            )
            .padding(.horizontal, 8)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
        .frame(height: 10)
    }
}

// MARK: - Ornamental Divider (diamond motif center)

struct OrnamentalDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.borderSubtle, DarkFantasyTheme.borderMedium],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            DiamondDividerMotif(
                accentColor: DarkFantasyTheme.goldDim,
                dotColor: DarkFantasyTheme.borderMedium,
                accentSize: 6,
                dotSize: 4
            )
            .padding(.horizontal, 8)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.borderMedium, DarkFantasyTheme.borderSubtle, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .frame(height: 8)
    }
}
