import SwiftUI

// MARK: - Dungeon Trail View

/// The dungeon as a place you travel through: a painted panorama in the
/// hub's projection with all ten bosses standing on their clearings. The
/// road the hero has walked is drawn in gold up to the hero's token, the
/// rest of the trail is pale and runs on into the dark. Beaten bosses stand
/// greyed out, the next one is lit, the ones ahead are shadows.
///
/// Tapping a boss (or NEXT at the bottom) opens `DungeonRoomDetailView` on
/// that boss — the fight itself still starts there. Coming back after a win,
/// the hero walks on to the next boss.
struct DungeonTrailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    /// Same model as the room: resolves the dungeon from the cache and
    /// refreshes progress from the server in the background.
    @State private var vm: DungeonRoomViewModel?
    @State private var showDungeonInfo = false
    /// Hero position as a fraction of the trail's length. Animated when the
    /// defeated count grows (the hero walks to the next boss).
    @State private var heroFraction: CGFloat?
    /// Navigation depth this screen sits at, to tell a pop from a push.
    @State private var stackDepth: Int?

    /// Trail art for the dungeon the model resolved (not just the selected
    /// id), so the painting and the bosses standing on it always agree.
    private var config: DungeonTrailConfig? {
        DungeonTrailConfig.config(for: vm?.dungeon?.id)
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()

            if let config, let vm, let dungeon = vm.dungeon, !dungeon.bosses.isEmpty {
                TrailMap(
                    config: config,
                    geometry: DungeonTrailGeometry(config: config, bossCount: dungeon.bosses.count),
                    dungeon: dungeon,
                    defeated: min(vm.defeatedCount, dungeon.totalBosses),
                    heroFraction: heroFraction ?? targetHeroFraction ?? 0,
                    hero: appState.currentCharacter,
                    onBoss: { tapBoss(at: $0, vm: vm) }
                )
                .ignoresSafeArea()

                scrims
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    bottomPanel(vm: vm, dungeon: dungeon)
                }
            } else if let vm, vm.dungeon == nil, vm.errorMessage != nil {
                ErrorStateView.loadFailed {
                    Task { await vm.loadState() }
                }
            } else if let vm, vm.dungeon != nil {
                // A dungeon without trail art (the entry points route those
                // straight to the room): offer the way in.
                Button("ENTER") { openRoom(at: vm.currentBossIndex) }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.screenPadding)
            } else {
                HexPulseLoader(.compact)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text(vm?.dungeon?.name.uppercased() ?? "DUNGEON")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.arenaRankGold)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .subtleShadow()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showDungeonInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dungeon info")
            }
        }
        .sheet(isPresented: $showDungeonInfo) {
            if let dungeon = vm?.dungeon {
                DungeonInfoSheet(dungeon: dungeon, defeatedCount: vm?.defeatedCount ?? 0)
            }
        }
        .onAppear {
            if stackDepth == nil { stackDepth = appState.mainPath.count }
            appState.dungeonTrailDepth = stackDepth
            AmbientManager.shared.setZone(.dungeon)
        }
        .onDisappear {
            // Popped off (back to the overland map / hub), not covered by
            // the room: hand the ambience back to the hub.
            if appState.mainPath.count < (stackDepth ?? 0) {
                appState.dungeonTrailDepth = nil
                AmbientManager.shared.setZone(.hub)
            }
        }
        .task {
            let model: DungeonRoomViewModel
            if let vm {
                model = vm
            } else {
                model = DungeonRoomViewModel(appState: appState, cache: cache)
                vm = model
            }
            // Cache-first inside: the room writes every win into the shared
            // progress map, so coming back the hero walks on at once.
            await model.loadState()
        }
        .onChange(of: vm?.dungeon?.id) { _, _ in
            // First resolve: place the hero without walking.
            guard heroFraction == nil, let fraction = targetHeroFraction else { return }
            heroFraction = fraction
        }
        .onChange(of: vm?.defeatedCount) { _, _ in
            guard let fraction = targetHeroFraction else { return }
            if heroFraction == nil {
                heroFraction = fraction
            } else if fraction != heroFraction {
                withAnimation(.easeInOut(duration: MotionConstants.epic)) {
                    heroFraction = fraction
                }
            }
        }
    }

    // MARK: - Hero position

    /// Where the hero stands for the current progress: on the leg leading
    /// to the next boss, a little past halfway; at the lair once it is all
    /// cleared.
    private var targetHeroFraction: CGFloat? {
        guard let config, let vm, let dungeon = vm.dungeon, !dungeon.bosses.isEmpty else { return nil }
        let geometry = DungeonTrailGeometry(config: config, bossCount: dungeon.bosses.count)
        let stops = min(dungeon.bosses.count, config.stands.count)
        let defeated = min(vm.defeatedCount, dungeon.totalBosses)
        if defeated >= stops {
            return geometry.fraction(leg: stops - 1, t: 0.8)
        }
        return geometry.fraction(leg: defeated, t: 0.55)
    }

    // MARK: - Navigation

    private func tapBoss(at index: Int, vm: DungeonRoomViewModel) {
        guard let dungeon = vm.dungeon, dungeon.bosses.indices.contains(index) else { return }
        if vm.bossState(at: index) == .locked {
            HapticManager.selection()
            let next = vm.currentBoss?.name ?? "the next boss"
            appState.showToast("Stage \(index + 1) is still sealed", subtitle: "Defeat \(next) first", type: .info)
            return
        }
        SFXManager.shared.play(.uiTap)
        HapticManager.selection()
        openRoom(at: index)
    }

    /// Push the room with `index` on the stage. Ignored unless this screen
    /// is on top, so a double tap can't push twice.
    private func openRoom(at index: Int) {
        guard appState.mainPath.count == (stackDepth ?? appState.mainPath.count) else { return }
        appState.requestedDungeonBossIndex = index
        appState.mainPath.append(AppRoute.dungeonRoom)
    }

    // MARK: - Chrome

    /// Darken the top under the toolbar and the bottom under the panel so
    /// both read over the painting.
    private var scrims: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [DarkFantasyTheme.bgPrimary.opacity(0.85), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: LayoutConstants.safeAreaTop + 90)
            Spacer()
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.bgPrimary.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 210)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func bottomPanel(vm: DungeonRoomViewModel, dungeon: DungeonInfo) -> some View {
        let total = dungeon.totalBosses
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(vm.isDungeonComplete
                 ? "ALL \(total) CLEARED"
                 : "STAGE \(min(vm.defeatedCount + 1, total)) OF \(total)")
                .font(DarkFantasyTheme.body)
                .tracking(1.5)
                .foregroundStyle(vm.isDungeonComplete ? DarkFantasyTheme.success : DarkFantasyTheme.textSecondary)
                .subtleShadow()

            if vm.isDungeonComplete {
                Button {
                    SFXManager.shared.play(.uiTap)
                    openRoom(at: max(total - 1, 0))
                } label: {
                    Text("VIEW BOSSES")
                }
                .buttonStyle(.secondary)
            } else if let boss = vm.currentBoss {
                Button {
                    SFXManager.shared.play(.uiTap)
                    HapticManager.selection()
                    openRoom(at: vm.currentBossIndex)
                } label: {
                    Text("NEXT: \(boss.name.uppercased())")
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
                .buttonStyle(.primary)
                .accessibilityLabel(Text("Open stage \(vm.currentBossIndex + 1), \(boss.name)"))
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.bottom, LayoutConstants.spaceSM)
    }
}

