import SwiftUI

// MARK: - Tavern Scene Data
//
// The tavern is one painted hall (`bg-tavern`, 1536×2752 px) with every host
// painted into it: the shared table (Trickster, Veteran, Miner), Fortuna's corner
// with the game's own Wheel of Fortune behind her, the hero's stash corner and
// the barkeep behind the bar. Everything that moves lives in `TavernSceneLife.swift`.
// All coordinates are background pixels; `TavernSceneLayout` maps them to the screen.

// MARK: - COMING SOON hosts

/// The store build ships without the wagering games (`AppConstants.gamblingMinigamesEnabled`,
/// App Review 2.3.6). Their hosts stay in the painting and keep their idle life, but the
/// corner sits in shadow, a tap gives no reaction and opens nothing, and the plate reads
/// COMING SOON without naming the game.
private extension TavernTapTarget {
    var isComingSoon: Bool {
        switch self {
        case .shell, .wheel: !AppConstants.gamblingMinigamesEnabled
        case .chest, .rush, .mine, .keeper: false
        }
    }
}

/// Shadow over a COMING SOON corner: an ellipse in background pixels.
private struct TavernComingSoonShade {
    let center: CGPoint
    let radii: CGSize

    static let all: [TavernComingSoonShade] = AppConstants.gamblingMinigamesEnabled ? [] : [
        // The Trickster at the left end of the shared table.
        TavernComingSoonShade(center: CGPoint(x: 390, y: 1820), radii: CGSize(width: 250, height: 320)),
        // Fortuna, her table and the wheel behind her.
        TavernComingSoonShade(center: CGPoint(x: 1205, y: 1100), radii: CGSize(width: 260, height: 420)),
    ]
}

private struct TavernHost: Identifiable {
    let id: TavernTapTarget
    let title: String
    let hint: String
    let accent: Color
    let route: AppRoute
    /// Centre of the name plate.
    let plate: CGPoint

    static let all: [TavernHost] = [
        TavernHost(
            id: .chest,
            title: "SHARED CHEST",
            hint: "Opens the chest shared by all your heroes.",
            accent: DarkFantasyTheme.gold,
            route: .stash,
            plate: CGPoint(x: 270, y: 1470)
        ),
        TavernHost(
            id: .shell,
            title: "SHELL GAME",
            hint: "Bet gold, find the ball. Double or nothing.",
            accent: DarkFantasyTheme.gold,
            route: .shellGame,
            plate: CGPoint(x: 345, y: 2150)
        ),
        TavernHost(
            id: .rush,
            title: "DUNGEON RUSH",
            hint: "Endless waves. How far can you go?",
            accent: DarkFantasyTheme.danger,
            route: .dungeonRush,
            plate: CGPoint(x: 765, y: 2098)
        ),
        TavernHost(
            id: .mine,
            title: "GOLD MINE",
            hint: "Collect your gold. Catch bonus drops.",
            accent: DarkFantasyTheme.gold,
            route: .goldMine,
            plate: CGPoint(x: 1180, y: 2150)
        ),
        TavernHost(
            id: .wheel,
            title: "FORTUNE WHEEL",
            hint: "Spin for the Treasury, or take a seat at her table.",
            accent: DarkFantasyTheme.purple,
            route: .fortuneWheel,
            // On Fortuna's tablecloth, under the ball: at y 1600 the plate covered the Miner's helmet.
            plate: CGPoint(x: 1120, y: 1470)
        ),
    ]

    static func with(_ id: TavernTapTarget) -> TavernHost? {
        all.first { $0.id == id }
    }
}

/// Tappable area of the painting: an ellipse in background pixels.
private struct TavernHitArea {
    let target: TavernTapTarget
    let center: CGPoint
    let radii: CGSize

    func contains(_ p: CGPoint) -> Bool {
        let dx = (p.x - center.x) / radii.width
        let dy = (p.y - center.y) / radii.height
        return dx * dx + dy * dy <= 1
    }

