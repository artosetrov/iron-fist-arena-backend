import SwiftUI

struct InboxDetailView: View {
    @State private var viewModel = InboxViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) private var appState

    private var characterId: String {
        appState.currentCharacter?.id ?? ""
    }

    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Ornamental title — sticky above scroll
                OrnamentalTitle("MAIL", subtitle: unreadSubtitle)
                    .padding(.top, LayoutConstants.spaceXS)

                // Content
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    loadingState
                } else if viewModel.messages.isEmpty {
                    EmptyMailState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: LayoutConstants.spaceSM) {
                            ForEach(viewModel.messages) { message in
                                InboxRowView(
                                    message: message,
                                    viewModel: viewModel,
                                    characterId: characterId
                                )
                            }
                        }
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.top, LayoutConstants.spaceSM)
                        .padding(.bottom, LayoutConstants.spaceLG)
                    }
                    .refreshable {
                        await viewModel.fetchInbox(characterId: characterId)
                    }
                }

                if let error = viewModel.error {
                    ErrorBanner(message: error) {
                        Task { await viewModel.fetchInbox(characterId: characterId) }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceSM)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.gold)

                    Text("MAIL")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    if viewModel.unreadCount > 0 {
                        UnreadBadge(count: viewModel.unreadCount)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchInbox(characterId: characterId)
        }
    }

    // MARK: - Helpers

    private var unreadSubtitle: String? {
        guard viewModel.unreadCount > 0 else { return nil }
        return "\(viewModel.unreadCount) unread"
    }

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            // Skeleton cards
            ForEach(0..<4, id: \.self) { _ in
                SkeletonMailRow()
            }
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Skeleton Mail Row

private struct SkeletonMailRow: View {
    @State private var shimmer = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(width: 160, height: 14)

                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(width: 100, height: 12)
            }

            Spacer()

            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 50, height: 12)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .opacity(shimmer ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .onDisappear {
            shimmer = false
        }
    }
}

// MARK: - Empty State

private struct EmptyMailState: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            // Envelope icon with ornamental frame
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                DarkFantasyTheme.bgTertiary,
                                DarkFantasyTheme.bgSecondary,
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "envelope.open")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("NO SCROLLS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("Your mailbox is empty.\nCheck back later for rewards and messages.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceLG)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Unread Badge

private struct UnreadBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(DarkFantasyTheme.section(size: 11))
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.gold)
            )
            .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 4)
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            if let onRetry {
                Button("Retry") { onRetry() }
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.gold)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.danger.opacity(0.1),
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radiusMD
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.radiusMD)
        .innerBorder(cornerRadius: LayoutConstants.radiusMD - 2, inset: 2, color: DarkFantasyTheme.danger.opacity(0.1))
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 4, y: 2)
    }
}

#Preview {
    InboxDetailView()
}
