import SwiftUI

// MARK: - City Map View (horizontal scrollable panoramic hub)

struct CityMapView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { outerGeo in
            let availableHeight = outerGeo.size.height
            let terrainWidth = availableHeight * (21.0 / 9.0)
            let terrainSize = CGSize(width: terrainWidth, height: availableHeight)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Layer 1: Terrain background
                    Image("hub-terrain")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: terrainWidth, height: availableHeight)
                        .clipped()

                    // Layer 2: Buildings
                    ForEach(cityBuildings) { building in
                        CityBuildingView(
                            building: building,
                            terrainSize: terrainSize,
                            badge: badgeFor(building)
                        ) { tapped in
                            appState.mainPath.append(tapped.route)
                        }
                    }
                }
                .frame(width: terrainWidth, height: availableHeight)
            }
            .defaultScrollAnchor(.center)
        }
    }

    /// Per-building badge (e.g. free PvP fights remaining on Arena)
    private func badgeFor(_ building: CityBuilding) -> String? {
        guard building.id == "arena" else { return nil }
        let used = appState.currentCharacter?.freePvpToday ?? 0
        let remaining = AppConstants.freePvpPerDay - used
        guard remaining > 0 else { return nil }
        return "FREE \(remaining)"
    }
}
