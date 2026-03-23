import SwiftUI

// MARK: - Primary Button (Gold CTA — AAA Design Doc)
// Height: 56px, Gold gradient bg, dark text, ornamental border

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var envEnabled
    var isEnabled: Bool = true

    private var effectiveEnabled: Bool { isEnabled && envEnabled }

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(effectiveEnabled ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                ZStack {
                    // Base gold fill
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(effectiveEnabled ? AnyShapeStyle(DarkFantasyTheme.goldGradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
                    // Radial highlight for convex surface
                    if effectiveEnabled {
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.18), Color.clear],
                                    center: .init(x: 0.5, y: 0.35),
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                        // Surface lighting (top bright → bottom dark)
                        SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadius)
                    }
                }
            )
            // Inner bevel border (bright top, dark bottom)
            .innerBorder(
                cornerRadius: LayoutConstants.buttonRadius - 3,
                inset: 3,
                color: effectiveEnabled ? DarkFantasyTheme.goldBright.opacity(0.35) : Color.clear
            )
            // Outer ornamental frame
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(effectiveEnabled ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.borderSubtle, lineWidth: 2)
            )
            // Corner brackets + diamonds
            .cornerBrackets(color: effectiveEnabled ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderSubtle)
            .cornerDiamonds(color: effectiveEnabled ? DarkFantasyTheme.goldBright : DarkFantasyTheme.bgDisabled)
            .sideDiamonds(color: effectiveEnabled ? DarkFantasyTheme.goldBright : Color.clear)
            .shadow(color: effectiveEnabled ? DarkFantasyTheme.goldGlow : .clear, radius: pressed ? 16 : 10, y: pressed ? 2 : 4)
            .brightness(pressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Secondary Button (Outlined Gold)
// Height: 48px, Transparent bg, gold outline, gold text

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(DarkFantasyTheme.gold)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                ZStack {
                    // Subtle radial glow on hover/press
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(
                            RadialGradient(
                                colors: [DarkFantasyTheme.gold.opacity(pressed ? 0.08 : 0.03), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                }
            )
            // Outer ornamental border
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.goldDim, lineWidth: 1.5)
            )
            // Inner bevel
            .innerBorder(
                cornerRadius: LayoutConstants.buttonRadius - 3,
                inset: 3,
                color: DarkFantasyTheme.gold.opacity(0.12)
            )
            // Corner brackets + diamonds
            .cornerBrackets(color: DarkFantasyTheme.gold)
            .cornerDiamonds(color: DarkFantasyTheme.gold)
            .brightness(pressed ? -0.05 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Danger Button (Crimson)
// Height: 48px, Red bg, white text

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(Color(hex: 0x8B1A22))
                    // Radial glow center
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(
                            RadialGradient(
                                colors: [DarkFantasyTheme.danger.opacity(0.2), Color.clear],
                                center: .init(x: 0.5, y: 0.4),
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                    SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadius, topHighlight: 0.06, bottomShadow: 0.2)
                }
            )
            .innerBorder(cornerRadius: LayoutConstants.buttonRadius - 3, inset: 3, color: DarkFantasyTheme.danger.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(Color(hex: 0x5A0A10), lineWidth: 2)
            )
            .cornerBrackets(color: DarkFantasyTheme.danger)
            .cornerDiamonds(color: Color(hex: 0xFF6B6B))
            .shadow(color: DarkFantasyTheme.dangerGlow, radius: pressed ? 16 : 8, y: pressed ? 2 : 4)
            .brightness(pressed ? -0.08 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Ghost Button (Text only — tertiary)

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Nav Grid Button (Hub navigation tiles)

struct NavGridButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.navButtonHeight)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                // Metallic highlight top edge
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                    .mask(
                        Rectangle().frame(height: 1).frame(maxHeight: .infinity, alignment: .top)
                    )
            }
            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Combat Toggle Button (1X / 2X speed — active state)

