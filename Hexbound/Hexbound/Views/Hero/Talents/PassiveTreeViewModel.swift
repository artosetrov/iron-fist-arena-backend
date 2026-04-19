//
//  PassiveTreeViewModel.swift
//  Hexbound
//
//  Drives the Talents tab: loads the tree catalog + character unlocks,
//  exposes derived state (unlockable set), and performs optimistic unlock/respec.
//

import SwiftUI

@MainActor
@Observable
final class PassiveTreeViewModel {
    // Dependencies
    private let service: PassiveTreeService
    private let appState: AppState
    let characterId: String

    // Raw state
    var nodes: [PassiveNode] = []
    var connections: [PassiveConnection] = []
    var unlockedNodes: [CharacterPassiveUnlocked] = []
    var passivePointsAvailable: Int = 0

    // Active slots (Interactive Combat v1)
    var activeSlots: [ActiveSlot] = []
    var maxActiveSlots: Int = 3
    /// Phase 4.B — picker meta for every allowed health potion (name, price, owned).
    /// Refreshed together with `activeSlots` via `load()`.
    var consumablesMeta: [ConsumableMeta] = []
    /// Phase 4.C — controls presentation of the Active Skill Picker bottom sheet.
    /// Callers open the picker via `openActiveSkillPicker(focusedSlotIndex:)`.
    var showActiveSkillPicker: Bool = false
    /// Slot index the picker should pre-select when opened (tap a slot tile →
    /// picker opens with that slot highlighted).
    var pickerFocusedSlotIndex: Int? = nil

    // UI state
    var isLoading: Bool = false
    var isMutating: Bool = false
    var selectedNode: PassiveNode?
    var showRespecConfirm: Bool = false
    var errorMessage: String?

    // Pending allocation (Stats-style staged unlock).
    // Nodes here are visually staged but NOT spent server-side until commitPending().
    //
    // Talents v2 (2026-04-19): a single dict tracks BOTH first-unlocks and
    // rank-ups. Key = node id, value = target rank (1 = first unlock,
    // 2 or 3 = rank-up to that rank). A node can be staged from locked straight
    // to rank 3 in one session — on commit we issue 3 sequential unlock calls
    // (rank 1 → 2 → 3).
    private(set) var pendingRanks: [String: Int] = [:]

    /// Back-compat helper: just the set of nodes that have ANY pending action.
    /// Prefer `pendingRanks[id]` when you need the target rank number.
    var pendingUnlockIds: Set<String> { Set(pendingRanks.keys) }

    // Derived — recomputed when inputs change
    private(set) var unlockedIds: Set<String> = []
    private(set) var unlockableIds: Set<String> = []
    private(set) var adjacency: [String: Set<String>] = [:]

    // MARK: - Rank helpers

    /// Committed current rank from the server (1..maxRank), or 0 when the node
    /// has never been unlocked.
    func committedRank(for nodeId: String) -> Int {
        unlockedNodes.first(where: { $0.nodeId == nodeId })?.currentRankResolved ?? 0
    }

    /// Effective rank including any pending staging — what the node "looks
    /// like" to the player in-session. Used for ring progress, CTA copy, etc.
    func effectiveRank(for nodeId: String) -> Int {
        max(committedRank(for: nodeId), pendingRanks[nodeId] ?? 0)
    }

    /// Additional SP the user would spend to advance this node from its
    /// *committed* rank to `targetRank`. Used for cost chips on staged nodes.
    func additionalSPCost(node: PassiveNode, toRank targetRank: Int) -> Int {
        let committed = committedRank(for: node.id)
        guard targetRank > committed else { return 0 }
        let schedule = node.rankCostSchedule
        var total = 0
        for i in committed..<min(targetRank, schedule.count) { total += schedule[i] }
        return total
    }

    /// Cost to reach the next rank from the current effective rank. Returns
    /// nil when the node is already at max (committed + pending combined).
    func nextRankCost(for node: PassiveNode) -> Int? {
        let eff = effectiveRank(for: node.id)
        guard eff < node.maxRankResolved else { return nil }
        return node.rankCostSchedule[eff]
    }

    // MARK: - Pending derived helpers