// MARK: - Trail Map

/// The scrollable panorama: painting, fog ahead of the hero, the trail,
/// the bosses and the hero token. Everything is placed in map space, so it
/// scales with the screen height.
private struct TrailMap: View {
    let config: DungeonTrailConfig
    let geometry: DungeonTrailGeometry
    let dungeon: DungeonInfo
    let defeated: Int
    let heroFraction: CGFloat
    let hero: Character?
    let onBoss: (Int) -> Void

    private var stands: [CGPoint] {
        Array(config.stands.prefix(dungeon.bosses.count))
    }

    private var currentIndex: Int? {
        defeated < stands.count ? defeated : nil
    }

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = height * DungeonTrailConfig.imageAspect
            let focusX = (stands[safe: focusIndex]?.x ?? 0) * width

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        scrollTargets(mapWidth: width)

                        Image(config.background)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: width, height: height)

                        fogAhead(width: width, height: height)

                        trail
                            .frame(width: width, height: height)

                        ForEach(drawOrder, id: \.self) { index in
                            bossNode(index: index, mapWidth: width, mapHeight: height)
                        }

                        TrailHeroToken(hero: hero)
                            .modifier(TrailPositionEffect(fraction: heroFraction, geometry: geometry, height: height))
                    }
                    .frame(width: width, height: height)
                    .background(ScrollBounceDisabler())
                }
                .defaultScrollAnchor(
                    UnitPoint(
                        x: Self.anchor(focusX: focusX, contentWidth: width, viewWidth: geo.size.width),
                        y: 0.5
                    )
                )
                .onChange(of: defeated) { _, _ in
                    // A win (or fresher server progress): follow the hero to the
                    // next boss while they walk.
                    withAnimation(.easeInOut(duration: MotionConstants.epic)) {
                        proxy.scrollTo(Self.targetID(focusIndex), anchor: .center)
                    }
                }
            }
        }
    }

    /// The boss the camera follows: the next fight, or the lair once cleared.
    private var focusIndex: Int {
        currentIndex ?? max(stands.count - 1, 0)
    }

    private static func targetID(_ index: Int) -> String { "trail-stand-\(index)" }

    /// Invisible 1×1 marks at each stand's x, laid out for real (not
    /// `.position`ed), so `ScrollViewReader.scrollTo` can centre on them.
    private func scrollTargets(mapWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(stands.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    Color.clear.frame(width: max(stands[index].x * mapWidth - 0.5, 0), height: 1)
                    Color.clear.frame(width: 1, height: 1).id(Self.targetID(index))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Scroll anchor that puts `focusX` in the middle of the screen.
    private static func anchor(focusX: CGFloat, contentWidth: CGFloat, viewWidth: CGFloat) -> CGFloat {
        let travel = contentWidth - viewWidth
        guard travel > 0 else { return 0 }
        return min(max((focusX - viewWidth / 2) / travel, 0), 1)
    }

    /// Back to front: bosses higher on the map are farther away.
    private var drawOrder: [Int] {
        stands.indices.sorted { stands[$0].y < stands[$1].y }
    }

    private func state(_ index: Int) -> BossState {
        if index < defeated { return .defeated }
        if index == defeated { return .current }
        return .locked
    }

    // MARK: Fog

    /// The unexplored part of the map sinks into the dark, starting just
    /// past the next boss. Gone once the dungeon is cleared.
    @ViewBuilder
    private func fogAhead(width: CGFloat, height: CGFloat) -> some View {
        if let currentIndex, let stand = stands[safe: currentIndex] {
            let start = min(stand.x + 70 / width, 1)
            let end = min(start + 260 / width, 1)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: start),
                    .init(color: DarkFantasyTheme.bgAbyss.opacity(0.45), location: max(end, start))
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width, height: height)
            .allowsHitTesting(false)
        }
    }

    // MARK: Trail

    /// The whole trail as pale ink dots, the walked part re-inked in gold
    /// up to the hero (trimmed, so it grows as the hero walks).
    private var trail: some View {
        let shape = DungeonTrailShape(geometry: geometry)
        let dot: CGFloat = 7
        let gap: CGFloat = 14
        return ZStack {
            shape
                .stroke(DarkFantasyTheme.bgAbyss.opacity(0.65),
                        style: StrokeStyle(lineWidth: dot + 2, lineCap: .round, dash: [0.5, gap]))
            shape
                .stroke(DarkFantasyTheme.textPrimary.opacity(0.55),
                        style: StrokeStyle(lineWidth: dot - 2, lineCap: .round, dash: [0.5, gap]))
            shape
                .trim(from: 0, to: heroFraction)
                .stroke(DarkFantasyTheme.bgAbyss.opacity(0.9),
                        style: StrokeStyle(lineWidth: dot + 4, lineCap: .round, dash: [0.5, gap]))
            shape
                .trim(from: 0, to: heroFraction)
                .stroke(DarkFantasyTheme.gold,
                        style: StrokeStyle(lineWidth: dot, lineCap: .round, dash: [0.5, gap]))
        }
        .allowsHitTesting(false)
    }

    // MARK: Bosses

    private func bossNode(index: Int, mapWidth: CGFloat, mapHeight: CGFloat) -> some View {
        let boss = dungeon.bosses[index]
        let stand = stands[index]
        let isLair = index == stands.count - 1
        let spriteHeight = mapHeight * (isLair ? DungeonTrailConfig.lairHeight : DungeonTrailConfig.bossHeight)
        let plateHeight = TrailBossNode.plateHeight
        let nodeHeight = spriteHeight + LayoutConstants.spaceXS + plateHeight
        let feetY = stand.y * mapHeight

        return TrailBossNode(
            boss: boss,
            index: index,
            state: state(index),
            isLair: isLair,
            spriteHeight: spriteHeight,
            onTap: { onBoss(index) }
        )
        // First look at the map: the bosses rise onto their clearings one
        // after another along the trail.
        .staggeredAppear(index: index, slideDistance: 14, duration: MotionConstants.normal, stagger: 0.07)
        .frame(width: spriteHeight * 1.3, height: nodeHeight)
        .position(x: stand.x * mapWidth, y: feetY - spriteHeight + nodeHeight / 2)
    }
}