struct CombatToggleButtonStyle: ButtonStyle {
    var isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .foregroundStyle(isActive ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(isActive ? DarkFantasyTheme.gold : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(isActive ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Combat Control Button (SKIP — neutral action)

struct CombatControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.buttonRadius
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .brightness(configuration.isPressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Combat Forfeit Button (icon, danger accent)

struct CombatForfeitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DarkFantasyTheme.danger)
            .frame(width: LayoutConstants.buttonHeightMD, height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.danger.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.danger.opacity(0.3), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Close Button (X — modal dismiss)

struct CloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .frame(width: 32, height: 32)
            .background(
                Circle().fill(DarkFantasyTheme.bgTertiary)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiClose) }
            }
    }
}

// MARK: - Social Auth Button (Apple / Google sign-in)

struct SocialAuthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Compact Primary Button (Inline CTA — purchases, small gold actions)
// Like Primary but adapts to content size instead of full-width

struct CompactPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .foregroundStyle(isEnabled ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(isEnabled ? AnyShapeStyle(DarkFantasyTheme.goldGradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
                    if isEnabled {
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    center: .init(x: 0.5, y: 0.35),
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                        SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadius)
                    }
                }
            )
            .innerBorder(cornerRadius: LayoutConstants.buttonRadius - 2, inset: 2, color: isEnabled ? DarkFantasyTheme.goldBright.opacity(0.25) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(isEnabled ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
            )
            // Ornamental accents
            .cornerBrackets(color: isEnabled ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderSubtle, length: 10, thickness: 1.2)
            .cornerDiamonds(color: isEnabled ? DarkFantasyTheme.goldBright : DarkFantasyTheme.bgDisabled, size: 4)
            .shadow(color: isEnabled ? DarkFantasyTheme.goldGlow.opacity(pressed ? 0.7 : 0.5) : .clear, radius: pressed ? 10 : 6)
            .brightness(pressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed && isEnabled { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Danger Compact Button (Inline danger action — REVENGE, delete)

struct DangerCompactButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
            .foregroundStyle(isEnabled ? .white : DarkFantasyTheme.textDisabled)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.danger.opacity(isEnabled ? 0.2 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.danger.opacity(isEnabled ? 0.5 : 0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && isEnabled { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Compact Outline Button (Colored outline — BOOST, UNLOCK, compact secondary)
// Content-sized, colored outline + tinted fill

struct CompactOutlineButtonStyle: ButtonStyle {
    var color: Color = DarkFantasyTheme.textSecondary
    var fillOpacity: Double = 0.08

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
            .foregroundStyle(color)
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(color.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Danger Outline Button (Full-width danger outline — Logout)
// Height: 48px, Transparent bg, danger outline, danger text

struct DangerOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(DarkFantasyTheme.danger)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(configuration.isPressed ? DarkFantasyTheme.danger.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.danger.opacity(0.5), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Neutral Button (Full-width neutral — Link Account, settings actions)
// Height: 48px, bgTertiary fill, primary text

struct NeutralButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .foregroundStyle(isEnabled ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(isEnabled ? DarkFantasyTheme.bgTertiary : DarkFantasyTheme.bgDisabled)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && isEnabled { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Color Toggle Button (Generic active/inactive toggle — bets, zone selectors)

struct ColorToggleButtonStyle: ButtonStyle {
    var isActive: Bool
    var activeColor: Color = DarkFantasyTheme.gold
    var height: CGFloat = LayoutConstants.buttonHeightSM

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .foregroundStyle(isActive ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(isActive ? activeColor : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(isActive ? activeColor : DarkFantasyTheme.borderSubtle, lineWidth: isActive ? 2 : 1)
            )
            .opacity(isActive ? 1.0 : 0.6)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Fight Button (Combat CTA — fightButtonGradient + shine + shadow)
// Used in: Arena opponent sheet, Dungeon boss card

struct FightButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var accentColor: Color = DarkFantasyTheme.arenaRankGold

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .tracking(2)
            .foregroundStyle(isEnabled ? .white : DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                ZStack {
                    // Base ember gradient (deeper red → orange)
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                        .fill(isEnabled ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color(hex: 0x8B1A00), Color(hex: 0xD35400), Color(hex: 0xC44200)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        ) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
                    if isEnabled {
                        // Radial ember glow in center
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: 0xFF6600).opacity(0.25), Color.clear],
                                    center: .init(x: 0.5, y: 0.4),
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                        SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadiusLG, topHighlight: 0.08, bottomShadow: 0.25)
                    }
                }
            )
            // Inner bevel
            .innerBorder(
                cornerRadius: LayoutConstants.buttonRadiusLG - 3,
                inset: 3,
                color: isEnabled ? Color(hex: 0xFF6600).opacity(0.25) : Color.clear
            )
            // Outer dark iron frame
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .stroke(isEnabled ? Color(hex: 0x4A1500) : DarkFantasyTheme.borderSubtle, lineWidth: 2)
            )
            // Ember highlight line along top
            .overlay(alignment: .top) {
                if isEnabled {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(hex: 0xFF7832).opacity(0.5), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                }
            }
            // Corner brackets + diamonds
            .cornerBrackets(color: isEnabled ? Color(hex: 0xFF6600) : DarkFantasyTheme.borderSubtle)
            .cornerDiamonds(color: isEnabled ? Color(hex: 0xFF8833) : DarkFantasyTheme.bgDisabled)
            .sideDiamonds(color: isEnabled ? Color(hex: 0xFF8833) : Color.clear)
            .shadow(color: isEnabled ? accentColor.opacity(pressed ? 0.55 : 0.35) : .clear, radius: pressed ? 20 : 15, y: pressed ? 3 : 6)
            .shadow(color: isEnabled ? Color(hex: 0xFF5000).opacity(pressed ? 0.3 : 0.15) : .clear, radius: 8)
            .brightness(pressed ? -0.08 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed && isEnabled { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Compact Fight Button (Content-sized orange CTA — Refresh, secondary combat actions)
// Like FightButtonStyle but adapts to content size instead of full-width

struct CompactFightButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(isEnabled ? .white : DarkFantasyTheme.textDisabled)
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(isEnabled ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Color(hex: 0x8B1A00), Color(hex: 0xD35400), Color(hex: 0xC44200)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        ) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
                    if isEnabled {
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: 0xFF6600).opacity(0.2), Color.clear],
                                    center: .init(x: 0.5, y: 0.35),
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                        SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadius, topHighlight: 0.06, bottomShadow: 0.2)
                    }
                }
            )
            .innerBorder(
                cornerRadius: LayoutConstants.buttonRadius - 2,
                inset: 2,
                color: isEnabled ? Color(hex: 0xFF6600).opacity(0.2) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(isEnabled ? Color(hex: 0x4A1500) : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
            )
            .shadow(color: isEnabled ? Color(hex: 0xFF5000).opacity(pressed ? 0.4 : 0.2) : .clear, radius: 6)
            .brightness(pressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed && isEnabled { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

// MARK: - Scale Press Style (Pure press feedback — no chrome)
// Replaces: AppearanceButtonStyle, EditorAppearanceButtonStyle, CardTapStyle
// Now uses opacity instead of scale for consistency

struct ScalePressStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.9  // kept for API compat, ignored

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

// MARK: - Convenience Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(enabled: Bool) -> PrimaryButtonStyle { PrimaryButtonStyle(isEnabled: enabled) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

extension ButtonStyle where Self == NavGridButtonStyle {
    static var navGrid: NavGridButtonStyle { NavGridButtonStyle() }
}

extension ButtonStyle where Self == DangerButtonStyle {
    static var danger: DangerButtonStyle { DangerButtonStyle() }
}

extension ButtonStyle where Self == ScalePressStyle {
    static var scalePress: ScalePressStyle { ScalePressStyle() }
    static func scalePress(_ scale: CGFloat) -> ScalePressStyle { ScalePressStyle(pressedScale: scale) }
}

extension ButtonStyle where Self == CombatToggleButtonStyle {
    static func combatToggle(isActive: Bool) -> CombatToggleButtonStyle { CombatToggleButtonStyle(isActive: isActive) }
}

extension ButtonStyle where Self == CombatControlButtonStyle {
    static var combatControl: CombatControlButtonStyle { CombatControlButtonStyle() }
}

extension ButtonStyle where Self == CombatForfeitButtonStyle {
    static var combatForfeit: CombatForfeitButtonStyle { CombatForfeitButtonStyle() }
}

extension ButtonStyle where Self == CloseButtonStyle {
    static var closeButton: CloseButtonStyle { CloseButtonStyle() }
}

extension ButtonStyle where Self == SocialAuthButtonStyle {
    static var socialAuth: SocialAuthButtonStyle { SocialAuthButtonStyle() }
}

extension ButtonStyle where Self == FightButtonStyle {
    static var fight: FightButtonStyle { FightButtonStyle() }
    static func fight(accent: Color) -> FightButtonStyle { FightButtonStyle(accentColor: accent) }
}

extension ButtonStyle where Self == CompactPrimaryButtonStyle {
    static var compactPrimary: CompactPrimaryButtonStyle { CompactPrimaryButtonStyle() }
}

extension ButtonStyle where Self == DangerCompactButtonStyle {
    static var dangerCompact: DangerCompactButtonStyle { DangerCompactButtonStyle() }
}

extension ButtonStyle where Self == CompactFightButtonStyle {
    static var compactFight: CompactFightButtonStyle { CompactFightButtonStyle() }
}

extension ButtonStyle where Self == CompactOutlineButtonStyle {
    static func compactOutline(color: Color, fillOpacity: Double = 0.08) -> CompactOutlineButtonStyle {
        CompactOutlineButtonStyle(color: color, fillOpacity: fillOpacity)
    }
}

extension ButtonStyle where Self == DangerOutlineButtonStyle {
    static var dangerOutline: DangerOutlineButtonStyle { DangerOutlineButtonStyle() }
}

extension ButtonStyle where Self == NeutralButtonStyle {
    static var neutral: NeutralButtonStyle { NeutralButtonStyle() }
}

extension ButtonStyle where Self == ColorToggleButtonStyle {
    static func colorToggle(isActive: Bool, color: Color = DarkFantasyTheme.gold, height: CGFloat = LayoutConstants.buttonHeightSM) -> ColorToggleButtonStyle {
        ColorToggleButtonStyle(isActive: isActive, activeColor: color, height: height)
    }
}

// MARK: - Get More Button (Currency purchase CTA — gold outline, compact)
// Height: 36px, Gold 2px outline, gold tinted fill, gold text
// Used in: Shop currency bar — replaces hidden plus icon

struct GetMoreButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .padding(.horizontal, LayoutConstants.spaceMD)
            .frame(height: LayoutConstants.buttonHeightSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.gold.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.gold, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

extension ButtonStyle where Self == GetMoreButtonStyle {
    static var getMore: GetMoreButtonStyle { GetMoreButtonStyle() }
}

// MARK: - Premium Button (Purple → Pink gradient — Special offers)
// Height: 56px, purple→pink gradient bg, white text, pink border + shadow
// Used in: CurrencyPurchaseView Special tab — Premium Forever CTA

struct PremiumButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    private let gradient = LinearGradient(
        colors: [Color(hex: 0x7B2D8E), DarkFantasyTheme.purple, Color(hex: 0xC77DDF)],
        startPoint: .leading,
        endPoint: .trailing
    )

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .fill(isEnabled ? AnyShapeStyle(gradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
                    if isEnabled {
                        // Radial arcane glow
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .fill(
                                RadialGradient(
                                    colors: [DarkFantasyTheme.premiumPink.opacity(0.15), Color.clear],
                                    center: .init(x: 0.5, y: 0.35),
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                        SurfaceLightingOverlay(cornerRadius: LayoutConstants.buttonRadius, topHighlight: 0.08, bottomShadow: 0.15)
                    }
                }
            )
            .innerBorder(
                cornerRadius: LayoutConstants.buttonRadius - 3,
                inset: 3,
                color: isEnabled ? DarkFantasyTheme.premiumPink.opacity(0.2) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(isEnabled ? Color(hex: 0x6C3483) : DarkFantasyTheme.borderSubtle, lineWidth: 2)
            )
            .cornerBrackets(color: isEnabled ? DarkFantasyTheme.premiumPink : DarkFantasyTheme.borderSubtle)
            .cornerDiamonds(color: isEnabled ? DarkFantasyTheme.premiumPink : DarkFantasyTheme.bgDisabled)
            .sideDiamonds(color: isEnabled ? DarkFantasyTheme.premiumPink : Color.clear)
            .shadow(color: isEnabled ? DarkFantasyTheme.purple.opacity(pressed ? 0.45 : 0.3) : .clear, radius: pressed ? 16 : 12, y: pressed ? 2 : 4)
            .shadow(color: isEnabled ? DarkFantasyTheme.premiumPink.opacity(pressed ? 0.2 : 0.1) : .clear, radius: 8)
            .brightness(pressed ? -0.05 : 0)
            .onChange(of: configuration.isPressed) { _, newPressed in
                if newPressed && isEnabled { SFXManager.shared.play(.uiTapHeavy) }
            }
    }
}

extension ButtonStyle where Self == PremiumButtonStyle {
    static var premium: PremiumButtonStyle { PremiumButtonStyle() }
}
