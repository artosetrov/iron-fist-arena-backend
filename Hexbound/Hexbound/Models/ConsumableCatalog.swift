import Foundation
import SwiftUI

enum ConsumableCatalog {
    struct Metadata {
        let displayName: String
        let rarity: ItemRarity
        let imageKey: String
        let systemIcon: String
        let systemIconColor: Color
    }

    private static let metadataByID: [String: Metadata] = [
        "stamina_potion_small": Metadata(
            displayName: "Small Stamina Potion",
            rarity: .common,
            imageKey: "stamina_potion_small",
            systemIcon: "bolt.fill",
            systemIconColor: DarkFantasyTheme.success
        ),
        "stamina_potion_medium": Metadata(
            displayName: "Medium Stamina Potion",
            rarity: .uncommon,
            imageKey: "stamina_potion_medium",
            systemIcon: "bolt.fill",
            systemIconColor: DarkFantasyTheme.success
        ),
        "stamina_potion_large": Metadata(
            displayName: "Large Stamina Potion",
            rarity: .rare,
            imageKey: "stamina_potion_large",
            systemIcon: "bolt.fill",
            systemIconColor: DarkFantasyTheme.success
        ),
        "health_potion_small": Metadata(
            displayName: "Small Health Potion",
            rarity: .common,
            imageKey: "health_potion_small",
            systemIcon: "heart.fill",
            systemIconColor: DarkFantasyTheme.danger
        ),
        "health_potion_medium": Metadata(
            displayName: "Medium Health Potion",
            rarity: .uncommon,
            imageKey: "health_potion_medium",
            systemIcon: "heart.fill",
            systemIconColor: DarkFantasyTheme.danger
        ),
        "health_potion_large": Metadata(
            displayName: "Large Health Potion",
            rarity: .rare,
            imageKey: "health_potion_large",
            systemIcon: "heart.fill",
            systemIconColor: DarkFantasyTheme.danger
        ),
        "gem_pack_small": Metadata(
            displayName: "Small Gem Pack",
            rarity: .rare,
            imageKey: "gem_pack_small",
            systemIcon: "diamond.fill",
            systemIconColor: DarkFantasyTheme.cyan
        ),
        "gem_pack_medium": Metadata(
            displayName: "Medium Gem Pack",
            rarity: .epic,
            imageKey: "gem_pack_medium",
            systemIcon: "diamond.fill",
            systemIconColor: DarkFantasyTheme.cyan
        ),
        "gem_pack_large": Metadata(
            displayName: "Large Gem Pack",
            rarity: .legendary,
            imageKey: "gem_pack_large",
            systemIcon: "diamond.fill",
            systemIconColor: DarkFantasyTheme.cyan
        ),
    ]

    private static let legacyImageKeyMap: [String: String] = [
        "pot_stamina_small": "stamina_potion_small",
        "pot_stamina_medium": "stamina_potion_medium",
        "pot_stamina_large": "stamina_potion_large",
        "pot_health_small": "health_potion_small",
        "pot_health_medium": "health_potion_medium",
        "pot_health_large": "health_potion_large",
    ]

    static var knownIDs: [String] {
        Array(metadataByID.keys).sorted()
    }

    static func canonicalID(
        consumableType: String?,
        catalogId: String?,
        imageKey: String?
    ) -> String? {
        if let imageKey, let remapped = legacyImageKeyMap[imageKey] {
            return remapped
        }

        for raw in [consumableType, catalogId, imageKey] {
            guard let raw, !raw.isEmpty else { continue }
            if metadataByID[raw] != nil {
                return raw
            }
            if raw.contains("stamina") && raw.contains("large") { return "stamina_potion_large" }
            if raw.contains("stamina") && raw.contains("medium") { return "stamina_potion_medium" }
            if raw.contains("stamina") { return "stamina_potion_small" }
            if raw.contains("health") && raw.contains("large") { return "health_potion_large" }
            if raw.contains("health") && raw.contains("medium") { return "health_potion_medium" }
            if raw.contains("health") { return "health_potion_small" }
            if raw.contains("gem_pack") && raw.contains("large") { return "gem_pack_large" }
            if raw.contains("gem_pack") && raw.contains("medium") { return "gem_pack_medium" }
            if raw.contains("gem_pack") { return "gem_pack_small" }
        }

        return nil
    }

    static func metadata(
        consumableType: String?,
        catalogId: String?,
        imageKey: String?
    ) -> Metadata? {
        guard let id = canonicalID(
            consumableType: consumableType,
            catalogId: catalogId,
            imageKey: imageKey
        ) else {
            return nil
        }
        return metadataByID[id]
    }

    static func displayName(for id: String) -> String {
        metadataByID[id]?.displayName ?? humanizedName(for: id)
    }

    static func displayName(forKnownOrRaw raw: String) -> String {
        if let id = canonicalID(consumableType: raw, catalogId: raw, imageKey: raw) {
            return displayName(for: id)
        }
        return humanizedName(for: raw)
    }

    static func rarity(for id: String) -> ItemRarity? {
        metadataByID[id]?.rarity
    }

    static func resolvedImageKey(
        consumableType: String?,
        catalogId: String?,
        imageKey: String?
    ) -> String? {
        if let imageKey, !imageKey.isEmpty {
            return legacyImageKeyMap[imageKey] ?? imageKey
        }
        return metadata(consumableType: consumableType, catalogId: catalogId, imageKey: imageKey)?.imageKey
    }

    static func systemIcon(
        consumableType: String?,
        catalogId: String?,
        imageKey: String?
    ) -> String? {
        metadata(consumableType: consumableType, catalogId: catalogId, imageKey: imageKey)?.systemIcon
    }

    static func systemIconColor(
        consumableType: String?,
        catalogId: String?,
        imageKey: String?
    ) -> Color? {
        metadata(consumableType: consumableType, catalogId: catalogId, imageKey: imageKey)?.systemIconColor
    }

    private static func humanizedName(for raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
