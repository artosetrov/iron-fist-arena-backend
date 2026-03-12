import Foundation

enum CharacterGender: String, Codable, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    var icon: String {
        switch self {
        case .male: "♂"
        case .female: "♀"
        }
    }
}
