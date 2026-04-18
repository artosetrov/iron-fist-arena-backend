import SwiftUI

/// Currency type for quest reward display.
enum QuestRewardType {
    case gold
    case xp
    case gems

    var assetName: String {
        switch self {
        case .gold: return "icon-gold"
        case .xp:   return "icon-xp"
        case .gems: return "icon-gems"
        }
    }

    var accentColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.goldBright
        case .xp:   return DarkFantasyTheme.cyan
        case .gems: return DarkFantasyTheme.purple
        }
    }

    /// The color used for border, glow, corner brackets (slightly muted vs accent)
    var borderColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.gold
        case .xp:   return DarkFantasyTheme.cyan
        case .gems: return DarkFantasyTheme.purple
        }
    }
}

/// Loot-style reward cell that mirrors `ItemCardView` (`.shop` context) layer-for-layer:
/// gradient background → radial glow → art filling the cell → bottom vignette →
/// corner accents → inner/outer borders → corner diamonds → rarity shadow.
/// The value is rendered in a bottom price-bar, exactly like the shop price bar.
///
/// Usage:
/// ```
/// QuestRewardCell(type: .gold, value: 150)
/// QuestRewardCell(type: .xp, value: 80)
/// QuestRewardCell(type: .gems, value: 10)
/// ```
struct QuestRewardCell: View {
    let type: QuestRewardType
    let value: Int

    private let cellSize: CGFloat = LayoutConstants.itemCardSize

    var body: some View {
        cellBase
            // MARK: - Inner bevel border (mirrors ItemCardView)
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 2,
                inset: 2,
                color: type.borderColor.opacity(0.15)
            )
            // MARK: - Inner bevel stroke (subtle)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 2)
                    .padding(1)
            )
            // MARK: - Outer rarity border
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(type.borderColor.opacity(0.7), lineWidth: 2.5)
            )
            // MARK: - Corner diamonds (rarity-colored)
            .cornerDiamonds(color: type.borderColor.opacity(0.5), size: 4)
            // MARK: - Glow shadows (mirrors high-rarity item shadow)
            .shadow(color: type.borderColor.opacity(0.25), radius: 6)
            .shadow(color: type.borderColor.opacity(0.15), radius: 4)
            .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Cell Base (layers 1-5 — identical structure to ItemCardView.cellBase)

    @ViewBuilder
    private var cellBase: some View {
        ZStack {
            // MARK: - Layer 1: Gradient background
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(LinearGradient(
                    colors: [
                        type.borderColor.opacity(0.10),
                        DarkFantasyTheme.bgAbyss.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))

            // MARK: - Layer 2: Radial glow
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(
                    RadialGradient(
                        colors: [
                            type.borderColor.opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 48
                    )
                )

            // MARK: - Layer 3: Reward asset — fills the entire cell
            Image(type.assetName)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(LayoutConstants.space2XS)
                .shadow(color: Color.black.opacity(0.5), radius: 3, y: 2)
                .clipped()

            // MARK: - Layer 4: Bottom vignette
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        DarkFantasyTheme.bgAbyss.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))

            // MARK: - Layer 5: Corner accents (L-brackets)
            CornerAccentsOverlay(
                cornerRadius: LayoutConstants.cardRadius,
                color: DarkFantasyTheme.borderMedium.opacity(0.6),
                length: 8,
                lineWidth: 1.5
            )
        }
        // MARK: - Bottom price-bar overlay (mirrors ItemCardView.shopPriceBar)
        .overlay(alignment: .bottom) {
            valueBar
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    // MARK: - Value Bar (mirrors shop price bar)

    @ViewBuilder
    private var valueBar: some View {
        Text("\(value)")
            .font(DarkFantasyTheme.body.bold())
            .foregroundStyle(type.accentColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .shadow(color: Color.black.opacity(0.7), radius: 1.5, y: 1)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .frame(maxWidth: .infinity)
            .background(DarkFantasyTheme.bgAbyss.opacity(0.65))
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: LayoutConstants.cardRadius,
                    bottomTrailingRadius: LayoutConstants.cardRadius,
                    topTrailingRadius: 0
                )
            )
    }
}
