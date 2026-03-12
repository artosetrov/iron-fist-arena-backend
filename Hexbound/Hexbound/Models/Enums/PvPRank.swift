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
        case ..<1100: .bronze
        case 1100..<1300: .silver
        case 1300..<1500: .gold
        case 1500..<1700: .platinum
        case 1700..<2000: .diamond
        default: .grandmaster
        }
    }

    var color: Color {
        DarkFantasyTheme.rankColor(for: minRating)
    }

    var icon: String {
        switch self {
        case .bronze: "🥉"
        case .silver: "🥈"
        case .gold: "🥇"
        case .platinum: "💎"
        case .diamond: "💠"
        case .grandmaster: "👑"
        }
    }

    var minRating: Int {
        switch self {
        case .bronze: 0
        case .silver: 1100
        case .gold: 1300
        case .platinum: 1500
        case .diamond: 1700
        case .grandmaster: 2000
        }
    }
}
