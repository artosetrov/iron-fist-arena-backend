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
                Image(systemName: "flame")
                    .font(.system(size: 12))
                Text("SPECIAL OFFERS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceMD) {
                    ForEach(Array(offers.enumerated()), id: \.element.id) { index, offer in
                        OfferCard(
                            offer: offer,
                            canAfford: canAfford(offer),
                            isBuying: buyingId == offer.id,
                            onBuy: { onBuy(offer) }
                        )
                        .staggeredAppear(index: index)
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
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.danger)
                        )
                        .shadow(color: DarkFantasyTheme.danger.opacity(0.4), radius: 4)
                }

                Spacer()

                if let remaining = offer.timeRemaining {
                    HStack(spacing: LayoutConstants.space2XS) {
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
                        HapticManager.heavy()
                        onBuy()
                    } label: {
                        if isBuying {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(DarkFantasyTheme.textPrimary)
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
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: (offer.hasDiscount ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold).opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    offer.hasDiscount
                        ? DarkFantasyTheme.stamina.opacity(0.5)
                        : DarkFantasyTheme.gold.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .cornerBrackets(
            color: (offer.hasDiscount ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold).opacity(0.3),
            length: 12,
            thickness: 1.5
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }
}
