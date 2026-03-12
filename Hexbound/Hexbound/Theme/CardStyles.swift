import SwiftUI

// MARK: - Panel Card Modifier (AAA Design Doc)

struct PanelCardModifier: ViewModifier {
    var highlight: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        highlight ? DarkFantasyTheme.borderGold : DarkFantasyTheme.borderSubtle,
                        lineWidth: highlight ? 2 : 1
                    )
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                    .mask(
                        Rectangle().frame(height: 1).frame(maxHeight: .infinity, alignment: .top)
                    )
            }
            .shadow(
                color: highlight ? DarkFantasyTheme.goldGlow : .black.opacity(0.4),
                radius: highlight ? 12 : 4,
                y: 2
            )
    }
}

// MARK: - Rarity Card Modifier

struct RarityCardModifier: ViewModifier {
    let rarity: ItemRarity

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.rarityColor(for: rarity), lineWidth: 2)
            )
            .shadow(
                color: DarkFantasyTheme.rarityGlow(for: rarity),
                radius: rarity == .legendary ? 12 : 8,
                y: 2
            )
    }
}

// MARK: - Info Panel Modifier

struct InfoPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                    .mask(
                        Rectangle().frame(height: 1).frame(maxHeight: .infinity, alignment: .top)
                    )
            }
    }
}

// MARK: - Modal Overlay Modifier

struct ModalOverlayModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.spaceLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.8), radius: 32, y: 8)
    }
}

// MARK: - View Extensions

extension View {
    func panelCard(highlight: Bool = false) -> some View {
        modifier(PanelCardModifier(highlight: highlight))
    }

    func rarityCard(_ rarity: ItemRarity) -> some View {
        modifier(RarityCardModifier(rarity: rarity))
    }

    func infoPanel() -> some View {
        modifier(InfoPanelModifier())
    }

    func modalOverlay() -> some View {
        modifier(ModalOverlayModifier())
    }
}

// MARK: - Screen Background

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }
}

// MARK: - Gold Divider (ornamental gradient)

struct GoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.goldDim, DarkFantasyTheme.gold, DarkFantasyTheme.goldDim, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Ornamental Divider

struct OrnamentalDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
            Text("---")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.goldDim)
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle)
                .frame(height: 1)
        }
    }
}
