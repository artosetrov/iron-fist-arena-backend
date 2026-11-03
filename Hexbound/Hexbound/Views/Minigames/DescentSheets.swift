import SwiftUI

// MARK: - Map

/// The depth drawn on parchment: inked routes, tokens for rooms, a wax seal for
/// the guardian and the hero's figure where you stand.
struct DescentMapSheet: View {
    let snapshot: DescentSnapshot
    let onClose: () -> Void

    static let parchmentAspect: CGFloat = 1240.0 / 1680.0
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
                        DescentMapBoard(map: snapshot.map)
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

/// One step of the hero's walk on the map: the route from `from` (nil: the
/// depth's entrance) to `to`, and how far along it the figure is (0…1).
struct DescentMapStep: Equatable {
    let from: String?
    let to: String
    let progress: Double
}

/// Routes, room tokens and the hero's figure, laid out on a 320-wide grid like
/// the prototype. Walked routes are solid ink — where the hero has been — the
/// rest dotted. With a `step`, the figure walks that route and its ink fills in
/// behind it.
struct DescentMapBoard: View {
    let map: DescentMap
    var step: DescentMapStep?
    /// The room just reached: a warm glow under its token.
    var arrivedAt: String?

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
            // The route being walked, eased so the figure sets off and arrives gently.
            let walkCurve: Curve? = step.flatMap { st -> Curve? in
                guard let to = byId[st.to] else { return nil }
                let from: CGPoint = st.from.flatMap { byId[$0] }.map { pos($0, s: s, origin: origin) } ?? start
                return curve(from: from, to: pos(to, s: s, origin: origin), key: (st.from ?? "S") + st.to, s: s)
            }
            let eased: Double = step.map { Self.ease($0.progress) } ?? 1
            let resting: CGPoint = current.map { pos($0, s: s, origin: origin) } ?? start
            let heroPoint: CGPoint = walkCurve?.point(at: eased) ?? resting

            ZStack {
                Canvas { ctx, _ in
                    for id in map.startNext {
                        guard let to = byId[id] else { continue }
                        ink(&ctx, curve(from: start, to: pos(to, s: s, origin: origin), key: "S" + id, s: s), walked: to.visited, s: s)
                    }
                    for node in nodes {
                        for id in node.next {
                            guard let to = byId[id] else { continue }
                            ink(&ctx, curve(from: pos(node, s: s, origin: origin), to: pos(to, s: s, origin: origin), key: node.id + id, s: s),
                                walked: node.visited && to.visited, s: s)
                        }
                    }
                    if let walkCurve, eased > 0 {
                        ctx.stroke(
                            walkCurve.path.trimmedPath(from: 0, to: eased),
                            with: .color(Self.walkedInk),
                            style: StrokeStyle(lineWidth: 3.8 * s, lineCap: .round)
                        )
                    }
                    let mark = Path(ellipseIn: CGRect(x: start.x - 7 * s, y: start.y - 7 * s, width: 14 * s, height: 14 * s))
                    ctx.stroke(mark, with: .color(DarkFantasyTheme.btnOrangeDark), lineWidth: 3 * s)
                }

                ForEach(nodes) { node in
                    ZStack {
                        if node.id == arrivedAt {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [DarkFantasyTheme.goldBright.opacity(0.55), DarkFantasyTheme.goldBright.opacity(0)],
                                    center: .center, startRadius: 0, endRadius: 44 * s
                                ))
                                .frame(width: 88 * s, height: 88 * s)
                                .transition(.opacity)
                        }
                        DescentMapToken(node: node, s: s)
                    }
                    .position(pos(node, s: s, origin: origin))
                }
                .animation(.easeOut(duration: 0.35), value: arrivedAt)

