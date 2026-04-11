import SwiftUI

/// Resource counter header shown at the top of the Gold Mine screen.
///
/// Shows live gold + gems values with tick-up animation, plus the current
/// hourly rate derived from active mining slots. Flying coin/gem particles
/// emitted from mine cards arrive at the icon positions inside this header,
/// and the counters increment on arrival.
///
/// Uses `GoldMineAnchorPreferenceKey` to publish the anchor points (gold icon
/// center + gem icon center) back up to `GoldMineDetailView`, which uses them
/// as `targetPoint` for `CoinFlyAnimationView`.
struct MineResourceHeader: View {
    let visualGold: Int
    let visualGems: Int
    let goldPerHour: Int
    let gemsPerHour: Double
    let activeSlotCount: Int

    var body: some View {
        HStack(spacing: 0) {
            resourceItem(
                icon: "icon-gold",
                value: visualGold,
                color: DarkFantasyTheme.goldBright,
                rateText: "+\(goldPerHour)/HR",
                anchorRole: .gold
            )

            Divider()
                .frame(width: 1, height: 36)
                .background(DarkFantasyTheme.gold.opacity(0.25))

            resourceItem(
                icon: "icon-gems",
                value: visualGems,
                color: DarkFantasyTheme.cyan,
                rateText: formattedGemRate,
                anchorRole: .gem
            )
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(maxWidth: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.5,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.10, bottomShadow: 0.14)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.gold.opacity(0.10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.45), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.goldBright.opacity(0.55), length: 14, thickness: 2.0)
        .shadow(color: DarkFantasyTheme.gold.opacity(0.12), radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Resources: \(visualGold) gold, \(visualGems) gems. \(activeSlotCount) active slots producing \(goldPerHour) gold per hour."
        )
    }

    // MARK: - Resource Item

    @ViewBuilder
    private func resourceItem(
        icon: String,
        value: Int,
        color: Color,
        rateText: String,
        anchorRole: MineAnchorRole
    ) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                .shadow(color: color.opacity(0.4), radius: 4)
                .background(
                    // Publish center point of this icon to the parent view
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: GoldMineAnchorPreferenceKey.self,
                                value: [MineAnchorEntry(
                                    role: anchorRole,
                                    point: CGPoint(
                                        x: geo.frame(in: .global).midX,
                                        y: geo.frame(in: .global).midY
                                    )
                                )]
                            )
                    }
                )

            VStack(alignment: .leading, spacing: 0) {
                NumberTickUpText(
                    value: value,
                    color: color,
                    font: DarkFantasyTheme.section
                )
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

                Text(rateText)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Formatting

    private var formattedGemRate: String {
        if gemsPerHour <= 0 {
            return "+0/HR"
        } else if gemsPerHour >= 1 {
            return "+\(Int(gemsPerHour))/HR"
        } else {
            return String(format: "+%.1f/HR", gemsPerHour)
        }
    }
}

// MARK: - Anchor Preference Key

/// Role of a point published from `MineResourceHeader` — identifies which
/// currency icon the fly-particle should target.
enum MineAnchorRole: Equatable {
    case gold
    case gem
}

/// Entry published through `GoldMineAnchorPreferenceKey`. Holds the global
/// center point of a currency icon in `MineResourceHeader`, consumed by
/// `GoldMineDetailView` to position `CoinFlyAnimationView` overlay targets.
struct MineAnchorEntry: Equatable {
    let role: MineAnchorRole
    let point: CGPoint
}

struct GoldMineAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [MineAnchorEntry] = []

    static func reduce(value: inout [MineAnchorEntry], nextValue: () -> [MineAnchorEntry]) {
        value.append(contentsOf: nextValue())
    }
}
