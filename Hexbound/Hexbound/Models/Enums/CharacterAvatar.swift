import Foundation

enum CharacterAvatar: String, Codable, CaseIterable, Identifiable {
    // Male avatars
    case warlord
    case knight
    case barbarian
    case shadow

    // Female avatars
    case valkyrie
    case sorceress
    case enchantress
    case huntress

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    /// Which gender this avatar belongs to
    var gender: CharacterGender {
        switch self {
        case .warlord, .knight, .barbarian, .shadow: .male
        case .valkyrie, .sorceress, .enchantress, .huntress: .female
        }
    }

    /// Avatars filtered by gender
    static func avatars(for gender: CharacterGender) -> [CharacterAvatar] {
        switch gender {
        case .male: [.warlord, .knight, .barbarian, .shadow]
        case .female: [.valkyrie, .sorceress, .enchantress, .huntress]
        }
    }

    /// Asset image name — maps to images in asset catalog
    var imageName: String {
        "avatar_\(rawValue)"
    }
}
