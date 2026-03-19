import SwiftUI

// MARK: - Merchant Strip (Fixed Bottom — Shop Only)

/// Fixed bottom bar with merchant avatar (overflows upward) + speech bubble with contextual tips.
/// Avatar: 64pt, extends 28pt above strip border. Tap avatar → next tip.
/// Collapsible (mini floating avatar) and dismissible (hidden until next session).
struct MerchantStripView: View {
    @Bindable var tipProvider: MerchantTipProvider
    let onCollapse: () -> Void
    let onDismiss: () -> Void

    @State private var avatarBounce = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background strip
            HStack(spacing: LayoutConstants.spaceMS) {
                // Spacer for avatar area
                Spacer()
                    .frame(width: LayoutConstants.merchantAvatarSize + LayoutConstants.spaceSM)

                // Speech bubble
                VStack(alignment: .leading, spacing: 2) {
                    Text("MERCHANT")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text(tipProvider.currentTip.attributedText)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                        .id(tipProvider.currentTip) // force re-render on tip change
                        .transition(.opacity)
                }
                .padding(.horizontal, LayoutConstants.spaceMS)
                .padding(.vertical, LayoutConstants.spaceSM)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.merchantBubbleRadius)
                        .fill(DarkFantasyTheme.bgElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.merchantBubbleRadius)
                        .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                )

                // Action buttons (collapse / dismiss)
                VStack(spacing: 2) {
                    Button {
                        onCollapse()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.scalePress(0.85))

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.scalePress(0.85))
                }
            }
            .padding(.vertical, 10)
            .padding(.leading, LayoutConstants.spaceMS)
            .padding(.trailing, LayoutConstants.screenPadding)
            .background(
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgSecondary.opacity(0.95),
                        DarkFantasyTheme.bgPrimary.opacity(0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(DarkFantasyTheme.borderOrnament)
                    .frame(height: 1)
            }

            // Avatar — overflows upward beyond strip
            merchantAvatar
                .offset(
                    x: LayoutConstants.spaceMS,
                    y: -LayoutConstants.merchantAvatarOverflow
                )
                .zIndex(1)
        }
    }

    // MARK: - Merchant Avatar

    @ViewBuilder
    private var merchantAvatar: some View {
        Button {
            // Bounce + next tip
            avatarBounce = true
            tipProvider.nextTip()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                avatarBounce = false
            }
        } label: {
            Group {
                if UIImage(named: "avatar_knight") != nil {
                    Image("avatar_knight")
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(
                width: LayoutConstants.merchantAvatarSize,
                height: LayoutConstants.merchantAvatarSize
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
            // Outer glow ring
            .overlay(
                Circle()
                    .stroke(DarkFantasyTheme.gold.opacity(0.15), lineWidth: 1)
                    .padding(-4)
            )
            .shadow(color: DarkFantasyTheme.goldGlow, radius: 12)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(avatarBounce ? 1.15 : 1)
        .animation(.easeOut(duration: 0.2), value: avatarBounce)
    }
}

// MARK: - Merchant Mini Button (Collapsed State)

/// Floating avatar button shown when merchant strip is collapsed.
/// Subtle bounce animation to indicate interactivity.
struct MerchantMiniButton: View {
    let onTap: () -> Void

    @State private var bouncing = false

    var body: some View {
        Button(action: onTap) {
            Group {
                if UIImage(named: "avatar_knight") != nil {
                    Image("avatar_knight")
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
            .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
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
