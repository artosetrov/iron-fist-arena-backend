import SwiftUI

extension GuildHallDetailView {
    // MARK: - Scrolls Tab (Messages)

    @ViewBuilder
    func scrollsTab(_ vm: GuildHallViewModel) -> some View {
        if vm.activeThreadCharacterId != nil {
            threadView(vm)
        } else {
            conversationsList(vm)
        }
    }

    @ViewBuilder
    func conversationsList(_ vm: GuildHallViewModel) -> some View {
        // Cache-first: show cached conversations immediately, skeleton only when empty
        if vm.conversations.isEmpty && (vm.scrollsLoadState == .idle || vm.scrollsLoadState == .loading) {
            VStack(spacing: LayoutConstants.sectionGap) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonConversationCard()
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        } else if vm.conversations.isEmpty, case .error = vm.scrollsLoadState {
            VStack(spacing: LayoutConstants.spaceMD) {
                ErrorStateView(
                    message: "Failed to load scrolls",
                    retryAction: { Task { await vm.loadConversations() } }
                )
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        } else if vm.conversations.isEmpty && vm.scrollsLoadState == .loaded {
            scrollsEmptyState
        } else {
            ForEach(vm.conversations) { convo in
                conversationRow(convo, vm: vm)
                    .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
    }

    func conversationRow(_ convo: Conversation, vm: GuildHallViewModel) -> some View {
        let hasUnread = convo.unreadCount > 0

        return Button {
            Task {
                await vm.openThread(
                    characterId: convo.otherCharacter.id,
                    characterName: convo.otherCharacter.characterName,
                    avatar: convo.otherCharacter.avatar,
                    characterClass: convo.otherCharacter.characterClass
                )
            }
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Avatar — use real skin asset if available, otherwise letter fallback
                if let avatarKey = convo.otherCharacter.avatar {
                    AvatarImageView(
                        skinKey: avatarKey,
                        characterClass: convo.otherCharacter.classEnum,
                        size: 40
                    )
                } else {
                    characterAvatar(
                        name: convo.otherCharacter.characterName,
                        className: convo.otherCharacter.characterClass
                    )
                }

                // Info
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    HStack {
                        Text(convo.otherCharacter.characterName)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        if hasUnread {
                            Text("\(convo.unreadCount)")
                                .font(DarkFantasyTheme.body.weight(.semibold))
                                .foregroundStyle(DarkFantasyTheme.textOnGold)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .padding(.vertical, LayoutConstants.space2XS)
                                .background(DarkFantasyTheme.gold)
                                .clipShape(Capsule())
                        }
                    }

                    Text(convo.lastMessage.content)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(hasUnread ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: hasUnread ? DarkFantasyTheme.gold.opacity(0.04) : DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: (hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium).opacity(hasUnread ? 0.1 : 0.15))
            .cornerBrackets(color: (hasUnread ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium).opacity(0.3), length: 10, thickness: 1)
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    var scrollsEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "scroll.fill")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.textTertiary)

            Text("No Scrolls Yet")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)

            Text("Send a message to an ally from their profile.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, LayoutConstants.space2XL)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Thread View (ChatGPT-style)

    @ViewBuilder
    func threadView(_ vm: GuildHallViewModel) -> some View {
        VStack(spacing: 0) {
            // Thread header — sticky top bar
            threadHeader(vm)

            // Relationship stats banner
            if let stats = vm.relationshipStats {
                relationshipBanner(stats)
            }

            // Messages area — opens instantly, messages load in background
            if case .error = vm.threadLoadState {
                Spacer()
                VStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.danger)
                    Text("Failed to load messages")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Button("Retry") {
                        if let targetId = vm.activeThreadCharacterId,
                           let name = vm.activeThreadCharacterName {
                            Task { await vm.openThread(characterId: targetId, characterName: name, avatar: vm.activeThreadCharacterAvatar, characterClass: vm.activeThreadCharacterClass) }
                        }
                    }
                    .buttonStyle(.primary)
                }
                Spacer()
            } else if vm.activeThread.isEmpty && !vm.isLoadingThreadMessages {
                Spacer()
                threadEmptyState
                Spacer()
            } else if vm.activeThread.isEmpty && vm.isLoadingThreadMessages {
                // Loading state — show centered spinner only when no messages yet
                Spacer()
                VStack(spacing: LayoutConstants.spaceSM) {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.gold)
                    Text("Loading messages...")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: LayoutConstants.spaceSM) {
                            if !vm.activeThread.isEmpty {
                                dateDivider("Today")
                            }

                            // Backend returns ASC order (oldest→newest) — no reverse needed
                            ForEach(vm.activeThread) { msg in
                                messageBubble(msg, vm: vm)
                                    .id(msg.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.top, LayoutConstants.spaceSM)
                        .padding(.bottom, LayoutConstants.spaceSM)
                    }
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: vm.activeThread.count) { _, _ in
                        // Auto-scroll to newest message
                        if let lastId = vm.activeThread.last?.id {
                            withAnimation(MotionConstants.snappy) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Quick replies — sticky above compose bar
            quickReplyChips(vm)

            // Compose bar — sticky bottom
            threadBottomBar(vm)
        }
        .onAppear {
            // Auto-focus compose field with short delay for keyboard animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isComposeFieldFocused = true
            }
            // Start polling for new incoming messages every 5 seconds
            vm.startThreadPolling()
        }
        .onDisappear {
            vm.stopThreadPolling()
        }
    }

    func threadHeader(_ vm: GuildHallViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Back button — unified HubLogoButton with custom action
            HubLogoButton {
                if openMessageTo != nil {
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    }
                } else {
                    vm.closeThread()
                }
            }

            Spacer()

            // Character name — centered, large Oswald title
            Text(vm.activeThreadCharacterName ?? "Unknown")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .lineLimit(1)

            Spacer()

            // Character avatar — tappable, opens profile sheet
            Button {
                guard let charId = vm.activeThreadCharacterId,
                      let charName = vm.activeThreadCharacterName else { return }
                HapticManager.light()
                appState.mainPath.append(AppRoute.characterProfile(
                    characterId: charId,
                    characterName: charName
                ))
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let avatar = vm.activeThreadCharacterAvatar {
                        AvatarImageView(
                            skinKey: avatar,
                            characterClass: CharacterClass(rawValue: vm.activeThreadCharacterClass ?? "warrior") ?? .warrior,
                            size: 48
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                .stroke(DarkFantasyTheme.goldDim, lineWidth: 2)
                        )
                    } else {
                        characterAvatar(
                            name: vm.activeThreadCharacterName ?? "?",
                            className: nil
                        )
                    }

                    // Online indicator
                    Circle()
                        .fill(DarkFantasyTheme.success)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(DarkFantasyTheme.bgSecondary, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            LinearGradient(
                colors: [DarkFantasyTheme.bgTertiary.opacity(0.95), DarkFantasyTheme.bgSecondary.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            // Surface lighting — top highlight
            Rectangle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.04), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: LayoutConstants.spaceLG)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            // Gold divider line
            Rectangle()
                .fill(LinearGradient(colors: [.clear, DarkFantasyTheme.goldDim, .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
    }

    func relationshipBanner(_ stats: RelationshipStats) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Friendship status pill
            let friendLabel = friendshipLabel(stats.friendshipStatus)
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: friendLabel.icon)
                    .font(DarkFantasyTheme.caption)
                Text(friendLabel.text)
                    .font(DarkFantasyTheme.caption)
            }
            .foregroundStyle(friendLabel.color)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule()
                    .fill(friendLabel.color.opacity(0.12))
            )

            // PvP stats (only if they've fought)
            if stats.pvp.totalBattles > 0 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("\(stats.pvp.totalBattles) battles")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text("·")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text("\(stats.pvp.wins)W")
                        .font(DarkFantasyTheme.caption.bold())
                        .foregroundStyle(DarkFantasyTheme.success)

                    Text("-")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)

                    Text("\(stats.pvp.losses)L")
                        .font(DarkFantasyTheme.caption.bold())
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            } else {
                Text("No battles yet")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgTertiary.opacity(0.5))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle.opacity(0.2))
                .frame(height: 0.5)
        }
    }

    func friendshipLabel(_ status: String) -> (text: String, icon: String, color: Color) {
        switch status {
        case "accepted":
            return ("Allies", "person.2.fill", DarkFantasyTheme.success)
        case "pending_sent":
            return ("Request Sent", "hourglass", DarkFantasyTheme.gold)
        case "pending_received":
            return ("Wants to be Allies", "person.badge.plus", DarkFantasyTheme.gold)
        case "blocked":
            return ("Blocked", "nosign", DarkFantasyTheme.danger)
        default:
            return ("Stranger", "person.slash", DarkFantasyTheme.textTertiary)
        }
    }

    var threadEmptyState: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.5))

            Text("Start the conversation")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Text("Send a quick message or write your own scroll.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, LayoutConstants.space2XL)
    }

    func messageBubble(_ msg: DirectMessageItem, vm: GuildHallViewModel) -> some View {
        let isMine = msg.senderId == appState.currentCharacter?.id
        let quickMsg = msg.isQuick ? QuickMessage(rawValue: msg.quickId ?? "") : nil

        return HStack(alignment: .bottom, spacing: LayoutConstants.spaceXS) {
            if isMine { Spacer(minLength: 32) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: LayoutConstants.spaceXS) {
                // Quick message: icon + text
                if let quick = quickMsg {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: quick.icon)
                            .font(DarkFantasyTheme.section)
                            .foregroundStyle(isMine ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.gold)
                        Text(msg.content)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(isMine ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)
                    }
                } else {
                    Text(msg.content)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(isMine ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)
                }

                // Timestamp + delivery status
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isMine {
                        messageStatusView(msg)
                    } else {
                        Text(formatMessageTime(msg.createdAt))
                            .font(DarkFantasyTheme.body.weight(.semibold))
                            .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background {
                if isMine {
                    ChatBubbleShape(isMine: true)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            // Surface lighting on gold bubble
                            ChatBubbleShape(isMine: true)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                } else {
                    ChatBubbleShape(isMine: false)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay {
                            // Inner bevel on received bubble
                            ChatBubbleShape(isMine: false)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.03), .clear, Color.black.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay {
                            ChatBubbleShape(isMine: false)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        }
                }
            }
            .shadow(color: isMine ? DarkFantasyTheme.gold.opacity(0.12) : Color.clear, radius: 6)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)

            if !isMine { Spacer(minLength: 32) }
        }
    }

    // MARK: - Date Divider

    func dateDivider(_ text: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.borderSubtle],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(text.uppercased())
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.borderSubtle, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    // MARK: - Quick Reply Chips

    func quickReplyChips(_ vm: GuildHallViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(QuickMessage.allCases, id: \.rawValue) { quick in
                    Button {
                        Task { await vm.sendQuickMessage(quick.rawValue) }
                    } label: {
                        Text(quick.displayText)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.gold)
                            .padding(.horizontal, LayoutConstants.spaceMD)
                            .padding(.vertical, LayoutConstants.spaceSM + 2)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.bgTertiary)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(DarkFantasyTheme.goldDim, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isSendingMessage)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
        }
        .background(DarkFantasyTheme.bgSecondary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DarkFantasyTheme.borderSubtle.opacity(0.3))
                .frame(height: 0.5)
        }
    }

    func threadBottomBar(_ vm: GuildHallViewModel) -> some View {
        let isEmpty = vm.composedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: LayoutConstants.spaceSM) {
            TextField("Write a scroll...", text: Binding(
                get: { vm.composedMessage },
                set: { vm.composedMessage = $0 }
            ))
            .focused($isComposeFieldFocused)
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.bgTertiary)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isComposeFieldFocused ? DarkFantasyTheme.goldDim.opacity(0.6) : DarkFantasyTheme.borderSubtle.opacity(0.5),
                        lineWidth: 1
                    )
            )

            Button {
                Task { await vm.sendMessage() }
            } label: {
                ZStack {
                    Image(systemName: "arrow.up")
                        .font(DarkFantasyTheme.section.bold())
                        .foregroundStyle(
                            isEmpty ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.textOnGold
                        )
                }
                .frame(width: 52, height: 52)
                .background {
                    if isEmpty {
                        Circle()
                            .fill(DarkFantasyTheme.bgTertiary)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.08), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                            }
                    }
                }
                .shadow(color: isEmpty ? .clear : DarkFantasyTheme.gold.opacity(0.3), radius: 8)
                .shadow(color: isEmpty ? .clear : DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 4, y: 2)
            }
            .buttonStyle(SendButtonPressStyle())
            .disabled(isEmpty)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .padding(.bottom, LayoutConstants.spaceLG)
        .background(DarkFantasyTheme.bgSecondary.opacity(0.95))
    }

    /// Status indicator for sent messages: Sending… → Sent → Read
    @ViewBuilder
    func messageStatusView(_ msg: DirectMessageItem) -> some View {
        let isSending = msg.id.hasPrefix("temp-")
        let statusColor = DarkFantasyTheme.textOnGold.opacity(isSending ? 0.4 : (msg.isRead ? 0.7 : 0.5))

        HStack(spacing: LayoutConstants.space2XS) {
            if isSending {
                // Sending… — animated clock icon
                Image(systemName: "clock")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.5))
                    .symbolEffect(.pulse.byLayer)
                Text("Sending…")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.4))
            } else {
                Text(formatMessageTime(msg.createdAt))
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(statusColor)

                if msg.isRead {
                    // Read — double checkmark
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.7))
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.7))
                        .offset(x: -4)
                } else {
                    // Sent — single checkmark
                    Image(systemName: "checkmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.4))
                }
            }
        }
        .animation(MotionConstants.smooth, value: isSending)
        .animation(MotionConstants.smooth, value: msg.isRead)
    }

    func formatMessageTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else { return "" }
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "Just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h ago" }
        return "\(Int(elapsed / 86400))d ago"
    }

}

