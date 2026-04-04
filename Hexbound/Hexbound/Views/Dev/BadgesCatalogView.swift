#if DEBUG
import SwiftUI

// MARK: - Badges & Pills Catalog

/// Showcases all badge, pill, tag, and currency display components.
struct BadgesCatalogView: View {

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    widgetPillsSection
                    classTagsSection
                    glassStatPillsSection
                    cardLevelBadgesSection
                    currencyDisplaySection
                    equippedBadgeSection
                    statPointsBadgeSection
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
                Text("BADGES & PILLS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Widget Pills

    private var widgetPillsSection: some View {
        catalogSection("Widget Pills") {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    WidgetPill(icon: "trophy.fill", label: "1847", variant: .gold)
                    WidgetPill(icon: "flame.fill", label: "5 Streak", variant: .streak)
                    WidgetPill(icon: "shield.fill", label: "85", variant: .armor)
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    WidgetPill(icon: "bolt.fill", label: "90/120", variant: .stamina)
                    WidgetPill(icon: "heart.fill", label: "680/850", variant: .hp)
                    WidgetPill(icon: "star.fill", label: "Lv 25", variant: .level)
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    WidgetPill(icon: "person.2.fill", label: "Guild", variant: .info)
                    WidgetPill(icon: "exclamationmark.triangle", label: "Error", variant: .danger)
                }
            }
        }
    }

    // MARK: - Class Tags

    private var classTagsSection: some View {
        catalogSection("Class Tags") {
            HStack(spacing: LayoutConstants.spaceSM) {
                ClassTagView(characterClass: .warrior)
                ClassTagView(characterClass: .rogue)
                ClassTagView(characterClass: .mage)
                ClassTagView(characterClass: .tank)
            }
        }
    }

    // MARK: - Glass Stat Pills

    private var glassStatPillsSection: some View {
        catalogSection("Glass Stat Pills") {
            VStack(spacing: LayoutConstants.spaceSM) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    GlassStatPill(value: "45", label: "STR", color: DarkFantasyTheme.gold)
                    GlassStatPill(value: "22", label: "AGI", color: DarkFantasyTheme.gold)
                    GlassStatPill(value: "38", label: "VIT", color: DarkFantasyTheme.gold)
                }
                HStack(spacing: LayoutConstants.spaceSM) {
                    GlassStatPill(value: "1847", label: "Rating", color: DarkFantasyTheme.gold, size: .large)
                    GlassStatPill(value: "85", label: "ARM", color: DarkFantasyTheme.gold, size: .compact)
                }
            }
        }
    }

    // MARK: - Card Level Badges

    private var cardLevelBadgesSection: some View {
        catalogSection("Card Level Badges") {
            HStack(spacing: LayoutConstants.spaceMD) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    CardLevelBadge(level: 5)
                    Text("Standard")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                VStack(spacing: LayoutConstants.spaceXS) {
                    CardLevelBadge(level: 25)
                    Text("High")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                VStack(spacing: LayoutConstants.spaceXS) {
                    CardLevelBadge(level: 99)
                    Text("Max")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - Currency Display

    private var currencyDisplaySection: some View {
        catalogSection("Currency Display") {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
                HStack {
                    Text("Standard")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 72, alignment: .leading)
                    CurrencyDisplay(gold: 14500, gems: 320, size: .standard)
                }
                HStack {
                    Text("Compact")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 72, alignment: .leading)
                    CurrencyDisplay(gold: 14500, gems: 320, size: .compact)
                }
                HStack {
                    Text("Mini")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 72, alignment: .leading)
                    CurrencyDisplay(gold: 14500, size: .mini)
                }
                HStack {
                    Text("Gold Only")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 72, alignment: .leading)
                    CurrencyDisplay(gold: 14500, currencyType: .gold, size: .standard)
                }
                HStack {
                    Text("Gems Only")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 72, alignment: .leading)
                    CurrencyDisplay(gold: 0, gems: 320, currencyType: .gems, size: .standard)
                }
            }
        }
    }

    // MARK: - Equipped Badge

    private var equippedBadgeSection: some View {
        catalogSection("Equipped Badge") {
            HStack(spacing: LayoutConstants.spaceMD) {
                VStack(spacing: LayoutConstants.spaceXS) {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 72, height: 72)
                        .overlay(alignment: .topTrailing) {
                            EquippedBadge()
                        }
                    Text("Equipped")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
    }

    // MARK: - Stat Points Badge

    private var statPointsBadgeSection: some View {
        catalogSection("Stat Points Badge") {
            HStack(spacing: LayoutConstants.spaceMD) {
                StatPointsBadge(points: 3)
                StatPointsBadge(points: 10)
                StatPointsBadge(points: 0)
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
}

#Preview("Badges & Pills") {
    NavigationStack {
        BadgesCatalogView()
    }
}
#endif
