import SwiftUI

/// Layer 3 — Celebration Banner for milestone events (Level Up, Achievement, Rank Up, Quest, Rare Drop).
/// Appears below navigation bar, does NOT overlap back button. Separate system from toasts.
struct CelebrationBannerOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack {
            if let banner = appState.celebrationBanner {
                CelebrationBannerView(banner: banner) {
                    appState.dismissCelebration()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .padding(.top, 94) // Below status bar (50) + nav bar (44)
        .animation(MotionConstants.spring, value: appState.celebrationBanner?.id)
    }
}

struct CelebrationBannerView: View {
    let banner: CelebrationBanner
    let onDismiss: () -> Void

    @State private var iconPulse: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(banner.type.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(banner.type.color.opacity(iconPulse ? 0.1 : 0.0))
                    .frame(width: 44, height: 44)

                Image(systemName: banner.type.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(banner.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(banner.type.color)
                    .lineLimit(1)

                if !banner.subtitle.isEmpty {
                    Text(banner.subtitle)
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(
            ZStack {
                // Gradient background: celebration color → transparent
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                banner.type.color.opacity(0.18),
                                banner.type.color.opacity(0.06),
                                DarkFantasyTheme.bgPrimary.opacity(0.95)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Bottom border glow
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [banner.type.color.opacity(0.5), banner.type.color.opacity(0.1), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }
            }
        )
        .shadow(color: banner.type.color.opacity(0.2), radius: 8, y: 2)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        .onTapGesture {
            onDismiss()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                iconPulse = true
            }
        }
        .onDisappear {
            iconPulse = false
        }
        .accessibilityLabel("\(banner.title): \(banner.subtitle)")
        .accessibilityAddTraits(.updatesFrequently)
    }
}