// MARK: - Boss node

/// One boss on its clearing: the figure in its state and a name plate at
/// its feet. Beaten: grey with a check. Next: lit, a pool of light and a
/// bobbing marker. Ahead: a dark shape — just the stage number.
private struct TrailBossNode: View {
    let boss: BossInfo
    let index: Int
    let state: BossState
    /// The last boss — its plate carries a crown even while it is sealed.
    let isLair: Bool
    let spriteHeight: CGFloat
    let onTap: () -> Void

    static let plateHeight: CGFloat = 30

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: LayoutConstants.spaceXS) {
                figure
                    .frame(width: spriteHeight * 1.3, height: spriteHeight, alignment: .bottom)
                plate
                    .frame(height: Self.plateHeight)
            }
            // Only the figure's core and the plate take taps, so a boss in
            // the front row can't steal taps meant for its neighbour's plate.
            .contentShape(TrailNodeHitShape(spriteHeight: spriteHeight, plateHeight: Self.plateHeight))
        }
        .buttonStyle(TrailNodeButtonStyle())
        .accessibilityLabel(Text(accessibilityText))
    }

    @ViewBuilder
    private var figure: some View {
        ZStack(alignment: .bottom) {
            // Ground under the feet: a pool of light for the next boss,
            // a contact shadow for everyone.
            if state == .current {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [DarkFantasyTheme.gold.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: spriteHeight * 0.6
                        )
                    )
                    .frame(width: spriteHeight * 1.3, height: spriteHeight * 0.32)
                    .offset(y: spriteHeight * 0.16)
            }
            Ellipse()
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
                .frame(width: spriteHeight * 0.7, height: 12)
                .blur(radius: 4)
                .offset(y: 6)

            sprite
                .frame(height: spriteHeight, alignment: .bottom)
        }
        .overlay(alignment: .top) {
            if state == .current {
                TrailNextMarker()
            }
        }
    }

    @ViewBuilder
    private var sprite: some View {
        switch state {
        case .current:
            BossArtImage(boss: boss, kind: .full, style: .lit)
        case .defeated:
            BossArtImage(boss: boss, kind: .full, style: .defeated)
                .opacity(0.92)
        case .locked:
            // A shape in the dark: the silhouette pushed near-black, with a
            // faint rim so it still reads against the painting.
            BossArtImage(boss: boss, kind: .full, style: .silhouette)
                .colorMultiply(DarkFantasyTheme.textTertiary)
                .opacity(0.85)
                .dualShadow(glowColor: DarkFantasyTheme.textSecondary.opacity(0.35), glowRadius: 3, depth: .text)
        }
    }

    @ViewBuilder
    private var plate: some View {
        switch state {
        case .locked:
            HStack(spacing: LayoutConstants.spaceXS) {
                if isLair { crown }
                Text("\(index + 1)")
            }
            .font(DarkFantasyTheme.buttonLabelCompact)
            .foregroundStyle(isLair ? DarkFantasyTheme.goldDim : DarkFantasyTheme.textTertiary)
            .padding(.horizontal, isLair ? LayoutConstants.spaceSM : 0)
            .frame(minWidth: Self.plateHeight, minHeight: Self.plateHeight)
            .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.85)))
            .overlay(Capsule().stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5))
            .depthShadow(.panel)
        case .defeated, .current:
            let isCurrent = state == .current
            HStack(spacing: LayoutConstants.spaceXS) {
                if isLair { crown.foregroundStyle(isCurrent ? DarkFantasyTheme.goldBright : DarkFantasyTheme.goldDim) }
                Text("\(index + 1)")
                    .foregroundStyle(isCurrent ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)
                Text(boss.name.uppercased())
                    .foregroundStyle(isCurrent ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
            }
            .font(isCurrent ? DarkFantasyTheme.cardTitle : DarkFantasyTheme.buttonLabelCompact)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .frame(minHeight: Self.plateHeight)
            .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.85)))
            .overlay(
                Capsule().stroke(
                    isCurrent ? DarkFantasyTheme.goldBright : DarkFantasyTheme.success.opacity(0.8),
                    lineWidth: 1.5
                )
            )
            .overlay(alignment: .topTrailing) {
                if !isCurrent {
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.bgAbyss)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(DarkFantasyTheme.success))
                        .offset(x: 6, y: -8)
                        .accessibilityHidden(true)
                }
            }
            .depthShadow(.panel)
            .fixedSize()
        }
    }

    private var crown: some View {
        Image(systemName: "crown.fill")
            .font(DarkFantasyTheme.body)
            .accessibilityHidden(true)
    }

    private var accessibilityText: String {
        switch state {
        case .defeated: return "Stage \(index + 1), \(boss.name), defeated"
        case .current: return "Stage \(index + 1), \(boss.name), next fight"
        case .locked: return "Stage \(index + 1), sealed"
        }
    }
}

