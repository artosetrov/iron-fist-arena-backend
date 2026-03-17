import SwiftUI

// MARK: - Primary Button (Gold CTA — AAA Design Doc)
// Height: 56px, Gold gradient bg, dark text, ornamental border

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var envEnabled
    var isEnabled: Bool = true

    private var effectiveEnabled: Bool { isEnabled && envEnabled }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(effectiveEnabled ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(effectiveEnabled ? AnyShapeStyle(DarkFantasyTheme.goldGradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(effectiveEnabled ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.borderSubtle, lineWidth: 2)
            )
            .shadow(color: effectiveEnabled ? DarkFantasyTheme.goldGlow : .clear, radius: 12, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (Outlined Gold)
// Height: 48px, Transparent bg, gold outline, gold text

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(DarkFantasyTheme.gold)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(configuration.isPressed ? DarkFantasyTheme.gold.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.gold, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Danger Button (Crimson)
// Height: 48px, Red bg, white text

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.danger)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Ghost Button (Text only — tertiary)

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .opacity(configuration.isPressed ? 0.6 : 1)
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
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Compact Primary Button (Inline CTA — purchases, small gold actions)
// Like Primary but adapts to content size instead of full-width

struct CompactPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .foregroundStyle(isEnabled ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textDisabled)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(isEnabled ? AnyShapeStyle(DarkFantasyTheme.goldGradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(color.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Fight Button (Combat CTA — fightButtonGradient + shine + shadow)
// Used in: Arena opponent sheet, Dungeon boss card

struct FightButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var accentColor: Color = DarkFantasyTheme.arenaRankGold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DarkFantasyTheme.section(size: LayoutConstants.textButton - 2))
            .tracking(2)
            .foregroundStyle(isEnabled ? .white : DarkFantasyTheme.textDisabled)
            .frame(maxWidth: .infinity)
            .frame(height: LayoutConstants.buttonHeightLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .fill(isEnabled ? AnyShapeStyle(DarkFantasyTheme.fightButtonGradient) : AnyShapeStyle(DarkFantasyTheme.bgDisabled))
            )
            .shadow(color: isEnabled ? accentColor.opacity(0.4) : .clear, radius: 15, y: 6)
            .overlay(
                // Shine effect
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadiusLG)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isEnabled ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Scale Press Style (Pure press feedback — no chrome)
// Replaces: AppearanceButtonStyle, EditorAppearanceButtonStyle, CardTapStyle

struct ScalePressStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.9

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
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
