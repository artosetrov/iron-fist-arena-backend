import SwiftUI

// MARK: - Map

/// The depth drawn on parchment: inked routes, tokens for rooms, a wax seal for
/// the guardian and the hero's figure where you stand.
struct DescentMapSheet: View {
    let snapshot: DescentSnapshot
    let onClose: () -> Void

    private static let parchmentAspect: CGFloat = 1240.0 / 1680.0
    private static let legend: [DescentRoomType] = [.combat, .elite, .treasure, .event, .camp, .merchant, .boss]

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)

            VStack(spacing: LayoutConstants.spaceMS) {
                HStack {
                    Text("DEPTH \(snapshot.depthRoman) · \(snapshot.depthName.uppercased())")
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(2)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                    .accessibilityLabel("Close the map")
                }

                GeometryReader { geo in
                    let size = Self.fit(Self.parchmentAspect, in: geo.size)
                    ZStack {
                        Image("rush2-map-parchment")
                            .resizable()
                            .frame(width: size.width, height: size.height)
                            .depthShadow(.modal)
                        DescentMapRoutes(map: snapshot.map)
                            .frame(width: size.width * 0.8, height: size.height * 0.84)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                Text("Campfires and merchants show from afar. Everything else you learn by walking, or by torchlight.")
                    .font(DarkFantasyTheme.tale)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                DescentFlowLayout(spacing: LayoutConstants.spaceMS) {
                    ForEach(Self.legend, id: \.self) { type in
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Image(type.iconAsset)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(type.displayName.uppercased())
                                .font(DarkFantasyTheme.buttonLabelCompact)
                                .tracking(1)
                                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                        }
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
        .transition(.opacity)
    }

    static func fit(_ aspect: CGFloat, in size: CGSize) -> CGSize {
        let byWidth = CGSize(width: size.width, height: size.width / aspect)
        if byWidth.height <= size.height { return byWidth }
        return CGSize(width: size.height * aspect, height: size.height)
    }
}

/// Routes and room tokens, laid out on a 320-wide grid like the prototype.
private struct DescentMapRoutes: View {
    let map: DescentMap

    private static let gridWidth: CGFloat = 320
    private static let rowHeight: CGFloat = 62

    private var gridHeight: CGFloat { 46 + CGFloat(map.rows.count) * Self.rowHeight + 24 }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / Self.gridWidth, geo.size.height / gridHeight)
            let origin = CGPoint(x: (geo.size.width - Self.gridWidth * s) / 2, y: (geo.size.height - gridHeight * s) / 2)
            let nodes = map.rows.flatMap { $0 }
            let byId = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
            let start = point(CGPoint(x: 160, y: 24), s: s, origin: origin)
            let current = nodes.first { $0.current }
            let hero = current.map { pos($0, s: s, origin: origin) } ?? start

            ZStack {
                Canvas { ctx, _ in
                    for id in map.startNext {
                        guard let to = byId[id] else { continue }
                        ink(&ctx, from: start, to: pos(to, s: s, origin: origin), walked: to.visited, key: "S" + id, s: s)
                    }
                    for node in nodes {
                        for id in node.next {
                            guard let to = byId[id] else { continue }
                            ink(&ctx, from: pos(node, s: s, origin: origin), to: pos(to, s: s, origin: origin),
                                walked: node.visited && to.visited, key: node.id + id, s: s)
                        }
                    }
                    let mark = Path(ellipseIn: CGRect(x: start.x - 7 * s, y: start.y - 7 * s, width: 14 * s, height: 14 * s))
                    ctx.stroke(mark, with: .color(DarkFantasyTheme.btnOrangeDark), lineWidth: 3 * s)
                }

                ForEach(nodes) { node in
                    DescentMapToken(node: node, s: s)
                        .position(pos(node, s: s, origin: origin))
                }

                Image("rush2-map-hero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52 * s, height: 52 * s)
                    .position(x: hero.x, y: hero.y - 36 * s)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
                    .accessibilityLabel("You are here")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Map of this depth")
    }

    private func point(_ p: CGPoint, s: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + p.x * s, y: origin.y + p.y * s)
    }

    private func pos(_ n: DescentMapNode, s: CGFloat, origin: CGPoint) -> CGPoint {
        point(CGPoint(x: 52 + CGFloat(n.lane) * 108, y: 46 + CGFloat(n.r + 1) * Self.rowHeight - 14), s: s, origin: origin)
    }

    /// A hand-inked route: a gentle bow per segment, the same bow every time for the same pair of rooms.
    private func ink(_ ctx: inout GraphicsContext, from a: CGPoint, to b: CGPoint, walked: Bool, key: String, s: CGFloat) {
        let hash = key.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF_FFFF }
        let bow = CGFloat(hash % 1000) / 1000 - 0.5
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(1, (dx * dx + dy * dy).squareRoot())
        var path = Path()
        path.move(to: a)
        path.addQuadCurve(to: b, control: CGPoint(x: mid.x - dy / len * bow * 26 * s, y: mid.y + dx / len * bow * 26 * s))
        let style = walked
            ? StrokeStyle(lineWidth: 3.8 * s, lineCap: .round)
            : StrokeStyle(lineWidth: 2.1 * s, lineCap: .round, dash: [1.5 * s, 7 * s])
        ctx.stroke(path, with: .color(walked ? DarkFantasyTheme.btnOrangeDark.opacity(0.92) : DarkFantasyTheme.shopSignTop.opacity(0.6)), style: style)
    }
}