/// The bobbing "next fight" marker over the current boss. Owns its loop,
/// so it starts whenever it appears (first open, or after a win moves it)
/// and stops when it leaves.
private struct TrailNextMarker: View {
    @State private var bob = false

    var body: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .font(DarkFantasyTheme.cardTitle)
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .depthShadow(.text)
            .offset(y: bob ? -14 : -22)
            .opacity(bob ? 1 : 0.7)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(MotionConstants.pulse) { bob = true }
            }
            .onDisappear { bob = false }
    }
}

/// Tap area of a map node: the middle of the figure plus the plate under
/// it — not the empty corners of the sprite box.
private struct TrailNodeHitShape: Shape {
    let spriteHeight: CGFloat
    let plateHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let coreWidth = spriteHeight * 0.7
        path.addRect(CGRect(x: rect.midX - coreWidth / 2, y: rect.minY + spriteHeight * 0.1,
                            width: coreWidth, height: spriteHeight * 0.9))
        let plateWidth = spriteHeight * 0.9
        path.addRect(CGRect(x: rect.midX - plateWidth / 2, y: rect.maxY - plateHeight,
                            width: plateWidth, height: plateHeight))
        return path
    }
}

/// Press feedback for map nodes: dim on touch, no scale.
private struct TrailNodeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Hero token

