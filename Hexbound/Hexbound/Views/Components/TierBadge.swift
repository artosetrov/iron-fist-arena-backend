// =============================================================================
// TierBadge.swift — PvP tier & division badge (W3.D5 — BAL-05)
// =============================================================================
//
// Renders the 8-tier × 3-division ladder (Bronze → Challenger). The tier
// classification is resolved server-side (see backend/src/lib/game/tier.ts),
// so this view is a pure display — it never touches pvpRating numerically.
// It reads `tierKey` (e.g. "silver") and `division` ("II" or nil) and emits
// a small rounded badge with a tier-colored gradient + Roman-numeral division.
//
// Sizes:
//   - .compact  (h=18) — inline next to names in leaderboard rows
//   - .regular  (h=24) — arena hero widget, profile sheet
//   - .large    (h=34) — promotion/demotion animations, settings screen
//
// All sizes use LayoutConstants for padding and DarkFantasyTheme tokens for
// color — no raw values, no custom font sizes.

import SwiftUI

struct TierBadge: View {
    let tierKey: String          // "bronze", "silver", ..., "challenger"
    let division: String?        // "III" | "II" | "I" | nil (Master/GM/Challenger have no division)
    let size: Size

    enum Size {
        case compact
        case regular
        case large

        var height: CGFloat {
            switch self {
            case .compact: return 18
            case .regular: return 24
            case .large:   return 34
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return LayoutConstants.spaceXS + 2
            case .regular: return LayoutConstants.spaceSM
            case .large:   return LayoutConstants.spaceMS
            }
        }

        var iconFont: Font {
            switch self {
            case .compact: return DarkFantasyTheme.badge
            case .regular: return DarkFantasyTheme.caption
            case .large:   return DarkFantasyTheme.uiLabel
            }
        }

        var labelFont: Font {
            switch self {
            case .compact: return DarkFantasyTheme.badge
            case .regular: return DarkFantasyTheme.caption.weight(.bold)
            case .large:   return DarkFantasyTheme.uiLabel.bold()
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .compact: return 10
            case .regular: return 14
            case .large:   return 20
            }
        }
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: tierSymbol)
                .font(size.iconFont)
                .foregroundStyle(iconColor)
                .frame(width: size.iconSize, height: size.iconSize)

            Text(displayLabel)
                .font(size.labelFont)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
        }
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
        .background(
            RoundedRectangle(cornerRadius: size.height / 2)
                .fill(backgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: size.height / 2)
                .stroke(borderColor.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: iconColor.opacity(0.25), radius: 3, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(displayLabel)
    }

    // MARK: - Derived styling

    /// Tier name + roman numeral, e.g. "Silver II" / "Master" / "Challenger".
    private var displayLabel: String {
        let tierName = tierKey.prefix(1).uppercased() + tierKey.dropFirst()
        if let div = division, !div.isEmpty {
            return "\(tierName) \(div)"
        }
        return tierName
    }

    /// SF Symbol representing the tier — tracks the apex theme of each tier.
    private var tierSymbol: String {
        switch tierKey {
        case "bronze":      return "shield.lefthalf.filled"
        case "silver":      return "shield.lefthalf.filled"
        case "gold":        return "crown.fill"
        case "platinum":    return "hexagon.fill"
        case "diamond":     return "diamond.fill"
        case "master":      return "star.fill"
        case "grandmaster": return "laurel.leading"
        case "challenger":  return "crown.fill"
        default:            return "shield.fill"
        }
    }

    /// Primary tier color used for icon + glow.
    private var iconColor: Color {
        switch tierKey {
        case "bronze":      return DarkFantasyTheme.rankBronze
        case "silver":      return DarkFantasyTheme.rankSilver
        case "gold":        return DarkFantasyTheme.rankGold
        case "platinum":    return DarkFantasyTheme.rankPlatinum
        case "diamond":     return DarkFantasyTheme.rankDiamond
        case "master":      return DarkFantasyTheme.rankMaster
        case "grandmaster": return DarkFantasyTheme.rankGrandmaster
        case "challenger":  return DarkFantasyTheme.rankChallenger
        default:            return DarkFantasyTheme.textSecondary
        }
    }

    /// Border stays consistent with the icon color for cohesion.
    private var borderColor: Color { iconColor }

    /// Subtle tier-tinted background — dark base + tier overlay for legibility
    /// against the panel-secondary surface behind leaderboard rows.
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                DarkFantasyTheme.bgAbyss.opacity(0.85),
                iconColor.opacity(0.22),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Tier Badge Ladder") {
    VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
        Group {
            TierBadge(tierKey: "bronze",      division: "III", size: .compact)
            TierBadge(tierKey: "silver",      division: "II",  size: .compact)
            TierBadge(tierKey: "gold",        division: "I",   size: .compact)
            TierBadge(tierKey: "platinum",    division: "II",  size: .regular)
            TierBadge(tierKey: "diamond",     division: "I",   size: .regular)
            TierBadge(tierKey: "master",      division: nil,   size: .regular)
            TierBadge(tierKey: "grandmaster", division: nil,   size: .large)
            TierBadge(tierKey: "challenger",  division: nil,   size: .large)
        }
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
