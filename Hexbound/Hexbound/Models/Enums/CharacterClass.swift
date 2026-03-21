import Foundation

enum CharacterClass: String, Codable, CaseIterable, Identifiable {
    case warrior
    case rogue
    case mage
    case tank

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .warrior: "⚔"
        case .rogue: "🗡️"
        case .mage: "🔮"
        case .tank: "🛡️"
        }
    }

    var description: String {
        switch self {
        case .warrior: "Masters of melee combat. Fearless front-liners who crush foes with raw power."
        case .rogue: "Silent and deadly. Strike from the shadows with precision and speed."
        case .mage: "Wielders of arcane power. Devastate enemies with elemental magic."
        case .tank: "Living fortresses. Absorb punishment and protect allies with iron will."
        }
    }

    var mainAttribute: String {
        switch self {
        case .warrior: "Strength"
        case .rogue: "Agility"
        case .mage: "Intelligence"
        case .tank: "Vitality"
        }
    }

    var mainAttributeDescription: String {
        switch self {
        case .warrior: "Deals devastating physical blows."
        case .rogue: "Can dodge enemy attacks."
        case .mage: "Unleashes powerful spells."
        case .tank: "Absorbs massive amounts of damage."
        }
    }

    var iconAsset: String {
        switch self {
        case .warrior: "icon-fights"
        case .rogue: "icon-rogue"
        case .mage: "icon-mage"
        case .tank: "icon-tank"
        }
    }

    var sfName: String {
        switch self {
        case .warrior: "Warrior"
        case .rogue: "Assassin"
        case .mage: "Mage"
        case .tank: "Guardian"
        }
    }

    var bonuses: String {
        switch self {
        case .warrior: "+3 Strength  +2 Vitality"
        case .rogue: "+3 Agility  +2 Luck"
        case .mage: "+3 Intelligence  +2 Wisdom"
        case .tank: "+3 Vitality  +2 Endurance"
        }
    }
}
