import SwiftUI

/// A number or word that floats up from the enemy, the hero bar or the scene.
struct DescentFloater: Identifiable, Equatable {
    enum Anchor: Equatable { case enemy, hero, scene }
    enum Tone: Equatable { case damage, crit, hurt, heal, info }

    let id = UUID()
    let anchor: Anchor
    let text: String
    let tone: Tone
    /// -1...1, spreads simultaneous numbers sideways.
    let jitter: CGFloat
}

/// Dungeon Rush v2 "The Descent".
///
/// The server owns the run: this view model sends one action at a time with the
/// run's `seq`, swaps in the snapshot it gets back and plays the `fx` beats
/// (numbers, shakes, coin rain). It never predicts an outcome.
@MainActor @Observable
final class DescentViewModel {
    enum Phase: Equatable {
        case loading
        case intro
        case playing
        case failed(String)
    }

    private let appState: AppState
    private let service: DescentService
    private let cache: GameDataCache?

    // MARK: State

    var phase: Phase = .loading
    var snapshot: DescentSnapshot?
    var staminaCost = 30
    var isBusy = false
    var isStarting = false

    /// Passage picked at a fork (client-side until "Take this path").
    var selectedNodeId: String?

    var autoFight = false
    /// Why auto-fight stopped, shown under the combat verdict.
    var autoNotice: String?

    var showMap = false
    var showBag = false
    var showAbandonConfirm = false

    // MARK: FX beats (the views animate on token changes)

    var floaters: [DescentFloater] = []
    var shakeToken = 0
    var hurtFlashToken = 0
    var critFlashToken = 0
    var enemyHitToken = 0
    var coinRainToken = 0
    var coinRainCount = 0
    var revealToken = 0
    var revealedNodeId: String?
    var chestOpenToken = 0
    var banner: String?
    var bannerToken = 0

    @ObservationIgnored private var autoTask: Task<Void, Never>?
    @ObservationIgnored private var bannerTask: Task<Void, Never>?

    init(appState: AppState, cache: GameDataCache?) {
        self.appState = appState
        self.service = DescentService(appState: appState)
        self.cache = cache
    }

    // MARK: Derived

    var screen: DescentScreenKind { snapshot?.screenKind ?? .unknown }

    var selectedOption: DescentForkOption? {
        guard let id = selectedNodeId else { return nil }
        return snapshot?.fork?.options.first { $0.id == id }
    }

    /// The HUD flask works outside fights (inside a fight it is the Potion button).
    var canDrink: Bool {
        guard let s = snapshot, !isBusy else { return false }
        let k = s.screenKind
        return k != .combat && k != .result && s.hero.potions > 0 && s.hero.hp < s.hero.maxHp
    }

    var characterStamina: Int { appState.currentCharacter?.currentStamina ?? 0 }

    // MARK: - Lifecycle

    /// Screen appeared: fetch the active run (resume) or show the intro.
    /// Skipped mid-request, and while a finished run's result is on screen.
    func load() async {
        guard !isBusy, snapshot?.isOver != true else { return }
        await refresh()
    }

    private func refresh() async {
        if snapshot == nil { phase = .loading }
        switch await service.state() {
        case .success(let res):
            staminaCost = res.staminaCost
            if res.active, let view = res.view {
                apply(view, playFx: false)
                phase = .playing
            } else {
                snapshot = nil
                phase = .intro
            }
        case .failure(let failure):
            if snapshot == nil { phase = .failed(failure.message) }
        }
    }

    func start() async {
        guard !isStarting else { return }
        isStarting = true
        defer { isStarting = false }
        switch await service.start() {
        case .success(let res):
            if let stamina = res.currentStamina {
                appState.currentCharacter?.currentStamina = stamina
            }
            staminaCost = res.staminaCost
            resetFx()
            apply(res.view, playFx: false)
            phase = .playing
            SFXManager.shared.play(.dungeonEnter)
            HapticManager.medium()
        case .failure(.noStamina(_)):
            CharacterService.showOutOfStamina(appState: appState, refillGemCost: cache?.gameConfig?.staminaRefillGems)
        case .failure(let failure):
            appState.showToast(
                "Could not start the descent",
                subtitle: failure.message,
                type: .error,
                actionLabel: "Retry"
            ) { [weak self] in
                Task { await self?.start() }
            }
        }
    }

    func onDisappear() {
        stopAuto()
        bannerTask?.cancel()
    }

    // MARK: - Player actions

    func perform(_ action: DescentAction) {
        guard !isBusy, snapshot != nil else { return }
        if action != .strike { autoNotice = nil }
        isBusy = true
        Task { await send(action) }
    }

