import SwiftUI

// MARK: - Dungeon Map Building View (single dungeon node on the dungeon map)

struct DungeonMapBuildingView: View {
    let building: DungeonMapBuilding
    let terrainSize: CGSize
    let isLocked: Bool
    let isCompleted: Bool
    /// Whether this is the next dungeon the player should tackle (pulsing highlight)
    var isNext: Bool = false
    /// Dungeon's required level — overlay shows "LV X".
    var requiredLevel: Int? = nil
    let onTap: (DungeonMapBuilding) -> Void

    @State private var isPressed = false
    @State private var glowPulse = false

    private var buildingHeight: CGFloat {
        terrainSize.height * building.relativeSize
    }

    var body: some View {
        let posX = terrainSize.width * building.relativeX
        let posY = terrainSize.height * building.relativeY

        VStack(spacing: LayoutConstants.spaceXS) {
            // Pulsing "next dungeon" indicator arrow
            if isNext {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.8), radius: 8)
                    .offset(y: glowPulse ? 4 : -2)
                    .opacity(glowPulse ? 1.0 : 0.6)
            }

            // Label above building
            dungeonLabel

            // Building sprite with lock overlay — mirrors `CityBuildingView`
            // so closed dungeons read the same way as closed hub buildings:
            // fully grayscaled + dimmed sprite, gold padlock disc, pill
            // showing what's needed to unlock.
            ZStack {
                buildingImage
                    .frame(height: buildingHeight)
                    .shadow(
                        color: isLocked
                            ? Color.clear
                            : isNext
                                ? building.glowColor.opacity(glowPulse ? 0.7 : 0.3)
                                : building.glowColor.opacity(isPressed ? 0.6 : 0),
                        radius: isNext ? (glowPulse ? 20 : 10) : (isPressed ? 16 : 0)
                    )
                    .brightness(isLocked ? -0.25 : (isPressed ? -0.06 : 0))
                    .opacity(isLocked ? 0.45 : 1.0)
                    .saturation(isLocked ? 0.0 : 1.0)

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
        .onAppear {
            if isNext {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    glowPulse = true
                }
            }
        }
    }

    // MARK: - Label

    @ViewBuilder
    private var dungeonLabel: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Text(building.label.uppercased())
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .stroke(
                    isLocked
                        ? DarkFantasyTheme.textSecondary.opacity(0.4)
                        : isNext
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.gold.opacity(0.7),
                    lineWidth: isNext ? 1.5 : 1
                )
        )
        .shadow(
            color: isNext ? DarkFantasyTheme.gold.opacity(glowPulse ? 0.5 : 0.2) : Color.clear,
            radius: isNext ? 6 : 0
        )
    }

    // MARK: - Building Image (with fallback + lock overlay)

    @ViewBuilder
    private var buildingImage: some View {
        ZStack {
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
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : building.glowColor)
                        Text(building.label)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)
                    }
                }
                .frame(width: buildingHeight * 0.7, height: buildingHeight)
            }
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        guard !isLocked else {
            // Haptic for locked
            HapticManager.warning()
            return
        }

        // Haptic
        HapticManager.medium()

        // Visual feedback
        withAnimation {
            isPressed = true
        }

        // Navigate after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onTap(building)
        }

        // Reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                isPressed = false
            }
        }
    }

}
