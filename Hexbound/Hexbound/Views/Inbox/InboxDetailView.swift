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

                // Tab Switcher — sticky
                TabSwitcher(
                    tabs: InboxViewModel.Tab.allCases.map(\.rawValue),
                    selectedIndex: Binding(
                        get: { InboxViewModel.Tab.allCases.firstIndex(of: viewModel.selectedTab) ?? 0 },
                        set: { newValue in
                            viewModel.selectedTab = InboxViewModel.Tab.allCases[newValue]
                        }
                    )
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceSM)

                // Content by tab
                switch viewModel.selectedTab {
                case .mail:
                    mailTabContent
                case .scrolls:
                    scrollsTabContent
                }

                if let error = viewModel.error, viewModel.selectedTab == .mail {
                    ErrorBanner(message: error) {
                        Task { await viewModel.fetchInbox(characterId: characterId) }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceSM)
                }

                if let error = viewModel.scrollsError, viewModel.selectedTab == .scrolls {
                    ErrorBanner(message: error) {
                        Task { await viewModel.loadConversations(characterId: characterId) }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceSM)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
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

                    if viewModel.totalUnreadCount > 0 {
                        UnreadBadge(count: viewModel.totalUnreadCount)
                    }
                }
            }
        }
        .task {
            // Fetch both in parallel
            async let mailTask: () = viewModel.fetchInbox(characterId: characterId)
            async let scrollsTask: () = viewModel.loadConversations(characterId: characterId)
            _ = await (mailTask, scrollsTask)
        }
    }

    // MARK: - Mail Tab

    private var mailTabContent: some View {
        Group {
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
        }
    }

    // MARK: - Scrolls Tab (Player Conversations)

    private var scrollsTabContent: some View {
        Group {
            if viewModel.isLoadingScrolls && viewModel.conversations.isEmpty {
                loadingState
            } else if viewModel.conversations.isEmpty {
                EmptyScrollsState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(viewModel.conversations) { conversation in
                            InboxConversationRow(conversation: conversation)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.light()
                                    // Navigate to Guild Hall message thread via deep-link
                                    appState.mainPath.append(
                                        AppRoute.guildHallMessage(
                                            characterId: conversation.otherCharacter.id,
                                            characterName: conversation.otherCharacter.characterName
                                        )
                                    )
                                }
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceLG)
                }
                .refreshable {
                    await viewModel.loadConversations(characterId: characterId)
                }
            }
        }
    }

    // MARK: - Helpers

    private var unreadSubtitle: String? {
        guard viewModel.totalUnreadCount > 0 else { return nil }
        return "\(viewModel.totalUnreadCount) unread"
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

// MARK: - Conversation Row (for Scrolls tab)

private struct InboxConversationRow: View {
    let conversation: Conversation
    @State private var isPressed = false

    private var hasUnread: Bool {
        conversation.unreadCount > 0
    }

    private var accentColor: Color {
        hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Avatar
            avatarView

            // Name + last message + timestamp
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(conversation.otherCharacter.characterName)
                        .font(DarkFantasyTheme.section(
                            size: hasUnread ? LayoutConstants.textCard : LayoutConstants.textBody
                        ))
                        .foregroundStyle(
                            hasUnread ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary
                        )
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(formatDate(conversation.lastMessage.createdAt))
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(conversation.lastMessage.content)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(
                            hasUnread ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary
                        )
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if hasUnread {
                        Text("\(conversation.unreadCount)")
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

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, 14)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: hasUnread ? accentColor.opacity(0.06) : DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(
            cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2, inset: 2,
            color: hasUnread
                ? accentColor.opacity(0.12)
                : DarkFantasyTheme.borderMedium.opacity(0.15)
        )
        .cornerBrackets(
            color: accentColor.opacity(0.3),
            length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .brightness(isPressed ? -0.06 : 0)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - Avatar

    private var avatarView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)

            if let avatar = conversation.otherCharacter.avatar, !avatar.isEmpty {
                Image(avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM - 2))
            } else {
                Text(String(conversation.otherCharacter.characterName.prefix(1)).uppercased())
                    .font(DarkFantasyTheme.section(size: 16))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            // Unread dot
            if hasUnread {
                Circle()
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(DarkFantasyTheme.bgSecondary, lineWidth: 2)
                    )
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 4)
                    .offset(x: 16, y: -16)
            }
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let date else { return dateString }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
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

// MARK: - Empty State (Mail)

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
                Text("NO MAIL")
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

// MARK: - Empty State (Scrolls)

private struct EmptyScrollsState: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
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

                Image(systemName: "scroll")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("NO SCROLLS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("No player messages yet.\nVisit the Guild Hall to find allies.")
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
