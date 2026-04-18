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
    var typewriterEnabled: Bool = true
    var typewriterSpeed: Double = 0.03

    @State private var typewriterText: String = ""
    @State private var typewriterTask: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            // NPC Avatar
            npcAvatar

            // Dialog
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(npcName.uppercased())
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(0.5)

                ZStack(alignment: .topLeading) {
                    // Hidden full text — reserves layout height so bubble doesn't grow
                    Text(message)
                        .font(.custom("Inter-Regular", size: 18))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(typewriterEnabled ? 0 : 1)

                    if typewriterEnabled {
                        Text(typewriterText)
                            .font(.custom("Inter-Regular", size: 18))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .id(messageId)
                .transition(.opacity)
                .onAppear {
                    if typewriterEnabled { startTypewriter() }
                }
                .onChange(of: message) { _, _ in
                    if typewriterEnabled { startTypewriter() }
                }
                .onDisappear {
                    typewriterTask?.cancel()
                    typewriterTask = nil
                }
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

    // MARK: - Typewriter

    private func startTypewriter() {
        typewriterText = ""
        let chars = Array(message)
        let speed = typewriterSpeed
        typewriterTask?.cancel()
        typewriterTask = Task { @MainActor in
            for char in chars {
                try? await Task.sleep(for: .seconds(speed))
                guard !Task.isCancelled else { return }
                typewriterText.append(char)
            }
        }
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
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
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