    /// First match wins: the wheel and the barkeep sit above the people around them.
    static let all: [TavernHitArea] = [
        TavernHitArea(target: .wheel, center: CGPoint(x: 1232, y: 935), radii: CGSize(width: 160, height: 160)),
        TavernHitArea(target: .wheel, center: CGPoint(x: 1180, y: 1260), radii: CGSize(width: 190, height: 230)),
        TavernHitArea(target: .keeper, center: CGPoint(x: 590, y: 880), radii: CGSize(width: 110, height: 170)),
        TavernHitArea(target: .chest, center: CGPoint(x: 220, y: 860), radii: CGSize(width: 160, height: 240)),
        TavernHitArea(target: .chest, center: CGPoint(x: 290, y: 1450), radii: CGSize(width: 210, height: 150)),
        TavernHitArea(target: .shell, center: CGPoint(x: 390, y: 1820), radii: CGSize(width: 230, height: 290)),
        TavernHitArea(target: .rush, center: CGPoint(x: 790, y: 1800), radii: CGSize(width: 165, height: 260)),
        TavernHitArea(target: .mine, center: CGPoint(x: 1210, y: 1820), radii: CGSize(width: 200, height: 290)),
    ]

    static func target(at p: CGPoint) -> TavernTapTarget? {
        all.first { $0.contains(p) }?.target
    }
}

/// Cover-fits the background into the container (like `scaledToFill`) and maps
/// background pixels to container points and back.
private struct TavernSceneLayout {
    let scale: CGFloat
    let sceneSize: CGSize
    let origin: CGPoint
    let bounds: CGSize

    init(container: CGSize) {
        let s = max(
            container.width / TavernSceneArt.size.width,
            container.height / TavernSceneArt.size.height
        )
        scale = s
        sceneSize = CGSize(width: TavernSceneArt.size.width * s, height: TavernSceneArt.size.height * s)
        origin = CGPoint(
            x: (container.width - sceneSize.width) / 2,
            y: (container.height - sceneSize.height) / 2
        )
        bounds = container
    }

    var isEmpty: Bool { scale <= 0 }

    /// Background pixels → scene-local points.
    func local(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * scale, y: p.y * scale)
    }

    /// Scene-local points → background pixels.
    func background(_ p: CGPoint) -> CGPoint {
        guard scale > 0 else { return .zero }
        return CGPoint(x: p.x / scale, y: p.y / scale)
    }

    /// Background pixels → container points, with x kept `inset` away from the visible edges.
    func onScreen(_ p: CGPoint, inset: CGFloat) -> CGPoint {
        let x = origin.x + p.x * scale
        let lo = inset
        let hi = max(lo, bounds.width - inset)
        return CGPoint(x: min(max(x, lo), hi), y: origin.y + p.y * scale)
    }
}

// MARK: - Tavern Detail View