/// "You are here": the hero's portrait in a gold ring on a pin, standing on
/// the trail. Its bottom tip sits on the trail point.
private struct TrailHeroToken: View {
    let hero: Character?

    static let size: CGFloat = 52
    static let tip: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(DarkFantasyTheme.bgAbyss)
                if let hero {
                    AvatarImageView(
                        skinKey: hero.avatar,
                        characterClass: hero.characterClass,
                        size: Self.size - 6
                    )
                    .clipShape(Circle())
                }
            }
            .frame(width: Self.size - 6, height: Self.size - 6)
            .padding(3)
            .background(Circle().fill(DarkFantasyTheme.gold))
            .overlay(Circle().stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5))

            TrailPinTip()
                .fill(DarkFantasyTheme.gold)
                .frame(width: 16, height: Self.tip)
        }
        .depthShadow(.card)
        .frame(width: Self.size, height: Self.size + Self.tip)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Your hero"))
    }
}

private struct TrailPinTip: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Places a view so its bottom centre sits on the trail at `fraction` of
/// its length. Animatable, so the hero walks the curve instead of cutting
/// across it.
private struct TrailPositionEffect: ViewModifier, Animatable {
    var fraction: CGFloat
    let geometry: DungeonTrailGeometry
    let height: CGFloat

    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }

    func body(content: Content) -> some View {
        let point = geometry.point(atFraction: fraction)
        let tokenHeight = TrailHeroToken.size + TrailHeroToken.tip
        content.position(x: point.x * height, y: point.y * height - tokenHeight / 2)
    }
}

// MARK: - Trail geometry

