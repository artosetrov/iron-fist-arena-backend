#if DEBUG
import SwiftUI

// MARK: - Components Catalog

/// Showcases empty/error states, loading, skeleton, titles, tabs, banners, and modals.
struct ComponentsCatalogView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    ornamentalTitlesSection
                    tabSwitcherSection
                    emptyStatesSection
                    errorStatesSection
                    loadingSection
                    skeletonSection
                    bannersSection
                    feedbackSection
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
                Text("COMPONENTS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Ornamental Titles

    private var ornamentalTitlesSection: some View {
        catalogSection("Ornamental Title") {
            VStack(spacing: LayoutConstants.spaceMD) {
                OrnamentalTitle("Screen Title")
                OrnamentalTitle("With Subtitle", subtitle: "A secondary line of text")
                OrnamentalTitle("Custom Accent", accentColor: DarkFantasyTheme.danger)
            }
        }
    }

    // MARK: - Tab Switcher

    private var tabSwitcherSection: some View {
        catalogSection("Tab Switcher") {
            VStack(spacing: LayoutConstants.spaceMD) {
                TabSwitcher(tabs: ["OPPONENTS", "REVENGE", "HISTORY"], selectedIndex: $selectedTab)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)

                Text("Selected: \(selectedTab)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
    }

    // MARK: - Empty States

    private var emptyStatesSection: some View {
        catalogSection("Empty States") {
            VStack(spacing: LayoutConstants.spaceMD) {
                EmptyStateView(
                    icon: "shippingbox",
                    title: "No Items Yet",
                    message: "Visit the shop to gear up your character."
                )

                EmptyStateView(
                    icon: "scroll",
                    title: "No Quests Available",
                    message: "Check back tomorrow for new challenges.",
                    actionLabel: "Go to Hub"
                ) { }
            }
        }
    }

    // MARK: - Error States

    private var errorStatesSection: some View {
        catalogSection("Error States") {
            VStack(spacing: LayoutConstants.spaceMD) {
                ErrorStateView()

                ErrorStateView(
                    icon: "wifi.slash",
                    title: "No Connection",
                    message: "Check your internet and try again.",
                    retryLabel: "Retry"
                ) { }
            }
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        catalogSection("Loading Overlay") {
            ZStack {
                DarkFantasyTheme.bgTertiary
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))

                LoadingOverlay()
            }
        }
    }

    // MARK: - Skeleton

    private var skeletonSection: some View {
        catalogSection("Skeleton Views") {
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                SkeletonRect(height: LayoutConstants.spaceMD)
                SkeletonRect(width: 200, height: LayoutConstants.spaceMD)
                SkeletonRect(height: 80, cornerRadius: LayoutConstants.cardRadius)

                HStack(spacing: LayoutConstants.spaceSM) {
                    SkeletonRect(width: 48, height: 48, cornerRadius: LayoutConstants.radiusSM)
                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        SkeletonRect(width: 120, height: LayoutConstants.spaceMD)
                        SkeletonRect(width: 80, height: LayoutConstants.spaceMS)
                    }
                }
            }
        }
    }

    // MARK: - Banners

    private var bannersSection: some View {
        catalogSection("Banners") {
            VStack(spacing: LayoutConstants.spaceMD) {
                OfflineBannerView()

                LowHPPotionBanner(
                    character: MockData.character,
                    hasHealthPotion: true,
                    onDrinkPotion: { },
                    onGoToShop: { }
                )

                LowHPPotionBanner(
                    character: MockData.character,
                    hasHealthPotion: false,
                    onDrinkPotion: { },
                    onGoToShop: { }
                )
            }
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        catalogSection("Inline Feedback") {
            VStack(spacing: LayoutConstants.spaceMD) {
                Text("FloatingFeedbackText — triggers on state change")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                Text("InlineFeedback — shows contextual messages")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
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

#Preview("Components") {
    NavigationStack {
        ComponentsCatalogView()
    }
}
#endif
