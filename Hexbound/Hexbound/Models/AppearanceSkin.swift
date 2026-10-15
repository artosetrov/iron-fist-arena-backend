import Foundation

/// Represents a skin from the backend `/api/appearances` catalog.
struct AppearanceSkin: Codable, Identifiable {
    let id: String
    let skinKey: String
    let name: String
    let origin: String
    let gender: String
    let rarity: String
    let priceGold: Int
    let priceGems: Int
    let imageUrl: String?
    let imageKey: String?
    let isDefault: Bool
    let sortOrder: Int
    /// Signed-in catalog only: the player already has this skin (default,
    /// Battle Pass reward or earlier purchase). `nil` from older backends or
    /// anonymous calls — treat as "not owned" unless `isDefault`.
    let owned: Bool?

    /// Catalog rarity as the shared item-rarity enum (unknown → common),
    /// so skin frames reuse `DarkFantasyTheme.rarityColor(for:)`.
    var itemRarity: ItemRarity {
        ItemRarity(rawValue: rarity) ?? .common
    }

    /// Display name for the skin (uppercased)
    var displayName: String {
        name.uppercased()
    }

    /// The key used to look up a local asset in the iOS bundle.
    /// Falls back to skinKey if imageKey is not set.
    var resolvedImageKey: String {
        imageKey ?? skinKey
    }

    /// Resolved URL for the skin image (remote fallback)
    var resolvedImageURL: URL? {
        guard let imageUrl, !imageUrl.isEmpty else { return nil }
        return URL(string: imageUrl)
    }
}

/// Wrapper for decoding the `/api/appearances` response: `{ "skins": [...] }`
struct AppearancesResponse: Codable {
    let skins: [AppearanceSkin]
}
