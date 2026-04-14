//
//  InteractiveBattleViewModel.swift
//  Hexbound
//
//  Interactive Combat v1 — match lifecycle orchestration.
//  Flow: startMatch → (predict → submitStrike → reveal)* → completeMatch → CombatData.
//  Server is authoritative: HP snapshots, opponent zones, and final rewards come
//  from /pvp/match/start, /pvp/strike, and /pvp/match/complete respectively.
//  Gated by INTERACTIVE_COMBAT_V1 on the server (404 → `unavailable` phase,
//  host can route back to classic /pvp/fight).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class InteractiveBattleViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case intro              // Waiting for /pvp/match/start
        case predict            // Player picks zones, timer ticking
        case resolving          // Awaiting /pvp/strike response
        case reveal             // Playing Reveal animation (player strike)
        case completing         // Awaiting /pvp/match/complete after finish
        case finished(winnerId: String)
        case unavailable        // Feature flag off — classic fight required
        case error(message: String)
    }

    // MARK: - Observable State

    var phase: Phase = .intro
    var state: InteractiveMatchState
    var predictTimeRemaining: Double = InteractiveBattleViewModel.predictWindowSeconds
    var selectedAttackZone: InteractiveBodyZone = .chest
    var selectedDefendZone: InteractiveBodyZone = .chest
    var lastOutcome: InteractiveStrikeOutcome?
    var lastTurn: InteractiveStrikeTurn?
    var lastOpponentTurn: InteractiveStrikeTurn?
    var lastOpponentZones: InteractiveOpponentZones?

    /// Authoritative fighter metadata — populated by `/match/start`.
    /// Used by the view to render YOU / ENEMY portrait cards (name, level, class, avatar).
    var attackerProfile: FighterProfile?
    var defenderProfile: FighterProfile?

    /// Whether the player just tapped SKIP (auto-pick zones).
    /// Purely presentational — flag used to visually highlight the auto-chosen zones.
    var lastStrikeWasSkipped: Bool = false

    /// Final `/match/complete` payload, emitted for navigation to CombatResultDetailView.
    var finalCombatData: CombatData?

    /// Opponent's historical zone pattern (for read strip). Empty in pure-blind mode.
    var opponentPattern: [InteractiveBodyZone] = []

    // MARK: - Phase 3: Active Slots

    /// Player's 3 equipped actives with live cooldown state (0 = ready).
    /// Populated by `/match/start`, refreshed by each `/strike` response.
    var playerActives: [InteractiveActiveSlotSnapshot] = []

    /// Opponent's 3 equipped actives (read-only — for UI tell). Cooldowns tick
    /// down but are not player-visible (Phase 3.B will surface opponent use).
    var opponentActives: [InteractiveActiveSlotSnapshot] = []

    /// Slot (0..2) the player queued for THIS pending strike; cleared after reveal.
    /// Nil = regular attack only.
    var pendingActiveSlot: Int? = nil

    /// Label for the active fired on the most recent strike — used for a
    /// floating-text cue ("BURST!" etc.) above the player avatar.
    var lastActiveFiredLabel: String? = nil

    /// Label for the opponent AI's fired active this round (Phase 3.B).
    var lastOpponentActiveFiredLabel: String? = nil

    // MARK: - VFX / SFX State

    /// Canvas particle VFX (sparks, flashes). Mounted by the view as an overlay.
    let vfxManager = CombatVFXManager()

    /// PNG image FX overlay (slash, crit text, shields, heal). Mounted above `vfxManager`.
    let fxImageManager = CombatFXImageManager()

    /// Avatar positions in the view's coordinate space, normalized to (0…1).
    /// Set by the view via `GeometryReader` so VFX land on the right avatar
    /// regardless of screen size. Defaults are the fallback layout used by
    /// classic `/fight` replay (attacker-left, defender-right on player turn).
    var playerAvatarPos: CGPoint = CGPoint(x: 0.25, y: 0.30)
    var enemyAvatarPos: CGPoint  = CGPoint(x: 0.75, y: 0.30)

    /// Per-side visual state driven by the animation pipeline. Mirrors
    /// `CombatViewModel.playTurn` — slide-in on attack, flash on hit.
    var playerSlideX: CGFloat = 0
    var enemySlideX: CGFloat = 0
    var playerFlash: Bool = false
    var enemyFlash: Bool = false

    /// Floating damage / heal popups on each fighter. Cap = 5 (GPU guard).
    var damagePopups: [DamagePopup] = []

    /// Whether an animation run is currently in flight. Prevents double-entry.
    private var isAnimating: Bool = false

    // MARK: - Config

    /// Predict window. Spec §3 calls for 6 s at level 1.
    static let predictWindowSeconds: Double = 6.0

    /// Reveal animation budget. Spec §3.4 scripted timeline: 1.4 s.
    static let revealDurationSeconds: Double = 1.4

    static let maxRounds: Int = 15

    // MARK: - Private

    private var predictTimerTask: Task<Void, Never>?
    private var strikeTask: Task<Void, Never>?
    private var completeTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?
    private let appState: AppState
    private let attackerCharacterId: String
    private let defenderCharacterId: String

    // MARK: - Init

    /// Initialize with opaque character IDs. Max HPs are provisional until
    /// `/match/start` returns the authoritative snapshot.
    init(appState: AppState,
         attackerCharacterId: String,
         defenderCharacterId: String,
         attackerMaxHp: Int,
         defenderMaxHp: Int,
         attackerCurrentHp: Int? = nil,
         defenderCurrentHp: Int? = nil) {
        self.appState = appState
        self.attackerCharacterId = attackerCharacterId
        self.defenderCharacterId = defenderCharacterId
        self.state = InteractiveMatchState(
            matchId: "",   // populated by /match/start
            attackerId: attackerCharacterId,
            defenderId: defenderCharacterId,
            attackerHp: attackerCurrentHp ?? attackerMaxHp,
            defenderHp: defenderCurrentHp ?? defenderMaxHp,
            attackerMaxHp: attackerMaxHp,
            defenderMaxHp: defenderMaxHp
        )
    }

    // NOTE: No deinit cancellation. @MainActor-isolated stored properties can't
    // be touched from a nonisolated deinit under Swift 6 strict concurrency,
    // and Swift 6.1 `isolated deinit` isn't available on our toolchain yet.
    // All tasks capture `[weak self]`; once the VM deallocates they early-
    // return on the next await. For deterministic teardown call `cancel()`
    // from the host view's screen-level `.onDisappear`.

    // MARK: - Lifecycle

    /// Kick off the match. Call from host view's `.onAppear`.
    func startMatch() {
        guard case .intro = phase else { return }
        startTask = Task { [weak self] in
            await self?.performStartMatch()
        }
    }

    /// Called when the player taps Strike or the timer expires.
    func submitStrike() {
        guard case .predict = phase else { return }
        predictTimerTask?.cancel()
        lastStrikeWasSkipped = false
        phase = .resolving
        strikeTask = Task { [weak self] in
            await self?.resolveStrike()
        }
    }

    /// Called when the player taps SKIP — auto-picks random zones and submits.
    /// Server still resolves normally; from its POV there's no difference.
    func skipAndSubmit() {
        guard case .predict = phase else { return }
        selectedAttackZone = InteractiveBodyZone.allCases.randomElement() ?? .chest
        selectedDefendZone = InteractiveBodyZone.allCases.randomElement() ?? .chest
        predictTimerTask?.cancel()
        lastStrikeWasSkipped = true
        phase = .resolving
        strikeTask = Task { [weak self] in
            await self?.resolveStrike()
        }
    }

    /// Called by the view when the Reveal animation finishes.
    func revealCompleted() {
        guard case .reveal = phase else { return }
        if state.isFinished {
            completeMatch()
            return
        }
        lastOutcome = nil
        lastTurn = nil
        lastOpponentTurn = nil
        lastOpponentZones = nil
        lastActiveFiredLabel = nil
        lastOpponentActiveFiredLabel = nil
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    func cancel() {
        predictTimerTask?.cancel()
        strikeTask?.cancel()
        completeTask?.cancel()
        startTask?.cancel()
    }

    // MARK: - Timer

    private func startPredictTimer() {
        predictTimerTask?.cancel()
        predictTimeRemaining = Self.predictWindowSeconds
        predictTimerTask = Task { [weak self] in
            guard let self else { return }
            let tickMs: UInt64 = 100
            while predictTimeRemaining > 0 {
                try? await Task.sleep(nanoseconds: tickMs * 1_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    self.predictTimeRemaining = max(0, self.predictTimeRemaining - Double(tickMs) / 1000.0)
                }
            }
            if Task.isCancelled { return }
            await MainActor.run {
                if case .predict = self.phase {
                    self.submitStrike()
                }
            }
        }
    }

    // MARK: - /match/start

    private func performStartMatch() async {
        let body = InteractiveMatchStartRequest(
            characterId: attackerCharacterId,
            opponentId: defenderCharacterId
        )
        do {
            let response: InteractiveMatchStartResponse = try await APIClient.shared.post(
                APIEndpoints.pvpMatchStart,
                body: body
            )
            await applyMatchStart(response)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Failed to start match"
            phase = .error(message: msg)
        }
    }

    private func applyMatchStart(_ response: InteractiveMatchStartResponse) async {
        state.matchId = response.matchId
        state.attackerHp = response.attacker.currentHp
        state.defenderHp = response.defender.currentHp
        attackerProfile = FighterProfile(snapshot: response.attacker)
        defenderProfile = FighterProfile(snapshot: response.defender)
        if let actives = response.actives {
            playerActives = actives.p1
            opponentActives = actives.p2
        }
        predictTimeRemaining = Self.predictWindowSeconds
        startPredictTimer()
        phase = .predict
    }

    // MARK: - Active Slots (Phase 3)

    /// Toggle the queued active for this pending strike. Only one active can
    /// fire per round. Tapping a ready slot arms it; tapping the armed slot
    /// cancels. Cooldown/empty slots are ignored.
    func toggleActiveSlot(_ slotIndex: Int) {
        guard case .predict = phase else { return }
        guard let slot = playerActives.first(where: { $0.slotIndex == slotIndex }) else { return }
        guard slot.isReady else { return }
        pendingActiveSlot = (pendingActiveSlot == slotIndex) ? nil : slotIndex
    }

    // MARK: - /strike

    private func resolveStrike() async {
        guard !state.matchId.isEmpty else {
            phase = .error(message: "Match not started")
            return
        }
        let request = InteractiveStrikeRequest(
            matchId: state.matchId,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone,
            playerActiveSlot: pendingActiveSlot
        )
        do {
            let response: InteractiveStrikeResponse = try await APIClient.shared.post(
                APIEndpoints.pvpStrike,
                body: request
            )
            await applyStrikeResponse(response)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch let APIError.clientError(status, _, _) where status == 410 {
            phase = .error(message: "Match timed out")
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Strike failed"
            phase = .error(message: msg)
        }
    }

    private func applyStrikeResponse(_ response: InteractiveStrikeResponse) async {
        // Refresh actives state first — server is authoritative on cooldowns.
        if let actives = response.actives {
            playerActives = actives.p1
            opponentActives = actives.p2
        }
        lastActiveFiredLabel = response.playerActiveLabel
        lastOpponentActiveFiredLabel = response.opponentActiveLabel
        pendingActiveSlot = nil

        state.strikes.append(response.playerStrike)
        if let opp = response.opponentStrike {
            state.strikes.append(opp)
            lastOpponentTurn = opp
        }
        lastOpponentZones = response.oppZones

        let outcome = InteractiveStrikeOutcome.classify(
            turn: response.playerStrike,
            attackerZone: selectedAttackZone,
            defenderZone: selectedDefendZone
        )
        lastTurn = response.playerStrike
        lastOutcome = outcome

        // Enter reveal and run the scripted VFX/SFX/HP-tween sequence.
        // HP is NOT set to the final server value up front — `animateStrike`
        // tweens it per-turn so the duel header bar animates naturally.
        // A final reconcile step snaps to the authoritative server values
        // to paper over any rounding / status-tick divergence.
        phase = .reveal
        await animateReveal(
            player: response.playerStrike,
            opponent: response.opponentStrike,
            targetAttackerHp: response.attackerHp,
            targetDefenderHp: response.defenderHp
        )
    }

    // MARK: - Reveal Animation Pipeline

    /// Plays the scripted reveal for this round: player strike → (brief gap)
    /// → opponent counter-strike → HP reconcile → phase advance.
    /// Mirrors `CombatViewModel.playTurn` but driven by server Turns rather
    /// than a pre-computed log. Slide, VFX particles, PNG FX overlay, SFX,
    /// damage popups, flash, and HP tween all fire per strike.
    private func animateReveal(
        player: InteractiveStrikeTurn,
        opponent: InteractiveStrikeTurn?,
        targetAttackerHp: Int,
        targetDefenderHp: Int
    ) async {
        guard !isAnimating else { return }
        isAnimating = true
        defer { isAnimating = false }

        // 1) Player attacks defender
        let playerLog = combatLogFrom(turn: player, fallbackAttackerId: state.attackerId)
        await animateStrike(log: playerLog, isPlayerAttacking: true)

        // 2) Defender counters (if alive)
        if let opp = opponent {
            try? await Task.sleep(for: .seconds(0.25))
            let oppLog = combatLogFrom(turn: opp, fallbackAttackerId: state.defenderId)
            await animateStrike(log: oppLog, isPlayerAttacking: false)
        }

        // 3) Reconcile to authoritative server HP (handles status ticks / rounding)
        withAnimation(.easeInOut(duration: 0.2)) {
            state.attackerHp = max(0, targetAttackerHp)
            state.defenderHp = max(0, targetDefenderHp)
        }
        try? await Task.sleep(for: .seconds(0.2))

        // 4) Phase advance
        if state.isFinished {
            completeMatch()
        } else {
            revealCompleted()
        }
    }

    /// Animates a single strike using the classic `playTurn` pipeline:
    /// slide-in → VFX+SFX+PNG FX → flash → damage popup → HP tween → slide back.
    private func animateStrike(log: CombatLog, isPlayerAttacking: Bool) async {
        let sm: Double = 1.0

        let defenderPos = isPlayerAttacking ? enemyAvatarPos  : playerAvatarPos
        let attackerPos = isPlayerAttacking ? playerAvatarPos : enemyAvatarPos

        // 1) Slide-in
        withAnimation(.easeOut(duration: 0.15 * sm)) {
            if isPlayerAttacking { playerSlideX = 40 } else { enemySlideX = -40 }
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))

        let fxDescriptor = CombatFXAssetMap.fxForTurn(log, isPlayerAttacking: isPlayerAttacking)

        // 2) Outcome VFX / SFX / PNG FX
        if log.isDodge {
            vfxManager.trigger(.dodge, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatDodge)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
        } else if log.isMiss {
            vfxManager.trigger(.miss, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatMiss)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
        } else if log.isBlocked {
            vfxManager.trigger(.block, at: defenderPos, speed: sm)
            SFXManager.shared.play(.combatBlock)
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }
            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking { enemyFlash = true } else { playerFlash = true }
            }
            try? await Task.sleep(for: .seconds(0.1 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        if !log.isMiss && !log.isDodge && !log.isBlocked && log.damage > 0 {
            let vfxType = VFXEffectType.from(log)
            vfxManager.trigger(vfxType, at: defenderPos, speed: sm)
            SFXManager.shared.play(SFX.from(vfxType: vfxType))
            if let fx = fxDescriptor {
                fxImageManager.trigger(fx, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
            }

            withAnimation(.easeInOut(duration: 0.1)) {
                if isPlayerAttacking { enemyFlash = true } else { playerFlash = true }
            }
            try? await Task.sleep(for: .seconds(0.15 * sm))
            withAnimation(.easeInOut(duration: 0.1)) {
                enemyFlash = false
                playerFlash = false
            }
        }

        // 3) Damage popup
        spawnDamagePopup(log: log, isPlayerAttacking: isPlayerAttacking)

        // 4) Heal FX (if any) + HP tween
        if let heal = log.heal, heal > 0 {
            vfxManager.trigger(.heal, at: attackerPos, speed: sm)
            SFXManager.shared.play(.combatHeal)
            let healFX = CombatFXAssetMap.healFX()
            fxImageManager.trigger(healFX, defenderPos: defenderPos, attackerPos: attackerPos, speed: sm)
        }

        withAnimation(.easeInOut(duration: 0.3 * sm)) {
            if isPlayerAttacking {
                state.defenderHp = max(0, state.defenderHp - log.damage)
                if let heal = log.heal, heal > 0 {
                    state.attackerHp = min(state.attackerMaxHp, state.attackerHp + heal)
                }
            } else {
                state.attackerHp = max(0, state.attackerHp - log.damage)
                if let heal = log.heal, heal > 0 {
                    state.defenderHp = min(state.defenderMaxHp, state.defenderHp + heal)
                }
            }
        }
        try? await Task.sleep(for: .seconds(0.3 * sm))

        // 5) Slide back
        withAnimation(.easeIn(duration: 0.15 * sm)) {
            playerSlideX = 0
            enemySlideX = 0
        }
        try? await Task.sleep(for: .seconds(0.15 * sm))
    }

    private func spawnDamagePopup(log: CombatLog, isPlayerAttacking: Bool) {
        let popup: DamagePopup
        if log.isMiss {
            popup = DamagePopup(text: "Missed!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else if log.isDodge {
            popup = DamagePopup(text: "Dodged!", color: DarkFantasyTheme.textTertiary, isCrit: false, onDefender: !isPlayerAttacking)
        } else {
            let text = log.isCrit ? "\(log.damage)!" : "\(log.damage)"
            let dmgStyle = DamageTypeStyle(from: log.damageType)
            popup = DamagePopup(text: text, color: dmgStyle.color, isCrit: log.isCrit, onDefender: !isPlayerAttacking)
        }
        if damagePopups.count >= 5 { damagePopups.removeFirst() }
        damagePopups.append(popup)

        if let heal = log.heal, heal > 0 {
            if damagePopups.count >= 5 { damagePopups.removeFirst() }
            let healPopup = DamagePopup(text: "+\(heal)", color: DarkFantasyTheme.success, isCrit: false, onDefender: isPlayerAttacking)
            damagePopups.append(healPopup)
        }

        let popupId = popup.id
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.0))
            self?.damagePopups.removeAll { $0.id == popupId }
        }
    }

    /// Adapt `InteractiveStrikeTurn` (match-aware DTO) → `CombatLog` so we can
    /// reuse `CombatFXAssetMap`, `VFXEffectType.from`, `SFX.from(vfxType:)` and
    /// `DamageTypeStyle` without duplicating mapping logic. `isBlocked` isn't
    /// a separate server flag — it's inferred when damage==0 with no miss/dodge.
    private func combatLogFrom(turn: InteractiveStrikeTurn, fallbackAttackerId: String) -> CombatLog {
        let miss = turn.isMiss ?? false
        let dodge = turn.isDodge ?? false
        let blocked = !miss && !dodge && turn.damage <= 0
        return CombatLog(
            attackerId: turn.attackerId ?? fallbackAttackerId,
            action: turn.skillUsed,
            targetZone: turn.targetZone,
            defendZone: turn.defendZone,
            damage: max(0, turn.damage),
            isCrit: turn.isCrit ?? false,
            isMiss: miss,
            isDodge: dodge,
            isBlocked: blocked,
            statusApplied: nil,
            heal: turn.healAmount,
            damageType: turn.damageType,
            skillUsed: turn.skillUsed
        )
    }

    // MARK: - /match/complete

    private func completeMatch() {
        phase = .completing
        completeTask = Task { [weak self] in
            await self?.performCompleteMatch()
        }
    }

    private func performCompleteMatch() async {
        let body = InteractiveMatchCompleteRequest(matchId: state.matchId)
        do {
            let data: CombatData = try await APIClient.shared.post(
                APIEndpoints.pvpMatchComplete,
                body: body
            )
            finalCombatData = data
            phase = .finished(winnerId: state.winnerId ?? state.defenderId)
        } catch let APIError.clientError(status, _, _) where status == 404 {
            phase = .unavailable
        } catch {
            let msg = (error as? APIError)?.errorDescription ?? "Failed to complete match"
            phase = .error(message: msg)
        }
    }
}

