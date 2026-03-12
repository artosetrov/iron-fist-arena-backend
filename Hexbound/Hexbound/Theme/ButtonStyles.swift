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
                    .fill(effectiveEnabled ? AnyShapeStyle(DarkFantasyTheme.goldGradient) : AnyShapeStyle(Color(hex: 0x333340)))
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
