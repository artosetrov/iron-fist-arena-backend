import SwiftUI

/// Compact banner showing the current NPC tutorial quest on the Hub.
/// Displays quest title, NPC message, progress bar, and CTA button.
/// Tapping navigates to the relevant building/screen.
struct TutorialQuestBanner: View {
    let questId: String
    let title: String
    let npcMessage: String
    let progress: Int
    let target: Int
    let isCompleted: Bool
    let rewardClaimed: Bool
    let onTap: () -> Void
    let onClaim: () -> Void

    @State private var isExpanded = true

    private var progressFraction: CGFloat {
        guard target > 0 else { return 0 }
        return min(CGFloat(progress) / CGFloat(target), 1.0)
    }

    var body: some View {
        if rewardClaimed { EmptyView() } else {
            VStack(spacing: 0) {
                // Header — always visible
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        // NPC avatar
                        Image("shopkeeper")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                            Text(title.uppercased())
                                .font(DarkFantasyTheme.uiLabel)
                                .foregroundStyle(DarkFantasyTheme.gold)

                            if !isExpanded {
                                // Compact progress
                                Text("\(progress)/\(target)")
                                    .font(DarkFantasyTheme.caption)
                                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                            }
                        }

                        Spacer()

                        // Chevron
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.vertical, LayoutConstants.spaceSM)
                }
                .buttonStyle(.plain)

                // Expanded content
                if isExpanded {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        // NPC message
                        Text(npcMessage)
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, LayoutConstants.spaceMD)

                        // Progress bar
                        HStack(spacing: LayoutConstants.spaceSM) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Track
                                    Capsule()
                                        .fill(DarkFantasyTheme.bgDarkPanel)
                                        .frame(height: 6)

                                    // Fill
                                    Capsule()
                                        .fill(
                                            isCompleted
                                                ? DarkFantasyTheme.success
                                                : DarkFantasyTheme.gold
                                        )
                                        .frame(width: geo.size.width * progressFraction, height: 6)
                                        .animation(.easeOut(duration: 0.3), value: progress)
                                }
                            }
                            .frame(height: 6)

                            Text("\(progress)/\(target)")
                                .font(DarkFantasyTheme.badge)
                                .foregroundStyle(
                                    isCompleted
                                        ? DarkFantasyTheme.success
                                        : DarkFantasyTheme.textSecondary
                                )
                                .frame(width: 32, alignment: .trailing)
                        }
                        .padding(.horizontal, LayoutConstants.spaceMD)

                        // Action button
                        if isCompleted && !rewardClaimed {
                            Button {
                                HapticManager.success()
                                SFXManager.shared.play(.uiRewardClaim)
                                onClaim()
                            } label: {
                                Text("ЗАБРАТЬ НАГРАДУ")
                                    .font(DarkFantasyTheme.buttonLabelCompact)
                                    .textCase(.uppercase)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, LayoutConstants.spaceMD)
                        } else if !isCompleted {
                            Button {
                                HapticManager.selection()
                                SFXManager.shared.play(.uiTap)
                                onTap()
                            } label: {
                                Text("ПЕРЕЙТИ")
                                    .font(DarkFantasyTheme.buttonLabelCompact)
                                    .textCase(.uppercase)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, LayoutConstants.spaceMD)
                        }
                    }
                    .padding(.bottom, LayoutConstants.spaceSM)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(DarkFantasyTheme.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(DarkFantasyTheme.gold.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
