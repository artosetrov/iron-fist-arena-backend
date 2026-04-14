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
    func victoryStarsView(earned: Int, total: Int) -> some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            ForEach(0..<total, id: \.self) { index in
                let isEarned = index < earned
                let isRevealed = index < revealedStars

                ZStack {
                    // Glow behind earned star
                    if isEarned && isRevealed {
                        Circle()
                            .fill(DarkFantasyTheme.goldBright.opacity(0.25))
                            .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                            .blur(radius: 8)
                    }

                    Image(systemName: isEarned ? "star.fill" : "star")
                        .font(DarkFantasyTheme.title)
                        .bold()
                        .foregroundStyle(
                            isEarned
                                ? DarkFantasyTheme.goldBright
                                : DarkFantasyTheme.borderMedium.opacity(0.4)
                        )
                        .shadow(
                            color: isEarned ? DarkFantasyTheme.gold.opacity(0.6) : .clear,
                            radius: 8
                        )
                        .opacity(isRevealed ? 1 : 0.3)
                        .offset(y: isRevealed && isEarned ? 0 : 8)
                }
            }
        }
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
                        .frame(width: 72, height: 72)
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
                    .frame(width: 72, height: 72)

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

    // MARK: - Animation Sequence (Motion Audit §2.12)
    // Victory: flash gold → title slam (2.5→1.0) → particles → reward burst → counters → loot → CTAs
    // Defeat:  flash red → title fade → shake + haptic → counters → CTAs (red glow)

}