    /// Sum of SP across staged-but-not-committed ranks (ranks above the
    /// committed baseline, per node).
    var pendingCost: Int {
        var total = 0
        for (id, targetRank) in pendingRanks {
            guard let n = nodes.first(where: { $0.id == id }) else { continue }
            total += additionalSPCost(node: n, toRank: targetRank)
        }
        return total
    }

    /// Points the user will have left after committing the current pending set.
    var pointsAvailableAfterPending: Int {
        passivePointsAvailable - pendingCost
    }

    var hasPendingChanges: Bool { !pendingRanks.isEmpty }

    init(service: PassiveTreeService, appState: AppState, characterId: String) {
        self.service = service
        self.appState = appState
        self.characterId = characterId
    }

    // MARK: - Load

    func load() async {
        if nodes.isEmpty { isLoading = true }
        async let tree = service.loadTree()
        async let character = service.loadCharacterPassives(characterId: characterId)
        async let slots = service.loadActiveSlots(characterId: characterId)
        let (t, c, s) = await (tree, character, slots)

        if let t {
            nodes = t.nodes
            connections = t.connections
            rebuildAdjacency()
        }
        if let c {
            unlockedNodes = c.unlockedNodes
            passivePointsAvailable = c.passivePointsAvailable
            // Mirror to character model so the HeroDetailView TALENTS tab badge
            // updates without waiting for a full character reload.
            appState.currentCharacter?.passivePointsAvailable = passivePointsAvailable
        }
        if let s {
            activeSlots = s.slots
            maxActiveSlots = s.maxSlots
            consumablesMeta = s.consumablesMeta ?? []
        }
        recomputeDerived()
        isLoading = false
    }

    // MARK: - Derived state

    private func rebuildAdjacency() {
        var map: [String: Set<String>] = [:]
        for conn in connections {
            map[conn.fromId, default: []].insert(conn.toId)
            map[conn.toId, default: []].insert(conn.fromId) // undirected traversal
        }
        adjacency = map
    }

    private func recomputeDerived() {
        unlockedIds = Set(unlockedNodes.map(\.nodeId))
        // Effective "frontier" for connectivity = committed ∪ any pending
        // (first-unlock OR rank-up). Both signal "this tile is on".
        let effectiveUnlocked = unlockedIds.union(pendingUnlockIds)
        var available: Set<String> = []
        for node in nodes where !effectiveUnlocked.contains(node.id) {
            if node.isStartNode {
                available.insert(node.id)
                continue
            }
            if let neighbors = adjacency[node.id],
               !neighbors.isDisjoint(with: effectiveUnlocked) {
                available.insert(node.id)
            }
        }
        unlockableIds = available
    }

    // MARK: - Affordability

    func canUnlock(_ node: PassiveNode) -> Bool {
        guard !unlockedIds.contains(node.id) else { return false }
        guard unlockableIds.contains(node.id) else { return false }
        // Talents v2: affordability is the cost of rank 1, not the total node cost.
        return passivePointsAvailable >= node.rankCostSchedule.first ?? node.cost
    }

    func isUnlocked(_ node: PassiveNode) -> Bool {
        unlockedIds.contains(node.id)
    }

    func isUnlockable(_ node: PassiveNode) -> Bool {
        unlockableIds.contains(node.id)
    }

    func isPending(_ node: PassiveNode) -> Bool {
        pendingRanks[node.id] != nil
    }

    /// Target rank the user currently has staged for this node (1/2/3), or
    /// nil when nothing is staged. Rendered as a "→ RANK N" chip in the sheet.
    func pendingTargetRank(_ node: PassiveNode) -> Int? {
        pendingRanks[node.id]
    }

    /// Can we start a first-unlock staging on this node right now?
    /// Talents v2: uses the rank-1 cost, not the total node cost.
    func canStage(_ node: PassiveNode) -> Bool {
        guard !unlockedIds.contains(node.id), pendingRanks[node.id] == nil else { return false }
        guard unlockableIds.contains(node.id) else { return false }
        let rankOneCost = node.rankCostSchedule.first ?? node.cost
        return pointsAvailableAfterPending >= rankOneCost
    }

