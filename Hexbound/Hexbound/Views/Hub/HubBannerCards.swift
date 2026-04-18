import SwiftUI

// MARK: - First Win Bonus Card

struct FirstWinBonusCard: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            SFXManager.shared.play(.uiTap)
            HapticManager.medium()
            appState.mainPath.append(AppRoute.arena)
        } label: {
            VStack(spacing: LayoutConstants.spaceSM) {
                // Title row
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("reward-first-win")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)

                    Text("FIRST WIN BONUS")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                }

                // Reward pills row
                HStack(spacing: LayoutConstants.spaceSM) {
                    // Gold reward pill
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-gold")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        Text("×2 Gold")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(DarkFantasyTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))

                    // XP reward pill
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("icon-xp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        Text("×2 XP")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(DarkFantasyTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1))

                    Spacer()
                }
            }
            .padding(LayoutConstants.bannerPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
            )
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.6), length: 14, thickness: 1.5)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.5), size: 5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
            .glowPulse(color: DarkFantasyTheme.gold, intensity: 0.4)
            .shimmer(color: DarkFantasyTheme.gold.opacity(0.3), duration: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Battle Invite Banner

/// Shows on Hub when there are pending incoming PvP challenges.
/// Single invite: shows challenger info + FIGHT / DECLINE buttons.
/// Multiple invites: shows first invite + "N more" counter.
/// Hidden when no pending challenges exist.
struct BattleInviteBanner: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    @State private var isAccepting = false
    @State private var isDeclining = false

    private var challenges: [IncomingChallenge] {
        cache.incomingChallenges
    }

    private var firstChallenge: IncomingChallenge? {
        challenges.first
    }

    var body: some View {
        if let challenge = firstChallenge {
            inviteCard(challenge)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func inviteCard(_ challenge: IncomingChallenge) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Header row
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "swords")
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.btnOrangePrimary)

                Text("BATTLE CHALLENGE")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.btnOrangePrimary)

                Spacer()

                if challenges.count > 1 {
                    Text("+\(challenges.count - 1) more")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            // Challenger info row
            HStack(spacing: LayoutConstants.spaceMD) {
                // Avatar
                if let avatar = challenge.challenger.avatar, !avatar.isEmpty {
                    AvatarImageView(
                        skinKey: avatar,
                        characterClass: challenge.challenger.classEnum,
                        size: 40
                    )
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                } else {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        )
                }

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(challenge.challenger.characterName)
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: LayoutConstants.spaceSM) {
                        Text("Lv.\(challenge.challenger.level)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)

                        Text(challenge.challenger.rankName)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.gold)
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: LayoutConstants.spaceSM) {
                Button {
                    acceptChallenge(challenge)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isAccepting {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textOnGold)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "swords")
                                .font(DarkFantasyTheme.body.bold())
                        }
                        Text("FIGHT")
                            .font(DarkFantasyTheme.body)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .disabled(isAccepting || isDeclining)

                Button {
                    declineChallenge(challenge)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if isDeclining {
                            HexPulseLoader(.compact)
                                .tint(DarkFantasyTheme.textSecondary)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "xmark")
                                .font(DarkFantasyTheme.body.bold())
                        }
                        Text("DECLINE")
                            .font(DarkFantasyTheme.body)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                .disabled(isAccepting || isDeclining)

                // View all button (if multiple)
                if challenges.count > 1 {
                    Button {
                        HapticManager.light()
                        appState.mainPath.append(AppRoute.guildHall)
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(DarkFantasyTheme.body.weight(.semibold))
                    }
                    .buttonStyle(.secondary)
                    .disabled(isAccepting || isDeclining)
                }
            }
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.btnOrangePrimary.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.btnOrangePrimary.opacity(0.5), lineWidth: 1.5)
        )
        .cornerBrackets(color: DarkFantasyTheme.btnOrangePrimary.opacity(0.5), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.btnOrangePrimary.opacity(0.12), radius: 8, y: 2)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)
    }

    // MARK: - Actions

    private func acceptChallenge(_ challenge: IncomingChallenge) {
        guard !isAccepting else { return }

        // Client-side stamina pre-check
        let staminaCost = cache.gameConfig?.pvpStaminaCost ?? AppConstants.pvpStaminaCost
        if (appState.currentCharacter?.currentStamina ?? 0) < staminaCost {
            appState.showToast("Not enough stamina", subtitle: "Wait for regen or use a potion", type: .error)
            return
        }

        isAccepting = true
        HapticManager.heavy()

        Task {
            guard let charId = appState.currentCharacter?.id else {
                isAccepting = false
                return
            }
            do {
                let result = try await ChallengeService.shared.acceptChallenge(
                    characterId: charId,
                    challengeId: challenge.id
                )

                // Build CombatData for playback
                let playerFighter = CombatFighter(
                    id: result.defender.id,
                    characterName: result.defender.characterName,
                    characterClass: CharacterClass(rawValue: result.defender.characterClass) ?? .warrior,
                    origin: CharacterOrigin(rawValue: result.defender.origin ?? "human") ?? .human,
                    level: result.defender.level,
                    maxHp: result.defender.maxHp,
                    currentHp: nil,
                    avatar: result.defender.avatar
                )
                let enemyFighter = CombatFighter(
                    id: result.challenger.id,
                    characterName: result.challenger.characterName,
                    characterClass: CharacterClass(rawValue: result.challenger.characterClass) ?? .warrior,
                    origin: CharacterOrigin(rawValue: result.challenger.origin ?? "human") ?? .human,
                    level: result.challenger.level,
                    maxHp: result.challenger.maxHp,
                    currentHp: nil,
                    avatar: result.challenger.avatar
                )
                let combatResultInfo = CombatResultInfo(
                    isWin: result.won,
                    winnerId: result.winnerId,
                    goldReward: result.goldReward,
                    xpReward: result.xpReward,
                    turnsTaken: result.totalTurns,
                    ratingChange: result.ratingChange,
                    firstWinBonus: nil, leveledUp: nil, newLevel: nil, statPointsAwarded: nil, passivePointsAwarded: nil
                )
                let combatData = CombatData(
                    player: playerFighter, enemy: enemyFighter,
                    combatLog: result.combatLog, result: combatResultInfo,
                    rewards: CombatRewards(gold: result.goldReward, xp: result.xpReward),
                    source: "challenge", matchId: result.matchId
                )

                // Clear combat state + navigate
                appState.combatData = nil
                appState.combatResult = nil
                appState.resolveResult = nil
                appState.pendingLoot = []
                appState.mainPath.append(AppRoute.combat)
                appState.combatData = combatData
                appState.resolveResult = ResolveResult(
                    verified: true, clientMatches: true,
                    serverWinnerId: result.winnerId,
                    goldReward: result.goldReward, xpReward: result.xpReward,
                    ratingChange: result.ratingChange,
                    firstWinBonus: false, leveledUp: false,
                    newLevel: nil, statPointsAwarded: nil, passivePointsAwarded: nil,
                    loot: [],
                    staminaCurrent: appState.currentCharacter?.currentStamina ?? 0,
                    staminaMax: appState.currentCharacter?.maxStamina ?? 180,
                    matchId: result.matchId,
                    durabilityDegraded: [], hpCurrent: nil, hpMax: nil
                )

                // Remove from cache
                cache.cacheIncomingChallenges(
                    cache.incomingChallenges.filter { $0.id != challenge.id }
                )
            } catch let apiError as APIError {
                switch apiError {
                case .serverError(_, let msg):
                    appState.showToast(msg, type: .error)
                default:
                    appState.showToast(apiError.localizedDescription, type: .error)
                }
                HapticManager.error()
            } catch {
                appState.showToast("Failed to start duel", type: .error)
                HapticManager.error()
            }
            isAccepting = false
        }
    }

    private func declineChallenge(_ challenge: IncomingChallenge) {
        guard !isDeclining else { return }
        isDeclining = true
        HapticManager.light()

        // Optimistic: remove from cache
        let savedChallenges = cache.incomingChallenges
        cache.cacheIncomingChallenges(
            cache.incomingChallenges.filter { $0.id != challenge.id }
        )

        Task {
            guard let charId = appState.currentCharacter?.id else {
                isDeclining = false
                return
            }
            do {
                try await ChallengeService.shared.declineChallenge(
                    characterId: charId,
                    challengeId: challenge.id
                )
                appState.showToast("Challenge declined", type: .info)
            } catch {
                // Revert on failure
                cache.cacheIncomingChallenges(savedChallenges)
                appState.showToast("Failed to decline", type: .error)
            }
            isDeclining = false
        }
    }
}

