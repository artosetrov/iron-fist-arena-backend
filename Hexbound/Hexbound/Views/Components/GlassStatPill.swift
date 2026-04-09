import SwiftUI

/// Reusable stat pill — value on top, label below.
/// Three size variants for different contexts:
/// - `.default` — glass-morphism background, used in ArenaOpponentCard, DungeonBossCard, CharacterSelectionView
/// - `.compact` — no background, bold value + smaller label, used in OpponentCardView
/// - `.large` — no background, title-sized value, used in SessionSummaryView
///
/// Usage:
/// ```swift
/// GlassStatPill(value: "1,240", label: "ATK", color: DarkFantasyTheme.danger)
/// GlassStatPill(value: "85", label: "HP", color: DarkFantasyTheme.danger, size: .compact)
/// GlassStatPill(value: "12", label: "Wins", color: DarkFantasyTheme.gold, size: .large)
/// ```
struct GlassStatPill: View {
    let value: String
    let label: String
    let color: Color
    var size: Size = .default

    enum Size {
        case `default`
        case compact
        case large
    }

    var body: some View {
        VStack(spacing: verticalSpacing) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(color)

            Text(label)
                .font(labelFont)
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, size == .default ? LayoutConstants.spaceXS : 0)
        .background(backgroundView)
    }

    // MARK: - Size-dependent properties

    private var verticalSpacing: CGFloat {
        switch size {
        case .default: return 1
        case .compact: return LayoutConstants.space2XS
        case .large: return LayoutConstants.spaceXS
        }
    }

    private var valueFont: Font {
        switch size {
        case .default: return DarkFantasyTheme.uiLabel
        case .compact: return DarkFantasyTheme.body.bold()
        case .large: return DarkFantasyTheme.title
        }
    }

    private var labelFont: Font {
        switch size {
        case .default: return DarkFantasyTheme.caption
        case .compact: return DarkFantasyTheme.badge
        case .large: return DarkFantasyTheme.caption
        }
    }

    private var labelColor: Color {
        switch size {
        case .default: return DarkFantasyTheme.textTertiaryAA
        case .compact: return DarkFantasyTheme.textTertiary
        case .large: return DarkFantasyTheme.textSecondary
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if size == .default {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(color.opacity(0.15), lineWidth: 0.5)
                )
        }
    }
}
