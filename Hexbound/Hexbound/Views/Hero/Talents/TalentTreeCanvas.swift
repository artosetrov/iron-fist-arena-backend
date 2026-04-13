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
    let isUnlockable: (PassiveNode) -> Bool
    let onTap: (PassiveNode) -> Void

    private let nodePadding: CGFloat = 60  // keep nodes from touching edges
    private let minCanvasSize: CGFloat = 800

    // MARK: - Bounding box of the tree in backend coordinates
    private var bounds: (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        guard !nodes.isEmpty else { return (0, 1, 0, 1) }
        let xs = nodes.map(\.positionX)
        let ys = nodes.map(\.positionY)
        return (xs.min() ?? 0, xs.max() ?? 1, ys.min() ?? 0, ys.max() ?? 1)
    }

    /// Maps backend (positionX, positionY) → screen points inside `canvasSize`.
    private func screenPosition(for node: PassiveNode, in canvasSize: CGSize) -> CGPoint {
        let b = bounds
        let rangeX = max(b.maxX - b.minX, 1)
        let rangeY = max(b.maxY - b.minY, 1)
        let usableW = canvasSize.width - nodePadding * 2
        let usableH = canvasSize.height - nodePadding * 2
        let nx = (node.positionX - b.minX) / rangeX
        let ny = (node.positionY - b.minY) / rangeY
        return CGPoint(
            x: nodePadding + CGFloat(nx) * usableW,
            y: nodePadding + CGFloat(ny) * usableH
        )
    }

    private func state(for node: PassiveNode) -> TalentNodeView.State {
        if isUnlocked(node) { return .unlocked }
        if isUnlockable(node) { return .unlockable }
        return .locked
    }

    private func connectionColor(_ conn: PassiveConnection, nodeMap: [String: PassiveNode]) -> Color {
        guard let from = nodeMap[conn.fromId], let to = nodeMap[conn.toId] else {
            return DarkFantasyTheme.borderSubtle
        }
        let fromUnlocked = isUnlocked(from)
        let toUnlocked = isUnlocked(to)
        if fromUnlocked && toUnlocked { return DarkFantasyTheme.gold }
        if fromUnlocked || toUnlocked { return DarkFantasyTheme.goldDim }
        return DarkFantasyTheme.borderSubtle
    }

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = CGSize(
                width: max(proxy.size.width, minCanvasSize),
                height: max(proxy.size.height, minCanvasSize)
            )
            let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

            ZStack {
                // Connections — drawn in Canvas for perf
                Canvas { context, _ in
                    for conn in connections {
                        guard let from = nodeMap[conn.fromId],
                              let to = nodeMap[conn.toId] else { continue }
                        let p1 = screenPosition(for: from, in: canvasSize)
                        let p2 = screenPosition(for: to, in: canvasSize)
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)
                        let isBoth = isUnlocked(from) && isUnlocked(to)
                        context.stroke(
                            path,
                            with: .color(connectionColor(conn, nodeMap: nodeMap)),
                            lineWidth: isBoth ? 3 : 2
                        )
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)

                // Nodes — tappable
                ForEach(nodes) { node in
                    let pos = screenPosition(for: node, in: canvasSize)
                    Button {
                        onTap(node)
                    } label: {
                        TalentNodeView(node: node, state: state(for: node))
                    }
                    .buttonStyle(.plain)
                    .position(pos)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
        }
    }
}