// MARK: - Quest Reward Widget

/// Shows on Hub when there are completed-but-unclaimed daily quests.
/// Single quest: shows title + reward + Claim button.
/// Multiple quests: shows summary "X rewards ready" + Go to Quests button.
/// Hidden when no claimable quests exist.
struct QuestRewardWidget: View {
    @Environment(AppState.self) private var appState

    @State private var claimingId: String?

    private var claimableQuests: [Quest] {
        appState.cachedTypedQuests?.filter(\.canClaim) ?? []
    }

    var body: some View {
        if !claimableQuests.isEmpty {
            questContent()
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.3), value: claimableQuests.count)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func questContent() -> some View {
        if claimableQuests.count == 1, let quest = claimableQuests.first {
            singleQuestCard(quest)
        } else {
            multiQuestCard()
        }
    }

    // MARK: - Single Quest

    private func singleQuestCard(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            AssetPlaceholderView(systemIcon: "scroll.fill")
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(quest.title)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)

                rewardRow(gold: quest.rewardGold, xp: quest.rewardXp, gems: quest.rewardGems)
            }

            Spacer(minLength: 4)

            Button {
                claimQuest(quest)
            } label: {
                if claimingId == quest.id {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textOnGold)
                        .frame(width: 60)
                } else {
                    Text("Claim")
                        .frame(minWidth: 60)
                }
            }
            .buttonStyle(.compactPrimary)
            .disabled(claimingId != nil)
        }
        .modifier(QuestRewardCardStyle(accentColor: DarkFantasyTheme.cyan))
    }

    // MARK: - Multiple Quests

    private func multiQuestCard() -> some View {
        Button {
            SFXManager.shared.play(.uiTap)
            HapticManager.medium()
            appState.mainPath.append(AppRoute.dailyQuests)
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image("hud-daily-quests")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("\(claimableQuests.count) REWARDS READY")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text("Tap to claim your quest rewards")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .modifier(QuestRewardCardStyle(accentColor: DarkFantasyTheme.gold))
    }

    // MARK: - Reward Pills

    private func rewardRow(gold: Int, xp: Int, gems: Int?) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(gold)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            if xp > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-xp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(xp)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.cyan)
                }
            }
            if let gems, gems > 0 {
                HStack(spacing: LayoutConstants.space2XS) {
                    Image("icon-gems")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(gems)")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.purple)
                }
            }
        }
    }

    // MARK: - Claim Logic

    private func claimQuest(_ quest: Quest) {
        claimingId = quest.id

        let questId = quest.id
        let previousLevel = appState.currentCharacter?.level
        Task {
            let service = QuestService(appState: appState)
            let result = await service.claimQuest(questId: questId)
            claimingId = nil

            guard let result = result else {
                // QuestService already toasted the specific server reason
                // (e.g. "Already claimed", "Quest not completed yet"). The
                // hub card's retry affordance is no longer surfaced here —
                // the user can tap Claim again from the same card.
                return
            }

            appState.applyAuthoritativeRewardState(
                gold: result.gold,
                gems: result.gems,
                xp: result.xp,
                leveledUp: result.leveledUp,
                newLevel: result.newLevel,
                statPointsAwarded: result.statPointsAwarded,
                passivePointsAwarded: result.passivePointsAwarded,
                previousLevel: previousLevel
            )

            if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == questId }) {
                withAnimation(.easeOut(duration: 0.3)) {
                    appState.cachedTypedQuests?[idx].rewardClaimed = true
                }
            }

            HapticManager.success()

            appState.claimRewardConfig = ClaimRewardConfig(
                title: "CLAIMED!",
                subtitle: quest.title,
                goldReward: result.rewardGold,
                gemsReward: result.rewardGems,
                xpReward: result.rewardXp,
                lootItems: []
            )
        }
    }
}

// MARK: - Quest Reward Card Style

struct QuestRewardCardStyle: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(LayoutConstants.bannerPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
            )
            .cornerBrackets(color: accentColor.opacity(0.4), length: 12, thickness: 1.5)
            .compositingGroup()
            .shadow(color: accentColor.opacity(0.12), radius: 6, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}
