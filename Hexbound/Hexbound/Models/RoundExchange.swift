//
//  RoundExchange.swift
//  Hexbound
//
//  Interactive Combat v3 — value type that represents ONE resolved round
//  ("exchange") as a pair of ordered event lists, ready to be rendered
//  inside the log card in `InteractiveBattleView`.
//
//  Built purely from an `InteractiveStrikeResponse` via `build(from:…)`.
//  The view never does any damage / crit / skill math — those values flow
//  from the server. This struct only re-shapes them into rows.
//
//  Ordering rule inside each side's list:
//    1. `.talentFired` (if this side fired an active this round)
//    2. the strike event (`.strike`, `.crit`, `.blocked`, `.dodged`, `.missed`)
//
//  The talent row reads naturally as "I fired BURST — then I hit HEAD for 220".
//

import Foundation

/// A single round exchange, pre-sliced into "ally" (you) and "enemy" (them).
struct RoundExchange: Sendable, Identifiable, Equatable {

    // MARK: - Stored properties

    let id: UUID
    let roundNumber: Int
    let allyEvents: [CombatLogEvent]
    let enemyEvents: [CombatLogEvent]
    let talentFired: Bool
    let finishingBlow: Bool
    let verdict: RoundVerdict
    let playerAttackZone: InteractiveBodyZone
    let playerDefendZone: InteractiveBodyZone
    let opponentAttackZone: InteractiveBodyZone
    let opponentDefendZone: InteractiveBodyZone

    // MARK: - Display timing

    /// Auto-dismiss delay for the Round Exchange card. Longer cards (talent
    /// rows, finishing-blow rounds, peak verdicts) linger so the player has
    /// time to read the subtitle and see the gold border pulse on OUTPLAYED.
    var autoDismissDelay: Duration {
        if finishingBlow  { return .milliseconds(3200) }
        if talentFired    { return .milliseconds(2400) }
        if verdict.isPeak { return .milliseconds(2500) }
        return .milliseconds(1800)
    }

    // MARK: - Aggregate stats

    /// Pre-computed summary of a whole battle's log. Built once on the
    /// `.summary` phase so `BattleSummaryView` can render a stats header
    /// without recomputing on every body-rebuild.
    struct BattleStats: Sendable, Equatable {
        let damageDealt: Int
        let damageTaken: Int
        let hitAttempts: Int       // player strike attempts (landed or not)
        let hitsLanded: Int        // of those, ones that dealt damage
        let bestHitDamage: Int
        let bestRoundNumber: Int?  // round with the highest single landed hit
        let rounds: Int

        var accuracyPercent: Int {
            guard hitAttempts > 0 else { return 0 }
            return Int((Double(hitsLanded) / Double(hitAttempts)) * 100.0)
        }
    }

    // MARK: - Factory (stats)

    /// Aggregate a full battle log into a single `BattleStats` snapshot.
    /// Purely a reducer over the already-resolved exchanges — no server
    /// calls, no damage math. Safe to call every frame if needed.
    static func aggregate(log: [RoundExchange]) -> BattleStats {
        var damageDealt = 0
        var damageTaken = 0
        var attempts = 0
        var landed = 0
        var bestDamage = 0
        var bestRound: Int? = nil

        for exchange in log {
            for ev in exchange.allyEvents {
                if ev.isStrikeAttempt { attempts += 1 }
                if ev.didLand         { landed   += 1 }
                damageDealt += ev.damageDealt
                if ev.damageDealt > bestDamage {
                    bestDamage = ev.damageDealt
                    bestRound  = exchange.roundNumber
                }
            }
            for ev in exchange.enemyEvents {
                damageTaken += ev.damageDealt
            }
        }

        return BattleStats(
            damageDealt: damageDealt,
            damageTaken: damageTaken,
            hitAttempts: attempts,
            hitsLanded: landed,
            bestHitDamage: bestDamage,
            bestRoundNumber: bestRound,
            rounds: log.count
        )
    }

    // MARK: - Factory

