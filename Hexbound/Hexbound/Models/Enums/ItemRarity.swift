import Foundation

enum ItemRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var displayName: String {
        rawValue.uppercased()
    }
}