struct TavernDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Number of items currently stored in the Shared Chest.
    /// `nil` while loading (the plate shows the title alone).
    @State private var stashItemCount: Int?

    /// Scene clock and schedules for blinks, coin, wheel, glints and light.
    @State private var life = TavernLife()
    /// The scene only animates while it is on screen (NavigationStack keeps it alive underneath).
    @State private var isOnScreen = false

    /// Target under the finger. Resets by itself when the touch ends or is cancelled.
    @GestureState private var touchedTarget: TavernTapTarget?
    /// Host being opened: stays lit while their reaction plays and the next screen pushes in.
    @State private var openingHost: TavernTapTarget?

    /// Lights up the plate and the warm press glow.
    private var litTarget: TavernTapTarget? { touchedTarget ?? openingHost }

    /// Barkeep's recorded line (NPC voice manifest, speaker `tavern`). While the store build
    /// ships without the wagering games he talks about the mine instead (also recorded).
    private static let keeperLine = AppConstants.gamblingMinigamesEnabled
        ? "They gamble for gold at the tavern — give it a try!"
        : "The mine earns gold while you sleep. Start mining."

    // MARK: - Aggregated currency totals (account-wide)

    /// Sum of gold across every character on the account. Falls back to the
    /// current character's gold when `userCharacters` hasn't been loaded yet.
    private var totalGold: Int {
        if !appState.userCharacters.isEmpty {
            return appState.userCharacters.reduce(0) { $0 + $1.gold }
        }
        return appState.currentCharacter?.gold ?? 0
    }

    /// Sum of gems across every character on the account. Falls back to the
    /// current character's gems when `userCharacters` hasn't been loaded yet.
    private var totalGems: Int {
        if !appState.userCharacters.isEmpty {
            return appState.userCharacters.reduce(0) { $0 + ($1.gems ?? 0) }
        }
        return appState.currentCharacter?.gems ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let layout = TavernSceneLayout(container: geo.size)
            ZStack {
                DarkFantasyTheme.bgAbyss

                if !layout.isEmpty {
                    TimelineView(.animation(minimumInterval: TavernLifeTiming.frameInterval, paused: !isOnScreen)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate - life.epoch
                        let frame = life.frame(at: t, reduceMotion: reduceMotion)
                        scene(layout, frame: frame)
                    }
                    .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                    // One touch surface for the whole room, outside the rasterised scene.
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)
                        .gesture(pressGesture(layout))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .accessibilityHidden(true)

                    ForEach(TavernHost.all) { host in
                        plate(host)
                            .position(layout.onScreen(host.plate, inset: Self.plateEdgeInset))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) { topScrim }
        .overlay(alignment: .top) { purse }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("TAVERN")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .subtleShadow()
            }
        }
        .task {
            await loadStashCount()
        }
        .onAppear {
            openingHost = nil
            isOnScreen = true
            AmbientManager.shared.setZone(.tavern)
        }
        .onDisappear {
            isOnScreen = false
            AmbientManager.shared.setZone(.hub)
        }
    }

    // MARK: - Scene

    /// Half the widest plate plus the screen padding: keeps a plate whole on the narrowest phones,
    /// where the background is cropped at the sides.
    private static let plateEdgeInset: CGFloat = 80

    /// Back to front: painting (hands and hanging props removed) → hanging props and the spider →
    /// wheel → Fortuna's head in front of it → blinks → hands → coin → candle light (additive,
    /// so it also falls on everything that moves) → effects.
    private func scene(_ layout: TavernSceneLayout, frame: TavernLifeFrame) -> some View {
        ZStack(alignment: .topLeading) {
            Image("bg-tavern")
                .resizable()
                .interpolation(.high)
                .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)

            ForEach(TavernPart.props, id: \.self) { part in
                partView(part, pose: frame.parts[part] ?? .rest, layout)
            }

            if let spider = frame.spider {
                spiderView(spider, layout)
            }

            wheel(layout, frame: frame)

            sprite("tavern-fortuna-front", TavernSceneArt.fortunaFront, layout)

            ForEach(TavernBlinker.allCases, id: \.self) { host in
                if let rect = TavernSceneArt.blinks[host] {
                    sprite(TavernSceneArt.blinkAsset(host), rect, layout)
                        .opacity(frame.blink[host] ?? 0)
                }
            }

            ForEach(TavernPart.hands, id: \.self) { part in
                partView(part, pose: frame.parts[part] ?? .rest, layout)
            }

            coin(layout, frame: frame)

            ForEach(TavernLightZoneID.allCases, id: \.self) { zone in
                if let rect = TavernSceneArt.lightZones[zone] {
                    sprite(TavernSceneArt.lightAsset(zone), rect, layout)
                        .opacity(frame.light[zone] ?? 0)
                        .blendMode(.plusLighter)
                }
            }

            // COMING SOON corners sit in shadow, after the candle light so it cannot lift them.
            ForEach(TavernComingSoonShade.all.indices, id: \.self) { index in
                comingSoonShade(TavernComingSoonShade.all[index], layout)
            }

            TavernEffectsCanvas(frame: frame, scale: layout.scale, pressed: litTarget)
                .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)
        }
        .frame(width: layout.sceneSize.width, height: layout.sceneSize.height, alignment: .topLeading)
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func comingSoonShade(_ shade: TavernComingSoonShade, _ layout: TavernSceneLayout) -> some View {
        Ellipse()
            .fill(
                EllipticalGradient(
                    colors: [
                        DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy),
                        DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityStrong),
                        .clear
                    ],
                    center: .center
                )
            )
            .frame(width: shade.radii.width * 2 * layout.scale, height: shade.radii.height * 2 * layout.scale)
            .position(layout.local(shade.center))
    }

    private func sprite(_ asset: String, _ rect: CGRect, _ layout: TavernSceneLayout) -> some View {
        Image(asset)
            .resizable()
            .interpolation(.high)
            .frame(width: rect.width * layout.scale, height: rect.height * layout.scale)
            .position(layout.local(CGPoint(x: rect.midX, y: rect.midY)))
    }

    /// A piece of the painting turned about its pivot (wrist, elbow or hanging point) and nudged.
    private func partView(_ part: TavernPart, pose: TavernPose, _ layout: TavernSceneLayout) -> some View {
        let art = TavernSceneArt.part(part)
        return Image(art.asset)
            .resizable()
            .interpolation(.high)
            .frame(width: art.frame.width * layout.scale, height: art.frame.height * layout.scale)
            .rotationEffect(.radians(pose.angle), anchor: art.anchor)
            .offset(x: pose.dx * layout.scale, y: pose.dy * layout.scale)
            .position(layout.local(CGPoint(x: art.frame.midX, y: art.frame.midY)))
    }

    /// The spider on its thread; the silk itself is drawn by the effects canvas.
    private func spiderView(_ spider: TavernSpiderState, _ layout: TavernSceneLayout) -> some View {
        let size = TavernSceneArt.spiderSize
        let inset = TavernSceneArt.spiderThreadInset
        return Image("tavern-spider")
            .resizable()
            .interpolation(.high)
            .frame(width: size.width * layout.scale, height: size.height * layout.scale)
            .rotationEffect(.radians(spider.angle), anchor: UnitPoint(x: 0.5, y: inset / size.height))
            .opacity(spider.alpha)
            .position(layout.local(CGPoint(x: spider.hang.x, y: spider.hang.y - inset + size.height / 2)))
    }

    /// The minigame's own wheel face and pointer, hung on the painted wall mount.
    private func wheel(_ layout: TavernSceneLayout, frame: TavernLifeFrame) -> some View {
        let r = TavernSceneArt.wheelRadius * layout.scale
        let center = layout.local(TavernSceneArt.wheelCenter)
        let pointer = TavernSceneArt.pointerSize
        return ZStack {
            Image("fortune-wheel-face")
                .resizable()
                .interpolation(.high)
                .frame(width: r * 2, height: r * 2)
                .rotationEffect(.radians(frame.wheelAngle))
                .position(center)

            Image("fortune-pointer")
                .resizable()
                .interpolation(.high)
                .frame(width: pointer.width * layout.scale, height: pointer.height * layout.scale)
                // pivot near the tip, so the pointer flicks against the pegs
                .rotationEffect(.radians(frame.pointerTilt), anchor: UnitPoint(x: 0.5, y: 0.68))
                .position(x: center.x, y: center.y - r + (6 - pointer.height * 0.18) * layout.scale)
        }
    }

    /// The Trickster's coin: rides on his fist, and his flick throws it up now and then
    /// (rotation, never scale).
    private func coin(_ layout: TavernSceneLayout, frame: TavernLifeFrame) -> some View {
        let size = TavernSceneArt.coinSize * layout.scale
        return Image("tavern-coin")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .rotation3DEffect(.degrees(frame.coinTurnDegrees), axis: (x: 1, y: 0, z: 0))
            .position(layout.local(frame.coinCenter))
    }

    // MARK: - Touch

    private func pressGesture(_ layout: TavernSceneLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touchedTarget) { value, state, _ in
                // A COMING SOON host still catches the touch but never lights up.
                let target = isTap(value) ? TavernHitArea.target(at: layout.background(value.startLocation)) : nil
                state = target?.isComingSoon == true ? nil : target
            }
            .onEnded { value in
                guard isTap(value) else { return }
                // The spider runs back up its thread; the tap goes no further.
                if life.scareSpider(at: layout.background(value.location), time: life.now()) { return }
                guard let target = TavernHitArea.target(at: layout.background(value.startLocation)),
                      TavernHitArea.target(at: layout.background(value.location)) == target else { return }
                tap(target)
            }
    }

    /// A touch that wandered further than this is a slip, not a tap.
    private func isTap(_ value: DragGesture.Value) -> Bool {
        hypot(value.translation.width, value.translation.height) <= LayoutConstants.spaceMS
    }

    /// The host reacts first (wink, coin toss, wheel spin…), then their section opens.
    private func tap(_ target: TavernTapTarget) {
        // COMING SOON: no reaction (no coin toss, no wheel spin) and nothing opens.
        guard !target.isComingSoon else { return }
        life.react(to: target, at: life.now())

        guard let host = TavernHost.with(target) else {
            // The barkeep has no section: a glint on his tankard and his voiced line.
            SFXManager.shared.play(.uiTap)
            NPCVoice.shared.speak(Self.keeperLine)
            return
        }
        guard openingHost == nil else { return }
        openingHost = host.id
        SFXManager.shared.play(.uiTap)
        HapticManager.light()

        let lead = reduceMotion ? 0 : TavernLifeTiming.reactionLead
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(lead))
            appState.mainPath.append(host.route)
        }
    }

    // MARK: - Plates

    @ViewBuilder
    private func plate(_ host: TavernHost) -> some View {
        if host.id.isComingSoon {
            comingSoonPlate
        } else {
            openPlate(host)
        }
    }

    /// Same plate shape, muted, not a button; never names the game.
    private var comingSoonPlate: some View {
        Text("COMING SOON")
            .font(DarkFantasyTheme.buttonLabelCompact)
            .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .depthShadow(.panel)
            .padding(LayoutConstants.spaceSM)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Coming soon")
    }

    private func openPlate(_ host: TavernHost) -> some View {
        let isPressed = litTarget == host.id
        return Button {
            tap(host.id)
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Text(host.title)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                if host.id == .chest, let count = stashItemCount {
                    Text("\(count)/100")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .monospacedDigit()
                }
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(host.accent.opacity(isPressed ? 1 : DarkFantasyTheme.opacityHeavy), lineWidth: 1.5)
            )
            .dualShadow(
                glowColor: host.accent.opacity(isPressed ? DarkFantasyTheme.opacityStrong : 0),
                glowRadius: 6,
                depth: .panel
            )
            // Transparent padding lifts the touch target to the 48pt minimum without a bigger plate.
            .padding(LayoutConstants.spaceSM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(host.title.capitalized)
        .accessibilityHint(host.hint)
    }

    // MARK: - Top HUD

    /// Darkens the ceiling beams behind the title and the purse.
    private var topScrim: some View {
        LinearGradient(
            colors: [
                DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityOpaque),
                DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityStrong),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 96)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    /// Account-wide gold and gems, the same totals the Shared Chest card used to show.
    private var purse: some View {
        CurrencyDisplay(
            gold: totalGold,
            gems: totalGems,
            size: .compact,
            animated: false
        )
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule().fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            Capsule().stroke(DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 1)
        )
        .depthShadow(.panel)
        .padding(.top, LayoutConstants.spaceXS)
        .allowsHitTesting(false)
    }

    // MARK: - Loading

    /// Loads the stash item count for the chest plate. Cheap call —
    /// reuses the same endpoint StashDetailView hits on its own .task.
    ///
    /// A failure leaves the previous count alone and says nothing: the plate
    /// then shows the title alone, and the stash screen itself reports the
    /// error properly when the player opens it.
    private func loadStashCount() async {
        let service = StashService(appState: appState)
        if let response = await service.loadStash().value {
            stashItemCount = response.usedSlots
        }
    }
}
