import SwiftUI

/// Full-page opponent profile — replaces LeaderboardPlayerDetailSheet modal.
/// Pushed via AppRoute.characterProfile onto the NavigationStack.
/// Shows portrait+equipment card, action buttons with new friend UX, PvP stats, and stats.
struct CharacterProfileView: View {
    let characterId: String
    let characterName: String

    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var profile: OpponentProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Friendship state
    @State private var friendshipState: FriendshipButtonState = .none
    @State private var isFriendActionLoading = false

    // Challenge state
    @State private var isSendingChallenge = false
    @State private var challengeSent = false

    // Friend chip animation
    @State private var showFriendChip = false

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if let profile {
                profilePage(profile)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text(characterName)
                    .font(DarkFantasyTheme.section(size: 18))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            await loadProfile()
        }
        .transaction { $0.animation = nil }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ProgressView()
                .tint(DarkFantasyTheme.gold)
                .scaleEffect(1.3)
            Text("Загрузка профиля...")
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(DarkFantasyTheme.danger)

            Text(message)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("Повторить") { Task { await loadProfile() } }
                .buttonStyle(.primary)
        }
        .padding(LayoutConstants.screenPadding)
    }

    // MARK: - Main Page

    private func profilePage(_ profile: OpponentProfile) -> some View {
        ScrollView {
            VStack(spacing: LayoutConstants.spaceMD) {
                // Portrait + equipment grid
                OpponentIntegratedCard(profile: profile)

                // Friend status chip — appears below card when request sent or is friend
                friendStatusRow

                // Action buttons
                actionButtons

                // PvP stats
                pvpSection(profile)

                GoldDivider()

                // Base stats with player comparison
                baseStatsSection(profile)

                GoldDivider()

                // Derived stats
                derivedStatsSection(profile)

                Spacer(minLength: LayoutConstants.spaceLG)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMD)
            .padding(.bottom, LayoutConstants.spaceLG)
        }
    }

    // MARK: - Friend Status Row (new UX)

    @ViewBuilder
    private var friendStatusRow: some View {
        switch friendshipState {
        case .requestSent:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 11))
                Text("Запрос отправлен")
                    .font(DarkFantasyTheme.badge.bold())
            }
            .foregroundStyle(DarkFantasyTheme.gold)
            .padding(.horizontal, LayoutConstants.spaceSM + 2)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.gold.opacity(0.1))
                    .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))
            )
            .opacity(showFriendChip ? 1 : 0)
            .scaleEffect(showFriendChip ? 1 : 0.85)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showFriendChip)
            .frame(maxWidth: .infinity, alignment: .leading)

        case .requestReceived:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 11))
                Text("Хочет стать союзником")
                    .font(DarkFantasyTheme.badge.bold())
            }
            .foregroundStyle(DarkFantasyTheme.success)
            .padding(.horizontal, LayoutConstants.spaceSM + 2)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.success.opacity(0.1))
                    .overlay(Capsule().stroke(DarkFantasyTheme.success.opacity(0.3), lineWidth: 1))
            )
            .frame(maxWidth: .infinity, alignment: .leading)

        case .friends:
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11))
                Text("Союзник")
                    .font(DarkFantasyTheme.badge.bold())
            }
            .foregroundStyle(DarkFantasyTheme.success)
            .padding(.horizontal, LayoutConstants.spaceSM + 2)
            .padding(.vertical, LayoutConstants.spaceXS)
            .background(
                Capsule()
                    .fill(DarkFantasyTheme.success.opacity(0.1))
                    .overlay(Capsule().stroke(DarkFantasyTheme.success.opacity(0.3), lineWidth: 1))
            )
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            EmptyView()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Row 1: Challenge (full width)
            Button { Task { await sendChallenge() } } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    if isSendingChallenge {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else if challengeSent {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Вызов отправлен")
                    } else {
                        Image(systemName: "flame.fill")
                        Text("Вызвать")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(isSendingChallenge || challengeSent)

            // Row 2: Message + dynamic friend button
            HStack(spacing: LayoutConstants.spaceSM) {
                // Message always present
                Button(action: navigateToMessage) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "bubble.left.fill")
                        Text("Сообщение")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)

                // Friend button — changes shape by state
                friendActionButton
            }
        }
    }

    @ViewBuilder
    private var friendActionButton: some View {
        switch friendshipState {
        case .none:
            Button { Task { await sendFriendRequest() } } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isFriendActionLoading {
                        ProgressView().tint(DarkFantasyTheme.textPrimary)
                    } else {
                        Image(systemName: "person.badge.plus")
                    }
                    Text("Союзник")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .disabled(isFriendActionLoading)

        case .requestSent:
            // Button disappears — chip shows above
            EmptyView()

        case .requestReceived:
            Button { Task { await acceptFriendRequest() } } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    if isFriendActionLoading {
                        ProgressView().tint(DarkFantasyTheme.textOnGold)
                    } else {
                        Image(systemName: "checkmark")
                    }
                    Text("Принять")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(isFriendActionLoading)

        case .friends:
            // Show ··· context menu (remove/block)
            Menu {
                Button(role: .destructive) {
                    Task { await removeFriend() }
                } label: {
                    Label("Удалить из союзников", systemImage: "person.badge.minus")
                }
            } label: {
                Text("···")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 52, height: 44)
            }
            .buttonStyle(.neutral)

        case .blocked, .blockedBy:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "hand.raised.fill")
                    Text("Блок")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)

        case .maxReached:
            Button {} label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                    Text("Список полон")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.neutral)
            .disabled(true)
        }
    }

    // MARK: - PvP Section

    private func pvpSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("PVP СТАТИСТИКА")

            HStack(spacing: 0) {
                pvpStatCell(label: "Рейтинг", value: "\(profile.pvpRating)", color: DarkFantasyTheme.gold)
                pvpDivider
                pvpStatCell(label: "Статистика", value: "\(profile.pvpWins)П / \(profile.pvpLosses)П", color: DarkFantasyTheme.textPrimary)
                pvpDivider
                pvpStatCell(
                    label: "Победы",
                    value: profile.pvpWins + profile.pvpLosses > 0
                        ? String(format: "%.0f%%", profile.winRate * 100) : "—",
                    color: profile.winRate >= 0.5 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
                )
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.2,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        }
    }

    private func pvpStatCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            Text(value)
                .font(DarkFantasyTheme.section(size: 15))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var pvpDivider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderSubtle)
            .frame(width: 1, height: 36)
    }

    // MARK: - Base Stats

    private func baseStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(StatGroup.allCases, id: \.self) { group in
                VStack(spacing: LayoutConstants.spaceSM) {
                    statGroupHeader(group.rawValue)
                    ForEach(group.stats, id: \.self) { stat in
                        opponentStatCell(
                            stat,
                            value: profile.statValue(for: stat),
                            playerValue: playerStatValue(for: stat)
                        )
                    }
                }
            }
        }
    }

    private func playerStatValue(for stat: StatType) -> Int {
        guard let c = appState.currentCharacter else { return 0 }
        switch stat {
        case .strength:     return c.strength ?? 0
        case .agility:      return c.agility ?? 0
        case .vitality:     return c.vitality ?? 0
        case .endurance:    return c.endurance ?? 0
        case .intelligence: return c.intelligence ?? 0
        case .wisdom:       return c.wisdom ?? 0
        case .luck:         return c.luck ?? 0
        case .charisma:     return c.charisma ?? 0
        }
    }

    @ViewBuilder
    private func opponentStatCell(_ stat: StatType, value: Int, playerValue: Int) -> some View {
        let color = DarkFantasyTheme.statColor(for: stat.rawValue)
        let delta = value - playerValue

        HStack(spacing: LayoutConstants.spaceXS) {
            Image(stat.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)

            Text(stat.fullName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .lineLimit(1)

            Spacer(minLength: 4)

            if delta != 0 {
                let deltaColor = delta > 0 ? DarkFantasyTheme.danger : DarkFantasyTheme.success
                let arrow = delta > 0 ? "▲" : "▼"
                let label = delta > 0 ? "\(arrow)+\(delta)" : "\(arrow)\(delta)"

                Text(label)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                    .foregroundStyle(deltaColor)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(deltaColor.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                    .stroke(deltaColor.opacity(0.4), lineWidth: 1)
                            )
                    )
            }

            Text("\(value)")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .padding(LayoutConstants.spaceSM + 2)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius).stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1.5)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    @ViewBuilder
    private func statGroupHeader(_ label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, DarkFantasyTheme.goldDim.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
            }

            Text(label)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.gold.opacity(0.6))
                .lineLimit(1)
                .fixedSize()

            HStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.goldDim.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(LinearGradient(colors: [DarkFantasyTheme.goldDim.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
            }
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Derived Stats

    private func derivedStatsSection(_ profile: OpponentProfile) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            sectionHeader("ПРОИЗВОДНЫЕ СТАТЫ")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LayoutConstants.spaceSM) {
                derivedRow("Атака", value: "\(profile.attackPower) \(profile.damageTypeName)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Броня", value: "\(profile.armor ?? 0)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Маг. защита", value: "\(profile.magicResist ?? 0)", color: DarkFantasyTheme.statBarFill)
                derivedRow("Крит", value: String(format: "%.1f%%", profile.critChance), color: DarkFantasyTheme.statBarFill)
                derivedRow("Уклонение", value: String(format: "%.1f%%", profile.dodgeChance), color: DarkFantasyTheme.statBarFill)
            }
        }
    }

    @ViewBuilder
    private func derivedRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Spacer()
            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary.opacity(0.5),
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.2,
                cornerRadius: LayoutConstants.radiusSM
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.radiusSM - 1, inset: 1, color: DarkFantasyTheme.borderMedium.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func navigateToMessage() {
        appState.mainPath.append(AppRoute.guildHallMessage(
            characterId: characterId,
            characterName: characterName
        ))
    }

    private func sendFriendRequest() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isFriendActionLoading = true
        let errorMsg = await SocialService.shared.sendFriendRequest(
            characterId: charId,
            targetId: characterId
        )
        isFriendActionLoading = false

        if errorMsg == nil {
            // New UX: transition to chip instead of keeping button
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                friendshipState = .requestSent
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showFriendChip = true
                }
            }
            SFXManager.shared.play(.uiConfirm)
            HapticManager.success()
            appState.showToast("Запрос отправлен", subtitle: "\(characterName) получит уведомление", type: .info)
        } else {
            HapticManager.error()
            let reason: String
            switch errorMsg {
            case "Already friends or request pending":
                reason = "Запрос уже отправлен"
                friendshipState = .requestSent
                showFriendChip = true
            case "Friend list full":
                reason = "Список союзников полон (макс. 50)"
                friendshipState = .maxReached
            case "Cannot send request":
                reason = "Этот игрок недоступен"
            case "Too many requests today":
                reason = "Лимит запросов на сегодня (20/день)"
            case "Cooldown active":
                reason = "Подождите 24ч перед повторной отправкой"
            default:
                reason = errorMsg ?? "Что-то пошло не так"
            }
            appState.showToast("Не удалось отправить запрос", subtitle: reason, type: .error)
        }
    }

    private func acceptFriendRequest() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isFriendActionLoading = true
        let success = await SocialService.shared.acceptFriendRequest(
            characterId: charId,
            requesterId: characterId
        )
        isFriendActionLoading = false
        if success {
            withAnimation { friendshipState = .friends }
            showFriendChip = true
        }
    }

    private func removeFriend() async {
        guard let charId = appState.currentCharacter?.id else { return }
        _ = await SocialService.shared.removeFriend(characterId: charId, friendId: characterId)
        withAnimation { friendshipState = .none }
        showFriendChip = false
    }

    private func sendChallenge() async {
        guard let charId = appState.currentCharacter?.id else { return }
        isSendingChallenge = true

        do {
            _ = try await ChallengeService.shared.sendChallenge(
                characterId: charId,
                targetId: characterId,
                message: nil
            )
            challengeSent = true
            SFXManager.shared.play(.uiConfirm)
            appState.showToast("Вызов отправлен", subtitle: "\(characterName) — 24ч на ответ", type: .info)
        } catch {
            appState.showToast(
                "Не удалось отправить вызов",
                subtitle: "Попробуйте позже",
                type: .error,
                actionLabel: "Повторить",
                action: { Task { await sendChallenge() } }
            )
        }
        isSendingChallenge = false
    }

    // MARK: - Data Loading

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: OpponentProfileResponse = try await APIClient.shared.get(
                APIEndpoints.characterProfile(characterId)
            )
            profile = response.profile
        } catch {
            errorMessage = "Не удалось загрузить профиль"
        }

        isLoading = false

        // Fetch friendship status in parallel
        if let charId = appState.currentCharacter?.id {
            let state = await SocialService.shared.getFriendshipStatus(
                characterId: charId,
                targetId: characterId
            )
            friendshipState = state
            // Show chip immediately if already in relationship state
            if state == .requestSent || state == .friends || state == .requestReceived {
                showFriendChip = true
            }
        }
    }
}
