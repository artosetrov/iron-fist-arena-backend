import SwiftUI

struct AchievementCardView: View {
    let achievement: Achievement
    let isClaiming: Bool
    let onClaim: () -> Void

    @State private var showClaimBurst = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Category icon
            Text(achievement.categoryIcon)
                .font(.system(size: 28)) // emoji text — keep as is
                .frame(width: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(
                        achievement.rewardClaimed ? DarkFantasyTheme.textTertiary
                        : achievement.canClaim ? DarkFantasyTheme.goldBright
                        : DarkFantasyTheme.textPrimary
                    )

                Text(achievement.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(2)

                // Progress bar
                HStack(spacing: LayoutConstants.spaceSM) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DarkFantasyTheme.bgTertiary)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(achievement.completed ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                                .frame(width: geo.size.width * max(0, min(1, achievement.progressFraction)))
                        }
                    }
                    .frame(height: 6)

                    Text("\(achievement.progress)/\(achievement.target)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 50, alignment: .trailing)
                }

                // Reward text
                if achievement.rewardClaimed {
                    Text("Claimed")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.success)
                } else if !achievement.rewardText.isEmpty {
                    Text("Reward: \(achievement.rewardText)")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Claim button
            if achievement.canClaim {
                Button(action: {
                    HapticManager.success()
                    showClaimBurst = true
                    onClaim()
                }) {
                    if isClaiming {
                        ProgressView().tint(DarkFantasyTheme.textOnGold).scaleEffect(0.8)
                    } else {
                        Text("Claim")
                    }
                }
                .frame(width: 72, height: LayoutConstants.touchMin)
                .buttonStyle(.compactPrimary)
                .disabled(isClaiming)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(achievement.rewardClaimed ? DarkFantasyTheme.bgPrimary : DarkFantasyTheme.bgSecondary)
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
        .opacity(achievement.rewardClaimed ? 0.6 : 1.0)
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
    }
}