    /// Can we stage a rank-up (or initial-unlock) advancing this node by one
    /// rank from its current effective rank?
    func canStageRankUp(_ node: PassiveNode) -> Bool {
        guard node.isRanked || committedRank(for: node.id) == 0 else { return false }
        let eff = effectiveRank(for: node.id)
        guard eff < node.maxRankResolved else { return false }

        // First unlock still needs connectivity.
        if eff == 0 && !unlockableIds.contains(node.id) { return false }

        guard let cost = node.nextRankCost(currentRank: eff) else { return false }
        return pointsAvailableAfterPending >= cost
    }

    // MARK: - Mutations (Stage → Confirm pattern, mirrors Stats tab)

    /// Stage a node into the pending allocation at rank 1. UI flips immediately,
    /// no API call yet. Confirm via `commitPending()`. Prefer `stageNextRank`
    /// when you want to advance an already-unlocked ranked node.
    func stageUnlock(_ node: PassiveNode) {
        guard canStage(node) else { return }
        pendingRanks[node.id] = 1
        recomputeDerived()
        HapticManager.light()
    }

    /// Advance this node's staged target rank by one. Works for both locked
    /// nodes (first bump = rank 1 unlock) and already-unlocked ranked nodes
    /// (first bump = committedRank + 1). Bumps by one rank per call; when
    /// already at max no-ops.
    func stageNextRank(_ node: PassiveNode) {
        guard canStageRankUp(node) else { return }
        let eff = effectiveRank(for: node.id)
        pendingRanks[node.id] = eff + 1
        recomputeDerived()
        HapticManager.light()
    }

    /// Step a node's pending target rank down by one. If the node drops below
    /// its committed rank (rank-up being undone) the key is removed entirely.
    /// Cascades: any downstream pending first-unlock that loses its last
    /// frontier ancestor is un-staged too.
    func unstageRankStep(_ node: PassiveNode) {
        guard let target = pendingRanks[node.id] else { return }
        let committed = committedRank(for: node.id)
        if target <= 1 || target - 1 <= committed {
            pendingRanks.removeValue(forKey: node.id)
        } else {
            pendingRanks[node.id] = target - 1
        }
        cascadeRemoveOrphanedPending()
        recomputeDerived()
        HapticManager.light()
    }

    /// Legacy alias used by existing call sites — un-stages ALL pending ranks
    /// on the node (same as tapping unstage until empty).
    func unstageUnlock(_ node: PassiveNode) {
        guard pendingRanks.removeValue(forKey: node.id) != nil else { return }
        cascadeRemoveOrphanedPending()
        recomputeDerived()
        HapticManager.light()
    }

    /// Drop the entire pending set without firing any API calls.
    func resetPending() {
        guard !pendingRanks.isEmpty else { return }
        pendingRanks.removeAll()
        recomputeDerived()
        HapticManager.light()
    }

    /// Internal: after a pending removal, drop any other pending entry whose
    /// node is no longer reachable from the committed-∪-still-pending frontier.
    /// Only first-unlock (rank 1) entries can become unreachable; rank-ups
    /// always stay valid as long as the committed-rank node itself exists.
    private func cascadeRemoveOrphanedPending() {
        var changed = true
        while changed {
            changed = false
            recomputeDerived()
            for (id, target) in pendingRanks {
                guard target == 1 else { continue } // rank-ups are always valid
                guard let n = nodes.first(where: { $0.id == id }) else {
                    pendingRanks.removeValue(forKey: id); changed = true; break
                }
                let effective = unlockedIds.union(pendingRanks.keys).subtracting([id])
                let reachable = n.isStartNode ||
                    (adjacency[id] ?? []).contains(where: { effective.contains($0) })
                if !reachable {
                    pendingRanks.removeValue(forKey: id); changed = true; break
                }
            }
        }
    }

