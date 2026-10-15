import SwiftUI

// MARK: - Currency Package

/// One App Store SKU on the GET CURRENCY screen. Display data only: contents
/// mirror `IAP_PRODUCTS` in backend/src/lib/game/balance.ts, and the server
/// decides what is actually granted.
///
/// There is deliberately no price here. Cards show StoreKit's localized
/// `displayPrice` — a hardcoded US figure is a false price in every other
/// storefront (same reasoning as `PremiumPurchaseView`).
struct CurrencyPackage: Identifiable {
    let id: String
    let currencyType: CurrencyType
    /// Headline figure: gems for a gem pack, gold for a bundle.
    let amount: Int
    let bonusAmount: Int
    let productId: String // StoreKit product ID
    /// Card title for named offers ("STARTER BUNDLE"). Gem packs have none —
    /// their amount is the title.
    let title: String?
    let isBestValue: Bool
    let isPopular: Bool
    /// Everything else in the box — the gems and consumables of a bundle whose
    /// headline figure is gold. Listed on the card so it never understates
    /// what the player is paying for.
    let extras: [PackageReward]

    init(id: String, currencyType: CurrencyType, amount: Int, bonusAmount: Int = 0,
         productId: String, title: String? = nil,
         isBestValue: Bool = false, isPopular: Bool = false,
         extras: [PackageReward] = []) {
        self.id = id
        self.currencyType = currencyType
        self.amount = amount
        self.bonusAmount = bonusAmount
        self.productId = productId
        self.title = title
        self.isBestValue = isBestValue
        self.isPopular = isPopular
        self.extras = extras
    }

    var totalAmount: Int { amount + bonusAmount }

    /// Bonus as a share of the base amount — 50 on 500 is 10. Nil when none.
    var bonusPercent: Int? {
        guard bonusAmount > 0, amount > 0 else { return nil }
        return Int((Double(bonusAmount) / Double(amount) * 100).rounded())
    }

    /// Everything the purchase grants, headline first.
    var rewards: [PackageReward] {
        [PackageReward(kind: currencyType == .gold ? .gold : .gems, quantity: totalAmount)] + extras
    }

    /// Per-tier illustration. Falls back to the plain currency icon while a
    /// tier's art is not in the asset catalog yet.
    var artAsset: String {
        let tier: String? = switch id {
        // Economy v3 bundles reuse the retired gold-pack tier art so each card
        // still reads as its own tier.
        case "starter_bundle":        "shop-gold-tier1"
        case "adventurer_bundle_I":   "shop-gold-tier2"
        case "adventurer_bundle_II":  "shop-gold-tier4"
        case "adventurer_bundle_III": "shop-gold-tier5"
        // docs/08_prompts/CURRENCY_GEMS_PROMPTS.md: shard → cluster → chalice → coffer → hoard
        case "gems_small":            "shop-gems-tier1"
        case "gems_medium":           "shop-gems-tier2"
        case "gems_large":            "shop-gems-tier3"
        case "gems_huge":             "shop-gems-tier4"
        case "gems_mega":             "shop-gems-tier5"
        default:                      nil
        }
        guard let tier, UIImage(named: tier) != nil else { return currencyType.assetIcon }
        return tier
    }

    enum CurrencyType: String {
        case gold, gems
        var assetIcon: String { self == .gold ? "icon-gold" : "icon-gems" }
        var label: String { self == .gold ? "GOLD" : "GEMS" }
        var accentColor: Color { self == .gold ? DarkFantasyTheme.goldBright : DarkFantasyTheme.cyan }
    }
}

// MARK: - Package Reward

/// One line of what a purchase grants — "3,000 Gold", "1 Protection Scroll".
struct PackageReward: Identifiable, Hashable {
    enum Kind: Hashable {
        case gold, gems, protectionScroll, legendaryShard
    }

    let kind: Kind
    let quantity: Int

    var id: Kind { kind }

    static func gems(_ quantity: Int) -> PackageReward { .init(kind: .gems, quantity: quantity) }
    static func protectionScrolls(_ quantity: Int) -> PackageReward { .init(kind: .protectionScroll, quantity: quantity) }
    static func legendaryShards(_ quantity: Int) -> PackageReward { .init(kind: .legendaryShard, quantity: quantity) }

    var noun: String {
        switch kind {
        case .gold: "Gold"
        case .gems: quantity == 1 ? "Gem" : "Gems"
        case .protectionScroll: quantity == 1 ? "Protection Scroll" : "Protection Scrolls"
        case .legendaryShard: quantity == 1 ? "Legendary Shard" : "Legendary Shards"
        }
    }

    /// "3,000 Gold", "5 Legendary Shards".
    var label: String { "\(quantity.formatted()) \(noun)" }

    var assetIcon: String {
        switch kind {
        case .gold: "icon-gold"
        case .gems: "icon-gems"
        case .protectionScroll: "icon-protection-scroll"
        case .legendaryShard: "icon-legendary-shard"
        }
    }

    /// SF Symbol shown only while the item art is missing from the catalog.
    var fallbackSymbol: String {
        switch kind {
        case .gold, .gems: "circle.fill"
        case .protectionScroll: "scroll.fill"
        case .legendaryShard: "diamond.fill"
        }
    }

    var accent: Color {
        switch kind {
        case .gold: DarkFantasyTheme.goldBright
        case .gems: DarkFantasyTheme.cyan
        case .protectionScroll: DarkFantasyTheme.textPrimary
        case .legendaryShard: DarkFantasyTheme.rarityLegendary
        }
    }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing(packageId: String)
    case success(packageId: String)
    case failed(message: String)
}
