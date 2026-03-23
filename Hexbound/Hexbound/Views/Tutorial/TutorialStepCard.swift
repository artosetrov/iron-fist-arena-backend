import SwiftUI

// MARK: - Tutorial Step Card

/// Ornamental card for a single FTUE objective (First Battle, Gear Up, Explore Dungeon).
/// Three visual states: completed (green border, faded), current (gold pulsing border), locked (dashed, dimmed).
struct TutorialStepCard: View {
    let objective: FTUEObjective
    let state: FTUEObjectiveState
    let onTap: () -> Void

    @State private var glowOpacity: Double = 0

    private var accentColor: Color {
        switch state {
        case .completed: return DarkFantasyTheme.success
        case .current:   return DarkFantasyTheme.gold
        case .locked:    return DarkFantasyTheme.borderSubtle
        }
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Icon area
            iconArea

            // Title
            Text(objective.title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                .foregroundStyle(state == .locked ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textPrimary)
                .tracking(1)

            // Subtitle
            Text(objective.subtitle)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(state == .locked ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Reward
            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14))
                Text(objective.rewardText)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
            }
            .foregroundStyle(state == .locked ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.gold)
        }
        .padding(LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(cardBorder)
        .overlay(statusBadge, alignment: .topTrailing)
        .cornerBrackets(
            color: state == .current ? DarkFantasyTheme.gold.opacity(0.3) : accentColor.opacity(0.15),
            length: 12,
            thickness: 1.5
        )
        .shadow(
            color: state == .current ? DarkFantasyTheme.goldGlow.opacity(0.15 + glowOpacity * 0.15) : DarkFantasyTheme.bgAbyss.opacity(0.3),
            radius: state == .current ? 12 : 4,
            y: 3
        )
        .opacity(state == .locked ? 0.5 : 1.0)
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .onTapGesture {
            guard state != .locked else { return }
            HapticManager.light()
            onTap()
        }
        .accessibilityLabel("\(objective.title). \(objective.subtitle). \(state == .completed ? "Completed" : state == .locked ? "Locked" : "Current")")
        .onAppear {
            if state == .current {
                withAnimation(MotionConstants.pulse) {
                    glowOpacity = 1
                }
            }
        }
    }

    // MARK: - Icon Area

    @ViewBuilder
    private var iconArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(accentColor.opacity(0.08))
                .frame(height: 64)

            // Surface lighting on icon area
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color.clear,
                            Color.black.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 64)

            if let _ = UIImage(named: objective.iconAsset) {
                Image(objective.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            } else {
                Image(systemName: objective.fallbackIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor)
            }
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RadialGlowBackground(
            baseColor: DarkFantasyTheme.bgSecondary,
            glowColor: state == .current ? DarkFantasyTheme.gold.opacity(0.08) : DarkFantasyTheme.bgTertiary,
            glowIntensity: state == .current ? 0.6 : 0.3,
            cornerRadius: LayoutConstants.cardRadius
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.08)
    }

    // MARK: - Card Border

    @ViewBuilder
    private var cardBorder: some View {
        if state == .locked {
            // Dashed border for locked state
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    DarkFantasyTheme.borderSubtle.opacity(0.3),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
        } else {
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(accentColor.opacity(state == .current ? 0.6 : 0.4), lineWidth: state == .current ? 2 : 1.5)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        Group {
            if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DarkFantasyTheme.success)
            } else if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(DarkFantasyTheme.textDisabled)
            }
        }
        .padding(LayoutConstants.spaceSM)
    }
}