    /// Build from a raw server strike response.
    ///
    /// - Parameters:
    ///   - response: backend payload from `POST /api/pvp/strike`.
    ///   - roundNumber: 1-based round number (use `strikeIndex + 1` or the
    ///     local round counter).
    ///   - playerName: attacker-side display name (ally).
    ///   - opponentName: defender-side display name (enemy).
    ///   - playerAttackZone: zone the local player picked to attack.
    ///   - playerDefendZone: zone the local player picked to defend.
    static func build(
        from response: InteractiveStrikeResponse,
        roundNumber: Int,
        playerName: String,
        opponentName: String,
        playerAttackZone: InteractiveBodyZone,
        playerDefendZone: InteractiveBodyZone
    ) -> RoundExchange {

        var ally: [CombatLogEvent] = []
        var enemy: [CombatLogEvent] = []
        var didFireTalent = false

        // --- Ally (player) active fired this round ---
        if response.playerActiveFired != nil,
           let action = Self.talentAction(from: response.playerActiveLabel) {
            ally.append(.talentFired(
                index: roundNumber * 10 + 0,
                side: .ally,
                action: action,
                actorName: playerName
            ))
            didFireTalent = true
        }

        // --- Ally strike ---
        let pStrike = response.playerStrike
        let pZone = Self.zone(fromRaw: pStrike.targetZone) ?? playerAttackZone
        ally.append(Self.strikeEvent(
            turn: pStrike,
            side: .ally,
            zone: pZone,
            actorName: playerName,
            targetName: opponentName,
            index: roundNumber * 10 + 1
        ))

        // --- Enemy (opponent) active fired this round ---
        if response.opponentActiveFired != nil,
           let action = Self.talentAction(from: response.opponentActiveLabel) {
            enemy.append(.talentFired(
                index: roundNumber * 10 + 2,
                side: .enemy,
                action: action,
                actorName: opponentName
            ))
            didFireTalent = true
        }

        // --- Enemy strike (may be nil if the match ended on player's hit) ---
        if let oStrike = response.opponentStrike {
            let oZone = Self.zone(fromRaw: oStrike.targetZone) ?? response.oppZones.attack
            enemy.append(Self.strikeEvent(
                turn: oStrike,
                side: .enemy,
                zone: oZone,
                actorName: opponentName,
                targetName: playerName,
                index: roundNumber * 10 + 3
            ))
        }

        let verdict = RoundVerdict.classify(
            playerStrike: response.playerStrike,
            opponentStrike: response.opponentStrike
        )

        return RoundExchange(
            id: UUID(),
            roundNumber: roundNumber,
            allyEvents: ally,
            enemyEvents: enemy,
            talentFired: didFireTalent,
            finishingBlow: response.matchFinished,
            verdict: verdict,
            playerAttackZone: playerAttackZone,
            playerDefendZone: playerDefendZone,
            opponentAttackZone: response.oppZones.attack,
            opponentDefendZone: response.oppZones.defend
        )
    }

    // MARK: - Private helpers

    /// Convert one `InteractiveStrikeTurn` into the matching log-event case.
    /// Order of checks mirrors `InteractiveStrikeOutcome.classify(...)`:
    /// miss → dodge → blocked (damage == 0) → crit → strike.
    private static func strikeEvent(
        turn: InteractiveStrikeTurn,
        side: CombatLogEvent.Side,
        zone: InteractiveBodyZone,
        actorName: String,
        targetName: String,
        index: Int
    ) -> CombatLogEvent {
        if turn.isMiss == true {
            return .missed(
                index: index, side: side, zone: zone,
                actorName: actorName, targetName: targetName
            )
        }
        if turn.isDodge == true {
            return .dodged(
                index: index, side: side, zone: zone,
                actorName: actorName, targetName: targetName
            )
        }
        if turn.damage <= 0 {
            return .blocked(
                index: index, side: side, zone: zone,
                actorName: actorName, targetName: targetName
            )
        }
        if turn.isCrit == true {
            return .crit(
                index: index, side: side, zone: zone,
                actorName: actorName, damage: turn.damage, skillName: turn.skillUsed
            )
        }
        return .strike(
            index: index, side: side, zone: zone,
            actorName: actorName, damage: turn.damage, skillName: turn.skillUsed
        )
    }

    /// Parse the server-provided label ("burst_damage" / "heal_self" / …)
    /// into a `TalentSlotAction`. Safe no-op if label is missing or unknown.
    private static func talentAction(from label: String?) -> TalentSlotAction? {
        guard let raw = label?.lowercased(), !raw.isEmpty else { return nil }
        return TalentSlotAction(rawValue: raw)
    }

    /// Parse the raw target-zone string returned by backend into our enum.
    private static func zone(fromRaw raw: String?) -> InteractiveBodyZone? {
        guard let raw = raw?.lowercased() else { return nil }
        return InteractiveBodyZone(rawValue: raw)
    }
}
