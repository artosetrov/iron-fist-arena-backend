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

    // MARK: - Display timing

    /// Auto-dismiss delay for the Round Exchange card. Longer cards (talent
    /// rows, finishing-blow rounds) linger so the player has time to read.
    var autoDismissDelay: Duration {
        if finishingBlow { return .milliseconds(3200) }
        if talentFired   { return .milliseconds(2400) }
        return .milliseconds(1800)
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

        return RoundExchange(
            id: UUID(),
            roundNumber: roundNumber,
            allyEvents: ally,
            enemyEvents: enemy,
            talentFired: didFireTalent,
            finishingBlow: response.matchFinished
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
