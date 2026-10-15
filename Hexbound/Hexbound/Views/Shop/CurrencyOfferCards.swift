import SwiftUI

// Cards for GET CURRENCY (CurrencyPurchaseView). Prices arrive as StoreKit's
// localized `displayPrice` — nil until StoreKit has the product, never a
// guessed US figure.

/// Art sizes on the GET CURRENCY cards.
private enum ShopArt {
    static let tile: CGFloat = 96
    static let wide: CGFloat = 104
    static let bundle: CGFloat = 88
    static let hero: CGFloat = 112
    /// Label height inside `.compactPrimary` (8pt padding each side) that
    /// brings the button to the 48pt touch minimum.
    static let compactLabelHeight: CGFloat = LayoutConstants.touchMin - 2 * LayoutConstants.spaceSM
}

// MARK: - Starter Bundle (hero)

/// Hero card at the top of BUNDLES.
struct StarterBundleCard: View {
    let package: CurrencyPackage
    let price: String?
    let priceLoading: Bool
    let isPurchasing: Bool
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            HStack(alignment: .center, spacing: LayoutConstants.spaceMD) {
                Image(package.artAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: ShopArt.hero, height: ShopArt.hero)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                        Text(package.title ?? "Starter Bundle")
                            .font(DarkFantasyTheme.section)
                            .textCase(.uppercase)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .accessibilityAddTraits(.isHeader)
                        Text("A head start for new adventurers.")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                        ForEach(package.rewards) { reward in
                            PackageRewardRow(reward: reward)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            Button(action: onBuy) {
                PriceButtonLabel(price: price, isLoading: priceLoading, isPurchasing: isPurchasing)
            }
            .buttonStyle(.primary)
            .allowsHitTesting(!isPurchasing)
            .accessibilityLabel(buyLabel(package.spokenSummary, price: price, isPurchasing: isPurchasing))
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceLG)
        .padding(.bottom, LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.goldBright,
                glowIntensity: 0.14,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .premiumFrame(cornerRadius: LayoutConstants.cardRadius)
        .dualShadow(glowColor: DarkFantasyTheme.goldGlow, glowRadius: 12, depth: .elevated)
        .overlay(alignment: .top) {
            OfferRibbon(kind: .starter)
                .offset(y: -LayoutConstants.spaceMS)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Adventurer's Bundle

struct BundleOfferCard: View {
    let package: CurrencyPackage
    let price: String?
    let priceLoading: Bool
    let isPurchasing: Bool
    let onBuy: () -> Void

    private var accent: Color { package.currencyType.accentColor }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            HStack(alignment: .top, spacing: LayoutConstants.spaceMS) {
                Image(package.artAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: ShopArt.bundle, height: ShopArt.bundle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    if let title = package.title {
                        Text(title)
                            .font(DarkFantasyTheme.cardTitle)
                            .textCase(.uppercase)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9) // 18pt → never below the 16pt floor
                            .accessibilityAddTraits(.isHeader)
                    }
                    ForEach(package.rewards) { reward in
                        PackageRewardRow(reward: reward)
                    }
                }

                Spacer(minLength: 0)
            }

            Button(action: onBuy) {
                PriceButtonLabel(price: price, isLoading: priceLoading, isPurchasing: isPurchasing)
                    .frame(minHeight: ShopArt.compactLabelHeight)
            }
            .buttonStyle(.compactPrimary)
            .allowsHitTesting(!isPurchasing)
            .accessibilityLabel(buyLabel(package.spokenSummary, price: price, isPurchasing: isPurchasing))
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, package.isBestValue ? LayoutConstants.spaceLG : LayoutConstants.spaceMD)
        .padding(.bottom, LayoutConstants.spaceMD)
        .shopPanel(accent: accent, highlighted: package.isBestValue)
        .overlay(alignment: .top) {
            if package.isBestValue {
                OfferRibbon(kind: .bestValue)
                    .offset(y: -LayoutConstants.spaceMS)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Gem Pack Tile (2-column grid)

struct GemPackTile: View {
    let package: CurrencyPackage
    let price: String?
    let priceLoading: Bool
    let isPurchasing: Bool
    let onBuy: () -> Void

    private var accent: Color { package.currencyType.accentColor }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(package.artAsset)
                .resizable()
                .scaledToFit()
                .frame(width: ShopArt.tile, height: ShopArt.tile)
                .accessibilityHidden(true)

            GemAmountLabel(amount: package.totalAmount, accent: accent)

            BonusPill(percent: package.bonusPercent)

            Spacer(minLength: 0)

            Button(action: onBuy) {
                PriceButtonLabel(price: price, isLoading: priceLoading, isPurchasing: isPurchasing)
                    .frame(minHeight: ShopArt.compactLabelHeight)
            }
            .buttonStyle(.compactPrimary)
            .allowsHitTesting(!isPurchasing)
            .accessibilityLabel(buyLabel(package.spokenSummary, price: price, isPurchasing: isPurchasing))
        }
        // Same top inset with or without a ribbon, so tiles in a row line up.
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.top, LayoutConstants.spaceLG)
        .padding(.bottom, LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shopPanel(accent: accent, highlighted: package.ribbon != nil)
        .overlay(alignment: .top) {
            if let ribbon = package.ribbon {
                OfferRibbon(kind: ribbon)
                    .offset(y: -LayoutConstants.spaceMS)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Gem Pack Wide Card (the hoard closes the grid)

struct GemPackWideCard: View {
    let package: CurrencyPackage
    let price: String?
    let priceLoading: Bool
    let isPurchasing: Bool
    let onBuy: () -> Void

    private var accent: Color { package.currencyType.accentColor }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            Image(package.artAsset)
                .resizable()
                .scaledToFit()
                .frame(width: ShopArt.wide, height: ShopArt.wide)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                GemAmountLabel(amount: package.totalAmount, accent: accent, inline: true)
                BonusPill(percent: package.bonusPercent)

                Button(action: onBuy) {
                    PriceButtonLabel(price: price, isLoading: priceLoading, isPurchasing: isPurchasing)
                        .frame(minHeight: ShopArt.compactLabelHeight)
                }
                .buttonStyle(.compactPrimary)
                .allowsHitTesting(!isPurchasing)
                .accessibilityLabel(buyLabel(package.spokenSummary, price: price, isPurchasing: isPurchasing))
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceLG)
        .padding(.bottom, LayoutConstants.spaceMD)
        .shopPanel(accent: accent, highlighted: package.ribbon != nil)
        .overlay(alignment: .top) {
            if let ribbon = package.ribbon {
                OfferRibbon(kind: ribbon)
                    .offset(y: -LayoutConstants.spaceMS)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// "1,200 GEMS" — the headline of a gem pack.
private struct GemAmountLabel: View {
    let amount: Int
    let accent: Color
    var inline: Bool = false

    var body: some View {
        let layout = inline
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS))
            : AnyLayout(VStackLayout(spacing: 0))
        return layout {
            Text(amount.formatted())
                .font(DarkFantasyTheme.title)
                .foregroundStyle(accent)
                .monospacedDigit()
                .lineLimit(1)
            Text("GEMS")
                .font(DarkFantasyTheme.body)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }
}

// MARK: - Monthly Gem Card

/// Terms come from the server (GET /api/iap/offers → MONTHLY_GEM_CARD in
/// backend balance.ts): instant gems on purchase, then a daily payout on each
/// UTC day the player opens the game. Missed days are not paid out, so the
/// total is "up to". Buying while a card is active adds `days` to it.
struct MonthlyGemCardOffer: View {
    let terms: IAPOffers.GemCard
    /// "Up to 3× the gems of the 550-gem pack, same price". Nil hides it.
    let valueLine: String?
    let price: String?
    let priceLoading: Bool
    let isPurchasing: Bool
    let onBuy: () -> Void

    private var verb: String { terms.active ? "Add \(terms.days) Days" : "Get Gem Card" }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
            HStack(spacing: LayoutConstants.spaceMS) {
                Image("icon-gems")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("MONTHLY GEM CARD")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.cyan)
                        .accessibilityAddTraits(.isHeader)
                    Text("Up to \(terms.maxGems.formatted()) gems over \(terms.days) days")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            if terms.active {
                Text(activeText)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.cyan)
                    .badgeCapsule(color: DarkFantasyTheme.cyan)
            }

            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                OfferFeatureRow(
                    icon: .asset("hud-gift"),
                    text: "\(terms.instantGems.formatted()) gems right away",
                    tint: DarkFantasyTheme.cyan
                )
                OfferFeatureRow(
                    icon: .asset("hud-daily-login"),
                    text: "+\(terms.dailyGems.formatted()) gems each day you log in, for \(terms.days) days",
                    tint: DarkFantasyTheme.cyan
                )
            }

            if let valueLine {
                Text(valueLine)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textSuccess)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(terms.active
                 ? "Your remaining days are kept."
                 : "Log in each day to collect — missed days aren't paid out.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onBuy) {
                PriceButtonLabel(price: price, isLoading: priceLoading, isPurchasing: isPurchasing, verb: verb)
            }
            .buttonStyle(.primary)
            .allowsHitTesting(!isPurchasing)
            .accessibilityLabel(buyLabel(terms.active ? "\(terms.days) more days of the Monthly Gem Card" : "Monthly Gem Card",
                                         price: price, isPurchasing: isPurchasing))
        }
        .padding(LayoutConstants.spaceMD)
        .shopPanel(accent: DarkFantasyTheme.cyan, highlighted: true)
        .accessibilityElement(children: .contain)
    }

    private var activeText: String {
        terms.daysRemaining == 1 ? "ACTIVE · 1 DAY LEFT" : "ACTIVE · \(terms.daysRemaining) DAYS LEFT"
    }
}

// MARK: - Premium Pass teaser (navigates to PremiumPurchaseView)

struct PremiumUnlockCard: View {
    let price: String?
    let onOpen: () -> Void

    /// "SEE PREMIUM · $4.99 / MO" once StoreKit has the price.
    private var ctaTitle: String {
        guard let price else { return "See Premium" }
        return "See Premium · \(price) / mo"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
            HStack(spacing: LayoutConstants.spaceMS) {
                // No crown asset yet — same symbol as PremiumPurchaseView.
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
                    .foregroundStyle(DarkFantasyTheme.premiumPink)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("PREMIUM PASS")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.premiumPink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Monthly subscription · cancel anytime")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            // Only benefits the server grants — keep in step with
            // PremiumPurchaseView.features.
            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                OfferFeatureRow(icon: .symbol("bolt.fill"), text: "+20% XP from arena fights", tint: DarkFantasyTheme.premiumPink)
                OfferFeatureRow(icon: .asset("icon-gold"), text: "+10% gold from battles", tint: DarkFantasyTheme.goldBright)
                OfferFeatureRow(icon: .asset("icon-gems"), text: "300 gems every month", tint: DarkFantasyTheme.cyan)
            }

            Button(action: onOpen) {
                Text(ctaTitle)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .frame(height: LayoutConstants.buttonHeightLG)
            }
            .buttonStyle(.premium)
            .accessibilityLabel(price.map { "See Premium Pass, \($0) per month" } ?? "See Premium Pass")
        }
        .padding(LayoutConstants.spaceMD)
        .shopPanel(accent: DarkFantasyTheme.premiumPink, highlighted: true, base: DarkFantasyTheme.bgPremium)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Shared pieces

enum OfferRibbonKind {
    case bestValue, popular, starter

    var text: String {
        switch self {
        case .bestValue: "BEST VALUE"
        case .popular: "MOST POPULAR"
        // Once per account — enforced by the server (GET /api/iap/offers).
        case .starter: "ONE-TIME OFFER"
        }
    }

    var spokenText: String {
        switch self {
        case .bestValue: "Best value"
        case .popular: "Most popular"
        case .starter: "One-time offer"
        }
    }

    var fillColor: Color {
        switch self {
        case .bestValue, .starter: DarkFantasyTheme.goldBright
        case .popular: DarkFantasyTheme.purple
        }
    }

    var textColor: Color {
        switch self {
        case .bestValue, .starter: DarkFantasyTheme.textOnGold
        case .popular: DarkFantasyTheme.textPrimary
        }
    }
}

/// Labelled tag that sits on a card's top edge.
struct OfferRibbon: View {
    let kind: OfferRibbonKind

    var body: some View {
        Text(kind.text)
            .font(DarkFantasyTheme.buttonLabelCompact)
            .tracking(1.5)
            .foregroundStyle(kind.textColor)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(Capsule().fill(kind.fillColor))
            .overlay(Capsule().stroke(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1))
            .dualShadow(glowColor: kind.fillColor.opacity(DarkFantasyTheme.opacityStrong), glowRadius: 6, depth: .text)
            .fixedSize()
            .accessibilityLabel(kind.spokenText)
    }
}

/// "+20% BONUS". Laid out but invisible when there is no bonus, so tiles in a
/// row keep the same height.
struct BonusPill: View {
    let percent: Int?

    private var text: String { "+\(percent ?? 0)% BONUS" }

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(DarkFantasyTheme.textSuccess)
            .badgeCapsule(color: DarkFantasyTheme.success)
            .opacity(percent == nil ? 0 : 1)
            .accessibilityHidden(percent == nil)
    }
}

/// Content of a buy button: the localized price, a placeholder while StoreKit
/// is still loading, or a loader while the purchase runs.
struct PriceButtonLabel: View {
    let price: String?
    let isLoading: Bool
    let isPurchasing: Bool
    /// Leading words for full-width CTAs: "GET GEM CARD · $4.99".
    var verb: String? = nil

    var body: some View {
        Group {
            if isPurchasing {
                HexPulseLoader(.compact, tintColor: DarkFantasyTheme.textOnGold)
            } else if let price {
                Text(verb.map { "\($0) · \(price)" } ?? price)
            } else if isLoading {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if let verb {
                        Text("\(verb) ·")
                    }
                    Text("$0.00")
                        .redacted(reason: .placeholder)
                }
            } else {
                // StoreKit has no price for this SKU right now. Apple's sheet
                // shows the real one before the player confirms.
                Text(verb ?? "BUY")
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
    }
}

/// Icon + amount + noun: [scroll] 3 Protection Scrolls.
struct PackageRewardRow: View {
    let reward: PackageReward
    var iconSize: CGFloat = LayoutConstants.iconLG

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            RewardIcon(reward: reward, size: iconSize)
            HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                Text(reward.quantity.formatted())
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(reward.accent)
                    .monospacedDigit()
                Text(reward.noun)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reward.label)
    }
}

/// Catalog art for a reward. An SF Symbol stands in until the item art ships.
struct RewardIcon: View {
    let reward: PackageReward
    let size: CGFloat

    var body: some View {
        if UIImage(named: reward.assetIcon) != nil {
            Image(reward.assetIcon)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            // TODO: replace with asset — icon-protection-scroll / icon-legendary-shard (2026-10-15)
            Image(systemName: reward.fallbackSymbol)
                .resizable()
                .scaledToFit()
                .padding(size * 0.15)
                .frame(width: size, height: size)
                .foregroundStyle(reward.accent)
        }
    }
}

/// Icon + one line of what an offer gives.
struct OfferFeatureRow: View {
    enum Icon {
        case asset(String)
        case symbol(String)
    }

    let icon: Icon
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Group {
                switch icon {
                case .asset(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                case .symbol(let name):
                    Image(systemName: name)
                        .resizable()
                        .scaledToFit()
                        .padding(LayoutConstants.space2XS)
                        .foregroundStyle(tint)
                }
            }
            .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            .accessibilityHidden(true)

            Text(text)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Helpers

extension CurrencyPackage {
    /// Which ribbon the card wears, if any.
    var ribbon: OfferRibbonKind? {
        if isBestValue { return .bestValue }
        if isPopular { return .popular }
        return nil
    }

    /// What VoiceOver says the player is buying.
    var spokenSummary: String {
        if let title {
            return "\(title): " + rewards.map(\.label).joined(separator: ", ")
        }
        guard bonusAmount > 0 else { return "\(totalAmount.formatted()) gems" }
        return "\(totalAmount.formatted()) gems, including \(bonusAmount.formatted()) bonus"
    }
}

/// VoiceOver label for a buy button.
private func buyLabel(_ what: String, price: String?, isPurchasing: Bool) -> String {
    if isPurchasing { return "Purchasing \(what)" }
    guard let price else { return "Buy \(what)" }
    return "Buy \(what) for \(price)"
}

/// Standard shop panel (Hexbound/CLAUDE.md panel pattern) with an optional
/// accent highlight for featured offers.
private struct ShopPanel: ViewModifier {
    let accent: Color
    let highlighted: Bool
    let base: Color

    func body(content: Content) -> some View {
        let radius = LayoutConstants.cardRadius
        return content
            .background(
                RadialGlowBackground(
                    baseColor: base,
                    glowColor: highlighted ? accent : DarkFantasyTheme.bgTertiary,
                    glowIntensity: highlighted ? 0.14 : 0.4,
                    cornerRadius: radius
                )
            )
            .surfaceLighting(cornerRadius: radius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(
                cornerRadius: radius - 2,
                inset: 2,
                color: (highlighted ? accent : DarkFantasyTheme.borderMedium).opacity(DarkFantasyTheme.opacityMild)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        highlighted ? accent.opacity(0.55) : DarkFantasyTheme.borderSubtle,
                        lineWidth: highlighted ? 1.5 : 1
                    )
            )
            .cornerBrackets(color: accent.opacity(highlighted ? 0.6 : 0.3), length: 14, thickness: 1.5)
            .compositingGroup()
            .dualShadow(
                glowColor: highlighted ? accent.opacity(0.18) : .clear,
                glowRadius: 10,
                depth: .card
            )
    }
}

private extension View {
    func shopPanel(accent: Color, highlighted: Bool = false,
                   base: Color = DarkFantasyTheme.bgSecondary) -> some View {
        modifier(ShopPanel(accent: accent, highlighted: highlighted, base: base))
    }
}
