import SwiftUI

enum PvPRank: String, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case diamond = "Diamond"
    case grandmaster = "Grandmaster"

    static func fromRating(_ rating: Int) -> PvPRank {
        switch rating {
        case ..<1200: .bronze
        case 1200..<1500: .silver
        case 1500..<1800: .gold
        case 1800..<2100: .platinum
        case 2100..<2400: .diamond
        default: .grandmaster
        }
    }

    var color: Color {
        DarkFantasyTheme.rankColor(for: minRating)
    }

    var icon: String {
        switch self {
        case .bronze: "shield"
        case .silver: "shield.fill"
        case .gold: "shield.lefthalf.filled"
        case .platinum: "star.shield"
        case .diamond: "diamond"
        case .grandmaster: "crown"
        }
    }

    /// Whether `icon` is an SF Symbol (true) or emoji (false)
    var iconIsSFSymbol: Bool { true }

    var minRating: Int {
        switch self {
        case .bronze: 0
        case .silver: 1200
        case .gold: 1500
        case .platinum: 1800
        case .diamond: 2100
        case .grandmaster: 2400
        }
    }
}
