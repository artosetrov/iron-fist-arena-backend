import SwiftUI

/// W2.D4 — Snarky unlock copy for the building ceremony.
///
/// Each entry is the voice of a dark-fantasy NPC announcing a new building
/// has awakened. Tone: medieval braggadocio + dry humor. Kept SHORT because
/// the ceremony overlay auto-dismisses after ~3s.
///
/// Keys are CityBuilding.id values. If a key is missing we fall back to a
/// generic "{LABEL} is yours" line so a new building never crashes the flow.
///
/// Paired with `BuildingUnlockCeremony.swift` which reads these entries.
enum BuildingUnlockCatalog {
    struct Entry {
        let headline: String      // Big gold title
        let barkline: String      // Smaller subtitle, NPC voice
        let icon: String          // SF Symbol accent icon
        let accent: Color         // Accent color for the ceremony banner
    }

    /// Ordered by unlock level so the tone escalates from "small win" to
    /// "endgame is yours". Seven ceremonial entries — one per unlock building.
    static let entries: [String: Entry] = [
        "shop": Entry(
            headline: "THE SHOP OPENS",
            barkline: "The merchant sharpens his prices. Spend or perish.",
            icon: "bag.fill",
            accent: DarkFantasyTheme.gold
        ),
        "achievements": Entry(
            headline: "HALL OF DEEDS",
            barkline: "The scribes have noticed you. Try not to disappoint them.",
            icon: "medal.fill",
            accent: DarkFantasyTheme.toastAchievement
        ),
        "dungeon": Entry(
            headline: "THE DEPTHS CALL",
            barkline: "Something below just heard your name. It laughed.",
            icon: "door.left.hand.open",
            accent: DarkFantasyTheme.danger
        ),
        "gold-mine": Entry(
            headline: "THE MINE IS YOURS",
            barkline: "Gold for the patient. Rocks for everyone else.",
            icon: "hammer.fill",
            accent: DarkFantasyTheme.gold
        ),
        "tavern": Entry(
            headline: "THE TAVERN OPENS",
            barkline: "Drinks, rumors, questionable decisions. Come in.",
            icon: "mug.fill",
            accent: DarkFantasyTheme.toastReward
        ),
        "battlepass": Entry(
            headline: "THE LONG ROAD",
            barkline: "A pass for the devoted. Tiers stack higher than corpses.",
            icon: "star.circle.fill",
            accent: DarkFantasyTheme.toastLevelUp
        ),
        "ranks": Entry(
            headline: "THE LADDER AWAKENS",
            barkline: "Climb, fall, climb again. The crown is patient.",
            icon: "trophy.fill",
            accent: DarkFantasyTheme.toastRankUp
        ),
    ]

    /// Lookup with a sane fallback for unknown building IDs.
    static func entry(for buildingId: String, fallbackLabel: String) -> Entry {
        if let found = entries[buildingId] { return found }
        return Entry(
            headline: "\(fallbackLabel.uppercased()) OPENS",
            barkline: "A new door creaks open in the city.",
            icon: "building.columns.fill",
            accent: DarkFantasyTheme.gold
        )
    }

    /// Short anticipation bark shown on the level BEFORE unlock — toast only,
    /// not a full ceremony. Distinct voice: "something is coming".
    static func anticipationBark(for buildingId: String, fallbackLabel: String) -> String {
        switch buildingId {
        case "shop":        return "One more level — the merchant sets up shop."
        case "achievements": return "One more level — the scribes sharpen their quills."
        case "dungeon":     return "One more level — something below stirs."
        case "gold-mine":   return "One more level — the mine rumbles awake."
        case "tavern":      return "One more level — the tavern keeper unbars the door."
        case "battlepass":  return "One more level — the long road reveals itself."
        case "ranks":       return "One more level — the ladder descends for you."
        default:            return "One more level — \(fallbackLabel) awaits."
        }
    }
}
