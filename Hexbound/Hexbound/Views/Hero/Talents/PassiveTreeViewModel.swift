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

    // UI state
    var isLoading: Bool = false
    var isMutating: Bool = false
    var selectedNode: PassiveNode?
    var showRespecConfirm: Bool = false
    var errorMessage: String?

    // Pending allocation (Stats-style staged unlock).
    // Nodes here are visually staged but NOT spent server-side until commitPending().
    private(set) var pendingUnlockIds: Set<String> = []

    // Derived — recomputed when inputs change
    private(set) var unlockedIds: Set<String> = []
    private(set) var unlockableIds: Set<String> = []
    private(set) var adjacency: [String: Set<String>] = [:]

    // MARK: - Pending derived helpers

    /// Sum of cost across staged-but-not-committed nodes.
    var pendingCost: Int {
        var total = 0
        for id in pendingUnlockIds {
            if let n = nodes.first(where: { $0.id == id }) { total += n.cost }
        }
        return total
    }

    /// Points the user will have left after committing the current pending set.
    var pointsAvailableAfterPending: Int {
        passivePointsAvailable - pendingCost
    }

    var hasPendingChanges: Bool { !pendingUnlockIds.isEmpty }

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
        // Effective "frontier" = committed unlocked ∪ staged pending.
        // This lets a staged node act as a parent for the next stageable node.
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
        return passivePointsAvailable >= node.cost
    }

    func isUnlocked(_ node: PassiveNode) -> Bool {
        unlockedIds.contains(node.id)
    }

    func isUnlockable(_ node: PassiveNode) -> Bool {
        unlockableIds.contains(node.id)
    }

    func isPending(_ node: PassiveNode) -> Bool {
        pendingUnlockIds.contains(node.id)
    }

    /// Can we add this node to the pending set right now?
    func canStage(_ node: PassiveNode) -> Bool {
        guard !unlockedIds.contains(node.id), !pendingUnlockIds.contains(node.id) else { return false }
        guard unlockableIds.contains(node.id) else { return false }
        return pointsAvailableAfterPending >= node.cost
    }

    // MARK: - Mutations (Stage → Confirm pattern, mirrors Stats tab)

    /// Stage a node into the pending allocation. UI flips immediately,
    /// no API call yet. Confirm via `commitPending()`.
    func stageUnlock(_ node: PassiveNode) {
        guard canStage(node) else { return }
        pendingUnlockIds.insert(node.id)
        recomputeDerived()
        HapticManager.light()
    }

    /// Remove a node from pending. If a downstream pending node only
    /// had this one as a parent, it is also un-staged (cascade).
    func unstageUnlock(_ node: PassiveNode) {
        guard pendingUnlockIds.contains(node.id) else { return }
        pendingUnlockIds.remove(node.id)
        // Cascade: any pending node that is no longer reachable should drop too.
        var changed = true
        while changed {
            changed = false
            recomputeDerived()
            for id in pendingUnlockIds {
                guard let n = nodes.first(where: { $0.id == id }) else { continue }
                let effective = unlockedIds.union(pendingUnlockIds).subtracting([id])
                let reachable = n.isStartNode ||
                    (adjacency[id] ?? []).contains(where: { effective.contains($0) })
                if !reachable {
                    pendingUnlockIds.remove(id)
                    changed = true
                    break
                }
            }
        }
        recomputeDerived()
        HapticManager.light()
    }

    /// Drop the entire pending set without firing any API calls.
    func resetPending() {
        guard !pendingUnlockIds.isEmpty else { return }
        pendingUnlockIds.removeAll()
        recomputeDerived()
        HapticManager.light()
    }

    /// Commit all staged unlocks server-side, in BFS order from the
    /// committed unlocked frontier so each unlock satisfies adjacency.
    /// Optimistic per node; on failure we stop and refund the rest into
    /// the pool (they remain pending for the user to retry or reset).
    func commitPending() {
        guard hasPendingChanges, !isMutating else { return }
        isMutating = true

        // Snapshot for full rollback if everything fails.
        let prevPoints = passivePointsAvailable
        let prevUnlockedNodes = unlockedNodes

        // Compute a valid commit order: BFS from committed unlocked set.
        let order = bfsCommitOrder()
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            var anySuccess = false
            for node in order {
                let result = await service.unlock(characterId: characterId, nodeId: node.id)
                if let result, result.success {
                    // Apply optimistically into local state.
                    passivePointsAvailable = result.passivePointsAvailable
                    appState.currentCharacter?.passivePointsAvailable = passivePointsAvailable
                    let optimistic = CharacterPassiveUnlocked(
                        id: "optimistic-\(node.id)",
                        nodeId: node.id,
                        nodeKey: node.nodeKey,
                        name: node.name,
                        description: node.description,
                        bonusType: node.bonusType,
                        bonusStat: node.bonusStat,
                        bonusValue: node.bonusValue,
                        tier: node.tier,
                        cost: node.cost,
                        icon: node.icon,
                        isActivatable: node.isActivatable,
                        activeActionType: node.activeActionType,
                        activeCooldown: node.activeCooldown,
                        activeMagnitude: node.activeMagnitude,
                        unlockedAt: nil
                    )
                    unlockedNodes.append(optimistic)
                    pendingUnlockIds.remove(node.id)
                    recomputeDerived()
                    anySuccess = true
                } else {
                    // Stop on first failure; remaining stay in pending.
                    break
                }
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

    /// BFS-order pending nodes so each commit step has a satisfied parent.
    private func bfsCommitOrder() -> [PassiveNode] {
        var ordered: [PassiveNode] = []
        var resolved = unlockedIds
        var remaining = pendingUnlockIds

        // Multiple passes; each pass picks every pending node whose
        // adjacency intersects the resolved frontier.
        while !remaining.isEmpty {
            var addedThisPass: [String] = []
            for id in remaining {
                guard let node = nodes.first(where: { $0.id == id }) else {
                    addedThisPass.append(id) // bogus id — drop it
                    continue
                }
                let isReachable = node.isStartNode ||
                    (adjacency[id] ?? []).contains(where: { resolved.contains($0) })
                if isReachable {
                    ordered.append(node)
                    addedThisPass.append(id)
                }
            }
            if addedThisPass.isEmpty { break }
            for id in addedThisPass {
                remaining.remove(id)
                resolved.insert(id)
            }
        }
        return ordered
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

    /// Equip node into first free slot, or replace the given slotIndex if provided.
    func equipActive(node: PassiveNode, slotIndex explicit: Int? = nil) {
        guard canEquip(node), !isMutating else { return }
        let targetSlot: Int = {
            if let s = explicit { return s }
            // Prefer a free slot; else slot 0
            let taken = Set(activeSlots.map(\.slotIndex))
            for i in 0..<maxActiveSlots where !taken.contains(i) { return i }
            return 0
        }()

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
                pendingUnlockIds.removeAll()
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
}
