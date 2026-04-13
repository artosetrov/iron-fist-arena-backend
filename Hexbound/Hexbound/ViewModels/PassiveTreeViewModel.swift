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

    // UI state
    var isLoading: Bool = false
    var isMutating: Bool = false
    var selectedNode: PassiveNode?
    var showRespecConfirm: Bool = false
    var errorMessage: String?

    // Derived — recomputed when inputs change
    private(set) var unlockedIds: Set<String> = []
    private(set) var unlockableIds: Set<String> = []
    private(set) var adjacency: [String: Set<String>] = [:]

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
        let (t, c) = await (tree, character)

        if let t {
            nodes = t.nodes
            connections = t.connections
            rebuildAdjacency()
        }
        if let c {
            unlockedNodes = c.unlockedNodes
            passivePointsAvailable = c.passivePointsAvailable
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
        var available: Set<String> = []
        for node in nodes where !unlockedIds.contains(node.id) {
            if node.isStartNode {
                available.insert(node.id)
                continue
            }
            if let neighbors = adjacency[node.id],
               !neighbors.isDisjoint(with: unlockedIds) {
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

    // MARK: - Mutations

    /// Optimistic unlock. UI flips immediately; on failure we roll back.
    func unlock(_ node: PassiveNode) {
        guard canUnlock(node), !isMutating else { return }
        isMutating = true

        // Snapshot for rollback
        let prevPoints = passivePointsAvailable
        let prevUnlocked = unlockedNodes

        // Optimistic
        passivePointsAvailable -= node.cost
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
            unlockedAt: nil
        )
        unlockedNodes.append(optimistic)
        recomputeDerived()
        HapticManager.light()

        Task { [weak self] in
            guard let self else { return }
            let result = await service.unlock(characterId: characterId, nodeId: node.id)
            isMutating = false
            if let result, result.success {
                // Sync authoritative point count. Node stays optimistically present.
                passivePointsAvailable = result.passivePointsAvailable
                SFXManager.shared.play(.uiConfirm)
            } else {
                // Rollback
                passivePointsAvailable = prevPoints
                unlockedNodes = prevUnlocked
                recomputeDerived()
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
                recomputeDerived()
                // Sync gems on the character model (matches GoldMine/Respec pattern).
                appState.currentCharacter?.gems = result.gemsRemaining
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