    /// Commit all staged changes server-side.
    ///
    /// Talents v2 order: first-unlocks flow BFS-style from the committed
    /// frontier (adjacency still matters), then rank-ups run sequentially
    /// against whichever nodes are now unlocked. Each rank-up issues exactly
    /// one unlock call per rank step (1→2, 2→3) so the server can validate
    /// `currentRank === rank - 1` at each step.
    ///
    /// Optimistic per step; on ANY failure we stop and leave the remainder of
    /// the staging intact for the user to retry or reset.
    func commitPending() {
        guard hasPendingChanges, !isMutating else { return }
        isMutating = true

        // Snapshot for full rollback if everything fails.
        let prevPoints = passivePointsAvailable
        let prevUnlockedNodes = unlockedNodes

        let plan = commitPlan()
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            var anySuccess = false

            for step in plan {
                // Rank 1 hits the first-unlock path (creates the row); rank 2/3
                // hit the rank-up path (updates currentRank).
                let result = await service.unlock(
                    characterId: characterId,
                    nodeId: step.node.id,
                    rank: step.targetRank
                )
                guard let result, result.success else { break }

                // Apply optimistically into local state.
                passivePointsAvailable = result.passivePointsAvailable
                appState.currentCharacter?.passivePointsAvailable = passivePointsAvailable

                if step.targetRank == 1 {
                    let optimistic = CharacterPassiveUnlocked(
                        id: "optimistic-\(step.node.id)",
                        nodeId: step.node.id,
                        nodeKey: step.node.nodeKey,
                        name: step.node.name,
                        description: step.node.description,
                        bonusType: step.node.bonusType,
                        bonusStat: step.node.bonusStat,
                        bonusValue: step.node.bonusValue,
                        tier: step.node.tier,
                        cost: step.node.cost,
                        icon: step.node.icon,
                        isActivatable: step.node.isActivatable,
                        activeActionType: step.node.activeActionType,
                        activeCooldown: step.node.activeCooldown,
                        activeMagnitude: step.node.activeMagnitude,
                        unlockedAt: nil,
                        currentRank: result.currentRank ?? 1,
                        maxRank: result.maxRank ?? step.node.maxRankResolved
                    )
                    unlockedNodes.append(optimistic)
                } else if let idx = unlockedNodes.firstIndex(where: { $0.nodeId == step.node.id }) {
                    // Bump the rank on the optimistic row. CharacterPassiveUnlocked
                    // is a value type so we rebuild it — only currentRank changes.
                    let prev = unlockedNodes[idx]
                    unlockedNodes[idx] = CharacterPassiveUnlocked(
                        id: prev.id,
                        nodeId: prev.nodeId,
                        nodeKey: prev.nodeKey,
                        name: prev.name,
                        description: prev.description,
                        bonusType: prev.bonusType,
                        bonusStat: prev.bonusStat,
                        bonusValue: prev.bonusValue,
                        tier: prev.tier,
                        cost: prev.cost,
                        icon: prev.icon,
                        isActivatable: prev.isActivatable,
                        activeActionType: prev.activeActionType,
                        activeCooldown: prev.activeCooldown,
                        activeMagnitude: prev.activeMagnitude,
                        unlockedAt: prev.unlockedAt,
                        currentRank: result.currentRank ?? step.targetRank,
                        maxRank: result.maxRank ?? prev.maxRankResolved
                    )
                }

                // Clear the staged target once it's been fully satisfied.
                if let target = pendingRanks[step.node.id], target <= step.targetRank {
                    pendingRanks.removeValue(forKey: step.node.id)
                }
                recomputeDerived()
                anySuccess = true
            }

            isMutating = false
            if anySuccess {
                SFXManager.shared.play(.uiConfirm)
            } else {
                // Nothing committed → restore exactly to pre-commit state.
                passivePointsAvailable = prevPoints
                unlockedNodes = prevUnlockedNodes
                appState.currentCharacter?.passivePointsAvailable = prevPoints
                recomputeDerived()
                appState.showToast("Failed to confirm talents", subtitle: "Try again", type: .error)
            }
        }
    }

    /// One server-side step in a commit plan — "take this node to this rank".
    private struct CommitStep {
        let node: PassiveNode
        let targetRank: Int
    }

    /// Build the commit plan: BFS-ordered first-unlocks interleaved with
    /// sequential rank-up steps so every call the server sees is valid.
    private func commitPlan() -> [CommitStep] {
        var plan: [CommitStep] = []
        var resolved = unlockedIds                        // committed first-unlocks
        var remainingRankOne: Set<String> = pendingRanks
            .filter { committedRank(for: $0.key) == 0 }
            .map(\.key)
            .reduce(into: Set<String>()) { $0.insert($1) }

        // Pass 1 — BFS first-unlocks. Each pass adds every pending first-unlock
        // whose adjacency now hits the resolved frontier, then advances the
        // frontier and loops until nothing new can be added.
        while !remainingRankOne.isEmpty {
            var added: [String] = []
            for id in remainingRankOne {
                guard let node = nodes.first(where: { $0.id == id }) else { added.append(id); continue }
                let reachable = node.isStartNode ||
                    (adjacency[id] ?? []).contains(where: { resolved.contains($0) })
                if reachable { plan.append(CommitStep(node: node, targetRank: 1)); added.append(id) }
            }
            if added.isEmpty { break }
            for id in added { remainingRankOne.remove(id); resolved.insert(id) }
        }

        // Pass 2 — rank-ups. One CommitStep per rank step so the server sees
        // currentRank+1 at every call. Covers:
        //   (a) nodes that were already committed and got rank-ups staged
        //   (b) nodes that were staged locked → rank 2/3 in the same session
        //       (rank 1 came from pass 1 above)
        for (id, target) in pendingRanks {
            guard let node = nodes.first(where: { $0.id == id }) else { continue }
            let startRank = max(1, committedRank(for: id))
            // If the node isn't yet in `resolved` (rank-1 BFS failed to add it)
            // there's no point queuing rank-ups — they'd fail the server check.
            if committedRank(for: id) == 0 && !resolved.contains(id) { continue }
            if target <= startRank { continue }
            for r in (startRank + 1)...target {
                plan.append(CommitStep(node: node, targetRank: r))
            }
        }
        return plan
    }

    // MARK: - Active Slot Mutations

    /// True if node is eligible to be equipped (unlocked + activatable + class-OK).
    func canEquip(_ node: PassiveNode) -> Bool {
        guard unlockedIds.contains(node.id) else { return false }
        return node.isActivatable == true
    }

    /// Slot index currently holding a given node, or nil if not equipped.
    func equippedSlotIndex(for nodeId: String) -> Int? {
        activeSlots.first(where: { $0.nodeId == nodeId })?.slotIndex
    }

    /// First free slot in the current active-skill loadout, or nil when full.
    func firstFreeActiveSlotIndex() -> Int? {
        let taken = Set(activeSlots.map(\.slotIndex))
        for i in 0..<maxActiveSlots where !taken.contains(i) { return i }
        return nil
    }

    /// Equip node into first free slot, or replace the given slotIndex if provided.
    func equipActive(node: PassiveNode, slotIndex explicit: Int? = nil) {
        guard canEquip(node), !isMutating else { return }
        guard let targetSlot = explicit ?? firstFreeActiveSlotIndex() else {
            appState.showToast(
                "Active slots full",
                subtitle: "Use Edit to replace a skill",
                type: .info
            )
            return
        }

        let prev = activeSlots
        // Optimistic: remove any existing slot for same slotIndex OR same node, then append.
        activeSlots.removeAll { $0.slotIndex == targetSlot || $0.nodeId == node.id }
        activeSlots.append(ActiveSlot(
            slotIndex: targetSlot,
            nodeId: node.id,
            nodeKey: node.nodeKey,
            name: node.name,
            description: node.description,
            icon: node.icon,
            activeActionType: node.activeActionType,
            activeCooldown: node.activeCooldown,
            activeMagnitude: node.activeMagnitude,
            equippedAt: nil
        ))
        activeSlots.sort { $0.slotIndex < $1.slotIndex }
        isMutating = true

        Task { [weak self] in
            guard let self else { return }
            let ok = await service.equipActiveSlot(
                characterId: characterId, slotIndex: targetSlot, nodeId: node.id
            )
            isMutating = false
            if !ok { activeSlots = prev }
        }
    }

    /// Detail-sheet entry point for active talent equip.
    /// Uses the deterministic direct-equip path while free slots exist,
    /// and otherwise routes the player into the picker so replacement
    /// stays slot-aware instead of silently mutating an arbitrary slot.
    func beginEquipActive(node: PassiveNode) {
        guard canEquip(node), !isMutating else { return }
        if let freeSlot = firstFreeActiveSlotIndex() {
            equipActive(node: node, slotIndex: freeSlot)
            return
        }

        openActiveSkillPicker(focusedSlotIndex: nil)
        appState.showToast(
            "Choose a slot to replace",
            subtitle: "Tap a slot in the loadout bar, then equip the talent",
            type: .info
        )
    }

    /// Clear a specific slot.
    func clearActive(slotIndex: Int) {
        guard !isMutating else { return }
        let prev = activeSlots
        activeSlots.removeAll { $0.slotIndex == slotIndex }
        isMutating = true

        Task { [weak self] in
            guard let self else { return }
            let ok = await service.clearActiveSlot(
                characterId: characterId, slotIndex: slotIndex
            )
            isMutating = false
            if !ok { activeSlots = prev }
        }
    }

    /// Unlock the 4th active-skill slot. Flat gem cost (server-side).
    /// Optimistic: bumps `maxActiveSlots` after the API call succeeds.
    func unlockPremiumSlot() {
        guard !isMutating else { return }
        guard maxActiveSlots < 4 else { return }
        isMutating = true

        Task { [weak self] in
            guard let self else { return }
            let result = await service.unlockPremiumSlot(characterId: characterId)
            isMutating = false
            if let result, result.success {
                maxActiveSlots = result.maxSlots
                appState.currentCharacter?.gems = result.gems
                appState.showToast(
                    "Slot unlocked",
                    subtitle: "4th active-skill slot available",
                    type: .reward
                )
                SFXManager.shared.play(.uiConfirm)
            }
        }
    }

    /// Respec — gems cost applied server-side; we only confirm & refresh.
    func respec() {
        guard !isMutating else { return }
        isMutating = true

        Task { [weak self] in
            guard let self else { return }
            let result = await service.respec(characterId: characterId)
            isMutating = false
            if let result, result.success {
                passivePointsAvailable = result.passivePointsAvailable
                unlockedNodes = []
                activeSlots = []
                pendingRanks.removeAll()
                recomputeDerived()
                // Sync gems + talent points on the character model so HeroDetailView
                // badges + header update immediately (GoldMine/Respec pattern).
                appState.currentCharacter?.gems = result.gemsRemaining
                appState.currentCharacter?.passivePointsAvailable = passivePointsAvailable
                appState.showToast(
                    "Talents reset",
                    subtitle: "+\(result.pointsRefunded) points refunded",
                    type: .success
                )
                SFXManager.shared.play(.uiConfirm)
            }
            showRespecConfirm = false
        }
    }

    // MARK: - Active Skill Picker (Phase 4.C)

    /// Open the picker sheet, optionally focused on a specific slot.
    func openActiveSkillPicker(focusedSlotIndex: Int? = nil) {
        pickerFocusedSlotIndex = focusedSlotIndex
        showActiveSkillPicker = true
    }

    /// Persist a full 3-slot loadout via the atomic batch endpoint.
    /// Optimistic: `activeSlots` is updated client-side BEFORE the API call,
    /// rolled back on failure. Also increments `isMutating` so concurrent
    /// single-slot mutations don't interleave.
    func commitLoadout(_ draftSlots: [ActiveSlot]) async -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        defer { isMutating = false }

        let prev = activeSlots
        // Optimistic mirror — insert the draft's non-empty slots, sorted.
        activeSlots = draftSlots.sorted { $0.slotIndex < $1.slotIndex }

        let payload: [ActiveSlotLoadoutEntry] = (0..<maxActiveSlots).map { i in
            if let slot = draftSlots.first(where: { $0.slotIndex == i }) {
                switch slot.kind {
                case .talent:
                    if let nodeId = slot.nodeId {
                        return .talent(slotIndex: i, nodeId: nodeId)
                    }
                    return .empty(slotIndex: i)
                case .consumable:
                    if let ct = slot.consumableType {
                        return .consumable(slotIndex: i, consumableType: ct)
                    }
                    return .empty(slotIndex: i)
                }
            }
            return .empty(slotIndex: i)
        }

        let ok = await service.saveLoadout(characterId: characterId, slots: payload)
        if !ok { activeSlots = prev }
        return ok
    }

    /// Refresh picker meta (name/price/owned) without a full reload — used after
    /// an inline Buy so the consumable row flips from "Buy" to "Equip" immediately.
    func refreshConsumablesMeta() async {
        guard let response = await service.loadActiveSlots(characterId: characterId) else { return }
        consumablesMeta = response.consumablesMeta ?? []
        // Also re-sync slots in case server-side state changed.
        activeSlots = response.slots
    }
}
