import SwiftUI

// MARK: - NPC Speech Bubble

/// A speech bubble with NPC avatar, name, and dialog text for the tutorial screen.
/// Different from `NPCGuideWidget` (which is a bottom-pinned bar with dismiss/skip).
/// This is an inline, non-dismissable dialog bubble used within the TutorialView layout.
struct NPCSpeechBubble: View {
    let npcName: String
    let message: String
    var npcImageName: String? = "shopkeeper"
    var npcFallbackIcon: String = "person.crop.circle.fill"
    var messageId: AnyHashable? = nil

    var body: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            // NPC Avatar
            npcAvatar

            // Dialog
            VStack(alignment: .leading, spacing: 4) {
                Text(npcName.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(0.5)

                Text(message)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(messageId)
                    .transition(.opacity)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bubbleBackground)
        .overlay(bubbleBorder)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.gold.opacity(0.06)
        )
    }

    // MARK: - NPC Avatar

    @ViewBuilder
    private var npcAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )

            Circle()
                .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 2)

            if let imageName = npcImageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: npcFallbackIcon)
                    .font(.system(size: 22))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .frame(width: 48, height: 48)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 4, y: 2)
    }

    // MARK: - Bubble Background

    @ViewBuilder
    private var bubbleBackground: some View {
        RadialGlowBackground(
            baseColor: DarkFantasyTheme.bgSecondary,
            glowColor: DarkFantasyTheme.bgTertiary,
            glowIntensity: 0.3,
            cornerRadius: LayoutConstants.cardRadius
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.05, bottomShadow: 0.08)
    }

    // MARK: - Bubble Border

    @ViewBuilder
    private var bubbleBorder: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
            .stroke(DarkFantasyTheme.gold.opacity(0.15), lineWidth: 1)
    }
}
