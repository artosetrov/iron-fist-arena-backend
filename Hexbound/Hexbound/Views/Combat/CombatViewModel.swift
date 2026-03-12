import SwiftUI

@MainActor @Observable
final class CombatViewModel {
    let appState: AppState
    let combatData: CombatData

    // Fighter state
    var playerHp: Int
    var enemyHp: Int
    let playerMaxHp: Int
    let enemyMaxHp: Int

    // Turn / Round state
    var currentTurnIndex = -1
    var totalTurns: Int
    var currentRound = 0
    var turnLabel = "Preparing..."
    var turnLabelColor: Color = DarkFantasyTheme.textSecondary

    // Current action display
    var currentAttackZone: String?
    var currentDefendZone: String?

    // Combat log entries for display
    var visibleLogEntries: [CombatLogEntry] = []

    // Animation state
    var playerSlideX: CGFloat = 0
    var enemySlideX: CGFloat = 0
    var playerFlash = false
    var enemyFlash = false
    var playerStatuses: [StatusEffect] = []
    var enemyStatuses: [StatusEffect] = []
    var damagePopups: [DamagePopup] = []

    // Control
    var speedMode = 0 // 0 = 1x, 1 = 2x
    var isPlaying = false
    var isFinished = false
    var skipRequested = false
    var isNavigatingToResult = false

    // Callbacks
    var onHit: ((_ isCrit: Bool) -> Void)?

    var speedMultiplier: Double {
        speedMode == 1 ? 0.5 : 1.0
    }

    var speedLabel: String {
        speedMode == 0 ? "1x" : "2x"
    }

    init(appState: AppState, combatData: CombatData) {
        self.appState = appState
        self.combatData = combatData
        self.playerHp = combatData.player.currentHp ?? combatData.player.maxHp
        self.enemyHp = combatData.enemy.currentHp ?? combatData.enemy.maxHp
        self.playerMaxHp = combatData.player.maxHp
        self.enemyMaxHp = combatData.enemy.maxHp
        self.totalTurns = combatData.combatLog.count
    }

    // MARK: - Playback

    func play() async {
        guard !isPlaying else { return }
        isPlaying = true

        // Small initial delay
        try? await Task.sleep(for: .seconds(0.5))

        for i in 0..<combatData.combatLog.count {
            if skipRequested { break }

            currentTurnIndex = i
            let turn = combatData.combatLog[i]
            let isPlayerAttacking = turn.attackerId == combatData.player.id

            // Update round (every 2 turns = 1 round, or each turn is a round)
            currentRound = (i / 2) + 1

            // Update turn label — show attack vs defense context
            withAnimation(.easeInOut(duration: 0.2)) {
                if isPlayerAttacking {
                    turnLabel = "YOUR ATTACK"
                    turnLabelColor = DarkFantasyTheme.danger
                } else {
                    turnLabel = "YOUR DEFENSE"
                    turnLabelColor = DarkFantasyTheme.info
                }
            }

            // Update action zones
            withAnimation(.easeInOut(duration: 0.2)) {
                currentAttackZone = turn.targetZone?.uppercased()
                currentDefendZone = turn.defendZone?.uppercased()
            }

            // Animate this turn
            await animateTurn(turn, isPlayerAttacking: isPlayerAttacking)

            // Add to visible combat log
            addLogEntry(turn, isPlayerAttacking: isPlayerAttacking)

            // Inter-turn delay
            if !skipRequested {
                try? await Task.sleep(for: .seconds(0.3 * speedMultiplier))
            }
        }

        // Combat finished (guard against double call when skip() already called finishCombat)
        if !isFinished { finishCombat() }
    }

    private func animateTurn(_ turn: CombatLog, isPlayerAttacking: Bool) async {
        let sm = speedMultiplier

        // 1. Attacker slides forward
        withAnimation(.easeOut(duration: 0.15 * sm)) {
            if isPlayerAttacking {
                playerSlideX = 40
            } else {
                enemySlideX = -40
            }
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))

