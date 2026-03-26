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

    // VFX
    let vfxManager = CombatVFXManager()
    let fxImageManager = CombatFXImageManager()

    // Callbacks — combat event types for screen shake + haptics
    enum CombatEventType { case hit, crit, block, dodge, miss }
    var onCombatEvent: ((_ event: CombatEventType) -> Void)?


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

        // Defender position (normalized 0-1) for VFX placement
        let defenderX: CGFloat = isPlayerAttacking ? 0.75 : 0.25
        let defenderY: CGFloat = 0.28
        let attackerX: CGFloat = isPlayerAttacking ? 0.25 : 0.75

        // 1. Attacker slides forward
        withAnimation(.easeOut(duration: 0.15 * sm)) {
            if isPlayerAttacking {
                playerSlideX = 40
            } else {
                enemySlideX = -40
            }
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))

        // Positions for FX image overlay
        let defenderPos = CGPoint(x: defenderX, y: defenderY)
        let attackerPos = CGPoint(x: attackerX, y: defenderY)

        // 2. Hit effects + VFX + SFX + PNG FX
        // Get PNG FX descriptor for this turn (always computed regardless of branch)
        let fxDescriptor = CombatFXAssetMap.fxForTurn(turn, isPlayerAttacking: isPlayerAttacking)

        if turn.isDodge {
            // Dodge VFX on defender
            vfxManager.trigger(.dodge, at: CGPoint(x: defenderX, y: defenderY), speed: sm)
            SFXManager.shared.play(.combatDodge)
            // PNG: fullscreen DODGE text
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            onCombatEvent?(.dodge)
        } else if turn.isMiss {
            // Miss VFX on defender
            vfxManager.trigger(.miss, at: CGPoint(x: defenderX, y: defenderY), speed: sm)
            SFXManager.shared.play(.combatMiss)
            // PNG: fullscreen MISS text
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            onCombatEvent?(.miss)
        } else if turn.isBlocked {
            // Block VFX + mild flash
            vfxManager.trigger(.block, at: CGPoint(x: defenderX, y: defenderY), speed: sm)
            SFXManager.shared.play(.combatBlock)
            // PNG: shield on defender avatar
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking { enemyFlash = true } else { playerFlash = true }
            }
            onCombatEvent?(.block)
            try? await Task.sleep(for: .seconds(0.1 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        if !turn.isMiss && !turn.isDodge && !turn.isBlocked && turn.damage > 0 {
            // Damage VFX — map from CombatLog
            let vfxType = VFXEffectType.from(turn)
            vfxManager.trigger(vfxType, at: CGPoint(x: defenderX, y: defenderY), speed: sm)
            SFXManager.shared.play(SFX.from(vfxType: vfxType))
            // PNG: damage FX on defender (+ crit fullscreen text if crit)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }

            // Flash on defender + screen shake
            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking {
                    enemyFlash = true
                } else {
                    playerFlash = true
                }
            }
            onCombatEvent?(turn.isCrit ? .crit : .hit)
            try? await Task.sleep(for: .seconds(0.15 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        // 3. Damage popup
        spawnDamagePopup(turn: turn, isPlayerAttacking: isPlayerAttacking)

        // 4. Update HP
        // Heal VFX (trigger outside withAnimation)
        if let heal = turn.heal, heal > 0 {
            vfxManager.trigger(.heal, at: CGPoint(x: attackerX, y: defenderY), speed: sm)
            SFXManager.shared.play(.combatHeal)
            // PNG: heal FX on attacker
            let healFX = CombatFXAssetMap.healFX()
            fxImageManager.trigger(healFX, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
        }

        withAnimation(.easeInOut(duration: 0.3 * sm)) {
            if isPlayerAttacking {
                enemyHp = max(0, enemyHp - turn.damage)
            } else {
                playerHp = max(0, playerHp - turn.damage)
            }

            // Heal HP
            if let heal = turn.heal, heal > 0 {
                if isPlayerAttacking {
                    playerHp = min(playerMaxHp, playerHp + heal)
                } else {
                    enemyHp = min(enemyMaxHp, enemyHp + heal)
                }
            }
        }
        try? await Task.sleep(for: .seconds(0.3 * sm))

        // 5. Status effect + VFX + SFX
        if let status = turn.statusApplied, !status.isEmpty {
            vfxManager.trigger(.statusProc(status), at: CGPoint(x: defenderX, y: defenderY), speed: sm)
            SFXManager.shared.play(.combatPoison)
            // PNG: status FX on defender
            let statusFX = CombatFXAssetMap.statusFX(status)
            fxImageManager.trigger(statusFX, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
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
            popup = DamagePopup(text: "Missed!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else if turn.isDodge {
            popup = DamagePopup(text: "Dodged!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else {
            let text = turn.isCrit ? "\(turn.damage)!" : "\(turn.damage)"
            let dmgStyle = DamageTypeStyle(from: turn.damageType)
            let color = dmgStyle.color
            popup = DamagePopup(text: text, color: color, isCrit: turn.isCrit, onDefender: !isPlayerAttacking)
        }

        // Cap concurrent popups to prevent GPU overload
        if damagePopups.count >= 5 {
            damagePopups.removeFirst()
        }
        damagePopups.append(popup)

        // Heal popup
        if let heal = turn.heal, heal > 0 {
            if damagePopups.count >= 5 {
                damagePopups.removeFirst()
            }
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
                result: "Dodged!",
                resultColor: DarkFantasyTheme.textTertiary,
                damageTypeLabel: nil,
                damageTypeIcon: nil,
                damageTypeColor: nil
            )
        } else if turn.isMiss {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "Missed!",
                resultColor: DarkFantasyTheme.textTertiary,
                damageTypeLabel: nil,
                damageTypeIcon: nil,
                damageTypeColor: nil
            )
        } else if turn.isBlocked {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "Blocked! -\(turn.damage)",
                resultColor: DarkFantasyTheme.info,
                damageTypeLabel: dmgStyle.label,
                damageTypeIcon: dmgStyle.icon,
                damageTypeColor: dmgStyle.color
            )
        } else if turn.isCrit {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "Critical! -\(turn.damage)",
                resultColor: dmgStyle.color,
                damageTypeLabel: dmgStyle.label,
                damageTypeIcon: dmgStyle.icon,
                damageTypeColor: dmgStyle.color
            )
        } else {
            entry = CombatLogEntry(
                text: "\(attackerName) \(actionVerb) \(zone)",
                result: "-\(turn.damage)",
                resultColor: dmgStyle.color,
                damageTypeLabel: dmgStyle.label,
                damageTypeIcon: dmgStyle.icon,
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
        vfxManager.clearAll()
        fxImageManager.clearAll()
        finishCombat()
    }

    /// Forfeit: skip to end, result already determined server-side.
    /// The user sees the defeat screen immediately.
    func forfeit() {
        skip()
    }

    func toggleSpeed() {
        speedMode = speedMode == 0 ? 1 : 0
    }

    private func finishCombat() {
        isFinished = true
        isPlaying = false
        SFXManager.shared.play(.combatDeath)
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
        defer { isNavigatingToResult = false }

        // Wait briefly for resolve result if not yet available (max ~1.5s)
        if appState.resolveResult == nil {
            for _ in 0..<3 {
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
        name.capitalized
    }

    var icon: String {
        switch name.lowercased() {
        case "bleed": "drop.fill"
        case "burn": "flame.fill"
        case "stun": "bolt.fill"
        case "poison": "flask.fill"
        case "freeze": "snowflake"
        default: "exclamationmark.triangle.fill"
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
    let damageTypeIcon: String?
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
        case .magical:    DarkFantasyTheme.info
        case .poison:     DarkFantasyTheme.success
        case .trueDamage: .white
        case .unknown:    DarkFantasyTheme.danger
        }
    }

    var label: String {
        switch self {
        case .physical: "Physical"
        case .magical:  "Magic"
        case .poison:   "Poison"
        case .trueDamage: "True"
        case .unknown:  "Damage"
        }
    }

    var icon: String {
        switch self {
        case .physical:   "figure.fencing"
        case .magical:    "wand.and.stars"
        case .poison:     "flask.fill"
        case .trueDamage: "bolt.fill"
        case .unknown:    "burst.fill"
        }
    }
}
