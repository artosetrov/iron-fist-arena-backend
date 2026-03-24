import SwiftUI

struct BPRewardNodeView: View {
    let reward: BPReward
    let state: BPRewardState
    let isClaiming: Bool
    let onClaim: () -> Void

    @State private var showClaimBurst = false

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

                rewardIcon(reward, size: 32)
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(borderColor, lineWidth: state == .claimable ? 2 : 1)
            )
            .opacity(state == .locked ? 0.5 : 1)
            .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: state == .claimable)
            .overlay {
                if showClaimBurst {
                    RewardBurstView(style: burstStyleForReward, isActive: $showClaimBurst)
                        .allowsHitTesting(false)
                }
            }

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
                Button {
                    HapticManager.medium()
                    onClaim()
                } label: {
                    if isClaiming {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                            .scaleEffect(0.7)
                    } else {
                        Text("Claim")
                    }
                }
                .buttonStyle(.compactPrimary)
            case .claimed:
                Text("Claimed")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .frame(width: 90)
        .onChange(of: state) { oldState, newState in
            if oldState == .claimable && newState == .claimed {
                HapticManager.success()
                showClaimBurst = true
            }
        }
    }

    @ViewBuilder
    private func rewardIcon(_ reward: BPReward, size: CGFloat) -> some View {
        if let assetName = reward.assetIcon, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(reward.icon)
                .font(.system(size: size * 0.875))
        }
    }

    private var borderColor: Color {
        switch state {
        case .claimable: DarkFantasyTheme.goldBright
        case .claimed: DarkFantasyTheme.success.opacity(0.5)
        case .locked: DarkFantasyTheme.borderSubtle
        }
    }

    private var burstStyleForReward: BurstStyle {
        // Rarity-aware burst: rare/epic/legendary for special rewards, claim for normal
        switch reward.rewardType {
        case "skin": .epic
        case "chest": .legendary
        case "gems": .rare
        default: .claim
        }
    }
}
