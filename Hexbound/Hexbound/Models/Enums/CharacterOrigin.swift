import Foundation

enum CharacterOrigin: String, Codable, CaseIterable, Identifiable {
    case human
    case orc
    case skeleton
    case demon
    case dogfolk

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .human: "👤"
        case .orc: "👹"
        case .skeleton: "💀"
        case .demon: "😈"
        case .dogfolk: "🐕"
        }
    }

    var iconAsset: String {
        switch self {
        case .human: "race-icon-human"
        case .orc: "race-icon-orc"
        case .skeleton: "race-icon-skeleton"
        case .demon: "race-icon-demon"
        case .dogfolk: "race-icon-dogfolk"
        }
    }

    var bonuses: String {
        switch self {
        case .human: "+2 Charisma  +1 Luck"
        case .orc: "+3 Strength  -1 Charisma"
        case .skeleton: "+2 Endurance  +1 Intelligence"
        case .demon: "+2 Intelligence  +1 Strength"
        case .dogfolk: "+2 Agility  +1 Wisdom"
        }
    }

    var description: String {
        switch self {
        case .human: "Adaptable and charismatic. Bonus to gold and diplomacy."
        case .orc: "Brutal and powerful. Born warriors with primal strength."
        case .skeleton: "Undying resilience. Immune to poison, resistant to bleed."
        case .demon: "Infernal power. Dark magic runs through their veins."
        case .dogfolk: "Pack hunters. Enhanced senses and swift reflexes."
        }
    }
}
