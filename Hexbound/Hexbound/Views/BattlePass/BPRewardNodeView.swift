import SwiftUI

struct BPRewardNodeView: View {
    let reward: BPReward
    let state: BPRewardState
    let isClaiming: Bool
    let onClaim: () -> Void

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Level
            Text("Lv.\(reward.level)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Icon frame
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(width: 64, height: 64)

                Text(reward.icon)
                    .font(.system(size: 28)) // emoji text — keep as is
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(borderColor, lineWidth: state == .claimable ? 2 : 1)
            )
            .opacity(state == .locked ? 0.5 : 1)

            // Name + amount
            Text(reward.rewardName)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            if reward.amount > 1 {
                Text("x\(reward.amount)")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }

            // Status
            switch state {
            case .locked:
                Text(reward.track == "premium" ? "Premium" : "Locked")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            case .claimable:
                Button(action: onClaim) {
                    if isClaiming {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                            .scaleEffect(0.7)
                    } else {
                        Text("Claim")
                    }
                }
                .frame(width: 70, height: 36)
                .buttonStyle(.compactPrimary)
            case .claimed:
                Text("Claimed")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .frame(width: 90)
    }

    private var borderColor: Color {
        switch state {
        case .claimable: DarkFantasyTheme.goldBright
        case .claimed: DarkFantasyTheme.success.opacity(0.5)
        case .locked: DarkFantasyTheme.borderSubtle
        }
    }
}
