//
//  TalentTreeCanvas.swift
//  Hexbound
//
//  Renders the passive-tree nodes + connections on a pannable/zoomable canvas.
//  Node positions come from backend (PassiveNode.positionX/Y), auto-fitted to
//  the container with padding. Uses SwiftUI Canvas for connections, ZStack
//  for tappable nodes.
//

import SwiftUI

struct TalentTreeCanvas: View {
    let nodes: [PassiveNode]
    let connections: [PassiveConnection]
    let isUnlocked: (PassiveNode) -> Bool
    let isPending: (PassiveNode) -> Bool
    let isUnlockable: (PassiveNode) -> Bool
    let onTap: (PassiveNode) -> Void

    private let nodePadding: CGFloat = 36         // keep nodes from touching edges
    private let minNeighborDistance: CGFloat = 64 // center-to-center px between closest nodes (≥ max node size 56 + breathing room)

    // MARK: - Bounding box of the tree in backend coordinates
    private var bounds: (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        guard !nodes.isEmpty else { return (0, 1, 0, 1) }
        let xs = nodes.map(\.positionX)
        let ys = nodes.map(\.positionY)
        return (xs.min() ?? 0, xs.max() ?? 1, ys.min() ?? 0, ys.max() ?? 1)
    }

    /// Smallest non-zero distance between any two nodes in backend coords.
    /// Used to guarantee they never visually overlap regardless of backend density.
    private var minNodeDelta: Double {
        var minDelta = Double.greatestFiniteMagnitude
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let dx = nodes[i].positionX - nodes[j].positionX
                let dy = nodes[i].positionY - nodes[j].positionY
                let d = (dx * dx + dy * dy).squareRoot()
                if d > 0.001 { minDelta = min(minDelta, d) }
            }
        }
        return minDelta == .greatestFiniteMagnitude ? 1 : minDelta
    }

    /// Effective scale: closest pair sits exactly `minNeighborDistance` px apart (center-to-center).
    private var effectiveScale: CGFloat {
        minNeighborDistance / CGFloat(minNodeDelta)
    }

    /// Intrinsic canvas size derived from backend coord range × scale.
    private var canvasSize: CGSize {
        let b = bounds
        let rangeX = CGFloat(max(b.maxX - b.minX, 1))
        let rangeY = CGFloat(max(b.maxY - b.minY, 1))
        let scale = effectiveScale
        return CGSize(
            width: rangeX * scale + nodePadding * 2,
            height: rangeY * scale + nodePadding * 2
        )
    }

    /// Maps backend (positionX, positionY) → screen points inside `canvasSize`.
    private func screenPosition(for node: PassiveNode) -> CGPoint {
        let b = bounds
        let scale = effectiveScale
        return CGPoint(
            x: nodePadding + CGFloat(node.positionX - b.minX) * scale,
            y: nodePadding + CGFloat(node.positionY - b.minY) * scale
        )
    }

    private func state(for node: PassiveNode) -> TalentNodeView.NodeState {
        if isUnlocked(node) { return .unlocked }
        if isPending(node) { return .pending }
        if isUnlockable(node) { return .unlockable }
        return .locked
    }

    /// Pending counts as gold-dim for connection purposes — visually hints
    /// the staged path without overstating it as fully unlocked.
    private func connectionColor(_ conn: PassiveConnection, nodeMap: [String: PassiveNode]) -> Color {
        guard let from = nodeMap[conn.fromId], let to = nodeMap[conn.toId] else {
            return DarkFantasyTheme.borderSubtle
        }
        let fromActive = isUnlocked(from) || isPending(from)
        let toActive = isUnlocked(to) || isPending(to)
        let fromUnlocked = isUnlocked(from)
        let toUnlocked = isUnlocked(to)
        if fromUnlocked && toUnlocked { return DarkFantasyTheme.gold }
        if fromActive && toActive { return DarkFantasyTheme.goldDim }
        if fromActive || toActive { return DarkFantasyTheme.goldDim }
        return DarkFantasyTheme.borderSubtle
    }

    var body: some View {
        let size = canvasSize
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        ZStack {
            // Connections — drawn in Canvas for perf
            Canvas { context, _ in
                for conn in connections {
                    guard let from = nodeMap[conn.fromId],
                          let to = nodeMap[conn.toId] else { continue }
                    let p1 = screenPosition(for: from)
                    let p2 = screenPosition(for: to)
                    var path = Path()
                    path.move(to: p1)
                    path.addLine(to: p2)
                    let isBoth = isUnlocked(from) && isUnlocked(to)
                    context.stroke(
                        path,
                        with: .color(connectionColor(conn, nodeMap: nodeMap)),
                        lineWidth: isBoth ? 4 : 3
                    )
                }
            }
            .frame(width: size.width, height: size.height)

            // Nodes — tappable
            ForEach(nodes) { node in
                Button {
                    onTap(node)
                } label: {
                    TalentNodeView(node: node, state: state(for: node))
                }
                .buttonStyle(.plain)
                .position(screenPosition(for: node))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
