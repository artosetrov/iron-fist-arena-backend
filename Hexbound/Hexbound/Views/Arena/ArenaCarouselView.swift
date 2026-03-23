import SwiftUI

/// Paged carousel of opponents — 3 cards per page, swipe between pages.
/// Uses iOS 17+ ScrollView with `.scrollTargetBehavior(.paging)`.
struct ArenaCarouselView: View {
    let pages: [[Opponent]]
    let playerRating: Int
    let onSelect: (Opponent) -> Void
    @Binding var currentPage: Int

    @State private var scrolledID: Int?

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, opponents in
                        HStack(spacing: LayoutConstants.spaceSM) {
                            ForEach(opponents) { opponent in
                                ArenaOpponentCard(
                                    opponent: opponent,
                                    playerRating: playerRating,
                                    onTap: { onSelect(opponent) }
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .containerRelativeFrame(.horizontal)
                        .id(pageIndex)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrolledID)
            .frame(height: 220)
            .onChange(of: scrolledID) { _, newValue in
                if let newValue {
                    currentPage = newValue
                }
            }
            .onChange(of: currentPage) { _, newValue in
                if scrolledID != newValue {
                    scrolledID = newValue
                }
            }
            .onAppear {
                scrolledID = currentPage
            }

            // Page dots
            if pages.count > 1 {
                pageDots
            }
        }
    }

    // MARK: - Page Dots

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(index == currentPage ? DarkFantasyTheme.gold : DarkFantasyTheme.bgDarkPanelBorder)
                    .frame(
                        width: index == currentPage ? 20 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}
