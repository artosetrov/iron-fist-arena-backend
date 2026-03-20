import SwiftUI

// MARK: - Dungeon Map Building View (single dungeon node on the dungeon map)

struct DungeonMapBuildingView: View {
    let building: DungeonMapBuilding
    let terrainSize: CGSize
    let isLocked: Bool
    let isCompleted: Bool
    let onTap: (DungeonMapBuilding) -> Void

    @State private var isPressed = false
    @State private var idleGlow: CGFloat = 0.3

    private var buildingHeight: CGFloat {
        terrainSize.height * building.relativeSize
    }

    var body: some View {
        let posX = terrainSize.width * building.relativeX
        let posY = terrainSize.height * building.relativeY

        VStack(spacing: 4) {
            // Label above building
            dungeonLabel

            // Building sprite
            buildingImage
                .frame(height: buildingHeight)
                .shadow(
                    color: isLocked
                        ? Color.clear
                        : building.glowColor.opacity(idleGlow),
                    radius: isPressed ? 16 : 8
                )
                .scaleEffect(isPressed ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .saturation(isLocked ? 0.3 : 1.0)
                .opacity(isLocked ? 0.6 : 1.0)
        }
        .position(x: posX, y: posY)
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            if !isLocked {
                startIdleAnimation()
            }
        }
    }

    // MARK: - Label

    @ViewBuilder
    private var dungeonLabel: some View {
        HStack(spacing: 4) {
            Text(building.label.uppercased())
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    isLocked
                        ? DarkFantasyTheme.textSecondary.opacity(0.4)
                        : DarkFantasyTheme.gold.opacity(0.7),
                    lineWidth: 1
                )
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DarkFantasyTheme.bgSecondary.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(building.glowColor.opacity(0.5), lineWidth: 1.5)
                        )

                    VStack(spacing: 6) {
                        Image(systemName: building.fallbackIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : building.glowColor)
                        Text(building.label)
                            .font(DarkFantasyTheme.section(size: 10))
                            .foregroundStyle(isLocked ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.goldBright)
                    }
                }
                .frame(width: buildingHeight * 0.7, height: buildingHeight)
            }

            // Lock overlay for locked dungeons
            if isLocked {
                VStack(spacing: 2) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("Lvl \(building.minLevel)")
                        .font(DarkFantasyTheme.section(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .padding(8)
                .background(
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss.opacity(0.7))
                )
            }
        }
    }

    // MARK: - Tap Handler

    private func handleTap() {
        guard !isLocked else {
            // Haptic for locked
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

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

    // MARK: - Idle Animation

    private func startIdleAnimation() {
        idleGlow = 0.2
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            idleGlow = 0.6
        }
    }
}
