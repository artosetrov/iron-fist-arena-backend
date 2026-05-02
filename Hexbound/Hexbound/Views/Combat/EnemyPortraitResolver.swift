//
//  EnemyPortraitResolver.swift
//  Hexbound
//
//  Shared portrait-asset lookup for combat views (classic and interactive).
//  Combat surfaces need to map a fighter's display name → bundled portrait
//  asset for two enemy categories that don't carry a character `skinKey`:
//    • Dungeon bosses — name is matched against `DungeonInfo.bosses`.
//    • Rush mobs       — name is slugified into `rush-<slug>-portrait`,
//                        with a `-full` fallback before giving up.
//
//  Single source of truth so `CombatDetailView` (classic) and
//  `InteractiveBattleView.DuelFighterCard` (interactive combat) render the
//  same enemy art instead of one of them silently falling back to a class
//  icon. Keep this lookup centralized here rather than duplicating slightly
//  different heuristics across combat views.
//

import SwiftUI

/// Resolves bundled portrait asset names for non-PvP enemies (dungeon
/// bosses, rush mobs). Both call sites must use this resolver — do not
/// duplicate the lookup heuristics inline in views.
@MainActor
enum EnemyPortraitResolver {

    /// Find the boss portrait asset by matching the fighter's name against
    /// every dungeon boss known to the cache (or the bundled fallback list
    /// when the cache is cold). Case-insensitive, exact-match.
    static func bossPortraitImage(for name: String, cache: GameDataCache) -> String? {
        let lowered = name.lowercased()
        let dungeonSources: [DungeonInfo] = {
            if let cached = cache.cachedDungeonList(), !cached.isEmpty {
                return cached
            }
            return DungeonInfo.fallback
        }()
        for dungeon in dungeonSources {
            if let boss = dungeon.bosses.first(where: { $0.name.lowercased() == lowered }) {
                return boss.portraitImage
            }
        }
        return nil
    }

    /// Derive a rush enemy portrait asset from the fighter's name.
    /// "Flame Sprite" → "rush-flame-sprite-portrait", with a `-full`
    /// fallback before returning nil. The slug strips apostrophes and
    /// the standalone word "of" (e.g. "Lord of Ash" → "lord-ash") so the
    /// asset catalog stays terse.
    static func rushEnemyPortrait(for name: String) -> String? {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "of", with: "")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let portrait = "rush-\(slug)-portrait"
        if UIImage(named: portrait) != nil { return portrait }
        let full = "rush-\(slug)-full"
        if UIImage(named: full) != nil { return full }
        return nil
    }
}
