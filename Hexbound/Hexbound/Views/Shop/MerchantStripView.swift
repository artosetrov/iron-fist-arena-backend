import SwiftUI

// MARK: - DEPRECATED — Use NPCGuideWidget instead

/// **DEPRECATED**: Use `NPCGuideWidget` from `Views/Components/NPCGuideWidget.swift`.
/// This file is kept temporarily for reference. All call sites have been migrated.
@available(*, deprecated, renamed: "NPCGuideWidget", message: "Use NPCGuideWidget instead")
struct MerchantStripView: View {
    @Bindable var tipProvider: MerchantTipProvider
    let onCollapse: () -> Void
    let onDismiss: () -> Void
    var npcImageName: String = "shopkeeper"

    @State private var avatarBounce = false

    var body: some View {
        // Full-width bottom area: avatar bottom-left, bubble overlaid
        ZStack(alignment: .bottomLeading) {
            // Layer 1 (back): NPC image, bottom-left, peeks out behind card
            HStack(alignment: .bottom) {
                npcAvatar
                    .offset(y: LayoutConstants.npcAvatarOffset)
                Spacer()
            }

            // Layer 2 (front): speech card widget
            speechCard
        }
    }

    // MARK: - Speech Card (widget style, equal padding)

    @ViewBuilder
    private var speechCard: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MERCHANT")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(tipProvider.currentTip.attributedText)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(3)
                    .id(tipProvider.currentTip)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.scalePress(0.85))
        }
        .padding(.horizontal, LayoutConstants.npcBarPaddingH)
        .padding(.vertical, LayoutConstants.npcBarPaddingV)
        .frame(height: LayoutConstants.npcBarHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius)
                .fill(DarkFantasyTheme.bgElevated.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius)
                .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius))
        .onTapGesture {
            tipProvider.nextTip()
        }
    }

    // MARK: - NPC Avatar (peeks out behind card, bottom-left)

    @ViewBuilder
    private var npcAvatar: some View {
        Button {
            avatarBounce = true
            tipProvider.nextTip()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                avatarBounce = false
            }
        } label: {
            Group {
                if UIImage(named: npcImageName) != nil {
                    Image(npcImageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(
                width: LayoutConstants.npcAvatarSize,
                height: LayoutConstants.npcAvatarSize
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Speech Bubble (overlays on shopkeeper)

    @ViewBuilder
    private var speechBubble: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MERCHANT")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text(tipProvider.currentTip.attributedText)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(3)
                    .id(tipProvider.currentTip)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.scalePress(0.85))
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.merchantBubbleRadius)
                .fill(DarkFantasyTheme.bgElevated.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.merchantBubbleRadius)
                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
    }
}

// MARK: - DEPRECATED — Use NPCMiniButton instead

/// **DEPRECATED**: Use `NPCMiniButton` from `Views/Components/NPCGuideWidget.swift`.
@available(*, deprecated, renamed: "NPCMiniButton", message: "Use NPCMiniButton instead")
struct MerchantMiniButton: View {
    let onTap: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: onTap) {
            Group {
                if UIImage(named: "shopkeeper") != nil {
                    Image("shopkeeper")
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(
                width: LayoutConstants.merchantMiniSize,
                height: LayoutConstants.merchantMiniSize
            )
            .clipShape(Circle())
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.bgCardGradientStart, DarkFantasyTheme.bgTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 3)
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.goldGlow.opacity(0.5), radius: 10)
        }
        .buttonStyle(.plain)
        .offset(y: bouncing ? -3 : 0)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                bouncing = true
            }
        }
    }
}
