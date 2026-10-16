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

                // Tab switcher — matches Guild Hall style; unread count per tab
                TabSwitcher(
                    tabs: InboxFilter.allCases.map(\.rawValue),
                    selectedIndex: Binding(
                        get: { InboxFilter.allCases.firstIndex(of: viewModel.selectedFilter) ?? 0 },
                        set: { viewModel.selectedFilter = InboxFilter.allCases[$0] }
                    ),
                    badges: InboxFilter.allCases.map { filter -> Int? in viewModel.unreadCount(for: filter) },
                    badgeStyle: .count
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.tabSwitcherPaddingV)

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
                // Scrollable so pull-to-refresh works on an empty tab too,
                // and the scene never clips at large text sizes.
                GeometryReader { geo in
                    ScrollView {
                        emptyState
                            .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                    .refreshable {
                        await viewModel.fetchAll(characterId: characterId)
                    }
                }
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
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityHint("Opens the conversation")
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

    // MARK: - Empty States
    //
    // Illustrated scenes (Assets.xcassets/EmptyStates, prompts in
    // docs/08_prompts/EMPTY_STATE_ICONS_PROMPTS.md). Each one says what lands
    // in this tab, then gives one way to make something land there.
    // Facts: backend/src/lib/game/battle-mail.ts — every PvP fight (arena,
    // revenge, duel) mails a report to both fighters; a duel challenge mails
    // the defender. Game Master mail comes from admin/src/actions/mail.ts.

    @ViewBuilder
    private var emptyState: some View {
        switch viewModel.selectedFilter {
        case .all:
            EmptyStateScene(
                art: "empty-inbox",
                title: "No mail yet",
                message: "Battle reports, letters from other warriors and gifts from the Game Master all arrive here.",
                actionLabel: "Fight in the Arena",
                action: openArena
            )
        case .battles:
            EmptyStateScene(
                art: "empty-battles",
                title: "No battle reports yet",
                message: "Every Arena fight and duel sends you a report: the result, rating change, gold and XP. Duel challenges land here too.",
                actionLabel: "Fight in the Arena",
                action: openArena
            )
        case .messages:
            if canBrowseWarriors {
                EmptyStateScene(
                    art: "empty-scrolls",
                    title: "No scrolls yet",
                    message: "Scrolls are private letters between warriors. Open anyone's profile and tap Message — they don't have to be your ally.",
                    actionLabel: "Find a Warrior",
                    action: { appState.mainPath.append(AppRoute.leaderboard) }
                )
            } else {
                // Leaderboard opens at level 8 — until then, opponents are the
                // warriors you meet, and every battle report has a Message button.
                EmptyStateScene(
                    art: "empty-scrolls",
                    title: "No scrolls yet",
                    message: "Scrolls are private letters between warriors. Write to any opponent straight from their battle report.",
                    actionLabel: "Fight in the Arena",
                    action: openArena
                )
            }
        case .system:
            EmptyStateScene(
                art: "empty-system",
                title: "No news yet",
                message: "Gifts and announcements from the Game Master arrive here. Rewards wait inside the letter until you claim them.",
                actionLabel: "See Daily Quests",
                action: { appState.mainPath.append(AppRoute.dailyQuests) }
            )
        }
    }

    /// The leaderboard ("ranks" building) is the place to browse warriors.
    private var canBrowseWarriors: Bool {
        BuildingUnlockConfig.isUnlocked("ranks", characterLevel: appState.currentCharacter?.level ?? 1)
    }

    private func openArena() {
        appState.mainPath.append(AppRoute.arena)
    }

    // MARK: - Helpers

    private var unreadSubtitle: String? {
        guard viewModel.totalUnreadCount > 0 else { return nil }
        return "\(viewModel.totalUnreadCount) unread"
    }

    private var loadingState: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Skeleton cards — same rhythm as the real list
            ForEach(0..<4, id: \.self) { _ in
                SkeletonMailRow()
            }
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceSM)
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
        HStack(spacing: LayoutConstants.spaceMS) {
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

                    Spacer(minLength: LayoutConstants.spaceXS)

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

                    Spacer(minLength: LayoutConstants.spaceXS)

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
                            .accessibilityLabel(hasUnread ? "\(count) unread" : "\(count) letters")
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
                // No portrait yet — the warrior's class crest, not a letter.
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(conversation.otherCharacter.classEnum.iconAsset)
                            .resizable()
                            .scaledToFit()
                            .padding(LayoutConstants.spaceXS)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(
                                hasUnread ? DarkFantasyTheme.goldDim.opacity(0.5) : DarkFantasyTheme.borderSubtle,
                                lineWidth: 1.5
                            )
                    )
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
        .accessibilityHidden(true)
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
        HStack(spacing: LayoutConstants.spaceMS) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: 44, height: 44)

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
        .accessibilityHidden(true)
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
                .accessibilityHidden(true)

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
                    .frame(minHeight: LayoutConstants.touchMin)
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
