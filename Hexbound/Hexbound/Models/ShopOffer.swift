import Foundation

struct ShopOffer: Codable, Identifiable {
    let id: String
    let key: String
    let title: String
    let description: String?
    let offerType: String
    let contents: [OfferContent]
    let originalPrice: Int
    let salePrice: Int
    let currency: String
    let discountPct: Int
    let maxPurchases: Int
    let purchasesMade: Int
    let canPurchase: Bool
    let imageKey: String?
    let tags: [String]
    let startsAt: String?
    let endsAt: String?

    var isGemPurchase: Bool { currency == "gems" }

    var displayPrice: String {
        isGemPurchase ? "\(salePrice) gems" : "\(salePrice) gold"
    }

    var displayOriginalPrice: String {
        isGemPurchase ? "\(originalPrice) gems" : "\(originalPrice) gold"
    }

    var hasDiscount: Bool { discountPct > 0 }

    var hasTimeLimit: Bool { endsAt != nil }

    /// Remaining time description, or nil if no end date
    var timeRemaining: String? {
        guard let end = endsAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let endDate = formatter.date(from: end) else { return nil }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 { return "Expired" }
        let hours = Int(remaining) / 3600
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h" }
        if hours > 0 { return "\(hours)h" }
        let minutes = Int(remaining) / 60
        return "\(minutes)m"
    }

    /// Summary of contents for display
    var contentsSummary: String {
        contents.map { item in
            switch item.type {
            case "gold": return "\(item.quantity) Gold"
            case "gems": return "\(item.quantity) Gems"
            case "xp": return "\(item.quantity) XP"
            case "consumable": return "\(item.quantity)× \(Self.displayName(for: item.id ?? "potion"))"
            case "item": return "\(item.quantity)× \(Self.displayName(for: item.id ?? "item"))"
            default: return "\(item.quantity)× \(item.type)"
            }
        }.joined(separator: ", ")
    }

    /// Description with raw DB keys substituted for proper display names.
    /// Bug #11: Starter Pack description shipped with inline `health_potion_large`
    /// etc. — scrub ALL known keys before rendering so users never see raw
    /// snake_case identifiers in the UI.
    var displayDescription: String? {
        guard var desc = description else { return nil }
        for key in ConsumableCatalog.knownIDs {
            if desc.contains(key) {
                desc = desc.replacingOccurrences(of: key, with: ConsumableCatalog.displayName(for: key))
            }
        }
        return desc
    }

    /// Converts internal item keys to display names. Prefers the curated
    /// shared consumable catalog, then falls back to a cosmetic snake_case split.
    private static func displayName(for key: String) -> String {
        ConsumableCatalog.displayName(forKnownOrRaw: key)
    }
}

struct OfferContent: Codable {
    let type: String
    let id: String?
    let quantity: Int
}

struct ShopOffersResponse: Codable {
    let offers: [ShopOffer]
}

struct OfferPurchaseResponse: Codable {
    let success: Bool
    let gold: Int
    let gems: Int
    let xp: Int
    let leveledUp: Bool?
    let newLevel: Int?
    let statPointsAwarded: Int?
    let passivePointsAwarded: Int?
}
