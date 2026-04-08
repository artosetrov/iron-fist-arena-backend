import SwiftUI

// MARK: - City Map View (horizontal scrollable panoramic hub)

struct CityMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    // scrollOffset removed — position indicator pill was removed

    // MARK: - Quest → Building mapping (matches backend TUTORIAL_QUESTS)
    /// Maps quest IDs to the building they direct the player to
    private static let questBuildingMap: [String: String] = [
        "equip_gear": "shop",
        "win_3_pvp": "arena",
        "first_dungeon": "dungeon",
        "start_mining": "gold-mine",
        "try_tavern": "tavern",
        "explore_endgame": "battlepass",
        "join_guild": "guild-hall",
    ]

    /// Returns the building ID that has an active (incomplete) tutorial quest
    private var questTargetBuildingId: String? {
        let quests = TutorialManager.shared.tutorialQuests
        for quest in quests {
            let completed = quest["isCompleted"] as? Bool ?? false
            let claimed = quest["rewardClaimed"] as? Bool ?? false
            if !completed || !claimed,
               let questId = quest["questId"] as? String,
               let buildingId = Self.questBuildingMap[questId] {
                return buildingId
            }
        }
        return nil
    }

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
                            .interpolation(.medium)
                            .frame(width: terrainWidth, height: viewHeight)

                        // Layer 2: Lantern glow effects
                        LanternGlowLayer(terrainSize: terrainSize)

                        // Layer 2.5: Chimney smoke (above terrain, below buildings)
                        ChimneySmokeLayer(terrainSize: terrainSize)

                        // Layer 3: Building sprites (images only, no labels)
                        let layoutOverrides = cache.hubLayout
                        let buildings = applyOverrides(layoutOverrides)
                        let activeQuestBuilding = questTargetBuildingId
                        ForEach(buildings) { building in
                            let locked = isBuildinglocked(building)
                            let unlockLvl = BuildingUnlockConfig.requiredLevel(for: building.id)
                            CityBuildingView(
                                building: building,
                                terrainSize: terrainSize,
                                onTap: { tapped in
                                    if locked {
                                        if let lvl = unlockLvl {
                                            appState.showToast(
                                                "\(tapped.label) opens at Level \(lvl)",
                                                type: .info
                                            )
                                        } else {
                                            appState.showToast(
                                                "\(tapped.label) — Coming Soon",
                                                type: .info
                                            )
                                        }
                                    } else if let route = tapped.route {
                                        appState.mainPath.append(route)
                                    } else {
                                        appState.showToast(
                                            "\(tapped.label) — Coming Soon",
                                            type: .info
                                        )
                                    }
                                },
                                badge: locked ? nil : badgeFor(building),
                                spriteOnly: true,
                                isLocked: locked,
                                requiredLevel: (locked && building.route != nil) ? unlockLvl : nil
                            )
                            .id(building.id)
                        }

                        // Layer 3.5: Building labels (rendered ABOVE all sprites to prevent overlap)
                        ForEach(buildings) { building in
                            let posX = terrainSize.width * building.relativeX
                            let posY = terrainSize.height * building.relativeY
                            let bHeight = terrainSize.height * building.relativeSize
                            let locked = isBuildinglocked(building)
                            CityBuildingLabel(
                                text: building.label,
                                visible: true,
                                badge: locked ? nil : badgeFor(building),
                                isLocked: locked,
                                hasQuest: !locked && building.id == activeQuestBuilding
                            )
                            .position(
                                x: posX,
                                y: posY - bHeight / 2 - LayoutConstants.spaceXS + building.labelYOffset * terrainSize.height + 10
                            )
                            .allowsHitTesting(false)
                            .id("\(building.id)-label")
                        }

                        // Layer 4: Fog at bottom
                        FogLayer(width: terrainWidth, height: viewHeight)

                        // Layer 5: Wind particles (with gust dynamics)
                        WindParticlesLayer(width: terrainWidth, height: viewHeight)

                        // Layer 5.5: Falling leaves & embers
                        FallingLeavesLayer(width: terrainWidth, height: viewHeight)

                        // Layer 6: Front clouds (over terrain + buildings)
                        ParallaxLayer(factor: parallaxFactor(for: .frontCloud)) {
                            ForEach(frontClouds) { obj in
                                SkyObjectView(object: obj, terrainSize: terrainSize)
                            }
                        }
                        .frame(width: terrainWidth, height: viewHeight)
                    }
                    .frame(width: terrainWidth, height: viewHeight)
                    .drawingGroup() // Flatten entire map to Metal texture — major GPU win
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

    /// Buildings that are locked (not yet implemented / coming soon)
    private func isBuildinglocked(_ building: CityBuilding) -> Bool {
        // Always lock buildings without routes (Coming Soon)
        if building.route == nil { return true }
        // Level-based unlock from tutorial system
        let characterLevel = appState.currentCharacter?.level ?? 1
        return !BuildingUnlockConfig.isUnlocked(building.id, characterLevel: characterLevel)
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

        // Dungeon — total bosses remaining across all dungeons
        case "dungeon":
            guard let dungeons = cache.cachedDungeonList(), !dungeons.isEmpty else { return nil }
            let progress = cache.dungeonProgress
            var totalRemaining = 0
            for dungeon in dungeons {
                let defeated = progress[dungeon.id] ?? 0
                let remaining = max(0, dungeon.totalBosses - defeated)
                totalRemaining += remaining
            }
            guard totalRemaining > 0 else { return nil }
            return "⚔ \(totalRemaining)"

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
    @State private var shimmer: CGFloat = 0.6
    /// Secondary breathing cycle — slower, offsets primary for organic feel
    @State private var breathe: CGFloat = 0.8

    private var objectHeight: CGFloat {
        terrainSize.height * object.relativeSize
    }

    /// Combined glow intensity from two overlapping cycles
    private var glowIntensity: CGFloat {
        (shimmer * 0.6 + breathe * 0.4)
    }

    var body: some View {
        ZStack {
            if isMoon {
                // Outer halo — large, soft, responds to breathing
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.moonGlowOuter1.opacity(glowIntensity * 0.28),
                                DarkFantasyTheme.moonGlowOuter2.opacity(glowIntensity * 0.14),
                                DarkFantasyTheme.moonGlowOuter3.opacity(glowIntensity * 0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: objectHeight * 0.15,
                            endRadius: objectHeight * 1.4
                        )
                    )
                    .frame(width: objectHeight * 2.8, height: objectHeight * 2.8)
                    .blendMode(.screen)

                // Inner corona — tighter, warmer
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.moonGlowInner1.opacity(glowIntensity * 0.35),
                                DarkFantasyTheme.moonGlowInner2.opacity(glowIntensity * 0.12),
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
                .opacity(isMoon ? (0.85 + glowIntensity * 0.15) : object.opacity)
        }
        // Moon subtle scale breathing (±3%)
        .scaleEffect(isMoon ? (0.97 + glowIntensity * 0.06) : 1.0)
        .offset(x: drift)
        .position(
            x: terrainSize.width * object.relativeX,
            y: terrainSize.height * object.relativeY
        )
        .allowsHitTesting(false)
        .onAppear {
            if isMoon {
                // Primary shimmer: 7-10s cycle (slow, mystical)
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    shimmer = 1.0
                }
                // Secondary breathe: 12-15s cycle (even slower, offset)
                withAnimation(.easeInOut(duration: 13).repeatForever(autoreverses: true)) {
                    breathe = 1.0
                }
            }
            if object.driftSpeed > 0 {
                drift = CGFloat.random(in: -object.driftRange...object.driftRange)
                withAnimation(.linear(duration: object.driftSpeed).repeatForever(autoreverses: true)) {
                    drift = drift > 0 ? -object.driftRange : object.driftRange
                }
            }
        }
        .onDisappear {
            shimmer = 0.6
            breathe = 0.8
            drift = 0
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
