import SwiftUI

/// Unified stance display used across all screens.
///
/// Two-slot layout: Attack (red tint) | Ornamental Divider | Defense (blue tint).
/// Role icons (⚔/🛡) + zone icons make the meaning instant without reading text.
/// Follows the ornamental design system: RadialGlowBackground, surfaceLighting,
/// innerBorder, cornerBrackets, dual shadows.
///
/// Usage:
/// ```swift
/// StanceDisplayView(stance: character.combatStance!, onTap: { navigate() })
/// StanceDisplayView(attack: vm.attackZone, defense: vm.defenseZone) // editor mode
/// ```
struct StanceDisplayView: View {
    let attack: String
    let defense: String
    var isInteractive: Bool = false
    var onTap: (() -> Void)? = nil

    /// Convenience init from CombatStance model
    init(stance: CombatStance, isInteractive: Bool = false, onTap: (() -> Void)? = nil) {
        self.attack = stance.attack
        self.defense = stance.defense
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    /// Direct init with zone strings (for stance editor preview)
    init(attack: String, defense: String, isInteractive: Bool = false, onTap: (() -> Void)? = nil) {
        self.attack = attack
        self.defense = defense
        self.isInteractive = isInteractive
        self.onTap = onTap
    }

    var body: some View {
        if isInteractive, let onTap = onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(StancePressStyle())
        } else {
            content
        }
    }

    // MARK: - Main Content

    private var content: some View {
        HStack(spacing: 0) {
            // Attack slot — red tint
            slotView(
                role: .attack,
                zone: attack
            )

            // Ornamental vertical divider
            verticalDivider

            // Defense slot — blue tint
            slotView(
                role: .defense,
                zone: defense
            )
        }
        .frame(maxWidth: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.25), length: 10, thickness: 1.0)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .overlay(alignment: .trailing) {
            // Interactive chevron indicator
            if isInteractive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .padding(.trailing, LayoutConstants.spaceSM)
            }
        }
        .accessibilityLabel("Combat Stance: Attack \(attack), Defense \(defense)")
        .accessibilityHint(isInteractive ? "Tap to edit stance" : "")
    }

    // MARK: - Slot View

    @ViewBuilder
    private func slotView(role: StanceRole, zone: String) -> some View {
        let zoneCol = StanceSelectorViewModel.zoneColor(for: zone)

        VStack(spacing: LayoutConstants.space2XS) {
            // Row 1: Role icon + role label (colored by role)
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: role.sfSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(role.tintColor.opacity(0.85))

                Text(role.label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold())
                    .foregroundStyle(role.tintColor.opacity(0.85))
            }

            // Row 2: Zone icon + zone name (colored by zone)
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(StanceSelectorViewModel.zoneAsset(for: zone))
                    .resizable().scaledToFit().frame(width: 20, height: 20)

                Text(zone.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(zoneCol)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM + 2)
        .background(role.tintColor.opacity(0.06))
    }

    // MARK: - Ornamental Vertical Divider

    private var verticalDivider: some View {
        ZStack {
            // Gradient vertical line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.borderSubtle.opacity(0),
                            DarkFantasyTheme.borderMedium,
                            DarkFantasyTheme.goldDim,
                            DarkFantasyTheme.borderMedium,
                            DarkFantasyTheme.borderSubtle.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 1.5)

            // Center diamond motif
            Rectangle()
                .fill(DarkFantasyTheme.goldDim)
                .frame(width: 7, height: 7)
                .rotationEffect(.degrees(45))
                .shadow(color: DarkFantasyTheme.goldDim.opacity(0.4), radius: 4)
        }
        .frame(width: 20, height: 48)
    }
}

// MARK: - Stance Role

private enum StanceRole {
    case attack
    case defense

    var label: String {
        switch self {
        case .attack: "ATTACK"
        case .defense: "DEFENSE"
        }
    }

    var sfSymbol: String {
        switch self {
        case .attack: "bolt.fill"
        case .defense: "shield.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .attack: DarkFantasyTheme.danger
        case .defense: DarkFantasyTheme.info
        }
    }
}

// MARK: - Press Style (brightness, not scale/opacity)

/// Press feedback using brightness(-0.06) per project rules.
/// Plays haptic tap SFX on press.
private struct StancePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        // Same zone — the old design made this confusing
        StanceDisplayView(attack: "legs", defense: "legs")

        // Different zones
        StanceDisplayView(attack: "head", defense: "chest")

        // Interactive
        StanceDisplayView(attack: "chest", defense: "legs", isInteractive: true, onTap: {})
    }
    .padding()
    .background(DarkFantasyTheme.bgPrimary)
}
#endif
