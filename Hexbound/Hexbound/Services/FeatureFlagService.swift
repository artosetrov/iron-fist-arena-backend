import Foundation

/// Typed accessors for feature flags resolved by the backend.
/// Flags are fetched as part of /api/game/init and cached in GameDataCache.
/// This enum provides compile-time safe keys and typed getters.
enum FeatureFlag: String {
    // Kill switches
    case maintenanceMode = "maintenance_mode"
    case pvpEnabled = "pvp_enabled"
    case dungeonRushEnabled = "dungeon_rush_enabled"
    case shellGameEnabled = "shell_game_enabled"
    case goldMineEnabled = "gold_mine_enabled"
    case iapEnabled = "iap_enabled"

    // Events
    case doubleXpEvent = "double_xp_event"

    // A/B tests (percentage-based — resolved to Bool server-side)
    case newCombatUi = "new_combat_ui"
    case newLootTable = "new_loot_table"

    // JSON config
    case forceUpdate = "force_update"
}

/// Convenience extensions on GameDataCache for typed flag access.
extension GameDataCache {

    /// Check if a typed flag is enabled (boolean / percentage flags).
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        isFeatureEnabled(flag.rawValue)
    }

    /// Get the JSON value for a config-style flag.
    func flagJSON(_ flag: FeatureFlag) -> [String: Any]? {
        featureFlags[flag.rawValue] as? [String: Any]
    }

    /// Force update config — returns (minVersion, message) or nil.
    var forceUpdateConfig: (minVersion: String, message: String)? {
        guard let dict = flagJSON(.forceUpdate),
              let version = dict["minVersion"] as? String,
              let message = dict["message"] as? String else { return nil }
        return (version, message)
    }
}
