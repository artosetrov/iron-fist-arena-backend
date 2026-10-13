import SwiftUI

// MARK: - Currency Package

struct CurrencyPackage: Identifiable {
    let id: String
    let currencyType: CurrencyType
    let amount: Int
    let bonusAmount: Int
    let priceUSD: String
    let productId: String // StoreKit product ID
    let isBestValue: Bool
    let isPopular: Bool
    let isSubscription: Bool
    /// Extra contents beyond `amount` — e.g. the gems and consumables in a
    /// bundle whose headline figure is gold. Shown under the amount so the
    /// card never understates what the player is paying for.
    let subtitle: String?
    /// What to name in the "purchase complete" message. The card subtitle is
    /// marketing copy with separators in it and reads badly in a sentence.
    let successSummary: String?

    init(id: String, currencyType: CurrencyType, amount: Int, bonusAmount: Int,
         priceUSD: String, productId: String, isBestValue: Bool, isPopular: Bool,
         isSubscription: Bool = false, subtitle: String? = nil,
         successSummary: String? = nil) {
        self.id = id
        self.currencyType = currencyType
        self.amount = amount
        self.bonusAmount = bonusAmount
        self.priceUSD = priceUSD
        self.productId = productId
        self.isBestValue = isBestValue
        self.isPopular = isPopular
        self.isSubscription = isSubscription
        self.subtitle = subtitle
        self.successSummary = successSummary
    }

    /// Per-tier illustration asset (gold only — gems use icon-gems for all tiers)
    var tierAsset: String? {
        switch id {
        // Economy v3 bundles reuse the retired gold-pack tier art so each
        // card still reads as its own tier instead of five identical coins.
        case "starter_bundle":        return "shop-gold-tier1"
        case "adventurer_bundle_I":   return "shop-gold-tier2"
        case "adventurer_bundle_II":  return "shop-gold-tier4"
        case "adventurer_bundle_III": return "shop-gold-tier5"
        default:                      return nil
        }
    }

    var totalAmount: Int { amount + bonusAmount }
    var displayAmount: String {
        if totalAmount >= 1000 {
            let k = Double(totalAmount) / 1000.0
            return k.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(k))K" : String(format: "%.1fK", k)
        }
        return "\(totalAmount)"
    }

    enum CurrencyType: String {
        case gold, gems
        var assetIcon: String { self == .gold ? "icon-gold" : "icon-gems" }
        var label: String { self == .gold ? "GOLD" : "GEMS" }
        var accentColor: Color { self == .gold ? DarkFantasyTheme.goldBright : DarkFantasyTheme.cyan }
    }
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case purchasing(packageId: String)
    case success(packageId: String)
    case failed(message: String)
}
