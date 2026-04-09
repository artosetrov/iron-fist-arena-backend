#if DEBUG
import SwiftUI

// MARK: - Cards & Ornamental Catalog

/// Showcases all card styles, ornamental primitives, dividers, and shadow depths.
struct CardsCatalogView: View {

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    cardStylesSection
                    rarityCardsSection
                    ornamentalPrimitivesSection
                    dividersSection
                    shadowDepthsSection
                    radiusScaleSection
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceMD)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("CARDS & ORNAMENTAL")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Card Styles

    private var cardStylesSection: some View {
        catalogSection("Card Styles") {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Panel Card
                Text("Panel Card (.panelCard())")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .panelCard()

                // Info Panel
                Text("Info Panel (.infoPanel())")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .infoPanel()

                // Modal Overlay
                Text("Modal Overlay (.modalOverlay())")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding(LayoutConstants.spaceMD)
                    .modalOverlay()

                // Screen Background
                HStack {
                    Text("Screen Background")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .screenBackground()
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            }
        }
    }

    // MARK: - Rarity Cards

    private var rarityCardsSection: some View {
        catalogSection("Rarity Cards") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LayoutConstants.spaceSM) {
                ForEach([ItemRarity.common, .uncommon, .rare, .epic, .legendary], id: \.self) { rarity in
                    VStack(spacing: LayoutConstants.spaceXS) {
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .frame(height: 80)
                            .rarityCard(rarity)

                        Text(rarity.rawValue.uppercased())
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.rarityColor(for: rarity))
                    }
                }
            }
        }
    }

    // MARK: - Ornamental Primitives

    private var ornamentalPrimitivesSection: some View {
        catalogSection("Ornamental Primitives") {
            VStack(spacing: LayoutConstants.spaceMD) {
                ornamentalSample("Corner Brackets") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .cornerBrackets()
                }

                ornamentalSample("Corner Diamonds") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .cornerDiamonds()
                }

                ornamentalSample("Side Diamonds") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .sideDiamonds()
                }

                ornamentalSample("Inner Border") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .innerBorder()
                }

                ornamentalSample("Surface Lighting") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .surfaceLighting()
                }

                ornamentalSample("Double Border") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 64)
                        .doubleBorder()
                }

                ornamentalSample("Ornamental Frame (combo)") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 80)
                        .ornamentalFrame()
                }

                ornamentalSample("Premium Frame (combo)") {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(height: 80)
                        .premiumFrame()
                }
            }
        }
    }

    // MARK: - Dividers

    private var dividersSection: some View {
        catalogSection("Dividers") {
            VStack(spacing: LayoutConstants.spaceLG) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("Gold Divider")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    GoldDivider()
                }

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("Ornamental Divider")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    OrnamentalDivider()
                }

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text("Etched Groove")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    EtchedGroove()
                }
            }
        }
    }

    // MARK: - Shadow Depths

    private var shadowDepthsSection: some View {
        catalogSection("Shadow Depths") {
            VStack(spacing: LayoutConstants.spaceMD) {
                ForEach(["Text (r:2, y:1)", "Panel (r:4, y:2)", "Card (r:6, y:3)", "Elevated (r:8, y:4)", "Modal (r:32, y:8)"], id: \.self) { label in
                    let depth: ShadowDepth = {
                        if label.hasPrefix("Text") { return .text }
                        if label.hasPrefix("Panel") { return .panel }
                        if label.hasPrefix("Card") { return .card }
                        if label.hasPrefix("Elevated") { return .elevated }
                        return .modal
                    }()

                    HStack {
                        Text(label)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                        Spacer()
                    }
                    .padding(LayoutConstants.spaceMD)
                    .background(DarkFantasyTheme.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                    .depthShadow(depth)
                }
            }
        }
    }

    // MARK: - Radius Scale

    private var radiusScaleSection: some View {
        catalogSection("Radius Scale") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: LayoutConstants.spaceSM) {
                radiusSample("XS (3)", LayoutConstants.radiusXS)
                radiusSample("SM (6)", LayoutConstants.radiusSM)
                radiusSample("MD (8)", LayoutConstants.radiusMD)
                radiusSample("LG (12)", LayoutConstants.radiusLG)
                radiusSample("XL (16)", LayoutConstants.radiusXL)
                radiusSample("2XL (22)", LayoutConstants.radius2XL)
            }
        }
    }

    // MARK: - Helpers

    private func catalogSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(title.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(DarkFantasyTheme.gold)

            content()
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    private func ornamentalSample<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            content()
        }
    }

    private func radiusSample(_ label: String, _ radius: CGFloat) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            RoundedRectangle(cornerRadius: radius)
                .fill(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityMedium))
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(DarkFantasyTheme.gold, lineWidth: 1)
                )
            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }
}

#Preview("Cards & Ornamental") {
    NavigationStack {
        CardsCatalogView()
    }
}
#endif