    func select(_ option: DescentForkOption) {
        guard selectedNodeId != option.id else { return }
        selectedNodeId = option.id
        SFXManager.shared.play(.uiTap)
        HapticManager.selection()
    }

    func enterSelected() {
        guard let option = selectedOption else { return }
        perform(.move(nodeId: option.id))
    }

    func toggleAuto() {
        autoFight.toggle()
        autoNotice = nil
        SFXManager.shared.play(.uiToggle)
        if autoFight { runAuto() } else { stopAuto() }
    }

    func confirmAbandon() {
        showAbandonConfirm = false
        showBag = false
        perform(.abandon)
    }

    // MARK: - Network round trip

    private func send(_ action: DescentAction) async {
        defer { isBusy = false }
        guard let snap = snapshot else { return }
        switch await service.act(runId: snap.runId, seq: snap.seq, action: action) {
        case .success(let res):
            apply(res.view, playFx: true)
            applyRewards(res)
        case .failure(.stale(let view)):
            if let view {
                apply(view, playFx: false)
            } else {
                await refresh()
            }
        case .failure(.runOver(let message)):
            stopAuto()
            snapshot = nil
            phase = .intro
            appState.showToast(message, type: .info)
        case .failure(let failure):
            stopAuto()
            SFXManager.shared.play(.uiError)
            appState.showToast(
                failure.message,
                type: .error,
                actionLabel: "Retry"
            ) { [weak self] in
                self?.perform(action)
            }
        }
    }

    private func applyRewards(_ res: DescentActResponse) {
        if let sync = res.character {
            let before = appState.currentCharacter?.level
            appState.applyAuthoritativeRewardState(
                gold: sync.gold,
                xp: sync.xp,
                leveledUp: sync.leveledUp,
                newLevel: sync.newLevel,
                statPointsAwarded: sync.statPointsAwarded,
                passivePointsAwarded: sync.passivePointsAwarded,
                previousLevel: before
            )
        }
        if !res.granted.items.isEmpty {
            appState.cachedInventory = nil
        }
        if res.granted.gold > 0, res.view.screenKind == .camp {
            appState.showToast(
                "Loot stashed",
                subtitle: "\(res.granted.gold) gold is safe at the camp",
                type: .reward
            )
        }
        if res.ended {
            stopAuto()
            Task { [weak self] in await self?.appState.reloadCharacter() }
        }
    }

    // MARK: - Applying a snapshot

    private func apply(_ view: DescentSnapshot, playFx: Bool) {
        let previous = snapshot
        snapshot = view

        // Keep the fork pick only while it is still one of the passages.
        if let fork = view.fork {
            if let id = selectedNodeId, !fork.options.contains(where: { $0.id == id }) {
                selectedNodeId = nil
            }
            if selectedNodeId == nil, fork.options.count == 1 {
                selectedNodeId = fork.options.first?.id
            }
            if let revealed = fork.options.first(where: { $0.revealed }) {
                selectedNodeId = revealed.id
            }
        } else {
            selectedNodeId = nil
        }

        if view.screenKind != .combat {
            stopAuto()
        }
        if playFx {
            playScreenChange(from: previous, to: view)
            play(view.fx, in: view)
        }
    }

    private func playScreenChange(from old: DescentSnapshot?, to new: DescentSnapshot) {
        guard old?.screen != new.screen || old?.depth != new.depth else { return }
        switch new.screenKind {
        case .depthCard:
            SFXManager.shared.play(.dungeonEnter)
        case .fork:
            if new.fork?.isBossGate == true {
                SFXManager.shared.play(.chainRattle)
            } else {
                SFXManager.shared.play(.footstepStone)
            }
        case .combat:
            if new.combat?.isBoss == true {
                SFXManager.shared.play(.dungeonBossAppear)
                HapticManager.heavy()
            } else if new.combat?.isElite == true {
                SFXManager.shared.play(.creatureGrowl)
                HapticManager.medium()
            } else {
                SFXManager.shared.play(.battleStart)
            }
        case .camp:
            SFXManager.shared.play(.torchIgnite)
        case .merchant:
            SFXManager.shared.play(.merchantGreet)
        case .event:
            SFXManager.shared.play(.magicShimmer)
        case .depthClear:
            SFXManager.shared.play(.dungeonFloorComplete)
        case .result:
            switch new.result?.outcome ?? "" {
            case "victory":
                SFXManager.shared.play(.battleVictory)
                HapticManager.victory()
            case "escaped":
                SFXManager.shared.play(.uiRewardClaim)
                HapticManager.success()
            default:
                SFXManager.shared.play(.battleDefeat)
                HapticManager.defeat()
            }
        default:
            break
        }
    }

