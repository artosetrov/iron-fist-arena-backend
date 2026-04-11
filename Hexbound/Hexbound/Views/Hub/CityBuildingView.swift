import SwiftUI

// MARK: - City Building View (single building sprite + tap + idle animation)

struct CityBuildingView: View {
    let building: CityBuilding
    let terrainSize: CGSize
    let onTap: (CityBuilding) -> Void
    /// W2.D5 — structured badge with priority. Defaults to `.none`.
    var badge: BuildingBadge = .none
    /// When true, only render the sprite (no label). Used for z-order separation.
    var spriteOnly: Bool = false
    var isLocked: Bool = false
    /// Required level for unlock (shown as "LV.X" on lock overlay). Nil = "SOON".
    var requiredLevel: Int? = nil

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
            if !spriteOnly {
                // Label above building (always visible, lowered 10px closer to building)
                CityBuildingLabel(text: building.label, visible: true, badge: badge, isLocked: isLocked)
                    .offset(y: building.labelYOffset * terrainSize.height + 10)
            }

            // Building sprite
            ZStack {
                buildingImage
                    .frame(height: buildingHeight)
                    .shadow(
                        color: isLocked
                            ? Color.clear
                            : building.glowColor.opacity(isPressed ? 0.6 : 0),
                        radius: isPressed ? 16 : 0
                    )
                    .brightness(isPressed ? -0.06 : 0)
                    .opacity(isLocked ? 0.6 : 1.0)
                    .saturation(isLocked ? 0.3 : 1.0)

                // Lock overlay
                if isLocked {
                    VStack(spacing: LayoutConstants.space2XS) {
                        Image("icon-padlock")
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .saturation(0.4)
                            .opacity(0.85)
                        Text(requiredLevel != nil ? "LV.\(requiredLevel!)" : "SOON")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                }
            }
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
                .interpolation(.high)
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
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(building.glowColor)
                    Text(building.label)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(width: buildingHeight * 0.7, height: buildingHeight)
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        guard !isLocked else {
            HapticManager.warning()
            return
        }

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
