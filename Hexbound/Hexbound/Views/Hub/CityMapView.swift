import SwiftUI

// MARK: - City Map View (horizontal scrollable panoramic hub)

struct CityMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var scrollOffset: CGFloat = 0.5 // 0…1, 0.5 = center

    // Image native aspect ratio (4096×1738)
    private let imageAspect: CGFloat = 4096.0 / 1738.0

    var body: some View {
        GeometryReader { outerGeo in
            let viewWidth = outerGeo.size.width
            let viewHeight = outerGeo.size.height
            let terrainWidth = viewHeight * imageAspect
            let terrainSize = CGSize(width: terrainWidth, height: viewHeight)
            let maxScroll = max(terrainWidth - viewWidth, 0)

            ZStack {
                Color.black.ignoresSafeArea()

                // Main scrollable map
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Layer 1: Terrain background
                        Image("bg-hub")
                            .resizable()
                            .frame(width: terrainWidth, height: viewHeight)

                        // Layer 2: Lantern glow effects
                        LanternGlowLayer(terrainSize: terrainSize)

                        // Layer 3: Buildings
                        let layoutOverrides = cache.hubLayout
                        let buildings = applyOverrides(layoutOverrides)
                        ForEach(buildings) { building in
                            CityBuildingView(
                                building: building,
                                terrainSize: terrainSize,
                                badge: badgeFor(building)
                            ) { tapped in
                                appState.mainPath.append(tapped.route)
                            }
                            .id("\(building.id)_\(building.relativeX)_\(building.relativeY)_\(building.relativeSize)")
                        }

                        // Layer 4: Fog at bottom
                        FogLayer(width: terrainWidth, height: viewHeight)

                        // Layer 5: Wind particles
                        WindParticlesLayer(width: terrainWidth, height: viewHeight)

                        // Layer 6: Clouds at top
                        CloudLayer(width: terrainWidth, height: viewHeight)
                    }
                    .frame(width: terrainWidth, height: viewHeight)
                    .background(
                        GeometryReader { innerGeo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetKey.self,
                                    value: innerGeo.frame(in: .named("hubScroll")).minX
                                )
                        }
                    )
                }
                .coordinateSpace(name: "hubScroll")
                .defaultScrollAnchor(.center)
                .onPreferenceChange(ScrollOffsetKey.self) { minX in
                    guard maxScroll > 0 else {
                        scrollOffset = 0.5
                        return
                    }
                    let progress = -minX / maxScroll
                    scrollOffset = min(max(progress, 0), 1)
                }

                // Moon — fixed on screen, parallax with scroll
                MoonView(
                    scrollProgress: scrollOffset,
                    viewWidth: viewWidth,
                    viewHeight: viewHeight
                )

                // Position indicator pill
                VStack {
                    Spacer()
                    if maxScroll > 0 {
                        ScrollPositionIndicator(progress: scrollOffset)
                            .padding(.bottom, LayoutConstants.spaceSM)
                    }
                }
            }
        }
    }

    private func applyOverrides(_ overrides: [String: GameDataCache.BuildingOverride]) -> [CityBuilding] {
        guard !overrides.isEmpty else { return defaultCityBuildings }
        return defaultCityBuildings.map { building in
            var b = building
            if let o = overrides[building.id] {
                b.relativeX = o.x
                b.relativeY = o.y
                if let size = o.size { b.relativeSize = size }
            }
            return b
        }
    }

    private func badgeFor(_ building: CityBuilding) -> String? {
        guard building.id == "arena" else { return nil }
        let used = appState.currentCharacter?.freePvpToday ?? 0
        let remaining = AppConstants.freePvpPerDay - used
        guard remaining > 0 else { return nil }
        return "FREE \(remaining)"
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Position Indicator

struct ScrollPositionIndicator: View {
    let progress: CGFloat // 0…1

    private let trackWidth: CGFloat = 60
    private let thumbWidth: CGFloat = 20
    private let height: CGFloat = 4

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(DarkFantasyTheme.textPrimary.opacity(0.2))
                .frame(width: trackWidth, height: height)
            Capsule()
                .fill(DarkFantasyTheme.textPrimary.opacity(0.5))
                .frame(width: thumbWidth, height: height)
                .offset(x: (trackWidth - thumbWidth) * progress)
        }
        .allowsHitTesting(false)
    }
}
