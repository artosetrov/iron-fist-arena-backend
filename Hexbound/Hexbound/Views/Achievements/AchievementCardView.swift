import SwiftUI

struct AchievementCardView: View {
    let achievement: Achievement
    let isClaiming: Bool
    let onClaim: () -> Void

    @State private var showClaimBurst = false
    @State private var isPressed = false

    // MARK: - Accent color based on state

    private var accentColor: Color {
        if achievement.rewardClaimed { return DarkFantasyTheme.success }
        if achievement.canClaim { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.borderMedium
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Category icon — game asset, not emoji (C2 fix)
            categoryIconView
                .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(achievement.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(
                        achievement.rewardClaimed ? DarkFantasyTheme.textSecondary
                        : achievement.canClaim ? DarkFantasyTheme.goldBright
                        : DarkFantasyTheme.textPrimary
                    )

                Text(achievement.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary) // H3 fix: was textTertiary (2.8:1 contrast)
                    .lineLimit(2)

                // Progress bar with BarFillHighlight (M1 fix)
                HStack(spacing: LayoutConstants.spaceSM) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(DarkFantasyTheme.bgTertiary)
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(achievement.completed ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                                .frame(width: geo.size.width * max(0, min(1, achievement.progressFraction)))
                                .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        }
                    }
                    .frame(height: 6)

                    Text("\(achievement.formattedProgress)/\(achievement.formattedTarget)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .monospacedDigit()
                        .frame(width: 60, alignment: .trailing)
                }

                // Reward display — CurrencyDisplay component (H2 fix)
                rewardRow
            }

            Spacer()

            // Claim button (L1 fix: removed duplicate HapticManager call)
            if achievement.canClaim {
                Button(action: {
                    showClaimBurst = true
                    onClaim()
                }) {
                    if isClaiming {
                        ProgressView().tint(DarkFantasyTheme.textOnGold).scaleEffect(0.8)
                    } else {
                        Text("Claim")
                    }
                }
                .buttonStyle(.compactPrimary)
                .disabled(isClaiming)
            }
        }
        .padding(LayoutConstants.spaceSM)
        // H1 fix: Ornamental system — RadialGlowBackground + surfaceLighting + innerBorder + cornerBrackets + shadow
        .background(
            RadialGlowBackground(
                baseColor: achievement.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: achievement.rewardClaimed ? 0.2 : 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: accentColor.opacity(achievement.canClaim ? 0.15 : 0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    achievement.rewardClaimed ? DarkFantasyTheme.success.opacity(0.2)
                    : achievement.canClaim ? DarkFantasyTheme.gold.opacity(0.4)
                    : DarkFantasyTheme.borderSubtle,
                    lineWidth: achievement.canClaim ? 2 : 1
                )
        )
        .cornerBrackets(
            color: accentColor.opacity(achievement.canClaim ? 0.4 : 0.2),
            length: 14,
            thickness: 1.5
        )
        // H5 fix: no .opacity(0.6) — use muted colors instead for claimed cards
        .brightness(isPressed ? -0.06 : 0) // M5 fix: press state
        // Dual shadow (design system rule)
        .shadow(color: achievement.canClaim ? DarkFantasyTheme.goldGlow : Color.clear, radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .overlay {
            if showClaimBurst {
                GeometryReader { geo in
                    RewardBurstView(
                        style: .gold,
                        isActive: $showClaimBurst
                    )
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(false)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Category Icon (C2 fix: SF Symbol with themed circle instead of emoji)

    @ViewBuilder
    private var categoryIconView: some View {
        let (iconName, iconColor) = achievement.categoryAsset
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }

    // MARK: - Reward Row (H2 fix: CurrencyDisplay instead of raw text)

    @ViewBuilder
    private var rewardRow: some View {
        if achievement.rewardClaimed {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DarkFantasyTheme.success)
                Text("Claimed")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        } else if let reward = achievement.reward {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text("Reward:")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                if let gold = reward.gold, gold > 0 {
                    CurrencyDisplay(gold: gold, size: .mini, currencyType: .gold, animated: false)
                }
                if let gems = reward.gems, gems > 0 {
                    CurrencyDisplay(gold: 0, gems: gems, size: .mini, currencyType: .gems, animated: false)
                }
                if let title = reward.title {
                    Text("Title: \(title)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                if let frame = reward.frame {
                    Text("Frame: \(frame)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [achievement.title, achievement.description]
        parts.append("Progress: \(achievement.progress) of \(achievement.target)")
        if achievement.canClaim { parts.append("Ready to claim") }
        if achievement.rewardClaimed { parts.append("Already claimed") }
        return parts.joined(separator: ". ")
    }
}