/// The trail as one curve from the entrance through the ten stands, in map
/// units (height 1, width = aspect) so it scales with the map. Each leg
/// bows a little to alternating sides, like a road on an old map. Sampled
/// densely so a fraction of the length maps to a point (for the hero).
struct DungeonTrailGeometry {
    /// Entrance followed by the stands, in map units.
    let stops: [CGPoint]
    private let samples: [CGPoint]
    private let lengths: [CGFloat]

    private static let samplesPerLeg = 32
    private static let bow: CGFloat = 0.14

    /// `bossCount` trims the trail to the bosses the dungeon really has.
    init(config: DungeonTrailConfig, bossCount: Int) {
        let aspect = DungeonTrailConfig.imageAspect
        let stands = Array(config.stands.prefix(max(bossCount, 0)))
        let stops = ([config.entrance] + stands).map { CGPoint(x: $0.x * aspect, y: $0.y) }
        self.stops = stops

        var samples: [CGPoint] = []
        for leg in 0..<max(stops.count - 1, 0) {
            let start = stops[leg]
            let end = stops[leg + 1]
            let control = Self.control(start, end, leg: leg)
            for step in 0..<Self.samplesPerLeg {
                let t = CGFloat(step) / CGFloat(Self.samplesPerLeg)
                samples.append(Self.quad(start, control, end, t))
            }
        }
        if let last = stops.last { samples.append(last) }
        self.samples = samples

        var lengths: [CGFloat] = samples.isEmpty ? [] : [0]
        for i in samples.indices.dropFirst() {
            let a = samples[i - 1]
            let b = samples[i]
            lengths.append(lengths[i - 1] + hypot(b.x - a.x, b.y - a.y))
        }
        self.lengths = lengths
    }

    private var totalLength: CGFloat { lengths.last ?? 0 }

    /// Fraction of the trail's length at `t` (0…1) along leg `leg`
    /// (leg 0 runs from the entrance to boss 1).
    func fraction(leg: Int, t: CGFloat) -> CGFloat {
        guard totalLength > 0, samples.count > 1 else { return 0 }
        let legCount = max(stops.count - 1, 1)
        let clampedLeg = min(max(leg, 0), legCount - 1)
        let position = CGFloat(clampedLeg * Self.samplesPerLeg) + min(max(t, 0), 1) * CGFloat(Self.samplesPerLeg)
        let i = min(Int(position), samples.count - 2)
        let f = position - CGFloat(i)
        return (lengths[i] + (lengths[i + 1] - lengths[i]) * f) / totalLength
    }

    /// Point (map units) at a fraction of the trail's length.
    func point(atFraction fraction: CGFloat) -> CGPoint {
        guard samples.count > 1, totalLength > 0 else { return stops.first ?? .zero }
        let target = min(max(fraction, 0), 1) * totalLength
        var low = 0
        var high = lengths.count - 1
        while high - low > 1 {
            let mid = (low + high) / 2
            if lengths[mid] < target { low = mid } else { high = mid }
        }
        let span = lengths[high] - lengths[low]
        let f = span > 0 ? (target - lengths[low]) / span : 0
        let a = samples[low]
        let b = samples[high]
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }

    /// The trail as a path for a map `height` points tall.
    func path(height: CGFloat) -> Path {
        var path = Path()
        guard let first = stops.first else { return path }
        path.move(to: CGPoint(x: first.x * height, y: first.y * height))
        for leg in 0..<max(stops.count - 1, 0) {
            let start = stops[leg]
            let end = stops[leg + 1]
            let control = Self.control(start, end, leg: leg)
            path.addQuadCurve(
                to: CGPoint(x: end.x * height, y: end.y * height),
                control: CGPoint(x: control.x * height, y: control.y * height)
            )
        }
        return path
    }

    private static func control(_ a: CGPoint, _ b: CGPoint, leg: Int) -> CGPoint {
        let bow = leg.isMultiple(of: 2) ? Self.bow : -Self.bow
        return CGPoint(
            x: (a.x + b.x) / 2 - (b.y - a.y) * bow,
            y: (a.y + b.y) / 2 + (b.x - a.x) * bow
        )
    }

    private static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
            y: u * u * a.y + 2 * u * t * c.y + t * t * b.y
        )
    }
}

/// The trail curve as a shape filling the map frame.
private struct DungeonTrailShape: Shape {
    let geometry: DungeonTrailGeometry

    func path(in rect: CGRect) -> Path {
        geometry.path(height: rect.height)
    }
}
