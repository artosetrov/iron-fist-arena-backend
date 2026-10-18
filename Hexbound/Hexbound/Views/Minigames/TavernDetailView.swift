import SwiftUI
import UIKit

// MARK: - Tavern Scene Data
//
// The tavern is one illustrated hall (`bg-tavern`, 1536×2752 px) with every host
// and their prop as a separate layer on top of it. All coordinates below are in
// background pixels; `TavernSceneLayout` maps them to the screen.
// Source of truth for the numbers: `User/Tavern/placement.json`
// (art pack and pipeline: TAVERN_SCENE_ART_PACK_2026-10-16).

private enum TavernScene {
    static let size = CGSize(width: 1536, height: 2752)
}

private enum TavernHostID: String {
    case chest, shell, wheel, rush, mine
}

private struct TavernHost: Identifiable {
    let id: TavernHostID
    let title: String
    let hint: String
    let accent: Color
    let route: AppRoute
    /// Centre of the name plate.
    let plate: CGPoint
    /// Tappable areas painted into the background itself (the chest on the bar, the cellar door).
    let hotspots: [CGRect]

    static let all: [TavernHost] = [
        TavernHost(
            id: .chest,
            title: "SHARED CHEST",
            hint: "Opens the chest shared by all your heroes.",
            accent: DarkFantasyTheme.gold,
            route: .stash,
            plate: CGPoint(x: 760, y: 1112),
            hotspots: [CGRect(x: 1010, y: 750, width: 330, height: 310)]
        ),
        TavernHost(
            id: .shell,
            title: "SHELL GAME",
            hint: "Bet gold, find the ball. Double or nothing.",
            accent: DarkFantasyTheme.gold,
            route: .shellGame,
            plate: CGPoint(x: 395, y: 1560),
            hotspots: []
        ),
        TavernHost(
            id: .wheel,
            title: "FORTUNE WHEEL",
            hint: "Spin for the Treasury, or take a seat at her table.",
            accent: DarkFantasyTheme.purple,
            route: .fortuneWheel,
            plate: CGPoint(x: 1150, y: 1690),
            hotspots: []
        ),
        TavernHost(
            id: .rush,
            title: "DUNGEON RUSH",
            hint: "Endless waves. How far can you go?",
            accent: DarkFantasyTheme.danger,
            route: .dungeonRush,
            plate: CGPoint(x: 530, y: 2440),
            hotspots: [CGRect(x: 20, y: 1620, width: 310, height: 720)]
        ),
        TavernHost(
            id: .mine,
            title: "GOLD MINE",
            hint: "Collect your gold. Catch bonus drops.",
            accent: DarkFantasyTheme.gold,
            route: .goldMine,
            plate: CGPoint(x: 1110, y: 2420),
            hotspots: []
        ),
    ]

    static func with(_ id: TavernHostID) -> TavernHost? {
        all.first { $0.id == id }
    }
}

/// One picture on top of the background: a host or the prop that belongs to them.
private struct TavernLayer: Identifiable {
    let asset: String
    let host: TavernHostID
    let frame: CGRect
    /// Centre of the contact shadow under a standing figure (drawn in code, never baked).
    let feet: CGPoint?

    var id: String { asset }

    /// Back to front: whatever stands lower on the floor is nearer the camera and covers what is behind.
    /// Props sit in front of their host, so a host never hides their own table, wheel or cart.
    static let all: [TavernLayer] = [
        TavernLayer(asset: "tavern-npc-keeper", host: .chest,
                    frame: CGRect(x: 548, y: 672, width: 389, height: 346), feet: nil),
        TavernLayer(asset: "tavern-npc-trickster", host: .shell,
                    frame: CGRect(x: 168, y: 905, width: 434, height: 825), feet: CGPoint(x: 395, y: 1730)),
        TavernLayer(asset: "tavern-prop-table", host: .shell,
                    frame: CGRect(x: 380, y: 1300, width: 440, height: 530), feet: nil),
        TavernLayer(asset: "tavern-npc-fortuna", host: .wheel,
                    frame: CGRect(x: 992, y: 1070, width: 521, height: 790), feet: CGPoint(x: 1230, y: 1860)),
        TavernLayer(asset: "tavern-prop-wheel", host: .wheel,
                    frame: CGRect(x: 840, y: 1230, width: 320, height: 660), feet: nil),
        TavernLayer(asset: "tavern-npc-warden", host: .rush,
                    frame: CGRect(x: 295, y: 1780, width: 498, height: 895), feet: CGPoint(x: 530, y: 2675)),
        TavernLayer(asset: "tavern-npc-foreman", host: .mine,
                    frame: CGRect(x: 833, y: 1719, width: 530, height: 936), feet: CGPoint(x: 1120, y: 2655)),
        TavernLayer(asset: "tavern-prop-cart", host: .mine,
                    frame: CGRect(x: 1160, y: 2040, width: 376, height: 712), feet: nil),
    ]
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
            container.width / TavernScene.size.width,
            container.height / TavernScene.size.height
        )
        scale = s
        sceneSize = CGSize(width: TavernScene.size.width * s, height: TavernScene.size.height * s)
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

/// Coarse alpha map of a layer, so a tap on a transparent margin falls through
/// to whatever is behind it instead of opening the wrong host.
private struct TavernAlphaMask: Sendable {
    let width: Int
    let height: Int
    let alpha: [UInt8]

    /// `unit` is the point inside the layer, 0…1 on both axes.
    func isOpaque(at unit: CGPoint) -> Bool {
        let x = min(width - 1, max(0, Int(unit.x * CGFloat(width))))
        let y = min(height - 1, max(0, Int(unit.y * CGFloat(height))))
        return alpha[y * width + x] > 60
    }

