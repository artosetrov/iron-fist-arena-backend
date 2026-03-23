import SwiftUI

/// Unified currency display used across all screens.
///
/// Sizes:
/// - `.standard` — Large icons (36px) + large text (28px) — shop header, GET CURRENCY balance
/// - `.compact` — Small icons (14px) + small text — UnifiedHeroWidget, inventory header
/// - `.mini` — Tiny icons (12px) + caption text — price tags on shop cards, item detail prices
///
/// Currency type:
/// - `.both` (default) — Shows gold and optionally gems
/// - `.gold` — Shows only gold amount
/// - `.gems` — Shows only gems amount
struct CurrencyDisplay: View {
    let gold: Int
    var gems: Int? = nil
    var showAddButton: Bool = false
    var onAdd: (() -> Void)? = nil

    /// Display size preset.
    var size: DisplaySize = .standard

    /// Whether to show gems (overrides default behavior).
    var showGems: Bool = true

    /// Which currency to display. Defaults to `.both`.
    var currencyType: CurrencyType = .both

    /// Whether to use animated tick-up text. Defaults to true.
    var animated: Bool = true

    enum CurrencyType {
        case both   // Gold + gems (default)
        case gold   // Only gold
        case gems   // Only gems
    }

    enum DisplaySize {
        case standard  // Large icons + text (shop, inventory)
        case compact   // Small inline (widget, header)
        case mini      // Tiny price tags (shop cards, item detail)

        var iconSize: CGFloat {
            switch self {
            case .standard: 36
            case .compact: 14
            case .mini: 12
            }
        }

        var font: Font {
            switch self {
            case .standard: DarkFantasyTheme.section(size: 28)
            case .compact: DarkFantasyTheme.body(size: LayoutConstants.textLabel)
            case .mini: DarkFantasyTheme.section(size: LayoutConstants.textCaption)
            }
        }

        var spacing: CGFloat {
            switch self {
            case .standard: LayoutConstants.spaceXS
            case .compact: LayoutConstants.space2XS
            case .mini: LayoutConstants.space2XS
            }
        }

        var groupSpacing: CGFloat {
            switch self {
            case .standard: LayoutConstants.spaceMD
            case .compact: LayoutConstants.spaceMS
            case .mini: LayoutConstants.spaceXS
            }
        }

        var goldColor: Color {
            switch self {
            case .standard: DarkFantasyTheme.goldBright
            case .compact: DarkFantasyTheme.textGold
            case .mini: DarkFantasyTheme.goldBright
            }
        }

        var gemsColor: Color {
            switch self {
            case .standard: DarkFantasyTheme.cyan
            case .compact: DarkFantasyTheme.gems
            case .mini: DarkFantasyTheme.cyan
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: size.groupSpacing) {
            // Gold
            if currencyType == .both || currencyType == .gold {
                currencyItem(
                    icon: "icon-gold",
                    value: gold,
                    color: size.goldColor,
                    label: "Gold"
                )
            }

            // Gems
            if currencyType == .gems || (currencyType == .both && showGems) {
                let gemsValue = gems ?? 0
                if currencyType == .gems || gemsValue > 0 {
                    currencyItem(
                        icon: "icon-gems",
                        value: gemsValue,
                        color: size.gemsColor,
                        label: "Gems"
                    )
                }
            }

            if showAddButton {
                Button {
                    onAdd?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .accessibilityLabel("Buy currency")
            }
        }
    }

    // MARK: - Currency Item

    @ViewBuilder
    private func currencyItem(icon: String, value: Int, color: Color, label: String) -> some View {
        HStack(spacing: size.spacing) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: size.iconSize, height: size.iconSize)
            if animated {
                NumberTickUpText(
                    value: value,
                    color: color,
                    font: size.font
                )
                .lineLimit(1)
            } else {
                Text("\(value)")
                    .font(size.font)
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .accessibilityLabel("\(label): \(value)")
    }
}
