import SwiftUI

// MARK: - City Map View (horizontal scrollable panoramic hub)

struct CityMapView: View {
    @Environment(AppState.self) private var appState

    @State private var hasScrolledToCenter = false

    var body: some View {
        GeometryReader { outerGeo in
            let availableHeight = outerGeo.size.height
            let terrainWidth = availableHeight * (21.0 / 9.0)
            let terrainSize = CGSize(width: terrainWidth, height: availableHeight)

            ScrollViewReader { scrollProxy in
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
                                terrainSize: terrainSize
                            ) { tapped in
                                appState.mainPath.append(tapped.route)
                            }
                        }

                        // Invisible anchor at center for ScrollViewReader
                        Color.clear
                            .frame(width: 1, height: 1)
                            .id("centerAnchor")
                            .position(x: terrainWidth * 0.5, y: availableHeight * 0.5)
                    }
                    .frame(width: terrainWidth, height: availableHeight)
                }
                .onAppear {
                    if !hasScrolledToCenter {
                        hasScrolledToCenter = true
                        // Slight delay to ensure layout is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            scrollProxy.scrollTo("centerAnchor", anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