// MARK: - Convenience

extension InteractiveBattleViewModel.Phase {
    var isPredicting: Bool {
        if case .predict = self { return true }
        return false
    }
    var isRevealing: Bool {
        if case .reveal = self { return true }
        return false
    }
    var isBusy: Bool {
        switch self {
        case .resolving, .reveal, .completing: return true
        default: return false
        }
    }
}

// MARK: - Fighter Profile (view-ready snapshot)

/// View-ready snapshot of a fighter populated from `/pvp/match/start`.
/// Decouples view code from the raw DTO and provides safe defaults so
/// portraits render even when the server omits optional fields.
struct FighterProfile: Equatable, Sendable {
    let id: String
    let name: String
    let level: Int
    let characterClass: CharacterClass
    let avatar: String?

    init(id: String,
         name: String,
         level: Int,
         characterClass: CharacterClass,
         avatar: String?) {
        self.id = id
        self.name = name
        self.level = level
        self.characterClass = characterClass
        self.avatar = avatar
    }

    /// Adapt the decoded snapshot — tolerate missing/invalid class strings.
    init(snapshot: InteractiveCharacterSnapshot) {
        self.id = snapshot.id
        self.name = snapshot.characterName?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? snapshot.characterName!
            : "Unknown"
        self.level = snapshot.level ?? 1
        self.characterClass = snapshot.characterClass
            .flatMap { CharacterClass(rawValue: $0.lowercased()) } ?? .warrior
        self.avatar = snapshot.avatar
    }
}