                hero(s: s, at: heroPoint, phase: walkCurve == nil ? 1 : eased)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Map of this depth")
    }

    /// The figure stands on its room; walking, it hops once per step and leans
    /// into each one.
    private func hero(s: CGFloat, at p: CGPoint, phase: Double) -> some View {
        let pace = phase * Double(DescentWalk.steps)
        let hop = sin(.pi * (pace - pace.rounded(.down)))
        return Image("rush2-map-hero")
            .resizable()
            .scaledToFit()
            .frame(width: 52 * s, height: 52 * s)
            .rotationEffect(.degrees(4 * sin(.pi * pace)), anchor: .bottom)
            .position(x: p.x, y: p.y - 36 * s - CGFloat(hop) * 7 * s)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)
            .accessibilityLabel("You are here")
    }

    private static let walkedInk = DarkFantasyTheme.btnOrangeDark.opacity(0.92)

    /// Smoothstep: the figure sets off and arrives gently.
    private static func ease(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    private func point(_ p: CGPoint, s: CGFloat, origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + p.x * s, y: origin.y + p.y * s)
    }

    private func pos(_ n: DescentMapNode, s: CGFloat, origin: CGPoint) -> CGPoint {
        point(CGPoint(x: 52 + CGFloat(n.lane) * 108, y: 46 + CGFloat(n.r + 1) * Self.rowHeight - 14), s: s, origin: origin)
    }

    /// A hand-inked route between two rooms: a quadratic curve with a gentle bow,
    /// the same bow every time for the same pair of rooms.
    private struct Curve {
        let a: CGPoint
        let c: CGPoint
        let b: CGPoint

        var path: Path {
            var path = Path()
            path.move(to: a)
            path.addQuadCurve(to: b, control: c)
            return path
        }

        func point(at t: Double) -> CGPoint {
            let t = CGFloat(t)
            let u = 1 - t
            return CGPoint(
                x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                y: u * u * a.y + 2 * u * t * c.y + t * t * b.y
            )
        }
    }

    private func curve(from a: CGPoint, to b: CGPoint, key: String, s: CGFloat) -> Curve {
        let hash = key.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF_FFFF }
        let bow = CGFloat(hash % 1000) / 1000 - 0.5
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = max(1, (dx * dx + dy * dy).squareRoot())
        return Curve(a: a, c: CGPoint(x: mid.x - dy / len * bow * 26 * s, y: mid.y + dx / len * bow * 26 * s), b: b)
    }

    private func ink(_ ctx: inout GraphicsContext, _ curve: Curve, walked: Bool, s: CGFloat) {
        let style = walked
            ? StrokeStyle(lineWidth: 3.8 * s, lineCap: .round)
            : StrokeStyle(lineWidth: 2.1 * s, lineCap: .round, dash: [1.5 * s, 7 * s])
        ctx.stroke(curve.path, with: .color(walked ? Self.walkedInk : DarkFantasyTheme.shopSignTop.opacity(0.6)), style: style)
    }
}

// MARK: - The walk

/// After "Take this path" (`DescentViewModel.walk`): the depth's map, the figure
/// walking the route to the chosen room with the trail inking in behind it.
/// Once the room is in, its token shows (a dark passage's room too) and the map
/// closes. A tap skips the walk.
struct DescentWalkOverlay: View {
    let walk: DescentWalk
    /// The live run: once the room is in, the map is its map.
    let snapshot: DescentSnapshot
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMS) {
                Text("DEPTH \(snapshot.depthRoman) · \(snapshot.depthName.uppercased())")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, minHeight: 32)

                GeometryReader { geo in
                    let size = DescentMapSheet.fit(DescentMapSheet.parchmentAspect, in: geo.size)
                    ZStack {
                        Image("rush2-map-parchment")
                            .resizable()
                            .frame(width: size.width, height: size.height)
                            .depthShadow(.modal)
                        TimelineView(.animation(paused: walk.arrived || walk.pinned != nil)) { context in
                            DescentMapBoard(
                                map: walk.arrived ? snapshot.map : walk.map,
                                step: walk.arrived ? nil : DescentMapStep(from: walk.from, to: walk.to, progress: walk.progress(at: context.date)),
                                arrivedAt: walk.arrived ? walk.to : nil
                            )
                        }
                        .frame(width: size.width * 0.8, height: size.height * 0.84)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                VStack(spacing: LayoutConstants.space2XS) {
                    Text(title.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(2)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text(walk.cue)
                        .font(DarkFantasyTheme.tale)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(minHeight: 56)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceMD)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSkip)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("On the map, walking to \(title)")
        .accessibilityHint("Double-tap to skip")
        .accessibilityAddTraits(.isButton)
    }

    /// Where the hero is going: the room once it is in (a dark passage's room
    /// shows itself on arrival), else the passage's name.
    private var title: String {
        if walk.arrived, let type = snapshot.map.rows.joined().first(where: { $0.id == walk.to })?.roomType {
            return type.displayName
        }
        return walk.destination ?? "Into the dark"
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
