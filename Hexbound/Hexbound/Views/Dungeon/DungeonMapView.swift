import SwiftUI

// MARK: - Dungeon Map View (horizontal scrollable panoramic dungeon map)

struct DungeonMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    /// Optional closures for when presented as a fullScreenCover (from Adventures button).
    /// When nil, falls back to standard NavigationStack behavior.
    var onBack: (() -> Void)? = nil
    var onNavigate: ((AppRoute) -> Void)? = nil

    // Image native aspect ratio (3535×1500)
    private let imageAspect: CGFloat = 3535.0 / 1500.0

    /// Character level for lock/unlock logic
    private var characterLevel: Int {
        appState.currentCharacter?.level ?? 1
    }

    /// Dungeon progress: dungeonSlug → bossesDefeated
    private var progress: [String: Int] {
        cache.dungeonProgress
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            GeometryReader { outerGeo in
                let viewHeight = outerGeo.size.height
                let terrainWidth = viewHeight * imageAspect
                let terrainSize = CGSize(width: terrainWidth, height: viewHeight)

                ZStack {
                    // Main scrollable map — fills entire screen
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            // Layer 0: Dark background
                            DarkFantasyTheme.bgAbyss
                                .frame(width: terrainWidth, height: viewHeight)

                            // Layer 1: Terrain background
                            Image("bg-dungeon-map")
                                .resizable()
                                .frame(width: terrainWidth, height: viewHeight)

                            // Layer 2: Dungeon buildings
                            let buildings = resolvedDungeonMapBuildings(from: cache)
                            ForEach(buildings) { building in
                                DungeonMapBuildingView(
                                    building: building,
                                    terrainSize: terrainSize,
                                    isLocked: characterLevel < building.minLevel,
                                    isCompleted: isDungeonCompleted(building.id),
                                    onTap: { tapped in
                                        navigateToDungeon(tapped)
                                    }
                                )
                                .id(building.id)
                            }

                            // Layer 3: Fog at bottom
                            FogLayer(width: terrainWidth, height: viewHeight)
                        }
                        .frame(width: terrainWidth, height: viewHeight)
                        .background(ScrollBounceDisabler())
                    }
                    .defaultScrollAnchor(.leading)
                }
            }
            .ignoresSafeArea()

            // CASTLE button — when pushed on mainPath (no onBack), show a floating back button
            if onBack == nil {
                VStack {
                    Spacer()
                    Button {
                        HapticManager.selection()
                        if !appState.mainPath.isEmpty {
                            appState.mainPath.removeLast()
                        }
                    } label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            Image("ui-arrow-left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("CASTLE")
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                                .tracking(1)
                        }
                        .padding(.horizontal, LayoutConstants.buttonPaddingH)
                        .padding(.vertical, LayoutConstants.spaceMD)
                    }
                    .buttonStyle(.compactPrimary)
                    .padding(.bottom, LayoutConstants.safeAreaBottom + LayoutConstants.spaceSM)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Next Dungeon (first uncompleted or first locked)

    /// The next dungeon the player should tackle: first uncompleted unlocked, or first locked.
    private var nextDungeon: DungeonMapBuilding? {
        let buildings = resolvedDungeonMapBuildings(from: cache).sorted { $0.sortOrder < $1.sortOrder }
        // First: find first unlocked but not completed
        if let next = buildings.first(where: { characterLevel >= $0.minLevel && !isDungeonCompleted($0.id) }) {
            return next
        }
        // Fallback: first locked dungeon
        return buildings.first(where: { characterLevel < $0.minLevel })
    }

    // MARK: - Helpers

    private func isDungeonCompleted(_ dungeonId: String) -> Bool {
        guard let defeated = progress[dungeonId] else { return false }
        // A dungeon is completed if all 10 bosses are defeated
        return defeated >= 10
    }

    private func navigateToDungeon(_ building: DungeonMapBuilding) {
        // Set the selected dungeon context, then navigate directly to dungeon room (boss list)
        appState.selectedDungeonId = building.id
        if let onNavigate {
            onNavigate(.dungeonRoom)
        } else {
            appState.mainPath.append(AppRoute.dungeonRoom)
        }
    }
}

// Note: DungeonMapCoverView removed — dungeon map is now embedded in HubView
// with slide transition. Navigation handled by HubView's dungeonPath NavigationStack.
