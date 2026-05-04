//
//  TalentTreeCanvas.swift
//  Hexbound
//
//  Renders the passive-tree nodes + connections. X is scaled so adjacent nodes
//  in the same row keep a minimum on-screen gap (`xMinGap`) — this prevents
//  overlap on dense rows but lets the canvas grow wider than the container,
//  in which case the parent ScrollView pans horizontally. Y uses a constant
//  row-index pitch (not derived from backend Y deltas) so rows stack uniformly
//  regardless of how far apart their Y coords are in the backend's 1400×600
//  world canvas.
//
//  Uses SwiftUI Canvas for connections (solid, dashed), ZStack for tappable
//  nodes. Node positions come from backend (PassiveNode.positionX/Y).
//

import SwiftUI

struct TalentTreeCanvas: View {
    let nodes: [PassiveNode]
    let connections: [PassiveConnection]
    let isUnlocked: (PassiveNode) -> Bool
    let isPending: (PassiveNode) -> Bool
    let isUnlockable: (PassiveNode) -> Bool
    /// Talents v2: committed rank from server (0 = not unlocked). Optional with
    /// a default so legacy call sites still compile.
    var currentRank: (PassiveNode) -> Int = { _ in 0 }
    /// Talents v2: locally-staged target rank (0 = nothing staged).
    var stagedRank: (PassiveNode) -> Int = { _ in 0 }
    let onTap: (PassiveNode) -> Void

    /// Inset around the entire tree from the canvas edges. Must be at least
    /// half the node size (28pt) so leftmost/rightmost foundation nodes and
    /// the bottom-row ultimates aren't clipped by the canvas border. 32pt
    /// gives a 4pt visual gap between node edge and canvas frame.
    private let nodePadding: CGFloat = 32
    /// Minimum on-screen X gap between centers of two nodes in the same row.
    /// Sized for the uniform 56pt node + 16pt breathing room.
    private let xMinGap: CGFloat = 72
    /// Vertical distance between adjacent tier rows. 56pt node + 8pt = 64pt;
    /// 6 unique tier rows post-migration → 5 transitions × 64 + 2 × 32 padding
    /// = 384pt content, fits inside the 400pt canvas frame in TalentsTabView.
    private let rowPitch: CGFloat = 64

    // MARK: - Layout cache
    //
    // bounds, sortedYs, minSameRowXDelta were previously computed properties
    // that re-ran on every body invalidation (selection, pulse, etc). For
    // n≈23 nodes the O(n²) inner loop is ~250 comparisons per render — small
    // but multiplied by SwiftUI's eager re-evaluation it adds up. CachedLayout
    // does the work once per body call and is reused by every helper below.

    private struct CachedLayout {
        let minX: Double
        let xScale: CGFloat
        let rowYs: [Double]      // sorted unique Y values (top → bottom on screen)
        let canvasSize: CGSize

        func position(
            for node: PassiveNode,
            padding: CGFloat,
            rowPitch: CGFloat
        ) -> CGPoint {
            let rowIndex = rowYs.firstIndex(of: node.positionY) ?? 0
            return CGPoint(
                x: padding + CGFloat(node.positionX - minX) * xScale,
                y: padding + CGFloat(rowIndex) * rowPitch
            )
        }
    }

    private func makeLayout() -> CachedLayout {
        guard !nodes.isEmpty else {
            return CachedLayout(
                minX: 0,
                xScale: 1,
                rowYs: [0],
                canvasSize: CGSize(width: nodePadding * 2, height: nodePadding * 2)
            )
        }

        // Bounds + unique-Y rows in one pass.
        var minX = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var ySet = Set<Double>()
        for node in nodes {
            if node.positionX < minX { minX = node.positionX }
            if node.positionX > maxX { maxX = node.positionX }
            ySet.insert(node.positionY)
        }
        let rowYs = ySet.sorted()

        // Min same-row X delta — keep O(n²) but hoisted out of body.
        var minSameRowDx = Double.greatestFiniteMagnitude
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                guard abs(nodes[i].positionY - nodes[j].positionY) < 0.001 else { continue }
                let dx = abs(nodes[i].positionX - nodes[j].positionX)
                if dx > 0.001 { minSameRowDx = min(minSameRowDx, dx) }
            }
        }
        if minSameRowDx == Double.greatestFiniteMagnitude { minSameRowDx = 1 }

        let xScale = xMinGap / CGFloat(minSameRowDx)
        let xRange = CGFloat(max(maxX - minX, 1))
        let rowCount = max(rowYs.count, 1)
        let canvasSize = CGSize(
            width: xRange * xScale + nodePadding * 2,
            height: CGFloat(rowCount - 1) * rowPitch + nodePadding * 2
        )

        return CachedLayout(
            minX: minX,
            xScale: xScale,
            rowYs: rowYs,
            canvasSize: canvasSize
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

    // MARK: - Connection routing (orthogonal "subway map" style)

    /// Returns a stepped path between two points instead of a straight diagonal.
    /// Same-row → straight horizontal; same-column → straight vertical;
    /// diagonal → vertical → horizontal at the midpoint between source and
    /// destination Y → vertical. The midpoint sits BETWEEN tier rows
    /// (rowPitch is constant), so horizontal segments don't intersect node
    /// rows. This gives the canvas a "circuit board" look that scales much
    /// better visually than crisscrossing diagonals.
    private func orthogonalPath(from p1: CGPoint, to p2: CGPoint) -> Path {
        var path = Path()
        path.move(to: p1)
        let dx = abs(p2.x - p1.x)
        let dy = abs(p2.y - p1.y)
        // ~1pt tolerance — anything below counts as axis-aligned.
        if dx < 1 || dy < 1 {
            path.addLine(to: p2)
            return path
        }
        let midY = (p1.y + p2.y) / 2
        path.addLine(to: CGPoint(x: p1.x, y: midY))
        path.addLine(to: CGPoint(x: p2.x, y: midY))
        path.addLine(to: p2)
        return path
    }

    // MARK: - Animation for dashed unlockable lines

    @State private var dashPhase: CGFloat = 0

    // MARK: - Body

    var body: some View {
        let layout = makeLayout()
        let size = layout.canvasSize
        let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        let pos: (PassiveNode) -> CGPoint = { node in
            layout.position(for: node, padding: self.nodePadding, rowPitch: self.rowPitch)
        }

        ZStack {
            // Background: radial gold glow on top of bgSecondary + noise grid overlay.
            background(size: size)

            // Corner ornaments (decorative brackets)
            cornerOrnaments(size: size)

            // Solid connections — drawn in Canvas for perf
            Canvas { context, _ in
                for conn in connections {
                    guard let from = nodeMap[conn.fromId],
                          let to = nodeMap[conn.toId] else { continue }
                    let s = style(for: conn, nodeMap: nodeMap)
                    guard s == .unlockedSolid || s == .pendingSolid || s == .locked else { continue }
                    let p1 = pos(from)
                    let p2 = pos(to)
                    let path = orthogonalPath(from: p1, to: p2)
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
                    let p1 = pos(from)
                    let p2 = pos(to)
                    let path = orthogonalPath(from: p1, to: p2)
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
                    TalentNodeView(
                        node: node,
                        state: state(for: node),
                        currentRank: currentRank(node),
                        stagedRank: stagedRank(node)
                    )
                }
                .buttonStyle(.plain)
                .position(pos(node))
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

    private func background(size: CGSize) -> some View {
        ZStack {
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

    private func cornerOrnaments(size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(width: size.width, height: size.height)
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