    /// Draws the asset into a small RGBA buffer and keeps the alpha channel.
    /// `UIImage(named:)` is thread-safe; call this off the main thread.
    static func load(asset: String, width: Int = 96) -> TavernAlphaMask? {
        guard let cg = UIImage(named: asset)?.cgImage, cg.width > 0 else { return nil }
        let height = max(1, Int((CGFloat(cg.height) / CGFloat(cg.width) * CGFloat(width)).rounded()))
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = rgba.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        let alpha = stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }
        return TavernAlphaMask(width: width, height: height, alpha: alpha)
    }
}

// MARK: - Tavern Detail View

struct TavernDetailView: View {
    @Environment(AppState.self) private var appState

    /// Number of items currently stored in the Shared Chest.
    /// `nil` while loading (the plate shows the title alone).
    @State private var stashItemCount: Int?

    /// Alpha maps of the layers, keyed by asset name. Empty until they load;
    /// until then a tap uses the layer's box.
    @State private var masks: [String: TavernAlphaMask] = [:]

    /// Host under the finger. Resets by itself when the touch ends or is cancelled.
    @GestureState private var touchedHost: TavernHostID?
    /// Host being opened: stays lit while the next screen pushes in.
    @State private var openingHost: TavernHostID?

    /// Lights up the host, their prop and their plate.
    private var litHost: TavernHostID? { touchedHost ?? openingHost }

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
                    scene(layout)
                        .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)

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
        .task {
            await loadMasks()
        }
        .onAppear {
            openingHost = nil
            AmbientManager.shared.setZone(.tavern)
        }
        .onDisappear {
            AmbientManager.shared.setZone(.hub)
        }
    }

    // MARK: - Scene

    /// Half the widest plate plus the screen padding: keeps a plate whole on the narrowest phones,
    /// where the background is cropped at the sides.
    private static let plateEdgeInset: CGFloat = 80

    private func scene(_ layout: TavernSceneLayout) -> some View {
        ZStack(alignment: .topLeading) {
            Image("bg-tavern")
                .resizable()
                .interpolation(.high)
                .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)

            ForEach(TavernLayer.all) { layer in
                layerView(layer, layout: layout)
            }

            // One touch surface for the whole room: the hit test reads the layers' alpha,
            // so a host's transparent margin never steals a tap from the one behind.
            Color.clear
                .contentShape(Rectangle())
                .frame(width: layout.sceneSize.width, height: layout.sceneSize.height)
                .gesture(pressGesture(layout))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func layerView(_ layer: TavernLayer, layout: TavernSceneLayout) -> some View {
        let isLit = litHost == layer.host
        let box = layer.frame

        if let feet = layer.feet {
            Ellipse()
                .fill(
                    EllipticalGradient(
                        colors: [DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy), .clear],
                        center: .center
                    )
                )
                .frame(width: box.width * 0.72 * layout.scale, height: box.width * 0.16 * layout.scale)
                .position(layout.local(CGPoint(x: feet.x, y: feet.y - 8)))
                .allowsHitTesting(false)
        }

        Image(layer.asset)
            .resizable()
            .interpolation(.high)
            .frame(width: box.width * layout.scale, height: box.height * layout.scale)
            // Glow only while pressed (tap-only glow rule); no shadow pass at rest.
            .if(isLit) { view in
                view
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityHeavy), radius: 2)
                    .shadow(color: DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong), radius: 10)
            }
            .position(layout.local(CGPoint(x: box.midX, y: box.midY)))
            .allowsHitTesting(false)
    }

    // MARK: - Touch

    private func pressGesture(_ layout: TavernSceneLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touchedHost) { value, state, _ in
                state = isTap(value) ? hostID(at: layout.background(value.startLocation)) : nil
            }
            .onEnded { value in
                guard isTap(value),
                      let id = hostID(at: layout.background(value.startLocation)),
                      hostID(at: layout.background(value.location)) == id,
                      let host = TavernHost.with(id) else { return }
                open(host)
            }
    }

    /// A touch that wandered further than this is a slip, not a tap.
    private func isTap(_ value: DragGesture.Value) -> Bool {
        hypot(value.translation.width, value.translation.height) <= LayoutConstants.spaceMS
    }

    /// Top layer first. Uses the alpha map when it has loaded, the layer's box until then,
    /// and finally the hotspots painted into the background.
    private func hostID(at point: CGPoint) -> TavernHostID? {
        for layer in TavernLayer.all.reversed() where layer.frame.contains(point) {
            guard let mask = masks[layer.asset] else { return layer.host }
            let unit = CGPoint(
                x: (point.x - layer.frame.minX) / layer.frame.width,
                y: (point.y - layer.frame.minY) / layer.frame.height
            )
            if mask.isOpaque(at: unit) { return layer.host }
        }
        return TavernHost.all.first { host in
            host.hotspots.contains { $0.contains(point) }
        }?.id
    }

    private func open(_ host: TavernHost) {
        openingHost = host.id
        SFXManager.shared.play(.uiTap)
        HapticManager.light()
        appState.mainPath.append(host.route)
    }

    // MARK: - Plates

    private func plate(_ host: TavernHost) -> some View {
        let isPressed = litHost == host.id
        return Button {
            open(host)
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

    /// Builds the alpha maps off the main thread (image decode never runs in a tap handler).
    private func loadMasks() async {
        guard masks.isEmpty else { return }
        let assets = TavernLayer.all.map(\.asset)
        let loaded = await Task.detached(priority: .utility) { () -> [String: TavernAlphaMask] in
            var result: [String: TavernAlphaMask] = [:]
            for asset in assets {
                if let mask = TavernAlphaMask.load(asset: asset) {
                    result[asset] = mask
                }
            }
            return result
        }.value
        masks = loaded
    }
}
