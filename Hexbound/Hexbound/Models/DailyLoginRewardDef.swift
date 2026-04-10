import Foundation

/// Server-driven daily login reward definition.
///
/// Mirrors `DailyLoginRewardDef` in `backend/src/lib/game/balance.ts`.
/// Comes down in the `/api/game/init` response under `config.dailyLoginRewards`.
///
/// W1.D3 SSoT contract (2026-04-10): the server is the single source of truth
/// for both the reward mechanics (`type`/`amount`/`itemId`) AND the display
/// label/icon. The client must NEVER hand-format `label` for known rewards —
/// always read `displayName` and map `displayIcon` through `assetName` below.
///
/// Offline / cold-start: when `cache.gameConfig == nil`, a bundled fallback
/// in `GameConfig.fallbackDailyRewards` is used so the UI never shows empty
/// cells. Fallback values must stay in sync with `balance.ts` (see CRIT-02).
struct DailyLoginRewardDef: Codable, Equatable {

    /// Mechanic type — drives backend rewarding logic, not display.
    /// Known values: `"gold" | "gems" | "consumable"`.
    let type: String

    /// Amount granted (gold pieces, gems, or consumable stack count).
    let amount: Int

    /// Consumable identifier (present only when `type == "consumable"`).
    /// Matches `ConsumableType` enum on the backend, e.g. `"stamina_potion_small"`.
    let itemId: String?

    /// Human-readable label authored on the server, e.g. `"150 Gold"` / `"1 S. Potion"`.
    /// When present, this is the authoritative label. Client-side label
    /// synthesis is only allowed as a fallback for missing/unknown values.
    let displayName: String?

    /// Asset key for the icon (authored on the server).
    /// See `assetName` below for the mapping to xcassets.
    let displayIcon: String?

    // MARK: - View derivation

    /// Resolve the xcassets image name for this reward.
    ///
    /// Priority:
    /// 1. Server-authored `displayIcon` → mapped through the icon catalog.
    /// 2. Derived from `type` + `itemId` (offline fallback / unknown server values).
    ///
    /// If a brand-new `displayIcon` ships on the server before the client
    /// adds it here, we degrade to the type-based fallback so nothing goes
    /// blank in the UI.
    var assetName: String {
        if let icon = displayIcon, let mapped = Self.iconAssetMap[icon] {
            return mapped
        }
        return Self.fallbackAssetName(type: type, itemId: itemId)
    }

    /// Resolve the label shown in the carousel / popup.
    ///
    /// Priority:
    /// 1. Server-authored `displayName`.
    /// 2. Client-side synthesis from `type` + `amount` + `itemId` (for old
    ///    cache entries that predate W1.D3, or for unknown `itemId`s).
    var resolvedLabel: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return Self.fallbackLabel(type: type, amount: amount, itemId: itemId)
    }

    // MARK: - Icon catalog

    /// Server `displayIcon` → xcassets image name.
    ///
    /// Keep this map exhaustive for every `displayIcon` value defined in
    /// `backend/src/lib/game/balance.ts` `DailyLoginRewardDef`. When the
    /// backend adds a new icon, add the mapping here in the same commit.
    private static let iconAssetMap: [String: String] = [
        "icon-gold":              "icon-gold",
        "icon-gems":              "icon-gems",
        "icon-stamina":           "icon-stamina",       // legacy
        "icon-stamina-small":     "icon-stamina",
        "icon-stamina-large":     "icon-stamina",
        "icon-hp-potion-small":   "icon-stamina",       // TODO: replace with real HP potion asset
        "icon-hp-potion-large":   "icon-stamina",       // TODO: replace with real HP potion asset
    ]

    /// Known-consumable label fallback. Used only when `displayName` is
    /// missing. Kept as a complete enumeration so we never show `"1×"` for
    /// any consumable we already know about.
    private static let consumableLabelMap: [String: (singular: String, plural: String)] = [
        "stamina_potion_small": ("S. Potion",  "S. Potions"),
        "stamina_potion_large": ("L. Potion",  "L. Potions"),
        "health_potion_small":  ("HP Potion",  "HP Potions"),
        "health_potion_large":  ("HP Potion+", "HP Potions+"),
        // NOTE: extend as new consumables are introduced in daily login.
    ]

    private static func fallbackAssetName(type: String, itemId: String?) -> String {
        switch type {
        case "gold": return "icon-gold"
        case "gems": return "icon-gems"
        case "consumable":
            // Every current consumable in daily login is a stamina potion.
            // When HP potions ship, add a dedicated `displayIcon` on the server.
            return "icon-stamina"
        default:
            return "icon-gold"
        }
    }

    private static func fallbackLabel(type: String, amount: Int, itemId: String?) -> String {
        switch type {
        case "gold": return "\(amount) Gold"
        case "gems": return "\(amount) Gems"
        case "consumable":
            if let id = itemId, let labels = consumableLabelMap[id] {
                let noun = amount == 1 ? labels.singular : labels.plural
                return "\(amount) \(noun)"
            }
            return "\(amount)×"
        default:
            return "\(amount)"
        }
    }
}
