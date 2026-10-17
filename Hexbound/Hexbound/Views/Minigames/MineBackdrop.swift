import SwiftUI

/// The mine behind the whole Gold Mine screen (2026-10-17): timbered
/// tunnel mouth, the foreman's lantern, rails running into the dark. The
/// scrim is lighter than the shops' (`ShopRoomScrim`) — the cards are
/// opaque, so the mine can show around them.
struct MineBackdrop: View {
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("bg-gold-mine")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            LinearGradient(
                stops: [
                    .init(color: DarkFantasyTheme.bgAbyss.opacity(0.3), location: 0),
                    .init(color: DarkFantasyTheme.bgAbyss.opacity(0.45), location: 0.24),
                    .init(color: DarkFantasyTheme.bgAbyss.opacity(0.62), location: 0.42),
                    .init(color: DarkFantasyTheme.bgAbyss.opacity(0.74), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Gold and gems under the foreman, dressed as the mine's counter
/// (`ShopCounterBackground`), with the way to buy more — same bar as the
/// shop and the black market.
struct MineCounterBar: View {
    let gold: Int
    let gems: Int
    let onGetMore: () -> Void

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // No rolling digits on this screen — the totals just change.
            CurrencyDisplay(gold: gold, gems: gems, animated: false)
            Spacer()
            Button(action: onGetMore) {
                Text("GET MORE")
            }
            .buttonStyle(.getMore)
            .accessibilityLabel("Get more gold and gems")
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(ShopCounterBackground(style: .goldMine))
    }
}
