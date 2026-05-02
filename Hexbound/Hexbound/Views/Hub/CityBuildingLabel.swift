import SwiftUI

// MARK: - City Building Label (Banner above building on tap)

struct CityBuildingLabel: View {
    let text: String
    let visible: Bool
    /// W2.D5 — structured badge instead of a bare string. Defaults to
    /// `BuildingBadge.none` so existing callsites with no badge keep working.
    /// Priority drives styling: `.critical` → danger-red pulsing pill,
    /// `.info` → gold static pill, `.none` → nothing.
    var badge: BuildingBadge = .none
    var isLocked: Bool = false
    /// Shows a pulsing quest indicator (!) when an NPC quest points to this building
    var hasQuest: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            // Quest indicator
            if hasQuest && !isLocked {
                Text("!")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(DarkFantasyTheme.gold))
            }

            Text(text)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)

            if !isLocked && badge.shouldShow {
                BuildingBadgeView(badge: badge, visible: visible)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.88))
        )
        .surfaceLighting(cornerRadius: LayoutConstants.radiusXS, topHighlight: 0.06, bottomShadow: 0.08)
        .innerBorder(cornerRadius: LayoutConstants.radiusXS - 1, inset: 1, color: isLocked ? DarkFantasyTheme.textSecondary.opacity(0.05) : DarkFantasyTheme.gold.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .stroke(
                    isLocked
                        ? DarkFantasyTheme.textSecondary.opacity(0.4)
                        : DarkFantasyTheme.gold.opacity(0.7),
                    lineWidth: 1
                )
        )
        .cornerBrackets(color: isLocked ? DarkFantasyTheme.textSecondary.opacity(0.3) : DarkFantasyTheme.gold.opacity(0.5), length: 8, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 6)
        .animation(.easeOut(duration: 0.25), value: visible)
    }
}

// MARK: - Building Badge View (priority-aware pill renderer)

/// W2.D5 — wrapper that picks the right pill style for a `BuildingBadge`.
/// Called from `CityBuildingLabel` when the badge `.shouldShow`.
///
/// Pulls text-on-gold / danger colors directly from `DarkFantasyTheme` tokens
/// per the design-system rule — no ad-hoc colors, no ad-hoc fonts.
struct BuildingBadgeView: View {
    let badge: BuildingBadge
    let visible: Bool

    var body: some View {
        Group {
            switch badge.priority {
            case .critical:
                CriticalBadgePill(text: badge.text, visible: visible)
            case .info:
                InfoBadgePill(text: badge.text, visible: visible)
            case .none:
                EmptyView()
            }
        }
    }
}

// MARK: - Info Pill (gold, static)

/// Gold pill with a subtle gold-glow pulse — the existing pill look.
/// Identical to the pre-W2.D5 rendering so non-critical badges don't regress.
private struct InfoBadgePill: View {
    let text: String
    let visible: Bool

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.barInternalPadding)
            .background(
                Capsule().fill(DarkFantasyTheme.gold)
            )
            .glowPulse(
                color: DarkFantasyTheme.goldGlow,
                intensity: 0.7,
                isActive: visible
            )
    }
}

// MARK: - Critical Pill (danger red, pulsing)

/// Danger-red pill with a white outline and a faster, stronger pulse.
/// Pulse is OPACITY-ONLY — we keep app-wide emphasis animation free of
/// scale-grow transforms.
private struct CriticalBadgePill: View {
    let text: String
    let visible: Bool

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.barInternalPadding)
            .background(
                Capsule().fill(DarkFantasyTheme.danger)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .glowPulse(
                color: DarkFantasyTheme.dangerGlow,
                intensity: 0.9,
                isActive: visible
            )
    }
}
