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
                    .brightness(isLocked ? -0.25 : (isPressed ? -0.06 : 0))
                    // BUG-57: locked sprite is fully grayscale + dimmed
                    // ~45%. Previous 0.6/0.3 felt identical to an open
                    // building at a glance. `saturation(0)` kills all
                    // colour so only the structured `BuildingLockOverlay`
                    // above it reads as a signal.
                    .opacity(isLocked ? 0.45 : 1.0)
                    .saturation(isLocked ? 0.0 : 1.0)

                // Lock overlay — BUG-57: swapped the bare padlock icon +
                // tiny "LV.4" text for a reusable `BuildingLockOverlay`
                // with vignette, gold padlock disc and LV pill. Sits
                // above the dimmed sprite inside the same ZStack so it
                // inherits the building's position but its own sizing.
                if isLocked {
                    BuildingLockOverlay(
                        requiredLevel: requiredLevel,
                        spriteHeight: buildingHeight
                    )
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
        SFXManager.shared.play(.doorCreak)

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
