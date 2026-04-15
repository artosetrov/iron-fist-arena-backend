import Foundation

struct Quest: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let title: String
    let description: String
    let icon: String
    let target: Int
    var progress: Int
    var completed: Bool
    var rewardClaimed: Bool
    let rewardGold: Int
    let rewardXp: Int
    let rewardGems: Int?
    // APIClient already converts snake_case -> camelCase.
    // Keep this DTO as plain camelCase to avoid double-conversion bugs.

    var progressFraction: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }

    var canClaim: Bool {
        completed && !rewardClaimed
    }
}
