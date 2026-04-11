import SwiftUI

/// Vertically-stacked list of special offers displayed above the regular shop grid.
///
/// Each offer is a full-width horizontal banner (no horizontal scroll) with:
///   • Header row — title + desc + discount ribbon + purchases counter
///   • Rewards row — up to 3 `ItemCardView(.offerReward)` tiles (single source of truth)
///   • Footer row — strikethrough original price + big "FREE"/price + `.primary` CTA
struct ShopOfferBannerView: View {
    let offers: [ShopOffer]
    let canAfford: (ShopOffer) -> Bool
    let buyingId: String?
    let onBuy: (ShopOffer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "flame")
                    .font(DarkFantasyTheme.body)
                Text("SPECIAL OFFERS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            VStack(spacing: LayoutConstants.spaceMD) {
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

// MARK: - Single Offer Card
//
// Redesigned 2026-04-10 — full-width horizontal banner (no scroll). Layout:
//
//   ┌─────────────────────────────────────────────────┐
//   │ STARTER PACK                       [-100%] [0/1]│  ← header
//   │ Welcome bonus for new warriors                  │
//   ├─────────────────────────────────────────────────┤
//   │  ┌────┐  ┌────┐  ┌────┐                         │  ← 3 ItemCardView
//   │  │ G  │  │ 🧪 │  │ XP │                         │    .offerReward
//   │  │×500│  │ ×3 │  │×17 │                         │
//   │  └────┘  └────┘  └────┘                         │
//   ├─────────────────────────────────────────────────┤
//   │ 499 gold  FREE                  [   CLAIM   ]   │  ← footer
//   └─────────────────────────────────────────────────┘

private struct OfferCard: View {
    let offer: ShopOffer
    let canAfford: Bool
    let isBuying: Bool
    let onBuy: () -> Void

    private var isFree: Bool { offer.salePrice == 0 }

    private var ctaLabel: String {
        if !offer.canPurchase { return "CLAIMED" }
        return isFree ? "CLAIM" : "BUY"
    }

    private var accent: Color {
        offer.hasDiscount ? DarkFantasyTheme.stamina : DarkFantasyTheme.gold
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            headerRow
            rewardsRow
            footerRow
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: accent.opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(accent.opacity(0.55), lineWidth: 1.5)
        )
        .cornerBrackets(
            color: accent.opacity(0.4),
            length: 14,
            thickness: 1.5
        )
        .cardShadow()
    }

    // MARK: Header row (title/desc + ribbon/counter)

    private var headerRow: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(offer.title.uppercased())
                    .font(DarkFantasyTheme.buttonLabel)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .tracking(0.5)
                    .lineLimit(1)

                if let desc = offer.displayDescription {
                    Text(desc)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                }

                if let remaining = offer.timeRemaining {
                    HStack(spacing: LayoutConstants.space2XS) {
                        Image(systemName: "clock")
                            .font(DarkFantasyTheme.badge)
                        Text(remaining)
                            .font(DarkFantasyTheme.badge)
                    }
                    .foregroundStyle(DarkFantasyTheme.stamina)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: LayoutConstants.space2XS) {
                if offer.hasDiscount {
                    Text("-\(offer.discountPct)%")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.danger)
                        )
                        .shadow(color: DarkFantasyTheme.danger.opacity(0.4), radius: 3)
                }

                if offer.maxPurchases > 0 {
                    HStack(spacing: LayoutConstants.space2XS) {
                        Circle()
                            .fill(offer.canPurchase ? DarkFantasyTheme.success : DarkFantasyTheme.textTertiary)
                            .frame(width: 5, height: 5)
                        Text("\(offer.purchasesMade)/\(offer.maxPurchases)")
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                    }
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                    )
                    .overlay(
                        Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: Rewards row (ItemCardView × up to 3)

    private var rewardsRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(offer.contents.prefix(3).enumerated()), id: \.offset) { _, content in
                OfferRewardMapper.card(for: content)
                    .allowsHitTesting(false)
            }
            // If fewer than 3 rewards, pad the row with transparent spacers so
            // the remaining cards keep their intrinsic square aspect instead of
            // ballooning to fill the full width.
            if offer.contents.count < 3 {
                ForEach(0..<(3 - offer.contents.count), id: \.self) { _ in
                    Color.clear
                }
            }
        }
    }

    // MARK: Footer row (price stack + CTA)

    private var footerRow: some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceMS) {
            VStack(alignment: .leading, spacing: 0) {
                if offer.hasDiscount {
                    Text(offer.displayOriginalPrice)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .strikethrough(true, color: DarkFantasyTheme.danger)
                }
                if isFree {
                    Text("FREE")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 6)
                } else {
                    Text(offer.displayPrice)
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }

            Spacer(minLength: LayoutConstants.spaceXS)

            Button {
                HapticManager.heavy()
                onBuy()
            } label: {
                Group {
                    if isBuying {
                        HexPulseLoader(.compact)
                    } else {
                        Text(ctaLabel)
                            .font(DarkFantasyTheme.buttonLabelCompact)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .frame(width: 140, height: 44)
            .disabled(!offer.canPurchase || (!canAfford && !isFree) || isBuying)
            .opacity((offer.canPurchase && (canAfford || isFree)) ? 1 : 0.5)
        }
    }
}

// MARK: - Offer Reward Mapper
//
// Maps an `OfferContent` (gold / gems / xp / consumable / item) to an
// `ItemCardView` with the `.offerReward` context. Reward cards use the SAME
// visual component as shop items — per `itemcard_unified_refactor` memory,
// ItemCardView is the single source of truth for every item tile in the game.

private enum OfferRewardMapper {

    /// Build an ItemCardView configured for an offer reward.
    @ViewBuilder
    static func card(for content: OfferContent) -> some View {
        let (rarity, imageKey, fallback) = visuals(for: content)
        ItemCardView(
            rarity: rarity,
            imageKey: imageKey,
            imageUrl: nil,
            fallbackIcon: fallback,
            context: .offerReward(label: label(for: content)),
            onTap: {}
        )
    }

    /// Rarity + imageKey + fallbackIcon per content type.
    private static func visuals(for content: OfferContent) -> (ItemRarity, String?, String) {
        switch content.type {
        case "gold":
            return (.legendary, "icon-gold", "shippingbox")
        case "gems":
            return (.epic, "icon-gems", "shippingbox")
        case "xp":
            return (.rare, "icon-xp", "shippingbox")
        case "consumable":
            // Catalog key is the asset name for seeded potions (e.g. health_potion_large)
            return (.uncommon, content.id, "shippingbox")
        case "item":
            return (.rare, content.id, "shippingbox")
        default:
            return (.common, nil, "shippingbox")
        }
    }

    /// Quantity label for the bottom bar ("×3", "×500", "×1K", "×1M").
    private static func label(for content: OfferContent) -> String {
        let q = content.quantity
        if q >= 1_000_000 { return "×\(q / 1_000_000)M" }
        if q >= 10_000 { return "×\(q / 1_000)K" }
        return "×\(q)"
    }
}
