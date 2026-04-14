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

    init(id: String, currencyType: CurrencyType, amount: Int, bonusAmount: Int,
         priceUSD: String, productId: String, isBestValue: Bool, isPopular: Bool,
         isSubscription: Bool = false) {
        self.id = id
        self.currencyType = currencyType
        self.amount = amount
        self.bonusAmount = bonusAmount
        self.priceUSD = priceUSD
        self.productId = productId
        self.isBestValue = isBestValue
        self.isPopular = isPopular
        self.isSubscription = isSubscription
    }

    /// Per-tier illustration asset (gold only — gems use icon-gems for all tiers)
    var tierAsset: String? {
        switch id {
        case "gold_500":   return "shop-gold-tier1"
        case "gold_1200":  return "shop-gold-tier2"
        case "gold_3500":  return "shop-gold-tier3"
        case "gold_8000":  return "shop-gold-tier4"
        case "gold_20000": return "shop-gold-tier5"
        default:           return nil
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