        // 2. Hit effects
        if !turn.isMiss && !turn.isDodge && turn.damage > 0 {
            // Flash on defender + screen shake
            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking {
                    enemyFlash = true
                } else {
                    playerFlash = true
                }
            }
            onHit?(turn.isCrit)
            try? await Task.sleep(for: .seconds(0.15 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        // 3. Damage popup
        spawnDamagePopup(turn: turn, isPlayerAttacking: isPlayerAttacking)

        // 4. Update HP
        withAnimation(.easeInOut(duration: 0.3 * sm)) {
            if isPlayerAttacking {
                enemyHp = max(0, enemyHp - turn.damage)
            } else {
                playerHp = max(0, playerHp - turn.damage)
            }

            // Heal
            if let heal = turn.heal, heal > 0 {
                if isPlayerAttacking {
                    playerHp = min(playerMaxHp, playerHp + heal)
                } else {
                    enemyHp = min(enemyMaxHp, enemyHp + heal)
                }
            }
        }
        try? await Task.sleep(for: .seconds(0.3 * sm))

        // 5. Status effect
        if let status = turn.statusApplied, !status.isEmpty {
            let effect = StatusEffect(name: status)
            withAnimation(.easeIn(duration: 0.2)) {
                if isPlayerAttacking {
                    if !enemyStatuses.contains(where: { $0.name == status }) {
                        enemyStatuses.append(effect)
                    }
                } else {
                    if !playerStatuses.contains(where: { $0.name == status }) {
                        playerStatuses.append(effect)
                    }
                }
            }
        }

        // 6. Attacker slides back
        withAnimation(.easeIn(duration: 0.15 * sm)) {
            playerSlideX = 0
            enemySlideX = 0
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))
    }

    private func spawnDamagePopup(turn: CombatLog, isPlayerAttacking: Bool) {
        let popup: DamagePopup
        if turn.isMiss {
            popup = DamagePopup(text: "MISS", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else if turn.isDodge {
            popup = DamagePopup(text: "DODGE", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else {
            let text = turn.isCrit ? "\(turn.damage)!" : "\(turn.damage)"
            let dmgStyle = DamageTypeStyle(from: turn.damageType)
            let color = dmgStyle.color
            popup = DamagePopup(text: text, color: color, isCrit: turn.isCrit, onDefender: !isPlayerAttacking)
        }

        damagePopups.append(popup)

        // Heal popup
        if let heal = turn.heal, heal > 0 {
            let healPopup = DamagePopup(text: "+\(heal)", color: DarkFantasyTheme.success, isCrit: false, onDefender: isPlayerAttacking)
            damagePopups.append(healPopup)
        }

        // Auto-remove after animation
        let popupId = popup.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            damagePopups.removeAll { $0.id == popupId }
        }
    }

    private func addLogEntry(_ turn: CombatLog, isPlayerAttacking: Bool) {
        let attackerName = isPlayerAttacking ? combatData.player.characterName : combatData.enemy.characterName
        let zone = turn.targetZone?.capitalized ?? "Body"
        let dmgStyle = DamageTypeStyle(from: turn.damageType)
        let actionVerb = turn.skillUsed ?? "attacks"

        let entry: CombatLogEntry
        if turn.isDodge {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "DODGE!",
                resultColor: DarkFantasyTheme.textTertiary,
                damageTypeLabel: nil,
                damageTypeColor: nil
            )
        } else if turn.isMiss {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "MISS!",
                resultColor: DarkFantasyTheme.textTertiary,
                damageTypeLabel: nil,
                damageTypeColor: nil
            )
        } else if turn.isBlocked {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "Blocked! -\(turn.damage)",
                resultColor: DarkFantasyTheme.info,
                damageTypeLabel: dmgStyle.label,
                damageTypeColor: dmgStyle.color
            )
        } else if turn.isCrit {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "CRIT! -\(turn.damage)",
                resultColor: dmgStyle.color,
                damageTypeLabel: dmgStyle.label,
                damageTypeColor: dmgStyle.color
            )
        } else {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "-\(turn.damage)",
                resultColor: dmgStyle.color,
                damageTypeLabel: dmgStyle.label,
                damageTypeColor: dmgStyle.color
            )
        }

        withAnimation(.easeIn(duration: 0.2)) {
            visibleLogEntries.append(entry)
        }
    }

    func skip() {
        skipRequested = true
        // Instantly apply all remaining turns
        for i in max(0, currentTurnIndex + 1)..<combatData.combatLog.count {
            let turn = combatData.combatLog[i]
            let isPlayerAttacking = turn.attackerId == combatData.player.id
            if isPlayerAttacking {
                enemyHp = max(0, enemyHp - turn.damage)
            } else {
                playerHp = max(0, playerHp - turn.damage)
            }
            if let heal = turn.heal, heal > 0 {
                if isPlayerAttacking {
                    playerHp = min(playerMaxHp, playerHp + heal)
                } else {
                    enemyHp = min(enemyMaxHp, enemyHp + heal)
                }
            }
            addLogEntry(turn, isPlayerAttacking: isPlayerAttacking)
        }
        currentTurnIndex = combatData.combatLog.count - 1
        currentRound = (currentTurnIndex / 2) + 1
        damagePopups.removeAll()
        finishCombat()
    }

    func toggleSpeed() {
        speedMode = speedMode == 0 ? 1 : 0
    }

    private func finishCombat() {
        isFinished = true
        isPlaying = false
        let isWin = combatData.result.isWin
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            turnLabel = isWin ? "VICTORY!" : "DEFEAT"
            turnLabelColor = isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger
            currentAttackZone = nil
            currentDefendZone = nil
        }
    }

    func goToResult() async {
        if combatData.source == "dungeon" || combatData.source == "dungeon_rush" {
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            return
        }

        isNavigatingToResult = true

        // Wait briefly for resolve result if not yet available
        if appState.resolveResult == nil {
            for _ in 0..<6 {
                try? await Task.sleep(for: .milliseconds(500))
                if appState.resolveResult != nil { break }
            }
        }

        // Merge server-verified rewards if resolve has completed
        if let resolve = appState.resolveResult {
            // Use SERVER winner to determine isWin (anti-cheat)
            let serverIsWin = resolve.serverWinnerId == combatData.player.id
            let mergedResult = CombatResultInfo(
                isWin: serverIsWin,
                winnerId: resolve.serverWinnerId,
                goldReward: resolve.goldReward,
                xpReward: resolve.xpReward,
                turnsTaken: combatData.result.turnsTaken,
                ratingChange: resolve.ratingChange,
                firstWinBonus: resolve.firstWinBonus,
                leveledUp: resolve.leveledUp,
                newLevel: resolve.newLevel,
                statPointsAwarded: resolve.statPointsAwarded
            )
            appState.combatResult = CombatData(
                player: combatData.player,
                enemy: combatData.enemy,
                combatLog: combatData.combatLog,
                result: mergedResult,
                rewards: nil,
                source: combatData.source
            )
        } else {
            // Resolve failed/timed out — use optimistic client data
            appState.combatResult = combatData
        }

        isNavigatingToResult = false
        appState.mainPath.append(AppRoute.combatResult)
    }
}

