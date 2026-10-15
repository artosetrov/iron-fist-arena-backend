import SwiftUI

extension BattleResultCardView {
    var rewardsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("REWARDS")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            HStack(alignment: .top, spacing: LayoutConstants.spaceLG) {
                if let gold = config.goldReward, gold > 0 {
                    rewardCounter(
                        iconImage: "reward-gold",
                        value: "+\(goldDisplay)",
                        label: "Gold",
                        color: DarkFantasyTheme.goldBright,
                        isVisible: goldItemVisible,
                        pulseOpacity: goldPulseOpacity
                    )
                }

                if let xp = config.xpReward, xp > 0 {
                    rewardCounter(
                        iconImage: "reward-xp",
                        value: "+\(xpDisplay)",
                        label: "XP",
                        color: DarkFantasyTheme.xpRing,
                        isVisible: xpItemVisible,
                        pulseOpacity: xpPulseOpacity
                    )
                }

                if let change = config.ratingChange, change != 0 {
                    rewardCounter(
                        iconImage: change > 0 ? "reward-rating-up" : "reward-rating-down",
                        value: ratingDisplay > 0 ? "+\(ratingDisplay)" : "\(ratingDisplay)",
                        label: "Rating",
                        color: change > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger,
                        isVisible: ratingItemVisible,
                        pulseOpacity: ratingPulseOpacity
                    )
                }
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
    }

