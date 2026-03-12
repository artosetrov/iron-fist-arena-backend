import Foundation

enum ItemType: String, Codable, CaseIterable {
    case weapon
    case helmet
    case chest
    case gloves
    case legs
    case boots
    case accessory
    case amulet
    case belt
    case relic
    case necklace
    case ring
    case consumable

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .weapon: "⚔️"
        case .helmet: "🪖"
        case .chest: "🛡️"
        case .gloves: "🧤"
        case .legs: "👖"
        case .boots: "👢"
        case .accessory: "💍"
        case .amulet: "📿"
        case .belt: "🪢"
        case .relic: "🔮"
        case .necklace: "📿"
        case .ring: "💍"
        case .consumable: "🧪"
        }
    }

    var iconAsset: String? {
        switch self {
        case .weapon: "icon-weapon-offhand"
        case .helmet: "icon-helmet"
        case .chest: "icon-chest"
        case .gloves: "icon-gloves"
        case .legs: "icon-legs"
        case .boots: "icon-boots"
        case .amulet: "icon-amulet"
        case .belt: "icon-belt"
        case .relic: "icon-relic"
        case .ring: "icon-ring"
        default: nil
        }
    }
}
