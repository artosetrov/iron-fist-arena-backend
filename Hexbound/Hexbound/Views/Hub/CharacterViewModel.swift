import SwiftUI

@MainActor @Observable
final class CharacterViewModel {
    let appState: AppState
    private let service: CharacterService

    // Stat allocation tracking
    var pendingChanges: [StatType: Int] = [:]
    var isSaving = false
    var isRespeccing = false
    var errorMessage: String?

    var hasChanges: Bool {
        pendingChanges.values.contains(where: { $0 != 0 })
    }

    var pointsSpent: Int {
        pendingChanges.values.reduce(0, +)
    }

    var availablePoints: Int {
        (appState.currentCharacter?.statPoints ?? 0) - pointsSpent
    }

    init(appState: AppState) {
        self.appState = appState
        self.service = CharacterService(appState: appState)
    }

    func currentValue(for stat: StatType) -> Int {
        guard let char = appState.currentCharacter else { return 0 }
        return stat.value(from: char) + (pendingChanges[stat] ?? 0)
    }

    func increment(_ stat: StatType) {
        guard availablePoints > 0 else { return }
        pendingChanges[stat, default: 0] += 1
    }

    func decrement(_ stat: StatType) {
        guard (pendingChanges[stat] ?? 0) > 0 else { return }
        pendingChanges[stat, default: 0] -= 1
    }

    func resetChanges() {
        pendingChanges.removeAll()
    }

    // MARK: - Derived Stat Helpers

    /// Primary derived stat label with its current (preview) value, updates live as you allocate
    func primaryDerivedLabel(for stat: StatType) -> String {
        guard let char = appState.currentCharacter else { return "" }

        let str = currentValue(for: .strength)
        let agi = currentValue(for: .agility)
        let vit = currentValue(for: .vitality)
        let end = currentValue(for: .endurance)
        let int_ = currentValue(for: .intelligence)
        let wis = currentValue(for: .wisdom)
        let luk = currentValue(for: .luck)
        let cha = currentValue(for: .charisma)

        switch stat {
        case .strength:
            switch char.characterClass {
            case .warrior: return "Damage \(Int(Double(str) * 1.5) + char.level * 2)"
            case .tank:    return "Damage \(Int(Double(str) * 1.2) + char.level * 2)"
            default:       return "Armor \(end * 2 + Int(Double(str) * 0.5))"
            }
        case .agility:
            if char.characterClass == .rogue {
                return "Damage \(Int(Double(agi) * 1.5) + char.level * 2)"
            }
            return String(format: "Dodge %.1f%%", Double(agi) * 0.3)
        case .vitality:
            return "HP \(80 + vit * 5 + end * 3)"
        case .endurance:
            return "Armor \(end * 2 + Int(Double(str) * 0.5))"
        case .intelligence:
            if char.characterClass == .mage {
                return "M.Dmg \(Int(Double(int_) * 1.5) + char.level * 2)"
            }
            return "M.Resist \(wis * 2 + Int(Double(int_) * 0.5))"
        case .wisdom:
            return "M.Resist \(wis * 2 + Int(Double(int_) * 0.5))"
        case .luck:
            return String(format: "Crit %.1f%%", Double(luk) * 0.5)
        case .charisma:
            return "Gold +\(cha)%"
        }
    }

    /// Accumulated benefit hints — scales with pending delta (1 pt → "+1.5 Dmg", 3 pts → "+4.5 Dmg")
    func perPointBenefits(for stat: StatType) -> [String] {
        guard let char = appState.currentCharacter else { return [] }
        let delta = pendingChanges[stat] ?? 0
        let n = Double(max(delta, 1)) // show per-1 when nothing allocated yet

        func fmt(_ v: Double) -> String {
            v.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", v)
                : String(format: "%.1f", v)
        }

        switch stat {
        case .strength:
            var r: [String] = []
            switch char.characterClass {
            case .warrior: r.append("+\(fmt(1.5 * n)) Dmg")
            case .tank:    r.append("+\(fmt(1.2 * n)) Dmg")
            default: break
            }
            r.append("+\(fmt(0.5 * n)) Armor")
            return r
        case .agility:
            var r: [String] = []
            if char.characterClass == .rogue { r.append("+\(fmt(1.5 * n)) Dmg") }
            r.append("+\(fmt(0.3 * n))% Dodge")
            return r
        case .vitality:
            return ["+\(fmt(5 * n)) HP"]
        case .endurance:
            return ["+\(fmt(3 * n)) HP", "+\(fmt(2 * n)) Armor"]
        case .intelligence:
            var r: [String] = []
            if char.characterClass == .mage { r.append("+\(fmt(1.5 * n)) Dmg") }
            r.append("+\(fmt(0.5 * n)) M.Resist")
            return r
        case .wisdom:
            return ["+\(fmt(2 * n)) M.Resist"]
        case .luck:
            return ["+\(fmt(0.5 * n))% Crit"]
        case .charisma:
            return ["+\(fmt(n))% Gold"]
        }
    }

    func respecStats() {
        isRespeccing = true
        pendingChanges.removeAll()
        HapticManager.success()

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            let success = await service.respecStats()
            isRespeccing = false
            if !success {
                appState.showToast("Respec failed", subtitle: "Try again", type: .error)
            }
        }
    }

    func saveStats() {
        guard hasChanges else { return }
        isSaving = true

        // Build allocation dict: { "str": delta, ... } — delta values only
        var statChanges: [String: Int] = [:]
        for (stat, delta) in pendingChanges where delta > 0 {
            statChanges[stat.apiKey] = delta
        }

        // Optimistic: clear pending + show success instantly
        let savedPending = pendingChanges
        pendingChanges.removeAll()
        HapticManager.success()
        isSaving = false

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            let success = await service.allocateStats(statChanges: statChanges)
            if !success {
                // Revert on failure
                pendingChanges = savedPending
                appState.showToast("Failed to save stats", subtitle: "Try again", type: .error)
            }
        }
    }
}