// MARK: - Chat Bubble Shape

/// A rounded rectangle with a small tail on the bottom-left or bottom-right,
/// similar to iMessage / ChatGPT message bubbles.
struct ChatBubbleShape: Shape {
    let isMine: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isMine {
            // Tail on bottom-right
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY, width: rect.width - tailSize / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail
            path.move(to: CGPoint(x: rect.maxX - tailSize - radius / 2, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control1: CGPoint(x: rect.maxX - tailSize + 2, y: rect.maxY),
                control2: CGPoint(x: rect.maxX - 2, y: rect.maxY + tailSize / 2)
            )
            path.addCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - 4),
                control1: CGPoint(x: rect.maxX, y: rect.maxY - 2),
                control2: CGPoint(x: rect.maxX - tailSize + 2, y: rect.maxY - 2)
            )
        } else {
            // Tail on bottom-left
            path.addRoundedRect(
                in: CGRect(x: rect.minX + tailSize / 2, y: rect.minY, width: rect.width - tailSize / 2, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
            // Tail
            path.move(to: CGPoint(x: rect.minX + tailSize + radius / 2, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY),
                control1: CGPoint(x: rect.minX + tailSize - 2, y: rect.maxY),
                control2: CGPoint(x: rect.minX + 2, y: rect.maxY + tailSize / 2)
            )
            path.addCurve(
                to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - 4),
                control1: CGPoint(x: rect.minX, y: rect.maxY - 2),
                control2: CGPoint(x: rect.minX + tailSize - 2, y: rect.maxY - 2)
            )
        }

        return path
    }
}

// MARK: - Send Button Press Style

/// Brightness-based press feedback for the send button (per design rules — brightness(-0.06), not scale)
struct SendButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