    @ViewBuilder
    func rewardCounter(
        iconImage: String,
        value: String,
        label: String,
        color: Color,
        isVisible: Bool,
        pulseOpacity: Double
    ) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(iconImage)
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.icon3XL, height: LayoutConstants.icon3XL)
                .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)

            Text(value)
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .shadow(color: Color.black.opacity(0.5), radius: 8)
                .opacity(pulseOpacity)

            Text(label)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Hero XP Bar (big numbers + thick bar)

    @ViewBuilder
    func heroXpBarView(_ xpConfig: XPBarConfig) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Header: Level + LEVEL UP badge
            HStack {
                Text("Level \(xpConfig.displayLevel)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.xpRing)
                    .shadow(color: DarkFantasyTheme.xpRing.opacity(0.3), radius: 6)

                Spacer()

                if xpConfig.leveledUp {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("reward-level-up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                        Text("LEVEL UP!")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: 8)
                    }
                    .transition(.opacity)
                }
            }

            // Hero counter: big current XP / needed
            if let xpNeeded = config.xpNeeded {
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                    Text("\(xpHeroDisplay)")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.xpRing)
                        .shadow(color: DarkFantasyTheme.xpRing.opacity(0.4), radius: 10)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text("/")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.4))

                    Text("\(xpNeeded)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.5))
                        .monospacedDigit()

                    // +XP gain badge
                    if let xpReward = config.xpReward, xpReward > 0 {
                        Text("+\(xpReward)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.xpRing.opacity(0.9))
                            .padding(.horizontal, LayoutConstants.spaceSM)
                            .padding(.vertical, LayoutConstants.space2XS)
                            .background(
                                Capsule()
                                    .fill(DarkFantasyTheme.xpRing.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(DarkFantasyTheme.xpRing.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Thick XP bar — high contrast track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(DarkFantasyTheme.bgAbyss)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                                .stroke(DarkFantasyTheme.xpRing.opacity(0.35), lineWidth: 1.5)
                        )
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 1)

                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(DarkFantasyTheme.xpGradient)
                        .overlay(
                            BarFillHighlight(cornerRadius: LayoutConstants.radiusLG)
                        )
                        .frame(width: geo.size.width * min(xpConfig.progress, 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
                        .shadow(color: DarkFantasyTheme.xpRing.opacity(0.5), radius: 10, y: 0)
                }
            }
            .frame(height: LayoutConstants.spaceLG)
        }
        .padding(.top, LayoutConstants.spaceXS)
    }

    // MARK: - Dungeon Progress

    @ViewBuilder
    func dungeonProgressBar(_ progress: DungeonProgressConfig) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                // Bug #16: honour per-track progress label (Training Camp etc.)
                Text(progress.progressLabel)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
                Text("\(progress.defeated) / \(progress.total)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(
                        progress.isComplete
                            ? DarkFantasyTheme.success
                            : DarkFantasyTheme.textSecondary
                    )
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(
                            progress.isComplete
                                ? DarkFantasyTheme.canonicalHpGradient(percentage: 1.0)
                                : DarkFantasyTheme.progressGradient
                        )
                        .frame(width: geo.size.width * progress.fraction)
                        .animation(.easeOut(duration: MotionConstants.tickUpLong), value: progress.defeated)
                }
            }
            .frame(height: LayoutConstants.spaceSM)

            if progress.isComplete {
                Text(progress.completeLabel)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.top, LayoutConstants.spaceXS)
            }
        }
        .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Victory Stars

    @ViewBuilder
    func victoryStarsView(conditions: [StarCondition]) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            ForEach(Array(conditions.enumerated()), id: \.offset) { index, cond in
                victoryStarSlot(condition: cond, index: index)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LayoutConstants.spaceMD)
    }

    @ViewBuilder
    func victoryStarSlot(condition: StarCondition, index: Int) -> some View {
        let isRevealed = index < revealedStars
        let isEarned = condition.earned

        VStack(spacing: LayoutConstants.spaceXS) {
            ZStack {
                // Soft glow behind earned star — fades in with the reveal
                if isEarned {
                    Circle()
                        .fill(DarkFantasyTheme.goldBright.opacity(0.30))
                        .frame(width: LayoutConstants.icon2XL + 12, height: LayoutConstants.icon2XL + 12)
                        .blur(radius: 14)
                        .opacity(isRevealed ? 1 : 0)
                }

                Image(systemName: isEarned ? "star.fill" : "star")
                    .font(DarkFantasyTheme.title)
                    .bold()
                    .foregroundStyle(
                        isEarned
                            ? DarkFantasyTheme.goldBright
                            : DarkFantasyTheme.borderMedium.opacity(0.45)
                    )
                    .shadow(
                        color: isEarned ? DarkFantasyTheme.gold.opacity(0.7) : .clear,
                        radius: isRevealed ? 12 : 0
                    )
                    .rotationEffect(.degrees(isRevealed ? 0 : (isEarned ? -60 : 0)))
                    .offset(y: isRevealed ? 0 : (isEarned ? -24 : -4))
                    .opacity(isRevealed ? 1 : 0)
            }
            .frame(height: LayoutConstants.icon2XL + 4)
            .glowPulse(
                color: DarkFantasyTheme.goldBright,
                intensity: 0.5,
                isActive: isRevealed && isEarned
            )

            Text(condition.label.uppercased())
                .font(DarkFantasyTheme.caption)
                .tracking(0.8)
                .foregroundStyle(
                    isRevealed && isEarned
                        ? DarkFantasyTheme.textSecondary
                        : DarkFantasyTheme.textTertiary.opacity(0.55)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .opacity(isRevealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: LayoutConstants.icon2XL + 40, alignment: .top)
    }

    // MARK: - Loot Section

    @ViewBuilder
    var lootSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("LOOT")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            HStack(spacing: LayoutConstants.spaceMD) {
                ForEach(Array(config.lootItems.enumerated()), id: \.offset) { index, item in
                    inlineLootCard(item, index: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    func inlineLootCard(_ item: LootItemDisplay, index: Int) -> some View {
        let isRevealed = revealedLootIndices.contains(index)
        let rarityColor = item.rarityColor

        ZStack {
            // Card back (shown before flip)
            if !isRevealed {
                VStack(spacing: LayoutConstants.spaceXS) {
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .fill(
                            LinearGradient(
                                colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: LayoutConstants.itemCardSize, height: LayoutConstants.itemCardSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)
                        )
                        .overlay(
                            Text("?")
                                .font(DarkFantasyTheme.cardTitle)
                                .foregroundStyle(DarkFantasyTheme.borderStrong)
                        )

                    Text("???")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: 80)

                    Text(" ")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                }
                .rotation3DEffect(
                    .degrees(isRevealed ? -90 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            }

            // Card front (shown after flip)
            if isRevealed {
                VStack(spacing: LayoutConstants.spaceXS) {
                    ItemCardView(
                        rarity: item.rarity,
                        imageKey: item.imageKey,
                        imageUrl: item.imageUrl,
                        fallbackIcon: item.fallbackIcon,
                        systemIcon: item.sfIcon,
                        systemIconColor: item.sfColor,
                        context: .loot
                    ) {
                        config.onLootTap?(index)
                    }
                    .frame(width: LayoutConstants.itemCardSize, height: LayoutConstants.itemCardSize)

                    Text(item.name)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)

                    Text(item.rarityName)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(rarityColor)
                }
                .rotation3DEffect(
                    .degrees(isRevealed ? 0 : 90),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRevealed)
        // Epic+ items get ambient glow pulse after reveal
        .glowPulse(color: rarityColor, intensity: item.rarityTier >= 3 ? 0.5 : 0, isActive: isRevealed && item.rarityTier >= 3)
    }

    // MARK: - Combat Log (optional)

    @ViewBuilder
    var combatLogSection: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Header — tap to toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showCombatLog.toggle()
                }
                HapticManager.light()
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "scroll.fill")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("COMBAT LOG")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1.2)
                    Spacer(minLength: 0)
                    Text("\(config.combatLog.count) rounds")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Image(systemName: "chevron.down")
                        .font(DarkFantasyTheme.caption.bold())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .rotationEffect(.degrees(showCombatLog ? 180 : 0))
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceSM)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if showCombatLog {
                VStack(spacing: LayoutConstants.space2XS) {
                    ForEach(Array(config.combatLog.enumerated()), id: \.offset) { index, entry in
                        combatLogRow(index: index + 1, entry: entry)
                    }
                }
                .padding(.vertical, LayoutConstants.spaceXS)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    func combatLogRow(index: Int, entry: CombatLogSummaryEntry) -> some View {
        // Outcome label + color
        let label: String = {
            if entry.isMiss { return "MISS" }
            if entry.isDodge { return "DODGE" }
            if entry.heal > 0 { return "+\(entry.heal) HP" }
            if entry.isCrit { return "CRIT −\(entry.damage)" }
            if entry.isBlocked { return "BLOCKED −\(entry.damage)" }
            return "−\(entry.damage)"
        }()
        let color: Color = {
            if entry.isMiss || entry.isDodge { return DarkFantasyTheme.textTertiary }
            if entry.heal > 0 { return DarkFantasyTheme.success }
            if entry.isCrit { return DarkFantasyTheme.danger }
            if entry.isBlocked { return DarkFantasyTheme.textSecondary }
            return DarkFantasyTheme.textPrimary
        }()

        HStack(spacing: LayoutConstants.spaceSM) {
            // Round number chip
            Text("\(index)")
                .font(DarkFantasyTheme.caption.bold())
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .monospacedDigit()
                .frame(width: 20, alignment: .trailing)

            // Arrow: player → or ← opponent
            Image(systemName: entry.isPlayerAttacking ? "arrow.right" : "arrow.left")
                .font(DarkFantasyTheme.caption.bold())
                .foregroundStyle(entry.isPlayerAttacking ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                .frame(width: 14)

            // Attacker name
            Text(entry.attackerName)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Outcome
            Text(label)
                .font(DarkFantasyTheme.caption.bold())
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(index % 2 == 0 ? DarkFantasyTheme.bgTertiary.opacity(0.25) : Color.clear)
        )
    }

    // MARK: - Buttons

    @ViewBuilder
    var buttonsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(config.buttons.enumerated()), id: \.offset) { index, button in
                resultButton(button, index: index)
            }
        }
    }

    @ViewBuilder
    func resultButton(_ button: ResultButton, index: Int) -> some View {
        if button.style == .primary && config.isVictory {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
                .glowPulse(color: DarkFantasyTheme.goldBright, intensity: 0.5, isActive: showButtons)
                .shimmer(color: DarkFantasyTheme.gold, duration: 3)
        } else if button.style == .primary && !config.isVictory {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
                .glowPulse(color: DarkFantasyTheme.danger, intensity: 0.4, isActive: showButtons)
        } else {
            buttonLabel(button)
                .buttonStyle(resolveButtonStyle(button.style))
        }
    }

    func buttonLabel(_ button: ResultButton) -> some View {
        Button {
            HapticManager.medium()
            button.action()
        } label: {
            if let asset = button.assetIcon {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    Text(button.title)
                }
            } else if let icon = button.icon {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: icon)
                        .font(DarkFantasyTheme.body.bold())
                    Text(button.title)
                }
            } else {
                Text(button.title)
            }
        }
    }

    func resolveButtonStyle(_ style: ResultButtonStyle) -> some ButtonStyle {
        switch style {
        case .primary: return AnyButtonStyle(PrimaryButtonStyle())
        case .secondary: return AnyButtonStyle(SecondaryButtonStyle())
        case .ghost: return AnyButtonStyle(GhostButtonStyle())
        }
    }

    // MARK: - Duel Layout (PvP)
    // You vs the rival up top (rating before → after, rival profile / message
    // as icon buttons), compact stars, one row of reward tiles (gold, XP, loot),
    // a one-line level bar, the combat log, then a single primary CTA.

    static let duelPortraitSize: CGFloat = 112
    static let duelActionSize: CGFloat = 48
    static let duelTileHeight: CGFloat = 64
    static let duelBarHeight: CGFloat = 10

    @ViewBuilder
    func duelCardContent(_ duel: DuelResultInfo) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            titleView
                .padding(.top, LayoutConstants.spaceLG)

            duelHeader(duel)
                .padding(.horizontal, LayoutConstants.cardPadding)
                .opacity(showTitle ? 1 : 0)

            if let conditions = config.starConditions, config.isVictory, !conditions.isEmpty {
                duelStarsRow(conditions)
                    .padding(.horizontal, LayoutConstants.cardPadding)
            }

            if let subtitle = config.subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(!config.isVictory ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showTitle ? 1 : 0)
            }

            if hasDuelRewards {
                duelRewardsSection
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showRewards ? 1 : 0)
            }

            if let xpBarConfig = config.xpBarConfig {
                compactXpRow(xpBarConfig)
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showRewards ? 1 : 0)
            }

            if !config.combatLog.isEmpty {
                combatLogSection
                    .padding(.horizontal, LayoutConstants.cardPadding)
                    .opacity(showButtons ? 1 : 0)
            }

            buttonsSection
                .padding(.horizontal, LayoutConstants.cardPadding)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 15)

            Spacer().frame(height: LayoutConstants.spaceXS)
        }
    }

    var hasDuelRewards: Bool {
        (config.goldReward ?? 0) > 0 || (config.xpReward ?? 0) > 0 || !config.lootItems.isEmpty
    }

    // MARK: Duel header

    @ViewBuilder
    func duelHeader(_ duel: DuelResultInfo) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            duelFighter(
                name: "YOU",
                skinKey: duel.playerSkinKey,
                characterClass: duel.playerClass,
                isWinner: config.isVictory
            ) {
                duelRatingView(duel)
            }

            Text("VS")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .padding(.top, Self.duelPortraitSize / 2 - LayoutConstants.spaceMS)
                .accessibilityHidden(true)

            duelFighter(
                name: duel.rivalName.uppercased(),
                skinKey: duel.rivalSkinKey,
                characterClass: duel.rivalClass,
                isWinner: !config.isVictory
            ) {
                Text("Lv \(duel.rivalLevel) · \(duel.rivalClass.displayName)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)

                HStack(spacing: LayoutConstants.spaceSM) {
                    if let onView = duel.onViewRival {
                        duelIconButton(
                            asset: duel.rivalClass.iconAsset,
                            label: "View \(duel.rivalName)'s profile",
                            action: onView
                        )
                    }
                    if let onMessage = duel.onMessageRival {
                        duelIconButton(
                            asset: "hud-inbox",
                            label: "Message \(duel.rivalName)",
                            action: onMessage
                        )
                    }
                }
                .padding(.top, LayoutConstants.space2XS)
            }
        }
    }

    func duelFighter<Details: View>(
        name: String,
        skinKey: String?,
        characterClass: CharacterClass,
        isWinner: Bool,
        @ViewBuilder details: () -> Details
    ) -> some View {
        let frameColor = isWinner ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderMedium

        return VStack(spacing: LayoutConstants.spaceXS) {
            CachedAvatarImage(
                skinKey: skinKey,
                characterClass: characterClass,
                size: Self.duelPortraitSize
            )
            .background(DarkFantasyTheme.bgTertiary)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(frameColor, lineWidth: 3)
            )
            .opacity(isWinner ? 1 : 0.75)
            .accessibilityHidden(true)

            Text(name)
                .font(DarkFantasyTheme.cardTitle)
                .tracking(1)
                .foregroundStyle(isWinner ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            details()
        }
        .frame(maxWidth: .infinity)
    }

    /// "1 240 → 1 262" and the animated "+22" under the player's portrait.
    @ViewBuilder
    func duelRatingView(_ duel: DuelResultInfo) -> some View {
        if let change = config.ratingChange, change != 0 {
            if let before = duel.ratingBefore {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("\(before)")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("→")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("\(before + change)")
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }
                .font(DarkFantasyTheme.body)
                .monospacedDigit()
                .lineLimit(1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rating \(before) to \(before + change)")
            }

            Text(ratingDisplay > 0 ? "+\(ratingDisplay)" : "\(ratingDisplay)")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(change > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                .monospacedDigit()
                .contentTransition(.numericText())
                .opacity(ratingPulseOpacity)
        } else {
            Text("Lv \(duel.playerLevel)")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    func duelIconButton(asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                .frame(width: Self.duelActionSize, height: Self.duelActionSize)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                )
        }
        .buttonStyle(.scalePress)
        .accessibilityLabel(label)
    }

    // MARK: Duel stars

    @ViewBuilder
    func duelStarsRow(_ conditions: [StarCondition]) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            ForEach(Array(conditions.enumerated()), id: \.offset) { index, condition in
                let isRevealed = index < revealedStars
                VStack(spacing: LayoutConstants.space2XS) {
                    Image(systemName: condition.earned ? "star.fill" : "star")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(
                            condition.earned
                                ? DarkFantasyTheme.goldBright
                                : DarkFantasyTheme.borderMedium.opacity(DarkFantasyTheme.opacityHeavy)
                        )
                    Text(condition.label)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(condition.earned ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .opacity(isRevealed ? 1 : 0)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(condition.label): \(condition.earned ? "earned" : "missed")")
            }
        }
    }

    // MARK: Duel rewards

    var duelRewardsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                Text("REWARDS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .tracking(2)
                Spacer(minLength: 0)
                if config.firstWinBonus {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("reward-first-win")
                            .resizable()
                            .scaledToFit()
                            .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                        Text("First win x2")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM), count: 3),
                spacing: LayoutConstants.spaceSM
            ) {
                if let gold = config.goldReward, gold > 0 {
                    duelRewardTile(
                        asset: "icon-gold",
                        value: "+\(goldDisplay)",
                        color: DarkFantasyTheme.goldBright,
                        label: "gold",
                        pulseOpacity: goldPulseOpacity
                    )
                }
                if let xp = config.xpReward, xp > 0 {
                    duelRewardTile(
                        asset: "icon-xp",
                        value: "+\(xpDisplay)",
                        color: DarkFantasyTheme.xpRing,
                        label: "XP",
                        pulseOpacity: xpPulseOpacity
                    )
                }
                ForEach(Array(config.lootItems.enumerated()), id: \.offset) { index, item in
                    duelLootTile(item, index: index)
                }
            }
        }
    }

    func duelRewardTile(asset: String, value: String, color: Color, label: String, pulseOpacity: Double) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .opacity(pulseOpacity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.duelTileHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    @ViewBuilder
    func duelLootTile(_ item: LootItemDisplay, index: Int) -> some View {
        let isRevealed = revealedLootIndices.contains(index)

        ItemCardView(
            rarity: item.rarity,
            imageKey: item.imageKey,
            imageUrl: item.imageUrl,
            fallbackIcon: item.fallbackIcon,
            systemIcon: item.sfIcon,
            systemIconColor: item.sfColor,
            context: .loot
        ) {
            config.onLootTap?(index)
        }
        .frame(width: Self.duelTileHeight, height: Self.duelTileHeight)
        .frame(maxWidth: .infinity)
        .opacity(isRevealed ? 1 : 0)
        .accessibilityLabel("\(item.name), \(item.rarityName)")
    }

    // MARK: Duel level row

    @ViewBuilder
    func compactXpRow(_ xpConfig: XPBarConfig) -> some View {
        let fraction = min(max(xpConfig.progress, 0), 1)

        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("LV \(xpConfig.displayLevel)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.xpRing)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.xpRing, lineWidth: 1)
                    )

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DarkFantasyTheme.bgAbyss)
                        Capsule()
                            .fill(DarkFantasyTheme.xpGradient)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: Self.duelBarHeight)

                if let xpNeeded = config.xpNeeded {
                    Text("\(xpHeroDisplay) / \(xpNeeded)")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .fixedSize()
                }
            }

            if xpConfig.leveledUp {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("reward-level-up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    Text("LEVEL UP!")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Animation Sequence (Motion Audit §2.12)
    // Victory: flash gold → title slam (2.5→1.0) → particles → reward burst → counters → loot → CTAs
    // Defeat:  flash red → title fade → shake + haptic → counters → CTAs (red glow)

}