    private func play(_ beats: [DescentFx], in view: DescentSnapshot) {
        var spread: CGFloat = -0.6
        for fx in beats {
            switch (fx.target, fx.kind) {
            case ("enemy", "dmg"):
                enemyHitToken += 1
                addFloater(.enemy, "\(fx.value ?? 0)", .damage, spread)
                SFXManager.shared.play(.hitPhysical)
                HapticManager.light()
            case ("enemy", "crit"):
                enemyHitToken += 1
                addFloater(.enemy, "\(fx.value ?? 0)!", .crit, spread)
                SFXManager.shared.play(.hitCritical)
                HapticManager.heavy()
                critFlashToken += 1
                shakeToken += 1
            case ("enemy", "heal"):
                addFloater(.enemy, "+\(fx.value ?? 0)", .heal, spread)
            case ("enemy", "info"):
                addFloater(.enemy, fx.text ?? "", .info, spread)
                SFXManager.shared.play(fx.text == "Dodged" ? .combatDodge : .combatBlock)
            case ("hero", "hurt"):
                addFloater(.hero, "−\(fx.value ?? 0)", .hurt, spread)
                hurtFlashToken += 1
                shakeToken += 1
                HapticManager.medium()
            case ("hero", "heal"):
                addFloater(.hero, "+\(fx.value ?? 0)", .heal, spread)
                SFXManager.shared.play(.potionUse)
            case ("hero", "info"):
                addFloater(.hero, fx.text ?? "", .info, spread)
                SFXManager.shared.play(.combatShield)
            case ("enemy", "slain"):
                SFXManager.shared.play(.combatDeath)
                HapticManager.success()
                showBanner(view.screenKind == .relic ? "Guardian slain" : "Slain")
            case ("scene", "coins"):
                coinRainCount = max(8, min(40, fx.value ?? 16))
                coinRainToken += 1
                SFXManager.shared.play(.coinDrop)
                HapticManager.coinCascade(count: 4)
            case ("scene", "reveal"):
                revealedNodeId = view.fork?.options.first(where: { $0.revealed })?.id
                revealToken += 1
                SFXManager.shared.play(.torchIgnite)
                HapticManager.light()
            case ("scene", "chest_open"):
                chestOpenToken += 1
                SFXManager.shared.play(.chestOpen)
                HapticManager.medium()
            case ("scene", "mimic"):
                shakeToken += 1
                hurtFlashToken += 1
                SFXManager.shared.play(.creatureGrowl)
                HapticManager.heavy()
            default:
                break
            }
            spread += 0.6
            if spread > 0.6 { spread = -0.6 }
        }
    }

    private func addFloater(_ anchor: DescentFloater.Anchor, _ text: String, _ tone: DescentFloater.Tone, _ jitter: CGFloat) {
        guard !text.isEmpty else { return }
        let floater = DescentFloater(anchor: anchor, text: text, tone: tone, jitter: jitter)
        floaters.append(floater)
        if floaters.count > 5 { floaters.removeFirst(floaters.count - 5) }
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1250))
            self?.floaters.removeAll { $0.id == floater.id }
        }
    }

    private func showBanner(_ text: String) {
        banner = text
        bannerToken += 1
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1700))
            guard !Task.isCancelled else { return }
            self?.banner = nil
        }
    }

    private func resetFx() {
        floaters = []
        banner = nil
        autoFight = false
        autoNotice = nil
        selectedNodeId = nil
    }

    // MARK: - Auto-fight

    private func runAuto() {
        autoTask?.cancel()
        autoTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.autoFight else { return }
                guard let snap = self.snapshot, snap.screenKind == .combat, let combat = snap.combat else {
                    self.autoFight = false
                    return
                }
                if combat.windup {
                    self.pauseAuto("Auto-fight paused: a crushing blow is coming. Brace or strike?")
                    return
                }
                if snap.hero.isLow, snap.hero.potions > 0 {
                    self.pauseAuto("Auto-fight paused: your health is low.")
                    return
                }
                if !self.isBusy {
                    self.isBusy = true
                    await self.send(.strike)
                }
                try? await Task.sleep(for: .milliseconds(650))
            }
        }
    }

    private func pauseAuto(_ notice: String) {
        autoFight = false
        autoNotice = notice
        autoTask = nil
        HapticManager.warning()
    }

    private func stopAuto() {
        autoTask?.cancel()
        autoTask = nil
        autoFight = false
    }
}
