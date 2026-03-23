import SwiftUI

// MARK: - City Building View (single building sprite + tap + idle animation)

struct CityBuildingView: View {
    let building: CityBuilding
    let terrainSize: CGSize
    let onTap: (CityBuilding) -> Void
    var badge: String? = nil

    @State private var isPressed = false
    @State private var showLabel = false

    private var buildingHeight: CGFloat {
        terrainSize.height * building.relativeSize
    }

    private var buildingWidth: CGFloat {
        buildingHeight // aspect ratio handled by .fit
    }

    var body: some View {
        let posX = terrainSize.width * building.relativeX
        let posY = terrainSize.height * building.relativeY

        VStack(spacing: LayoutConstants.spaceXS) {
            // Label above building (always visible)
            CityBuildingLabel(text: building.label, visible: true, badge: badge)
                .offset(y: building.labelYOffset * terrainSize.height)

            // Building sprite
            buildingImage
                .frame(height: buildingHeight)
                .shadow(
                    color: building.glowColor.opacity(isPressed ? 0.6 : 0),
                    radius: isPressed ? 16 : 0
                )
                .brightness(isPressed ? -0.06 : 0)
        }
        .position(x: posX, y: posY)
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture(minimumDuration: 0.4, perform: {}) { pressing in
            showLabel = pressing
        }
        .onAppear {}
    }

    // MARK: - Building Image (with fallback)

    @ViewBuilder
    private var buildingImage: some View {
        if UIImage(named: building.imageName) != nil {
            Image(building.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Placeholder fallback
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(building.glowColor.opacity(0.5), lineWidth: 1.5)
                    )

                VStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: building.fallbackIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(building.glowColor)
                    Text(building.label)
                        .font(DarkFantasyTheme.section(size: 10))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(width: buildingHeight * 0.7, height: buildingHeight)
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        HapticManager.medium()
        SFXManager.shared.play(.uiTap)

        // Visual feedback
        withAnimation {
            isPressed = true
            showLabel = true
        }

        // Navigate after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onTap(building)
        }

        // Reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                isPressed = false
                showLabel = false
            }
        }
    }

}