// MARK: - Combat Log Row (view-ready)

/// One row rendered in the combat log. Derived from `InteractiveStrikeTurn`
/// + fighter profiles so the view never has to cross-reference IDs itself.
struct InteractiveCombatLogRow: Identifiable, Equatable {
    let id: Int
    let attackerName: String
    let targetZone: String          // "Head" / "Chest" / "Legs"
    let damage: Int
    let healAmount: Int             // positive = healing tick
    let damageTypeLabel: String?    // "Physical" / "Magical" / "True" / "Poison"
    let damageTypeIcon: String?     // SF Symbol
    let outcomeLabel: String?       // "MISS" / "DODGE" / "CRIT" / nil for normal hit
    let isPlayer: Bool
}

extension InteractiveBattleViewModel {
    /// View-ready combat log — built on each access from `state.strikes`.
    /// Kept as a computed property (not stored) so it auto-updates when
    /// strikes append, without an extra @Observable property to coordinate.
    var combatLogRows: [InteractiveCombatLogRow] {
        let attackerId = state.attackerId
        return state.strikes.enumerated().map { idx, turn in
            let isPlayerStrike = (turn.attackerId ?? "") == attackerId
            let attackerName = isPlayerStrike
                ? (attackerProfile?.name ?? "You")
                : (defenderProfile?.name ?? "Enemy")
            let zone = (turn.targetZone ?? "").capitalized
            let zoneLabel = zone.isEmpty ? "—" : zone
            let heal = turn.healAmount ?? 0
            let outcome: String? = {
                if turn.isMiss == true { return "MISS" }
                if turn.isDodge == true { return "DODGE" }
                if turn.isCrit == true { return "CRIT" }
                return nil
            }()
            let type = turn.damageType?.lowercased()
            return InteractiveCombatLogRow(
                id: idx,
                attackerName: attackerName,
                targetZone: zoneLabel,
                damage: max(0, turn.damage),
                healAmount: max(0, heal),
                damageTypeLabel: Self.damageTypeLabel(type),
                damageTypeIcon: Self.damageTypeIcon(type),
                outcomeLabel: outcome,
                isPlayer: isPlayerStrike
            )
        }
    }

    private static func damageTypeLabel(_ type: String?) -> String? {
        switch type {
        case "physical": return "Physical"
        case "magical": return "Magical"
        case "true_damage", "true": return "True"
        case "poison": return "Poison"
        default: return nil
        }
    }

    private static func damageTypeIcon(_ type: String?) -> String? {
        switch type {
        case "physical": return "figure.walk"
        case "magical": return "sparkles"
        case "true_damage", "true": return "bolt.fill"
        case "poison": return "drop.fill"
        default: return nil
        }
    }
}
