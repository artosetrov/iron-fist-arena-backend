import SwiftUI

extension BattleResultCardView {

    // MARK: - Rewards

    /// One line per reward (`RewardCardRow`), in the order they tick up: gold,
    /// XP, rating. Each line fades in on its beat and dips once its counter lands.
    /// `ratingBefore` turns the rating line into "+22  1240 → 1262".
    func rewardsSection(ratingBefore: Int?) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            if let gold = config.goldReward, gold > 0 {
                RewardCardRow(
                    icon: "reward-gold",
                    value: "+\(goldDisplay)",
                    label: "Gold",
                    color: DarkFantasyTheme.goldBright
                )
                .opacity(goldPulseOpacity)
                .opacity(goldItemVisible ? 1 : 0)
            }

            if let xp = config.xpReward, xp > 0 {
                RewardCardRow(
                    icon: "reward-xp",
                    value: "+\(xpDisplay)",
                    label: "XP",
                    color: DarkFantasyTheme.xpRing
                )
                .opacity(xpPulseOpacity)
                .opacity(xpItemVisible ? 1 : 0)
            }

            if let change = config.ratingChange, change != 0 {
                ratingRow(change: change, before: ratingBefore)
                    .opacity(ratingPulseOpacity)
                    .opacity(ratingItemVisible ? 1 : 0)
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    func ratingRow(change: Int, before: Int?) -> some View {
        let direction = change > 0 ? "up" : "down"
        let label = before.map { "\($0) → \($0 + change)" } ?? "Rating"
        let spoken = before.map { "Rating \(direction) \(abs(change)), \($0) to \($0 + change)" }
            ?? "Rating \(direction) \(abs(change))"

        return RewardCardRow(
            icon: change > 0 ? "reward-rating-up" : "reward-rating-down",
            value: ratingDisplay > 0 ? "+\(ratingDisplay)" : "\(ratingDisplay)",
            label: label,
            color: change > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger
        )
        .accessibilityLabel(Text(spoken))
    }

    // MARK: - Hero XP Bar (big numbers + thick bar)

    @ViewBuilder
    func heroXpBarView(_ xpConfig: XPBarConfig) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            // Header: Level + LEVEL UP badge (same line, so the card keeps its height)
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
                        .frame(width: geo.size.width * max(0, min(xpConfig.progress, 1.0)))
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
                        .frame(width: geo.size.width * max(0, min(progress.fraction, 1)))
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
                .font(DarkFantasyTheme.body)
                .tracking(0.8)
                .foregroundStyle(
                    isRevealed && isEarned
                        ? DarkFantasyTheme.textSecondary
                        : DarkFantasyTheme.textTertiary.opacity(0.55)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .opacity(isRevealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: LayoutConstants.icon2XL + 40, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(condition.label): \(isEarned ? "earned" : "missed")"))
    }

    // MARK: - Loot Section

    /// Loot tile side and tiles per row (`RewardCardLayout`).
    static var lootTile: CGFloat { RewardCardLayout.lootTile }
    static var lootPerRow: Int { RewardCardLayout.lootPerRow }

    var lootSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("LOOT")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)
                .accessibilityAddTraits(.isHeader)

            // Three to a row: the card grows a row at a time. (Plain stacks, not
            // a lazy grid: the stage measures the card's ideal height.)
            VStack(spacing: LayoutConstants.spaceSM) {
                ForEach(lootRows, id: \.self) { row in
                    HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                        ForEach(row, id: \.self) { index in
                            inlineLootCard(config.lootItems[index], index: index)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Loot indices, three to a row.
    var lootRows: [[Int]] {
        let count = config.lootItems.count
        return stride(from: 0, to: count, by: Self.lootPerRow).map { start in
            Array(start..<min(start + Self.lootPerRow, count))
        }
    }

    /// A face-down tile that flips to the item on its beat, its name appearing
    /// under it; a tap on the item opens its details.
    func inlineLootCard(_ item: LootItemDisplay, index: Int) -> some View {
        let isRevealed = revealedLootIndices.contains(index)
        return VStack(spacing: LayoutConstants.spaceXS) {
            lootTileFace(item, index: index, isRevealed: isRevealed)
            // Laid out from the start so the row keeps its height through the flip.
            RewardCardLootName(name: item.name, color: item.rarityColor)
                .opacity(isRevealed ? 1 : 0)
                .animation(.easeOut(duration: MotionConstants.fast), value: isRevealed)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    func lootTileFace(_ item: LootItemDisplay, index: Int, isRevealed: Bool) -> some View {
        let rarityColor = item.rarityColor

        ZStack {
            // Card back (shown before flip)
            if !isRevealed {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                            .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1.5)
                    )
                    .overlay(
                        Text("?")
                            .font(DarkFantasyTheme.cardTitle)
                            .foregroundStyle(DarkFantasyTheme.borderStrong)
                    )
                    .frame(width: Self.lootTile, height: Self.lootTile)
                    .rotation3DEffect(
                        .degrees(isRevealed ? -90 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .accessibilityHidden(true)
            }

            // Card front (shown after flip)
            if isRevealed {
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
                .frame(width: Self.lootTile, height: Self.lootTile)
                .rotation3DEffect(
                    .degrees(isRevealed ? 0 : 90),
                    axis: (x: 0, y: 1, z: 0)
                )
                .accessibilityLabel(Text("\(item.name), \(item.rarityName)"))
            }
        }
        .frame(width: Self.lootTile, height: Self.lootTile)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRevealed)
        // Epic+ items get ambient glow pulse after reveal
        .glowPulse(color: rarityColor, intensity: item.rarityTier >= 3 ? 0.5 : 0, isActive: isRevealed && item.rarityTier >= 3)
    }

    // MARK: - Combat Log (optional)

    /// One line on the card; the rounds open in a sheet, so the card never grows
    /// (and never jumps to another size) when the player reads them.
    var combatLogSection: some View {
        Button {
            showCombatLog = true
            HapticManager.light()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image("hud-quests")
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                Text("COMBAT LOG")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .tracking(1.2)
                Spacer(minLength: 0)
                Text("\(config.combatLog.count) rounds")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.caption.bold())
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .frame(minHeight: LayoutConstants.touchMin)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Combat log, \(config.combatLog.count) rounds")
        .sheet(isPresented: $showCombatLog) {
            combatLogSheet
        }
    }

    var combatLogSheet: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("COMBAT LOG")
                .font(DarkFantasyTheme.section)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .padding(.top, LayoutConstants.spaceLG)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: LayoutConstants.space2XS) {
                    ForEach(Array(config.combatLog.enumerated()), id: \.offset) { index, entry in
                        combatLogRow(index: index + 1, entry: entry)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DarkFantasyTheme.bgSecondary)
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
    // The rival is the card's illustration. Under the title: their name with
    // profile / message buttons, compact stars, the reward lines (rating with
    // before → after), the loot, a one-line level bar, the combat log; the
    // buttons sit in the card's action band.

    static let duelActionSize: CGFloat = 48
    static let duelBarHeight: CGFloat = 10

    @ViewBuilder
    func duelCardContent(_ duel: DuelResultInfo) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            duelRivalRow(duel)
                .opacity(showTitle ? 1 : 0)

            if let conditions = config.starConditions, config.isVictory, !conditions.isEmpty {
                duelStarsRow(conditions)
            }

            if let subtitle = config.subtitle {
                subtitleText(subtitle)
            }

            if config.firstWinBonus {
                firstWinBadge
                    .opacity(showRewards ? 1 : 0)
            }

            if hasRewards {
                rewardsSection(ratingBefore: duel.ratingBefore)
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 10)
            }

            if !config.lootItems.isEmpty {
                lootSection
                    .opacity(showLoot ? 1 : 0)
            }

            if let xpBarConfig = config.xpBarConfig {
                compactXpRow(xpBarConfig)
                    .opacity(showRewards ? 1 : 0)
            }

            if !config.combatLog.isEmpty {
                combatLogSection
                    .opacity(showButtons ? 1 : 0)
            }
        }
    }

    // MARK: Duel rival

    /// Who the fight was against (painted big above), with their profile and a
    /// message one tap away.
    func duelRivalRow(_ duel: DuelResultInfo) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("VS \(duel.rivalName.uppercased())")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                Text("Lv \(duel.rivalLevel) · \(duel.rivalClass.displayName)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

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

            // Laid out from the start when this fight levels up, shown when the
            // bar fills (`XPBarConfig.willLevelUp`) — the card never grows mid-ceremony.
            if xpConfig.leveledUp || xpConfig.willLevelUp {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("reward-level-up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    Text("LEVEL UP!")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .opacity(xpConfig.leveledUp ? 1 : 0)
                .accessibilityHidden(!xpConfig.leveledUp)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Animation Sequence (Motion Audit §2.12)
    // Victory: flash gold → title → particles → reward burst → counters → loot → CTAs
    // Defeat:  flash red → title fade → shake + haptic → counters → CTAs (red glow)
    // (BattleResultAnimations.swift)
}