private struct DescentMapToken: View {
    let node: DescentMapNode
    let s: CGFloat

    private var isBoss: Bool { node.roomType == .boss }
    private var radius: CGFloat { (isBoss ? 27 : 19) * s }

    var body: some View {
        ZStack {
            if node.reachable {
                Circle()
                    .stroke(DarkFantasyTheme.gold, lineWidth: 3 * s)
                    .frame(width: (radius + 7 * s) * 2, height: (radius + 7 * s) * 2)
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 6)
            }
            Image(isBoss ? "rush2-map-seal" : "rush2-map-token")
                .resizable()
                .scaledToFit()
                .frame(width: radius * 2.55, height: radius * 2.55)
            if let type = node.roomType {
                Image(type.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: radius * 1.5, height: radius * 1.5)
                    .opacity(node.cleared ? 0.45 : 1)
            } else {
                Text("?")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.shopSignTagline.opacity(0.75))
            }
            if node.cleared {
                Path { p in
                    let d = 11 * s
                    p.move(to: CGPoint(x: -d, y: -d))
                    p.addLine(to: CGPoint(x: d, y: d))
                    p.move(to: CGPoint(x: d, y: -d))
                    p.addLine(to: CGPoint(x: -d, y: d))
                }
                .offsetBy(dx: radius * 1.3, dy: radius * 1.3)
                .stroke(DarkFantasyTheme.btnOrangeDark.opacity(0.85), style: StrokeStyle(lineWidth: 3.4 * s, lineCap: .round))
                .frame(width: radius * 2.6, height: radius * 2.6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(label)
    }

    private var label: String {
        let what = node.roomType?.displayName ?? "Unknown room"
        if node.current { return "\(what), you are here" }
        if node.cleared { return "\(what), cleared" }
        if node.reachable { return "\(what), reachable" }
        return what
    }
}

// MARK: - Bag

struct DescentBagSheet: View {
    let snapshot: DescentSnapshot
    let onClose: () -> Void
    let onAbandon: () -> Void

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)

            VStack(spacing: LayoutConstants.spaceMS) {
                HStack {
                    Text("YOUR BAG")
                        .font(DarkFantasyTheme.section)
                        .tracking(2)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.closeButton)
                    .accessibilityLabel("Close the bag")
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: LayoutConstants.spaceMS) {
                        DescentSummaryBox(title: "At risk", note: "Half lost if you fall", danger: true) {
                            DescentValueLine(label: "Gold", value: "\(snapshot.bag.gold)", color: DarkFantasyTheme.textGold)
                            DescentItemsList(items: snapshot.bag.items)
                        }
                        DescentSummaryBox(title: "Safe", note: "Stashed at campfires") {
                            DescentValueLine(label: "Gold", value: "\(snapshot.safe.gold)")
                            DescentItemsList(items: snapshot.safe.items)
                        }
                        DescentSummaryBox(title: "Belt") {
                            DescentValueLine(label: "Health potions",
                                             value: "\(snapshot.hero.potions) / \(snapshot.hero.maxPotions) · heal \(snapshot.hero.potionHeal)")
                            DescentValueLine(label: "Torches", value: "\(snapshot.hero.torches) / \(snapshot.hero.maxTorches)")
                            DescentValueLine(label: "Damage bonus", value: "+\(snapshot.hero.dmgBonusPct)%")
                            DescentValueLine(label: "Experience", value: "\(snapshot.xpEarned) XP · never lost")
                        }
                        DescentSummaryBox(title: "Relics") {
                            if snapshot.relics.isEmpty {
                                Text("Guardians drop relics. So do lucky chests.")
                                    .font(DarkFantasyTheme.tale)
                                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                            } else {
                                ForEach(snapshot.relics) { relic in
                                    HStack(spacing: LayoutConstants.spaceMS) {
                                        Image(relic.icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36)
                                        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                                            Text(relic.name)
                                                .font(DarkFantasyTheme.cardTitle)
                                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                                            Text(relic.desc)
                                                .font(DarkFantasyTheme.tale)
                                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        if !snapshot.isOver {
                            Button("Abandon the descent", action: onAbandon)
                                .buttonStyle(.dangerOutline)
                                .padding(.top, LayoutConstants.spaceSM)
                        }
                    }
                    .padding(.bottom, LayoutConstants.spaceMD)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
        }
        .transition(.opacity)
    }
}
