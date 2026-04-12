import SwiftUI

struct BPRewardNodeView: View {
    let reward: BPReward
    let state: BPRewardState
    let onClaim: () -> Void

    @State private var showClaimBurst = false

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Level
            Text("Lv.\(reward.level)")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            // Unified item card — same component as shop/inventory/loot
            ItemCardView(bpReward: reward, state: state) {
                onClaim()
            }
            .frame(width: 80, height: 80)
            .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: state == .claimable)
            .overlay {
                if showClaimBurst {
                    RewardBurstView(style: burstStyleForReward, isActive: $showClaimBurst)
                        .allowsHitTesting(false)
                }
            }

            // Name + amount
            if reward.amount > 1 {
                Text("\(reward.rewardName) x\(reward.amount)")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
            } else {
                Text(reward.rewardName)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
            }

            // Status
            switch state {
            case .locked:
                Text(reward.track == "premium" ? "Premium" : "Locked")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            case .claimable:
                Button {
                    onClaim()
                } label: {
                    Text("Claim")
                }
                .buttonStyle(.compactPrimary)
            case .claimed:
                Text("Claimed")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .frame(width: 90)
        .onChange(of: state) { oldState, newState in
            if oldState == .claimable && newState == .claimed {
                showClaimBurst = true
            }
        }
    }

    private var burstStyleForReward: BurstStyle {
        switch reward.rewardType {
        case "skin": .epic
        case "chest": .legendary
        case "gems": .rare
        default: .claim
        }
    }
}
