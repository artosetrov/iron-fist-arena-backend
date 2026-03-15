import SwiftUI

// MARK: - City Building View (single building sprite + tap + idle animation)

struct CityBuildingView: View {
    let building: CityBuilding
    let terrainSize: CGSize
    let onTap: (CityBuilding) -> Void

    @State private var isPressed = false
    @State private var showLabel = false
    @State private var idleGlow: CGFloat = 0.3

    private var buildingHeight: CGFloat {
        terrainSize.height * building.relativeSize
    }

    private var buildingWidth: CGFloat {
        buildingHeight // aspect ratio handled by .fit
    }

    var body: some View {
        let posX = terrainSize.width * building.relativeX
        let posY = terrainSize.height * building.relativeY

        VStack(spacing: 4) {
            // Label above building (always visible)
            CityBuildingLabel(text: building.label, visible: true)
                .offset(y: building.labelYOffset * terrainSize.height)

            // Building sprite
            buildingImage
                .frame(height: buildingHeight)
                .shadow(
                    color: building.glowColor.opacity(idleGlow),
                    radius: isPressed ? 16 : 8
                )
                .scaleEffect(isPressed ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .position(x: posX, y: posY)
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture(minimumDuration: 0.4, perform: {}) { pressing in
            showLabel = pressing
        }
        .onAppear {
            startIdleAnimation()
        }
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(building.glowColor.opacity(0.5), lineWidth: 1.5)
                    )

                VStack(spacing: 6) {
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
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

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

    // MARK: - Idle Animations

    private func startIdleAnimation() {
        let (low, high, duration) = idleParams(for: building.id)

        // Start at low
        idleGlow = low

        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            idleGlow = high
        }
    }

    private func idleParams(for id: String) -> (low: CGFloat, high: CGFloat, duration: Double) {
        switch id {
        case "arena":
            return (0.3, 0.7, 3.0)       // strong gold pulse
        case "tavern":
            return (0.2, 0.55, 2.5)      // warm orange flicker
        case "dungeon":
            return (0.2, 0.55, 2.5)      // warm orange flicker
        case "battlepass":
            return (0.2, 0.55, 2.5)      // warm orange flicker
        default:
            return (0.2, 0.45, 3.5)      // subtle torch glow
        }
    }
}
