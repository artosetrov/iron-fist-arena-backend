import Foundation
import SwiftUI

enum ItemRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var displayName: String {
        rawValue.uppercased()
    }

    /// Rarity color from the design system
    var color: Color {
        DarkFantasyTheme.rarityColor(for: self)
    }

    /// Numeric tier for animation scaling: 0=common → 4=legendary
    var tier: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}