// MARK: - Models

struct DamagePopup: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let isCrit: Bool
    let onDefender: Bool
}

struct StatusEffect: Identifiable {
    let id = UUID()
    let name: String

    var abbreviation: String {
        switch name.lowercased() {
        case "bleed": "BLD"
        case "burn": "BRN"
        case "stun": "STN"
        case "poison": "PSN"
        case "freeze": "FRZ"
        default: String(name.prefix(3)).uppercased()
        }
    }

    var color: Color {
        switch name.lowercased() {
        case "bleed": DarkFantasyTheme.danger
        case "burn": DarkFantasyTheme.stamina
        case "stun": DarkFantasyTheme.goldBright
        case "poison": DarkFantasyTheme.success
        case "freeze": DarkFantasyTheme.info
        default: DarkFantasyTheme.textSecondary
        }
    }
}

struct CombatLogEntry: Identifiable {
    let id = UUID()
    let text: String
    let result: String
    let resultColor: Color
    let damageTypeLabel: String?
    let damageTypeColor: Color?
}

enum DamageTypeStyle {
    case physical, magical, poison, trueDamage, unknown

    init(from string: String?) {
        switch string?.lowercased() {
        case "physical": self = .physical
        case "magical":  self = .magical
        case "poison":   self = .poison
        case "true_damage": self = .trueDamage
        default: self = .unknown
        }
    }

    var color: Color {
        switch self {
        case .physical:   DarkFantasyTheme.stamina
        case .magical:    DarkFantasyTheme.statINT
        case .poison:     DarkFantasyTheme.success
        case .trueDamage: .white
        case .unknown:    DarkFantasyTheme.danger
        }
    }

    var label: String {
        switch self {
        case .physical: "PHY"
        case .magical:  "MAG"
        case .poison:   "PSN"
        case .trueDamage: "TRUE"
        case .unknown:  "DMG"
        }
    }
}
