import SwiftUI

// MARK: - City Map View (horizontal scrollable panoramic hub)

struct CityMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    // scrollOffset removed — position indicator pill was removed

    // Image native aspect ratio (4096×1738)
    private let imageAspect: CGFloat = 4096.0 / 1738.0

    var body: some View {
        GeometryReader { outerGeo in
            let viewHeight = outerGeo.size.height
            let terrainWidth = viewHeight * imageAspect
            let terrainSize = CGSize(width: terrainWidth, height: viewHeight)


            let skyObjects = resolvedSkyObjects(from: cache)
            let moonObjects = skyObjects.filter { $0.layer == .moon }
            let backClouds = skyObjects.filter { $0.layer == .backCloud }
            let frontClouds = skyObjects.filter { $0.layer == .frontCloud }

            ZStack {
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()

                // Main scrollable map
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Layer 0: Sky background
                        DarkFantasyTheme.skyNight
                            .frame(width: terrainWidth, height: viewHeight)

                        // Layer 0.5: Moon (behind everything, slowest parallax)
                        ParallaxLayer(factor: parallaxFactor(for: .moon)) {
                            ForEach(moonObjects) { obj in
                                SkyObjectView(object: obj, terrainSize: terrainSize, isMoon: true)
                            }
                        }
                        .frame(width: terrainWidth, height: viewHeight)

                        // Layer 0.7: Back clouds (behind terrain)
                        ParallaxLayer(factor: parallaxFactor(for: .backCloud)) {
                            ForEach(backClouds) { obj in
                                SkyObjectView(object: obj, terrainSize: terrainSize)
                            }
                        }
                        .frame(width: terrainWidth, height: viewHeight)

                        // Layer 1: Terrain background (scrolls at 1x)
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
                                onTap: { tapped in
                                    if let route = tapped.route {
                                        appState.mainPath.append(route)
                                    } else {
                                        appState.showToast(
                                            "\(tapped.label) — Coming Soon",
                                            type: .info
                                        )
                                    }
                                },
                                badge: badgeFor(building)
                            )
                            .id(building.id)
                        }

                        // Layer 4: Fog at bottom
                        FogLayer(width: terrainWidth, height: viewHeight)

                        // Layer 5: Wind particles
                        WindParticlesLayer(width: terrainWidth, height: viewHeight)

                        // Layer 6: Front clouds (over terrain + buildings)
                        ParallaxLayer(factor: parallaxFactor(for: .frontCloud)) {
                            ForEach(frontClouds) { obj in
                                SkyObjectView(object: obj, terrainSize: terrainSize)
                            }
                        }
                        .frame(width: terrainWidth, height: viewHeight)
                    }
                    .frame(width: terrainWidth, height: viewHeight)
                    .background(ScrollBounceDisabler())
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
                // scroll offset tracking removed (indicator pill removed)

                // Position indicator pill — removed per UX decision (overlaps ADVENTURES button)
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
        switch building.id {

        // Arena — free PvP fights remaining
        case "arena":
            let used = appState.currentCharacter?.freePvpToday ?? 0
            let remaining = AppConstants.freePvpPerDay - used
            guard remaining > 0 else { return nil }
            return "FREE \(remaining)"

        // Achievements — unclaimed rewards
        case "achievements":
            let claimable = cache.achievements.filter(\.canClaim).count
            guard claimable > 0 else { return nil }
            return "\(claimable)"

        // Battle Pass — claimable tier rewards
        case "battlepass":
            guard let bp = cache.battlePassData else { return nil }
            let claimable = (bp.freeRewards + bp.premiumRewards).filter {
                !$0.claimed && $0.level <= bp.currentLevel && ($0.track == "free" || bp.hasPremium)
            }.count
            guard claimable > 0 else { return nil }
            return "\(claimable)"

        // Gold Mine — slots ready to collect
        case "gold-mine":
            let ready = cache.goldMineSlots.filter { ($0["status"] as? String) == "ready" }.count
            guard ready > 0 else { return nil }
            return "READY"

        // Guild Hall — total social badge (friends + challenges + messages + revenges)
        case "guild-hall":
            let total = cache.socialStatus?.totalBadge ?? 0
            guard total > 0 else { return nil }
            return "\(total)"

        default:
            return nil
        }
    }
}

// MARK: - Parallax Layer (reads scroll offset directly via GeometryReader)

struct ParallaxLayer<Content: View>: View {
    let factor: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scrollX = geo.frame(in: .named("hubScroll")).minX
            content()
                .offset(x: -scrollX * factor)
        }
    }
}

// MARK: - Sky Object View (renders a single sky object from config)

struct SkyObjectView: View {
    let object: SkyObject
    let terrainSize: CGSize
    var isMoon: Bool = false

    @State private var drift: CGFloat = 0
    @State private var shimmer: CGFloat = 0.7

    private var objectHeight: CGFloat {
        terrainSize.height * object.relativeSize
    }

    var body: some View {
        ZStack {
            if isMoon {
                // Moon glow layers
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.moonGlowOuter1.opacity(shimmer * 0.25),
                                DarkFantasyTheme.moonGlowOuter2.opacity(shimmer * 0.12),
                                DarkFantasyTheme.moonGlowOuter3.opacity(shimmer * 0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: objectHeight * 0.15,
                            endRadius: objectHeight * 1.3
                        )
                    )
                    .frame(width: objectHeight * 2.6, height: objectHeight * 2.6)
                    .blendMode(.screen)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.moonGlowInner1.opacity(shimmer * 0.3),
                                DarkFantasyTheme.moonGlowInner2.opacity(shimmer * 0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: objectHeight * 0.2,
                            endRadius: objectHeight * 0.6
                        )
                    )
                    .frame(width: objectHeight * 1.3, height: objectHeight * 1.3)
                    .blendMode(.screen)
            }

            Image(object.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: objectHeight)
                .opacity(object.opacity)
        }
        .offset(x: drift)
        .position(
            x: terrainSize.width * object.relativeX,
            y: terrainSize.height * object.relativeY
        )
        .allowsHitTesting(false)
        .onAppear {
            if isMoon {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    shimmer = 0.95
                }
            }
            if object.driftSpeed > 0 {
                drift = CGFloat.random(in: -object.driftRange...object.driftRange)
                withAnimation(.linear(duration: object.driftSpeed).repeatForever(autoreverses: true)) {
                    drift = drift > 0 ? -object.driftRange : object.driftRange
                }
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key (for indicator pill only)

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
