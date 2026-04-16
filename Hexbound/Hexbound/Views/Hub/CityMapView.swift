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
            if (!quest.isCompleted || !quest.rewardClaimed),
               let buildingId = Self.questBuildingMap[quest.questId] {
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
                        // W2.D5 — compute the cap-3 filtered badge set ONCE per
                        // frame so both the sprite layer (ForEach above) and the
                        // label layer (ForEach below) see the same result.
                        let visibleBadges = filteredBadges(for: buildings)
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
                                badge: locked ? .none : (visibleBadges[building.id] ?? .none),
                                spriteOnly: true,
                                isLocked: locked,
                                requiredLevel: (locked && building.route != nil) ? unlockLvl : nil
                            )
                            .id(building.id)
                        }

                        // Layer 3.5: Building labels (rendered ABOVE all sprites to prevent overlap)
                        ForEach(buildings) { building in
                            let rawPosX = terrainSize.width * building.relativeX
                            let posY = terrainSize.height * building.relativeY
                            let bHeight = terrainSize.height * building.relativeSize
                            let locked = isBuildinglocked(building)
                            // Clamp label X so it doesn't clip off left/right edges
                            let labelMargin: CGFloat = 60
                            let posX = min(max(rawPosX, labelMargin), terrainSize.width - labelMargin)
                            CityBuildingLabel(
                                text: building.label,
                                visible: true,
                                badge: locked ? .none : (visibleBadges[building.id] ?? .none),
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

                        // Layer 5.7: Periodic rain + lightning storm
                        StormEffectLayer(width: terrainWidth, height: viewHeight)

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

    // MARK: - W2.D5 Badge Pipeline

    /// Compute ALL raw badges for the unlocked buildings, then run the cap-3
    /// priority filter so the hub never renders more than three simultaneous
    /// red critical pills at once.
    ///
    /// Input order matters: ties in the cap-3 sort are resolved left-to-right
    /// in the building list, which matches the hub's layout order.
    private func filteredBadges(for buildings: [CityBuilding]) -> [String: BuildingBadge] {
        let raw: [(id: String, badge: BuildingBadge)] = buildings.compactMap { building in
            guard !isBuildinglocked(building) else { return nil }
            let badge = badgeFor(building)
            guard badge.shouldShow else { return nil }
            return (building.id, badge)
        }
        return BuildingBadge.applyCap(raw)
    }

    /// Raw badge for a single building (pre-cap). Returns `.none` when the
    /// building has nothing worth surfacing right now.
    ///
    /// W2.D5 priorities (per design doc W2_D5_BADGE_PRIORITY_DESIGN.md):
    ///   - `.critical` — claimable rewards (achievements, battlepass, gold
    ///     mine ready) + urgent social state (unread msgs / incoming duels).
    ///   - `.info`     — free attempts remaining, passive social counters.
    ///   - Dungeon "X bosses left" badge REMOVED — it's metadata, not a
    ///     call to action.
    ///
    /// Severity scales with count so the cap-3 filter prefers the building
    /// with the most rewards waiting when it has to downgrade.
    private func badgeFor(_ building: CityBuilding) -> BuildingBadge {
        switch building.id {

        // Arena — free PvP fights remaining. Useful but not urgent.
        case "arena":
            let used = appState.currentCharacter?.freePvpToday ?? 0
            let limit = cache.gameConfig?.freePvpPerDay ?? AppConstants.freePvpPerDay
            let remaining = limit - used
            guard remaining > 0 else { return .none }
            return .info("FREE \(remaining)", severity: 10 + remaining)

        // Achievements — unclaimed rewards. Actionable → critical.
        case "achievements":
            let claimable = cache.achievements.filter(\.canClaim).count
            guard claimable > 0 else { return .none }
            return .critical("\(claimable)", severity: 50 + claimable * 5)

        // Battle Pass — time-limited season rewards. Highest severity class
        // because tier expiration is the most expensive miss.
        case "battlepass":
            guard let bp = cache.battlePassData else { return .none }
            let claimable = (bp.freeRewards + bp.premiumRewards).filter {
                !$0.claimed && $0.level <= bp.currentLevel && ($0.track == "free" || bp.hasPremium)
            }.count
            guard claimable > 0 else { return .none }
            return .critical("\(claimable)", severity: 60 + claimable * 5)

        // Gold Mine — slots ready to collect. Actionable → critical.
        case "gold-mine":
            let ready = cache.goldMineSlots.filter { $0.resolvedStatus() == .ready }.count
            guard ready > 0 else { return .none }
            return .critical("READY", severity: 40 + ready * 2)

        // Guild Hall — priority depends on social state (see helper).
        case "guild-hall":
            return buildGuildHallBadge()

        // Dungeon — W2.D5: badge REMOVED. "X bosses left" is metadata, not a
        // signal the player can act on differently based on the number.

        default:
            return .none
        }
    }

    /// Guild Hall scales by what's actually waiting:
    ///   - Unread messages or incoming challenges → `.critical` (social
    ///     interaction is time-sensitive).
    ///   - Pending friend requests or pending revenges → `.info` (passive,
    ///     no expiration pressure).
    ///   - Nothing → `.none`.
    private func buildGuildHallBadge() -> BuildingBadge {
        guard let social = cache.socialStatus else { return .none }

        let unreadMsg  = social.unreadMessages
        let challenges = social.pendingChallenges
        let friendReq  = social.pendingRequests
        let revenges   = social.pendingRevenges

        // Critical tier — someone is waiting for a response RIGHT NOW.
        if unreadMsg > 0 || challenges > 0 {
            let total = unreadMsg + challenges
            return .critical("\(total)", severity: 55 + total * 3)
        }

        // Info tier — passive social state, no response deadline.
        if friendReq > 0 || revenges > 0 {
            let total = friendReq + revenges
            return .info("\(total)", severity: 15 + total)
        }

        return .none
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
