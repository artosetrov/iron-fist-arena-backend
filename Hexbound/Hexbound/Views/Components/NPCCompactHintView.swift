import SwiftUI

// MARK: - NPC Compact Hint View

/// Compact inline hint widget shown on repeat visits when a contextual action is available.
/// Replaces the tiny ActiveQuestBanner-style widget with a proper readable display.
///
/// Layout:
/// ┌──────────────────────────────────────────────┐
/// │  [NPC Icon]  Compact hint text    [ACTION →] │
/// └──────────────────────────────────────────────┘
struct NPCCompactHintView: View {
    let hint: NPCHint
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // NPC avatar (small)
            Image(hint.npcImage)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                )

            // Compact text
            if let compactText = hint.compactText {
                Text(compactText)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            // CTA button (if applicable)
            if let ctaLabel = hint.ctaLabel, let action = onAction {
                Button(action: action) {
                    Text(ctaLabel)
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            Capsule().fill(DarkFantasyTheme.gold)
                        )
                }
                .buttonStyle(.plain)
            }

            // Dismiss X
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
