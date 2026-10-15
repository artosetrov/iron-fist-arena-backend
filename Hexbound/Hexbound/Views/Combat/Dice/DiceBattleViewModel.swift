//
//  DiceBattleViewModel.swift
//  Hexbound
//
//  Dice combat — match lifecycle + round choreography.
//  Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md, prototype "Hexbound Dice Duel".
//
//  Flow per round:
//    dice land (tumble) → .decide: player may spend Focus once (tap a die →
//    reroll 2 / set face 4) → FIGHT (or the timer) → /pvp/dice/resolve →
//    replay the server's ordered events (enemy action, DoTs, omen, stance,
//    both strikes, runes) → next round's dice tumble in.
//  The server is authoritative for every number; this VM only animates.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class DiceBattleViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case intro                          // waiting for /match/start
        case decide                         // timer running, player may act
        case busy                           // act / resolve in flight or animating
        case ending                         // KO landed — VICTORY / DEFEAT card
        case completing                     // /match/complete in flight
        case finished(winnerId: String)
        case unavailable
        case error(message: String)

        var isDeciding: Bool { if case .decide = self { return true }; return false }
    }

    enum Slot: Hashable { case pa, pd, oa, od, oa2 }

    struct Chip: Equatable {
        enum Style: Equatable { case wait, crit, hit, pierce, blocked, miss }
        var text: String
        var detail: String?
        var style: Style
        var big: Bool = false
    }

    struct Banner: Equatable, Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String?
    }

    // MARK: - Observable state

    var phase: Phase = .intro
    private(set) var match: DiceMatchView?
    /// Faces currently drawn (follows the server roll, plus mid-animation changes).
    var shown: DiceRollView?
    var tumbling: Set<Slot> = []
    var pulses: [Slot: Int] = [:]
    var changed: Set<Slot> = []
    var lunging: Slot?
    var activeLane: DuelSide?

    var attackerProfile: FighterProfile?
    var defenderProfile: FighterProfile?
    var playerHp: Int
    var playerMaxHp: Int
    var enemyHp: Int
    var enemyMaxHp: Int
    var playerFocus: Int = 0
    var enemyFocus: Int = 0
    var focusMax: Int = 5

    var chipP = Chip(text: "—", style: .wait)
    var chipO = Chip(text: "—", style: .wait)
    var hint: String = ""
    var banner: Banner?
    var timeRemaining: Double = 8
    var windowSeconds: Double = 8
    var autoMode: Bool = false
    var sheetDie: DiceKind?
    var endWon: Bool?

    var finalCombatData: CombatData?
    private(set) var stats = (dealt: 0, taken: 0, spent: 0)

    // VFX — same managers / popups the classic interactive screen uses.
    let vfxManager = CombatVFXManager()
    let fxImageManager = CombatFXImageManager()
    var playerAvatarPos = CGPoint(x: 0.25, y: 0.22)
    var enemyAvatarPos = CGPoint(x: 0.75, y: 0.22)
    var playerSlideX: CGFloat = 0
    var enemySlideX: CGFloat = 0
    var playerFlash = false
    var enemyFlash = false
    var damagePopups: [DamagePopup] = []

    // MARK: - Config / private

    private var runeInfo: [String: DiceRuneInfo] = [:]
    private var matchId: String = ""
    private let appState: AppState
    private let attackerCharacterId: String
    private let defenderCharacterId: String
    let opponentType: InteractiveOpponentType
    let dungeonRunId: String?
    private var timerTask: Task<Void, Never>?
    private var flowTask: Task<Void, Never>?
    private var completeTask: Task<Void, Never>?

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    init(appState: AppState,
         attackerCharacterId: String,
         defenderCharacterId: String,
         attackerMaxHp: Int,
         defenderMaxHp: Int,
         opponentType: InteractiveOpponentType,
         dungeonRunId: String?,
         attackerProfile: FighterProfile?,
         defenderProfile: FighterProfile?) {
        self.appState = appState
        self.attackerCharacterId = attackerCharacterId
        self.defenderCharacterId = defenderCharacterId
        self.opponentType = opponentType
        self.dungeonRunId = dungeonRunId
        self.attackerProfile = attackerProfile
        self.defenderProfile = defenderProfile
        self.playerHp = attackerMaxHp
        self.playerMaxHp = attackerMaxHp
        self.enemyHp = defenderMaxHp
        self.enemyMaxHp = defenderMaxHp
    }

    // MARK: - Derived

    var round: Int { match?.round ?? 1 }
    var maxRounds: Int { match?.maxRounds ?? 15 }
    var playerStrikesFirst: Bool { match?.playerFirst ?? true }
    var enemyName: String { defenderProfile?.name ?? "Enemy" }
    var rerollCost: Int { match?.rules.rerollCost ?? 2 }
    var setFaceCost: Int { match?.rules.setFaceCost ?? 4 }
    var hasActed: Bool { match?.acted != nil }
    var playerFrozen: Bool { match?.p.frozen ?? false }

    /// Fatigue label for the round strip (+15% per round after round 10).
    var fatigueLabel: String? {
        guard round > 10 else { return nil }
        return "+\((round - 10) * 15)%"
    }

    var canAct: Bool {
        phase.isDeciding && !hasActed && playerFocus >= rerollCost
    }

    func face(_ slot: Slot) -> Int? {
        guard let s = shown else { return nil }
        switch slot {
        case .pa: return s.p.a
        case .pd: return s.p.d
        case .oa: return s.o.a
        case .od: return s.o.d
        case .oa2: return s.o.a2
        }
    }

    /// Rune key on the face a slot currently shows.
    func runeKey(_ slot: Slot) -> String? {
        guard let m = match, let f = face(slot), (0..<6).contains(f) else { return nil }
        switch slot {
        case .pa: return m.p.atk[safe: f] ?? nil
        case .pd: return m.p.grd[safe: f] ?? nil
        case .oa, .oa2: return m.o.atk[safe: f] ?? nil
        case .od: return m.o.grd[safe: f] ?? nil
        }
    }

    func runeAsset(_ slot: Slot) -> String? { Self.asset(for: runeKey(slot), info: runeInfo) }

    func faceRunes(_ slot: Slot) -> [String?] {
        guard let m = match else { return [] }
        let keys: [String?]
        switch slot {
        case .pa: keys = m.p.atk
        case .pd: keys = m.p.grd
        case .oa, .oa2: keys = m.o.atk
        case .od: keys = m.o.grd
        }
        return keys.map { Self.asset(for: $0, info: runeInfo) }
    }

    func rune(_ key: String?) -> DiceRuneInfo? { key.flatMap { runeInfo[$0] } }

    static func asset(for key: String?, info: [String: DiceRuneInfo]) -> String? {
        guard let key else { return nil }
        return info[key]?.asset ?? "rune-" + key.replacingOccurrences(of: ".", with: "-")
    }

    // MARK: - Lifecycle

    func startMatch() {
        guard case .intro = phase else { return }
        flowTask = Task { [weak self] in await self?.performStart() }
    }

    func cancel() {
        timerTask?.cancel()
        flowTask?.cancel()
        completeTask?.cancel()
    }

    private func performStart() async {
        let body = InteractiveMatchStartRequest(
            characterId: attackerCharacterId,
            opponentId: defenderCharacterId,
            opponentType: opponentType.rawValue,
            dungeonRunId: dungeonRunId
        )
        do {
            let res: DiceMatchStartResponse = try await APIClient.shared.post(APIEndpoints.pvpMatchStart, body: body)
            guard let dice = res.dice else {
                phase = .error(message: "This server doesn't run dice combat yet")
                return
            }
            matchId = res.matchId
            attackerProfile = FighterProfile(snapshot: res.attacker)
            defenderProfile = FighterProfile(snapshot: res.defender)
            runeInfo = Dictionary((res.runeInfo ?? []).map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
            apply(dice, syncHp: true)
            SFXManager.shared.play(.battleStart)
            await rollIn(dice.roll)
            beginDecide()
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            phase = .error(message: (error as? APIError)?.errorDescription ?? "Failed to start match")
        }
    }

    private func apply(_ m: DiceMatchView, syncHp: Bool) {
        match = m
        playerFocus = m.p.focus
        enemyFocus = m.o.focus
        focusMax = m.rules.focusMax
        windowSeconds = max(3, Double(m.rules.windowMs) / 1000)
        if syncHp {
            playerHp = m.p.hp; playerMaxHp = m.p.maxHp
            enemyHp = m.o.hp; enemyMaxHp = m.o.maxHp
        }
    }

    // MARK: - Round start

    /// Tumble all dice into the given roll (staggered like real dice).
    private func rollIn(_ roll: DiceRollView) async {
        changed.removeAll()
        chipP = Chip(text: "…", style: .wait)
        chipO = Chip(text: "…", style: .wait)
        hint = ""
        var slots: [Slot] = [.od, .pd, .oa, .pa]
        if roll.o.a2 != nil { slots.append(.oa2) }
        shown = roll
        tumbling = Set(slots)
        SFXManager.shared.play(.uiSlide)
        let stagger = reduceMotion ? 0.05 : 0.14
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.15 : 0.42))
        for slot in slots {
            if Task.isCancelled { return }
            tumbling.remove(slot)
            HapticManager.light()
            try? await Task.sleep(for: .seconds(stagger))
        }
        if let m = match, m.omen {
            HapticManager.heavy()
            banner = Banner(title: "OMEN", subtitle: "Every block breaks")
        }
    }

    private func beginDecide() {
        guard let m = match, !m.finished else { return }
        refreshChips()
        phase = .decide
        refreshHint()
        startTimer()
        if autoMode { runAuto() }
    }

    private func startTimer() {
        timerTask?.cancel()
        timeRemaining = windowSeconds
        timerTask = Task { [weak self] in
            while let self, self.timeRemaining > 0 {
                try? await Task.sleep(for: .milliseconds(100))
                if Task.isCancelled { return }
                if self.sheetDie == nil { self.timeRemaining = max(0, self.timeRemaining - 0.1) }
            }
            if Task.isCancelled { return }
            self?.fight()
        }
    }

    // MARK: - Player input

    func tapDie(_ kind: DiceKind) {
        guard phase.isDeciding else { return }
        guard !hasActed else {
            hint = "One action per round — hit FIGHT."
            HapticManager.warning()
            return
        }
        HapticManager.selection()
        sheetDie = kind
    }

    func closeSheet() { sheetDie = nil }

    func reroll(_ kind: DiceKind) {
        sheetDie = nil
        submit(DiceActionDTO(type: "reroll", die: kind.combatKey, face: nil))
    }

    func setFace(_ kind: DiceKind, face: Int) {
        sheetDie = nil
        submit(DiceActionDTO(type: "set", die: kind.combatKey, face: face))
    }

    func toggleAuto() {
        autoMode.toggle()
        HapticManager.selection()
        if autoMode, phase.isDeciding { runAuto() }
    }

    /// Client-side autopilot: reroll a blocked strike, else reroll a guard
    /// that is about to eat a crit, then fight. The server still validates.
    private func runAuto() {
        guard let m = match, phase.isDeciding else { return }
        if !hasActed, playerFocus >= rerollCost, !m.p.frozen, m.preview.p?.out == "blocked" {
            submit(DiceActionDTO(type: "reroll", die: "a", face: nil), thenFight: true)
        } else if !hasActed, playerFocus >= rerollCost, m.preview.o?.out == "crit" {
            submit(DiceActionDTO(type: "reroll", die: "d", face: nil), thenFight: true)
        } else {
            flowTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                self?.fight()
            }
        }
    }

    private func submit(_ action: DiceActionDTO, thenFight: Bool = false) {
        guard phase.isDeciding, !matchId.isEmpty else { return }
        phase = .busy
        timerTask?.cancel()
        let slot: Slot = action.die == "a" ? .pa : .pd
        let kind: DiceKind = action.die == "a" ? .attack : .guardDie
        flowTask = Task { [weak self] in
            guard let self else { return }
            if action.type == "reroll" { self.tumbling.insert(slot) }
            do {
                let res: DiceActResponse = try await APIClient.shared.post(
                    APIEndpoints.pvpDiceAct,
                    body: DiceActRequest(matchId: self.matchId, round: self.round, action: action)
                )
                self.stats.spent += action.type == "reroll" ? self.rerollCost : self.setFaceCost
                try? await Task.sleep(for: .seconds(action.type == "reroll" && !self.reduceMotion ? 0.4 : 0.05))
                self.apply(res.dice, syncHp: false)
                self.shown = res.dice.roll
                self.tumbling.remove(slot)
                self.changed.insert(slot)
                HapticManager.medium()
                SFXManager.shared.play(.uiConfirm)
                self.refreshChips()
                if thenFight {
                    try? await Task.sleep(for: .seconds(0.35))
                    self.phase = .decide
                    self.fight()
                } else {
                    self.phase = .decide
                    self.refreshHint()
                    self.resumeTimer()
                }
            } catch {
                self.tumbling.remove(slot)
                self.phase = .decide
                self.resumeTimer()
                let msg = Self.message(for: error, kind: kind)
                self.hint = msg
                HapticManager.error()
            }
        }
    }

    private func resumeTimer() {
        let left = timeRemaining
        startTimer()
        timeRemaining = max(1.5, left)
    }

    // MARK: - Clash

    func fight() {
        guard phase.isDeciding, !matchId.isEmpty else { return }
        sheetDie = nil
        timerTask?.cancel()
        timeRemaining = 0
        phase = .busy
        hint = ""
        flowTask = Task { [weak self] in await self?.performResolve() }
    }

    private func performResolve() async {
        do {
            let res: DiceResolveResponse = try await APIClient.shared.post(
                APIEndpoints.pvpDiceResolve,
                body: DiceResolveRequest(matchId: matchId, round: round)
            )
            await play(res.events)
            if Task.isCancelled { return }
            apply(res.dice, syncHp: true)
            if res.matchFinished || res.dice.finished {
                await finish(winnerId: res.winnerId)
                return
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.55))
            await rollIn(res.dice.roll)
            beginDecide()
        } catch {
            phase = .error(message: (error as? APIError)?.errorDescription ?? "Round failed")
        }
    }

    // MARK: - Event playback

    private func play(_ events: [DiceEvent]) async {
        let sm = reduceMotion ? 0.35 : 1.0
        for e in events {
            if Task.isCancelled { return }
            switch e.t {
            case "act":
                guard let action = e.action, let face = e.face else { break }
                let slot: Slot = action.die == "a" ? .oa : .od
                hint = "\(enemyName) \(action.type == "reroll" ? "rerolls" : "sets") the \(action.die == "a" ? "attack" : "guard") die!"
                if action.type == "reroll" {
                    tumbling.insert(slot)
                    try? await Task.sleep(for: .seconds(0.5 * sm))
                }
                setShown(slot, face)
                tumbling.remove(slot)
                changed.insert(slot)
                if let f = e.focus { enemyFocus = f }
                refreshChips()
                HapticManager.medium()
                try? await Task.sleep(for: .seconds(0.7 * sm))
                hint = ""

            case "dot":
                let onPlayer = e.side == "p"
                popup(text: "−\(e.dmg ?? 0) \(Self.dotName(e.kind))", color: DarkFantasyTheme.danger, crit: false, onEnemy: !onPlayer)
                SFXManager.shared.play(.combatPoison)
                syncHp(e.hp)
                try? await Task.sleep(for: .seconds(0.55 * sm))

            case "omen":
                banner = Banner(title: "OMEN", subtitle: "Every block breaks")
                try? await Task.sleep(for: .seconds(0.5 * sm))

            case "stance":
                let mine = e.side == "p"
                if let f = e.focus { if mine { playerFocus = f } else { enemyFocus = f } }
                popup(text: "+1 ◆ Stance", color: DarkFantasyTheme.goldBright, crit: false, onEnemy: !mine)
                try? await Task.sleep(for: .seconds(0.4 * sm))

            case "strike":
                await animateStrike(e, sm: sm)

            case "rune":
                await animateRune(e, sm: sm)

            default:
                break
            }
        }
        activeLane = nil
    }

    private func animateStrike(_ e: DiceEvent, sm: Double) async {
        let mine = e.from == "p"
        let slot: Slot = mine ? .pa : (e.die == "a2" ? .oa2 : .oa)
        let defenderPos = mine ? enemyAvatarPos : playerAvatarPos
        let attackerPos = mine ? playerAvatarPos : enemyAvatarPos
        activeLane = mine ? .player : .enemy
        let out = e.out ?? "hit"
        let dmg = e.dmg ?? 0
        let runeNames = (e.runes ?? []).compactMap { slug -> String? in
            runeInfo.values.first { $0.key.hasSuffix("." + slug) }?.name ?? slug.capitalized
        }

        if out == "stunned" {
            popup(text: "Stunned", color: DarkFantasyTheme.gold, crit: false, onEnemy: !mine)
            setChip(mine, Chip(text: "STUNNED", style: .miss, big: true))
            try? await Task.sleep(for: .seconds(0.7 * sm))
            return
        }

        lunging = slot
        withAnimation(.easeOut(duration: 0.15 * sm)) {
            if mine { playerSlideX = 40 } else { enemySlideX = -40 }
        }
        try? await Task.sleep(for: .seconds(0.18 * sm))

        let detail = ([e.opens == true ? "SWEEP" : nil] + runeNames.map { Optional($0.uppercased()) })
            .compactMap { $0 }.joined(separator: " · ")

        switch out {
        case "miss":
            vfxManager.trigger(.miss, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatMiss)
            popup(text: "Missed!", color: DarkFantasyTheme.textTertiary, crit: false, onEnemy: mine)
            setChip(mine, Chip(text: "MISSED", detail: detail.isEmpty ? nil : detail, style: .miss, big: true))
        case "blocked":
            vfxManager.trigger(.block, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatBlock)
            popup(text: "Blocked", color: DarkFantasyTheme.info, crit: false, onEnemy: mine)
            setChip(mine, Chip(text: "BLOCKED", detail: detail.isEmpty ? nil : detail, style: .blocked, big: true))
            pulse(mine ? .od : .pd)
            HapticManager.light()
        default:
            let crit = out == "crit"
            let log = CombatLog(
                attackerId: mine ? attackerCharacterId : defenderCharacterId,
                action: nil, targetZone: e.zone?.rawValue, defendZone: e.guardZone?.rawValue,
                damage: dmg, isCrit: crit, isMiss: false, isDodge: false, isBlocked: false,
                statusApplied: nil, heal: e.heal, damageType: nil, skillUsed: nil
            )
            let vfx = VFXEffectType.from(log)
            vfxManager.trigger(vfx, at: defenderPos, speed: sm)
            SFXManager.shared.play(SFX.from(vfxType: vfx))
            if let fx = CombatFXAssetMap.fxForTurn(log, isPlayerAttacking: mine) {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            withAnimation(.easeInOut(duration: 0.1)) { if mine { enemyFlash = true } else { playerFlash = true } }
            popup(text: crit ? "\(dmg)!" : "\(dmg)", color: crit ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary, crit: crit, onEnemy: mine)
            if let heal = e.heal, heal > 0 {
                popup(text: "+\(heal)", color: DarkFantasyTheme.success, crit: false, onEnemy: !mine)
            }
            let name = crit ? "CRIT" : out == "pierce" ? "PIERCE" : "HIT"
            setChip(mine, Chip(text: "\(name) −\(dmg)", detail: detail.isEmpty ? nil : detail,
                               style: crit ? .crit : out == "pierce" ? .pierce : .hit, big: true))
            if !runeNames.isEmpty { pulse(slot) }
            if crit { HapticManager.heavy() } else { HapticManager.medium() }
            if mine { stats.dealt += dmg } else { stats.taken += dmg }
        }

        syncHp(e.hp)
        try? await Task.sleep(for: .seconds(0.25 * sm))
        withAnimation(.easeInOut(duration: 0.1)) { enemyFlash = false; playerFlash = false }
        withAnimation(.easeIn(duration: 0.15 * sm)) { playerSlideX = 0; enemySlideX = 0 }
        lunging = nil
        try? await Task.sleep(for: .seconds((out == "crit" ? 0.55 : 0.4) * sm))
    }

    private func animateRune(_ e: DiceEvent, sm: Double) async {
        let mine = e.side == "p"
        let slot: Slot = mine ? (e.die == "a" ? .pa : .pd) : (e.die == "a" ? .oa : .od)
        pulse(slot)
        let value = e.value ?? 0
        let name = runeInfo.values.first { $0.key.hasSuffix("." + (e.rune ?? "")) }?.name ?? (e.rune ?? "Rune").capitalized
        switch e.fx {
        case "focus":
            if let f = e.focus { if mine { playerFocus = f } else { enemyFocus = f } }
            popup(text: "+\(value) ◆ \(name)", color: DarkFantasyTheme.goldBright, crit: false, onEnemy: !mine)
            SFXManager.shared.play(.combatBuff)
        case "heal":
            popup(text: "+\(value) \(name)", color: DarkFantasyTheme.success, crit: false, onEnemy: !mine)
            vfxManager.trigger(.heal, at: mine ? playerAvatarPos : enemyAvatarPos, speed: sm)
            SFXManager.shared.play(.combatHeal)
        case "counter", "reflect":
            // The rune owner's opponent takes the damage.
            popup(text: "−\(value) \(name)", color: DarkFantasyTheme.danger, crit: false, onEnemy: mine)
            SFXManager.shared.play(.combatSpecial)
            if mine { stats.dealt += value } else { stats.taken += value }
        case "bleed", "poison", "burn":
            popup(text: Self.dotName(e.fx).capitalized, color: DarkFantasyTheme.danger, crit: false, onEnemy: mine)
            SFXManager.shared.play(.combatPoison)
        case "stun":
            popup(text: "Stun!", color: DarkFantasyTheme.gold, crit: false, onEnemy: mine)
            SFXManager.shared.play(.combatSpecial)
        case "freeze":
            popup(text: "Frozen", color: DarkFantasyTheme.cyan, crit: false, onEnemy: mine)
            SFXManager.shared.play(.combatShield)
        case "taunt":
            popup(text: "Taunted", color: DarkFantasyTheme.gold, crit: false, onEnemy: mine)
            SFXManager.shared.play(.combatBuff)
        default:
            break
        }
        syncHp(e.hp)
        try? await Task.sleep(for: .seconds(0.5 * sm))
    }

    private func finish(winnerId: String?) async {
        timerTask?.cancel()
        let won = (winnerId ?? "") == attackerCharacterId || (match?.winner == "p")
        endWon = won
        phase = .ending
        if won { HapticManager.victory(); SFXManager.shared.play(.battleVictory) }
        else { HapticManager.defeat(); SFXManager.shared.play(.battleDefeat) }

        // Latency pass (2026-10-15): the server settles the match WHILE the
        // 1.6 s ending card plays. These used to run one after the other
        // (card, then the round trip), so the result screen came 1.6 s +
        // RTT after the KO; now it comes after max(1.6 s, RTT).
        let endingCard: Duration = .seconds(1.6)

        // Dungeon Rush: the rush route settles the room (rewards, HP%, next
        // room) and its response goes back to the rush screen.
        if opponentType == .dungeonRush, let runId = dungeonRunId {
            let service = DungeonService(appState: appState)
            async let settled = service.rushFight(runId: runId, matchId: matchId)
            try? await Task.sleep(for: endingCard)
            phase = .completing
            let settledResult = await settled
            if let result = settledResult {
                appState.pendingRushFightResult = result
                phase = .finished(winnerId: won ? attackerCharacterId : defenderCharacterId)
            } else {
                phase = .error(message: "Couldn't settle the rush room")
            }
            return
        }

        async let completion = completeMatch()
        try? await Task.sleep(for: endingCard)
        phase = .completing
        let outcome = await completion
        switch outcome {
        case .success(let data):
            finalCombatData = data
            phase = .finished(winnerId: data.result.winnerId ?? winnerId ?? defenderCharacterId)
        case .failure(let error):
            if case APIError.clientError(let status, _, _) = error, status == 404 {
                phase = .unavailable
            } else {
                phase = .error(message: (error as? APIError)?.errorDescription ?? "Failed to complete match")
            }
        }
    }

    private func completeMatch() async -> Result<CombatData, Error> {
        do {
            let data: CombatData = try await APIClient.shared.post(
                APIEndpoints.pvpMatchComplete,
                body: InteractiveMatchCompleteRequest(matchId: matchId)
            )
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Helpers

    private func setShown(_ slot: Slot, _ face: Int) {
        guard var s = shown else { return }
        switch slot {
        case .pa: s.p.a = face
        case .pd: s.p.d = face
        case .oa: s.o.a = face
        case .od: s.o.d = face
        case .oa2: s.o.a2 = face
        }
        shown = s
    }

    private func pulse(_ slot: Slot) { pulses[slot, default: 0] += 1 }

    private func setChip(_ mine: Bool, _ chip: Chip) {
        withAnimation(.easeOut(duration: 0.15)) { if mine { chipP = chip } else { chipO = chip } }
    }

    private func syncHp(_ hp: DiceHpSnap) {
        withAnimation(.easeInOut(duration: 0.3)) {
            playerHp = max(0, hp.p)
            enemyHp = max(0, hp.o)
        }
    }

    private func popup(text: String, color: Color, crit: Bool, onEnemy: Bool) {
        if damagePopups.count >= 5 { damagePopups.removeFirst() }
        let p = DamagePopup(text: text, color: color, isCrit: crit, onDefender: onEnemy)
        damagePopups.append(p)
        let id = p.id
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            self?.damagePopups.removeAll { $0.id == id }
        }
    }

    private func refreshChips() {
        guard let m = match else { return }
        chipP = Self.chip(m.preview.p, stunned: m.p.stunned)
        chipO = Self.chip(m.preview.o, stunned: m.o.stunned)
    }

    static func chip(_ p: DiceStrikePreview?, stunned: Bool) -> Chip {
        if stunned { return Chip(text: "STUNNED", style: .miss) }
        guard let p else { return Chip(text: "—", style: .wait) }
        var parts: [String] = []
        if p.missChance > 0 { parts.append("\(Int((p.missChance * 100).rounded()))% MISS") }
        if p.opens { parts.append("SWEEP") }
        if p.halved { parts.append("CUT") }
        let detail = parts.isEmpty ? nil : parts.joined(separator: " · ")
        switch p.out {
        case "blocked": return Chip(text: "BLOCKED", detail: detail, style: .blocked)
        case "miss": return Chip(text: "MISS", detail: detail, style: .miss)
        case "crit": return Chip(text: "CRIT ~\(p.expected)", detail: detail, style: .crit)
        case "pierce": return Chip(text: "PIERCE ~\(p.expected)", detail: detail, style: .pierce)
        default: return Chip(text: "HIT ~\(p.expected)", detail: detail, style: .hit)
        }
    }

    private func refreshHint() {
        guard let m = match else { return }
        if hasActed { hint = "Locked in. Tap FIGHT."; return }
        if m.omen { hint = "Omen: no blocks this round — every strike crits."; return }
        if playerFocus < rerollCost { hint = "Focus \(playerFocus)/\(focusMax) · a reroll costs \(rerollCost). +1 every round."; return }
        if m.preview.p?.out == "blocked" { hint = "Blocked. Tap your attack die to change it."; return }
        if m.preview.o?.out == "crit" { hint = "Crit incoming. Tap your guard die to block it."; return }
        if let next = m.bossNext {
            hint = "\(enemyName) winds up at your \(DiceZone.of(face: next).label.lowercased()) next round."
            return
        }
        if let r = rune(runeKey(.pa)) ?? rune(runeKey(.pd)) { hint = "Rune \(r.name): \(r.desc)."; return }
        if let r = rune(runeKey(.oa)) ?? rune(runeKey(.od)) { hint = "Their rune \(r.name): \(r.desc)."; return }
        hint = "Tap a die to change it, or FIGHT."
    }

    private static func dotName(_ kind: String?) -> String {
        switch kind {
        case "poison": return "poison"
        case "burn": return "burn"
        default: return "bleed"
        }
    }

    private static func message(for error: Error, kind: DiceKind) -> String {
        if case APIError.clientError(_, let msg, let body) = error {
            switch body?["error"] as? String ?? msg {
            case "not_enough_focus": return "Not enough Focus."
            case "frozen": return "Your attack die is frozen this round."
            case "already_acted": return "One action per round."
            case "same_face": return "That face is already up."
            default: return msg
            }
        }
        return (error as? APIError)?.errorDescription ?? "Action failed"
    }
}
