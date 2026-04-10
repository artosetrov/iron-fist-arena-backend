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
                    .font(DarkFantasyTheme.body)
                Text("SPECIAL OFFERS")
                    .font(DarkFantasyTheme.section)
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
//
// Redesigned 2026-04-10 — fixes truncated text, "0 gold / 0 gold" price bug,
// and the BUY button overlapping content. New layout:
//
//   ┌────────────────────┐
//   │ [-100%]      [0/1] │  ← hero: ribbon TL + counter pill TR
//   │   [🪙] [🧪] [⚔]    │  ← item slots (38×38, rarity-tinted)
//   ├────────────────────┤
//   │ STARTER PACK       │  ← Oswald 18 title
//   │ Welcome bonus…     │  ← Inter 12 subtitle (2 lines max)
//   │  499 G       FREE  │  ← old strike + big gold FREE/price
//   │ ────────────────── │  ← gold ornamental divider
//   │ [      CLAIM     ] │  ← full-width .primary CTA
//   └────────────────────┘

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
        VStack(spacing: 0) {
            heroArea
            contentArea
        }
        .frame(width: 200, height: 284)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.45,
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
                .stroke(accent.opacity(0.5), lineWidth: 1.5)
        )
        .cornerBrackets(
            color: accent.opacity(0.35),
            length: 12,
            thickness: 1.5
        )
        .cardShadow()
    }

    // MARK: Hero (radial glow + item slots + ribbon + counter)

    private var heroArea: some View {
        ZStack {
            // Base linear gradient (top panel tint)
            LinearGradient(
                colors: [
                    DarkFantasyTheme.bgElevated.opacity(0.65),
                    DarkFantasyTheme.bgSecondary.opacity(0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Warm radial glow behind the slots
            RadialGradient(
                colors: [
                    DarkFantasyTheme.gold.opacity(0.22),
                    DarkFantasyTheme.gold.opacity(0.0)
                ],
                center: .center,
                startRadius: 4,
                endRadius: 86
            )

            // Item slots, centered
            HStack(spacing: LayoutConstants.spaceXS) {
                ForEach(Array(offer.contents.prefix(3).enumerated()), id: \.offset) { _, content in
                    OfferContentSlot(content: content)
                }
            }

            // Overlay chips: discount ribbon (TL) + purchases pill (TR)
            VStack {
                HStack(alignment: .top) {
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

                    Spacer(minLength: 0)

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
                Spacer(minLength: 0)
            }
            .padding(LayoutConstants.spaceXS)
        }
        .frame(height: 92)
        .overlay(
            // bottom divider separating hero from content
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: Content (title, description, price, CTA)

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            // Title (Oswald 18, uppercase)
            Text(offer.title.uppercased())
                .font(DarkFantasyTheme.buttonLabel)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .tracking(0.5)

            // Description (Inter 12, 2 lines)
            if let desc = offer.displayDescription {
                Text(desc)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Optional countdown (time-limited offers)
            if let remaining = offer.timeRemaining {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image(systemName: "clock")
                        .font(DarkFantasyTheme.badge)
                    Text(remaining)
                        .font(DarkFantasyTheme.badge)
                }
                .foregroundStyle(DarkFantasyTheme.stamina)
            }

            Spacer(minLength: LayoutConstants.space2XS)

            // Price row: old (strikethrough) ← → new (FREE or price)
            HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                if offer.hasDiscount {
                    Text(offer.displayOriginalPrice)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .strikethrough(true, color: DarkFantasyTheme.danger)
                }
                Spacer(minLength: 0)
                if isFree {
                    Text("FREE")
                        .font(DarkFantasyTheme.buttonLabel)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 6)
                } else {
                    Text(offer.displayPrice)
                        .font(DarkFantasyTheme.buttonLabel)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }

            // Ornamental gold divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DarkFantasyTheme.gold.opacity(0.0),
                            DarkFantasyTheme.gold.opacity(0.4),
                            DarkFantasyTheme.gold.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, LayoutConstants.space2XS)

            // Full-width CTA (uses .primary gold ornamental button style)
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
            .disabled(!offer.canPurchase || (!canAfford && !isFree) || isBuying)
            .opacity((offer.canPurchase && (canAfford || isFree)) ? 1 : 0.5)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceMS)
    }
}

// MARK: - Offer Content Slot (small 38×38 content preview tile)
//
// Renders a single OfferContent (gold / gems / xp / consumable / item) as a
// rarity-tinted square with a quantity badge in the bottom-right. Used inside
// the OfferCard hero area to show pack contents at a glance — replaces the old
// truncated `contentsSummary` text.

private struct OfferContentSlot: View {
    let content: OfferContent

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Slot background + rarity-tinted border
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgAbyss)
                .frame(width: 38, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(borderColor, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM - 1)
                        .stroke(borderColor.opacity(0.25), lineWidth: 0.5)
                        .padding(1)
                )
                .overlay(iconContent)
                .shadow(color: borderColor.opacity(0.35), radius: 4)

            // Quantity badge (bottom-right pill)
            Text(quantityLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.space2XS)
                .background(
                    Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
                )
                .offset(x: 2, y: 2)
        }
    }

    private var borderColor: Color {
        switch content.type {
        case "gold":       return DarkFantasyTheme.gold
        case "gems":       return DarkFantasyTheme.purple
        case "xp":         return DarkFantasyTheme.xpRing
        case "consumable": return DarkFantasyTheme.success
        default:           return DarkFantasyTheme.gold.opacity(0.6)
        }
    }

    private var quantityLabel: String {
        let q = content.quantity
        if q >= 1_000_000 { return "\(q / 1_000_000)M" }
        if q >= 10_000 { return "\(q / 1_000)K" }
        return "×\(q)"
    }

    @ViewBuilder
    private var iconContent: some View {
        switch content.type {
        case "gold":
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(Circle().stroke(DarkFantasyTheme.goldDim, lineWidth: 0.5))
                Text("G")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
            }
            .frame(width: 22, height: 22)

        case "gems":
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.purple, DarkFantasyTheme.purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 14, height: 14)
                .rotationEffect(.degrees(45))

        case "xp":
            ZStack {
                Circle().fill(DarkFantasyTheme.xpRing)
                Text("XP")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
            }
            .frame(width: 22, height: 22)

        case "consumable":
            // Generic potion silhouette (cap + flask body)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim)
                    .frame(width: 6, height: 3)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.success)
                    .frame(width: 14, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .stroke(DarkFantasyTheme.success.opacity(0.8), lineWidth: 0.5)
                    )
            }

        default:
            // Item placeholder — small elevated square with gold hint
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 20, height: 20)
        }
    }
}
