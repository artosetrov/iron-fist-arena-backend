import SwiftUI

/// Horizontal carousel of special offers displayed above the regular shop grid.
struct ShopOfferBannerView: View {
    let offers: [ShopOffer]
    let canAfford: (ShopOffer) -> Bool
    let buyingId: String?
    let onBuy: (ShopOffer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("🔥")
                    .font(.system(size: 14))
                Text("SPECIAL OFFERS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceMD) {
                    ForEach(offers) { offer in
                        OfferCard(
                            offer: offer,
                            canAfford: canAfford(offer),
                            isBuying: buyingId == offer.id,
                            onBuy: { onBuy(offer) }
                        )
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
    }
}

// MARK: - Single Offer Card

private struct OfferCard: View {
    let offer: ShopOffer
    let canAfford: Bool
    let isBuying: Bool
    let onBuy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            // Header with type badge + timer
            HStack {
                if offer.hasDiscount {
                    Text("-\(offer.discountPct)%")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red.opacity(0.8))
                        )
                }

                Spacer()

                if let remaining = offer.timeRemaining {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                        Text(remaining)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    }
                    .foregroundStyle(DarkFantasyTheme.stamina)
                }
            }

            // Title
            Text(offer.title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            // Description
            if let desc = offer.description {
                Text(desc)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }

            // Contents summary
            Text(offer.contentsSummary)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.goldBright.opacity(0.8))
                .lineLimit(2)

            Spacer(minLength: 0)

            // Price + Buy
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    if offer.hasDiscount {
                        Text(offer.displayOriginalPrice)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .strikethrough()
                    }
                    Text(offer.displayPrice)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                Spacer()

                if !offer.canPurchase {
                    Text("SOLD")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                } else {
                    Button {
                        onBuy()
                    } label: {
                        if isBuying {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.7)
                        } else {
                            Text("BUY")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(!canAfford || isBuying)
                    .opacity(canAfford ? 1 : 0.5)
                }
            }

            // Purchase limit indicator
            if offer.maxPurchases > 0 {
                Text("\(offer.purchasesMade)/\(offer.maxPurchases) purchased")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .frame(width: 220, height: 200)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.bgSecondary,
                            DarkFantasyTheme.bgTertiary.opacity(0.6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    offer.hasDiscount
                        ? DarkFantasyTheme.stamina.opacity(0.5)
                        : DarkFantasyTheme.gold.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}
