import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy
    case normal
    case hard

    var displayName: String {
        rawValue.uppercased()
    }

    var staminaCost: Int {
        switch self {
        case .easy: 15
        case .normal: 20
        case .hard: 25
        }
    }
}
