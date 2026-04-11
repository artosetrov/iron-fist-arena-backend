import SwiftUI

// MARK: - Contextual Hint Bar

/// Compact inline hint bar shown on repeat visits — replaces NPCCompactHintView.
/// Uses category-based icon + accent color instead of NPC avatar.
///
/// Layout:
/// ┌──────────────────────────────────────────────────┐
/// │  [Icon]  Label text              [CTA]  [✕]     │
/// │          Sublabel (optional)                      │
/// └──────────────────────────────────────────────────┘
struct ContextualHintBar: View {
    let hint: NPCHint
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Category icon — colored rounded square
            categoryIcon

            // Text content
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                if let compactText = hint.compactText {
                    Text(compactText)
                        .font(DarkFantasyTheme.body.weight(.medium))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                }

                if let sublabel = hint.compactSublabel {
                    Text(sublabel)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // CTA button (if applicable)
            if let ctaLabel = hint.ctaLabel, let action = onAction {
                Button(action: action) {
                    Text(ctaLabel)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .buttonStyle(.compactOutline(color: hint.category.accentColor))
            }

            // Dismiss ✕
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                .contentShape(Rectangle())
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
                .stroke(hint.category.accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Category Icon

    @ViewBuilder
    private var categoryIcon: some View {
        if let assetName = hint.iconAsset {
            // Rounded square asset thumbnail (e.g. boss portrait for dungeon hints)
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(hint.category.accentColor.opacity(0.15))
                    .frame(
                        width: LayoutConstants.iconXL,
                        height: LayoutConstants.iconXL
                    )

                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(
                        width: LayoutConstants.iconXL,
                        height: LayoutConstants.iconXL
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(hint.category.accentColor.opacity(0.35), lineWidth: 1)
            )
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(hint.category.accentColor.opacity(0.15))
                    .frame(
                        width: LayoutConstants.iconXL,
                        height: LayoutConstants.iconXL
                    )

                Image(systemName: hint.category.sfSymbol)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(hint.category.accentColor)
            }
        }
    }
}
