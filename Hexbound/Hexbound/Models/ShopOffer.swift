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
        for key in Self.knownItemKeys.keys {
            if desc.contains(key) {
                desc = desc.replacingOccurrences(of: key, with: Self.knownItemKeys[key] ?? key)
            }
        }
        return desc
    }

    /// Bug #11: proper display names for all catalog items that might appear
    /// in bundle descriptions or offer content lists. Must stay in sync with
    /// `backend/prisma/migrations/*_seed_consumable_items/migration.sql`.
    private static let knownItemKeys: [String: String] = [
        "stamina_potion_small":  "Small Stamina Potion",
        "stamina_potion_medium": "Medium Stamina Potion",
        "stamina_potion_large":  "Large Stamina Potion",
        "health_potion_small":   "Small Health Potion",
        "health_potion_medium":  "Medium Health Potion",
        "health_potion_large":   "Large Health Potion",
        "gem_pack_small":        "Small Gem Pack",
        "gem_pack_medium":       "Medium Gem Pack",
        "gem_pack_large":        "Large Gem Pack",
    ]

    /// Converts internal item keys to display names. Prefers the curated
    /// `knownItemKeys` table, then falls back to a cosmetic snake_case split.
    private static func displayName(for key: String) -> String {
        if let curated = knownItemKeys[key] { return curated }
        return key.replacingOccurrences(of: "_", with: " ").capitalized
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
}
