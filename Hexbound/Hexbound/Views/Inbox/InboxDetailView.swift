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
                OrnamentalTitle("MESSAGES", subtitle: unreadSubtitle)
                    .padding(.top, LayoutConstants.spaceXS)
                    .padding(.bottom, LayoutConstants.spaceXS)

                // Tab switcher — matches Guild Hall style
                TabSwitcher(
                    tabs: InboxFilter.allCases.map(\.rawValue),
                    selectedIndex: Binding(
                        get: { InboxFilter.allCases.firstIndex(of: viewModel.selectedFilter) ?? 0 },
                        set: { viewModel.selectedFilter = InboxFilter.allCases[$0] }
                    )
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceSM)

                // Unified content
                unifiedContent

                if let error = viewModel.error {
                    ErrorBanner(message: error) {
                        Task { await viewModel.fetchAll(characterId: characterId) }
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
        }
        .task {
            await viewModel.fetchAll(characterId: characterId)
        }
    }

    // MARK: - Unified Content

    private var unifiedContent: some View {
        Group {
            if viewModel.isLoading && viewModel.isLoadingScrolls && viewModel.unifiedItems.isEmpty {
                loadingState
            } else if viewModel.filteredItems.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(viewModel.filteredItems) { item in
                            switch item {
                            case .mail(let message):
                                InboxRowView(
                                    message: message,
                                    viewModel: viewModel,
                                    characterId: characterId
                                )
                            case .conversation(let conversation):
                                InboxConversationRow(conversation: conversation)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticManager.light()
                                        appState.mainPath.append(
                                            AppRoute.guildHallMessage(
                                                characterId: conversation.otherCharacter.id,
                                                characterName: conversation.otherCharacter.characterName,
                                                avatar: conversation.otherCharacter.avatar,
                                                characterClass: conversation.otherCharacter.characterClass
                                            )
                                        )
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.top, LayoutConstants.spaceSM)
                    .padding(.bottom, LayoutConstants.spaceLG)
                }
                .refreshable {
                    await viewModel.fetchAll(characterId: characterId)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
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

                Image(systemName: emptyStateIcon)
                    .font(DarkFantasyTheme.title.weight(.light))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text(emptyStateTitle)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text(emptyStateSubtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceLG)
            }
        }
        .padding(.vertical, LayoutConstants.space2XL)
    }

    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case .all: return "tray"
        case .battles: return "shield.slash"
        case .messages: return "scroll"
        case .system: return "bell.slash"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .all: return "NO MESSAGES"
        case .battles: return "NO BATTLES"
        case .messages: return "NO SCROLLS"
        case .system: return "NO SYSTEM MAIL"
        }
    }

    private var emptyStateSubtitle: String {
        switch viewModel.selectedFilter {
        case .all: return "Your inbox is empty.\nCheck back later for rewards and messages."
        case .battles: return "No battle reports yet.\nFight in the Arena to receive them."
        case .messages: return "No player messages yet.\nVisit the Guild Hall to find allies."
        case .system: return "No system notifications.\nCheck back later."
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

    /// Badge value: unread count if any, otherwise total message count
    private var badgeCount: Int? {
        if conversation.unreadCount > 0 {
            return conversation.unreadCount
        }
        if let total = conversation.messageCount, total > 0 {
            return total
        }
        return nil
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar — real hero portrait via AvatarImageView
            avatarView

            // Name + last message + timestamp
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(conversation.otherCharacter.characterName)
                        .font(hasUnread ? DarkFantasyTheme.cardTitle : DarkFantasyTheme.body)
                        .foregroundStyle(
                            hasUnread ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary
                        )
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(formatDate(conversation.lastMessage.createdAt))
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(
                            hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.textTertiary
                        )
                }

                HStack(spacing: LayoutConstants.spaceSM) {
                    Text(conversation.lastMessage.content)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(
                            hasUnread ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary
                        )
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    // Badge: unread (gold) or total count (subtle)
                    if let count = badgeCount {
                        Text(count > 99 ? "99+" : "\(count)")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(hasUnread ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textSecondary)
                            .padding(.horizontal, LayoutConstants.spaceSM)
                            .padding(.vertical, LayoutConstants.space2XS)
                            .background(
                                Capsule()
                                    .fill(hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.bgTertiary)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        hasUnread ? DarkFantasyTheme.goldBright.opacity(0.4) : DarkFantasyTheme.borderSubtle,
                                        lineWidth: hasUnread ? 0 : 0.5
                                    )
                            )
                            .shadow(color: hasUnread ? DarkFantasyTheme.gold.opacity(0.4) : .clear, radius: 4)
                    }
                }
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceMS)
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
            length: 10, thickness: 1)
        .compositingGroup()
        .cardShadow()
        .brightness(isPressed ? -0.06 : 0)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - Avatar

    private var avatarView: some View {
        ZStack(alignment: .topTrailing) {
            if let avatar = conversation.otherCharacter.avatar, !avatar.isEmpty {
                AvatarImageView(
                    skinKey: avatar,
                    characterClass: conversation.otherCharacter.classEnum,
                    size: 44
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(
                            hasUnread ? DarkFantasyTheme.goldDim.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                            lineWidth: 1.5
                        )
                )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(
                                    hasUnread ? DarkFantasyTheme.goldDim.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                                    lineWidth: 1.5
                                )
                        )

                    Text(String(conversation.otherCharacter.characterName.prefix(1)).uppercased())
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
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
                    .offset(x: 3, y: -3)
            }
        }
        .frame(width: 44, height: 44)
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
                    .font(DarkFantasyTheme.title.weight(.light))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("NO MAIL")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("Your mailbox is empty.\nCheck back later for rewards and messages.")
                    .font(DarkFantasyTheme.body)
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
                    .font(DarkFantasyTheme.title.weight(.light))
                    .foregroundStyle(DarkFantasyTheme.goldDim)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("NO SCROLLS")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("No player messages yet.\nVisit the Guild Hall to find allies.")
                    .font(DarkFantasyTheme.body)
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
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
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
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(2)

            Spacer()

            if let onRetry {
                Button("Retry") { onRetry() }
                    .buttonStyle(.plain)
                    .font(DarkFantasyTheme.body)
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
