import Foundation
import SwiftUI

struct Achievement: Codable, Identifiable {
    var id: String { key }
    let key: String
    let category: String
    let title: String
    let description: String
    let target: Int
    var progress: Int
    var completed: Bool
    var rewardClaimed: Bool
    let reward: AchievementReward?

    // No explicit CodingKeys needed — all properties match camelCase backend keys.

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    var canClaim: Bool {
        completed && !rewardClaimed
    }

    /// Number formatter for progress display (e.g., 1,500 / 2,200).
    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    var formattedProgress: String {
        Self.numberFormatter.string(from: NSNumber(value: progress)) ?? "\(progress)"
    }

    var formattedTarget: String {
        Self.numberFormatter.string(from: NSNumber(value: target)) ?? "\(target)"
    }

    /// SF Symbol name + color per category. Used by AchievementCardView instead of emoji.
    var categoryAsset: (String, Color) {
        switch category {
        case "pvp":         return ("swords", DarkFantasyTheme.danger)
        case "progression": return ("arrow.up.circle", DarkFantasyTheme.purple)
        case "ranking":     return ("trophy", DarkFantasyTheme.gold)
        default:            return ("star.fill", DarkFantasyTheme.textSecondary)
        }
    }

    // Legacy: kept for any code that still references it.
    var categoryIcon: String {
        switch category {
        case "pvp": "⚔️"
        case "progression": "📈"
        case "ranking": "🏆"
        default: "⭐"
        }
    }

    var rewardText: String {
        guard let reward else { return "" }
        var parts: [String] = []
        if let gold = reward.gold, gold > 0 { parts.append("\(gold) Gold") }
        if let gems = reward.gems, gems > 0 { parts.append("\(gems) Gems") }
        if let title = reward.title { parts.append("Title: \(title)") }
        if let frame = reward.frame { parts.append("Frame: \(frame)") }
        return parts.joined(separator: ", ")
    }
}

struct AchievementReward: Codable {
    let gold: Int?
    let gems: Int?
    let title: String?
    let frame: String?
}
