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

    /// Size of the inline asset thumbnail when `iconAsset` is set.
    /// Intentionally larger than `icon2XL` (48) so the illustration reads
    /// clearly as the hint's visual anchor — no framed background.
    private let assetIconSize: CGFloat = 56

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Icon slot — iconAsset hints render the asset inline (no frame,
            // no background box). Category hints fall back to an SF symbol
            // thumbnail with a tinted rounded square.
            iconSlot

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
    }

    // MARK: - Icon Slot

    @ViewBuilder
    private var iconSlot: some View {
        if let assetName = hint.iconAsset {
            // Inline, frameless asset thumbnail. No background box, no stroke,
            // no peek-portrait — just the illustration, sized larger than the
            // default iconXL slot so it reads as the hint's visual anchor.
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: assetIconSize, height: assetIconSize)
        } else {
            // Category SF symbol thumbnail (no peek portrait for these)
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
