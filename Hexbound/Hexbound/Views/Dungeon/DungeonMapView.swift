import SwiftUI

// MARK: - Dungeon Map View (horizontal scrollable panoramic dungeon map)

struct DungeonMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

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
            Color.black.ignoresSafeArea()

            GeometryReader { outerGeo in
                let viewWidth = outerGeo.size.width
                let viewHeight = outerGeo.size.height
                let terrainWidth = viewHeight * imageAspect
                let terrainSize = CGSize(width: terrainWidth, height: viewHeight)

                ZStack {
                    // Main scrollable map
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

                    // Castle button overlay (return to hub) — bottom-left
                    VStack {
                        Spacer()
                        HStack {
                            castleButton
                            Spacer()
                        }
                    }
                    .padding(.leading, LayoutConstants.screenPadding)
                    .padding(.bottom, LayoutConstants.spaceLG)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("ADVENTURES")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            #if DEBUG
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    appState.mainPath.append(AppRoute.dungeonMapEditor)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
            #endif
        }
    }

    // MARK: - Castle Button (return to hub)

    private var castleButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("CASTLE")
                    .font(DarkFantasyTheme.section(size: 13))
            }
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
            )
            .overlay(
                Capsule()
                    .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
            )
        }
    }

    // MARK: - Helpers

    private func isDungeonCompleted(_ dungeonId: String) -> Bool {
        guard let defeated = progress[dungeonId] else { return false }
        // A dungeon is completed if all 10 bosses are defeated
        return defeated >= 10
    }

    private func navigateToDungeon(_ building: DungeonMapBuilding) {
        // Set the selected dungeon context, then navigate to dungeon select
        // which shows the boss list for this specific dungeon
        appState.selectedDungeonId = building.id
        appState.mainPath.append(AppRoute.dungeonSelect)
    }
}
