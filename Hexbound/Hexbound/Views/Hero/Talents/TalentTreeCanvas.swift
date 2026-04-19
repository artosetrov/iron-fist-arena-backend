//
//  TalentTreeCanvas.swift
//  Hexbound
//
//  Renders the passive-tree nodes + connections on a pannable/zoomable canvas.
//  Node positions come from backend (PassiveNode.positionX/Y), auto-fitted to
//  the container with padding. Uses SwiftUI Canvas for connections (solid, dashed),
//  ZStack for tappable nodes.
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
    private let minNeighborDistance: CGFloat = 64 // center-to-center px between closest nodes

    // MARK: - Bounding box of the tree in backend coordinates

    private var bounds: (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        guard !nodes.isEmpty else { return (0, 1, 0, 1) }
        let xs = nodes.map(\.positionX)
        let ys = nodes.map(\.positionY)
        return (xs.min() ?? 0, xs.max() ?? 1, ys.min() ?? 0, ys.max() ?? 1)
    }

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

    private var effectiveScale: CGFloat {
        minNeighborDistance / CGFloat(minNodeDelta)
    }

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

    // MARK: - Connection categorization

    private enum ConnectionStyle {
        case unlockedSolid    // both ends unlocked → bright gold + glow
        case pendingSolid     // at least one end pending → dim gold
        case unlockableDash   // one end unlocked/pending, other is unlockable → animated dashed
        case locked           // neither end active → faint border
    }

    private func style(for conn: PassiveConnection, nodeMap: [String: PassiveNode]) -> ConnectionStyle {
        guard let from = nodeMap[conn.fromId], let to = nodeMap[conn.toId] else { return .locked }
        let fromU = isUnlocked(from)
        let toU = isUnlocked(to)
        let fromP = isPending(from)
        let toP = isPending(to)
        let fromUnlockable = isUnlockable(from)
        let toUnlockable = isUnlockable(to)

        if fromU && toU { return .unlockedSolid }
        if (fromU || fromP) && (toU || toP) { return .pendingSolid }
        // Any "active" side (unlocked or pending) touching an unlockable peer → animated dash.
        let anyActive = fromU || toU || fromP || toP
        let anyUnlockable = fromUnlockable || toUnlockable
        if anyActive && anyUnlockable { return .unlockableDash }
        return .locked
    }

    // MARK: - Animation for dashed unlockable lines

    @State private var dashPhase: CGFloat = 0

    // MARK: - Body

    var body: some View {
        let size = canvasSize
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        ZStack {
            // Background: radial gold glow on top of bgSecondary + noise grid overlay.
            background

            // Corner ornaments (decorative brackets)
            cornerOrnaments

            // Solid connections — drawn in Canvas for perf
            Canvas { context, _ in
                for conn in connections {
                    guard let from = nodeMap[conn.fromId],
                          let to = nodeMap[conn.toId] else { continue }
                    let s = style(for: conn, nodeMap: nodeMap)
                    guard s == .unlockedSolid || s == .pendingSolid || s == .locked else { continue }
                    let p1 = screenPosition(for: from)
                    let p2 = screenPosition(for: to)
                    var path = Path()
                    path.move(to: p1)
                    path.addLine(to: p2)
                    let (color, width): (Color, CGFloat) = {
                        switch s {
                        case .unlockedSolid: return (DarkFantasyTheme.gold, 2.5)
                        case .pendingSolid:  return (DarkFantasyTheme.goldDim, 2)
                        case .locked:        return (DarkFantasyTheme.borderSubtle, 1.5)
                        default:             return (DarkFantasyTheme.borderSubtle, 1.5)
                        }
                    }()
                    context.stroke(path, with: .color(color), lineWidth: width)
                }
            }
            .frame(width: size.width, height: size.height)

            // Dashed animated unlockable connections — separate Canvas so the
            // animated dashPhase invalidation doesn't redraw the solid lines.
            Canvas { context, _ in
                for conn in connections {
                    guard let from = nodeMap[conn.fromId],
                          let to = nodeMap[conn.toId] else { continue }
                    guard style(for: conn, nodeMap: nodeMap) == .unlockableDash else { continue }
                    let p1 = screenPosition(for: from)
                    let p2 = screenPosition(for: to)
                    var path = Path()
                    path.move(to: p1)
                    path.addLine(to: p2)
                    context.stroke(
                        path,
                        with: .color(DarkFantasyTheme.gold.opacity(0.45)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4], dashPhase: dashPhase)
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
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                dashPhase = -16
            }
        }
        .onDisappear { dashPhase = 0 }
    }

    // MARK: - Background (radial glow + noise grid)

    private var background: some View {
        let size = canvasSize
        return ZStack {
            DarkFantasyTheme.bgSecondary
            // Top-center gold radial glow — pulls the eye to the keystone.
            RadialGradient(
                colors: [DarkFantasyTheme.gold.opacity(0.06), .clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: size.height * 0.7
            )
            // 24pt grid — barely-there lines so the canvas reads as "arcane chart".
            GridLinesOverlay(spacing: 24)
                .opacity(0.5)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    private var cornerOrnaments: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .overlay(alignment: .topLeading) { cornerBracket(rotation: 0) }
                .overlay(alignment: .topTrailing) { cornerBracket(rotation: 90) }
                .overlay(alignment: .bottomTrailing) { cornerBracket(rotation: 180) }
                .overlay(alignment: .bottomLeading) { cornerBracket(rotation: 270) }
        }
        .allowsHitTesting(false)
    }

    /// L-shaped corner bracket (top-left orientation at rotation 0).
    private func cornerBracket(rotation: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Horizontal arm
            Rectangle()
                .fill(DarkFantasyTheme.goldDim)
                .frame(width: 14, height: 1.5)
            // Vertical arm
            Rectangle()
                .fill(DarkFantasyTheme.goldDim)
                .frame(width: 1.5, height: 14)
        }
        .opacity(0.4)
        .frame(width: 14, height: 14)
        .padding(8)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Grid lines overlay

private struct GridLinesOverlay: View {
    let spacing: CGFloat

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let stroke = GraphicsContext.Shading.color(Color.white.opacity(0.015))
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                ctx.stroke(path, with: stroke, lineWidth: 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
