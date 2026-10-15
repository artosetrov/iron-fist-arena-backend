//
//  DiceBattleView.swift
//  Hexbound
//
//  Dice combat — battle screen (prototype "Hexbound Dice Duel").
//  Top: the same YOU / ENEMY duel header (portraits, hit flash, HP) as the
//  interactive screen. Below, no scrolling: two lanes —
//    YOUR STRIKE   their guard die · result chip · your attack die
//    ENEMY STRIKE  their attack die · result chip · your guard die
//  then a one-line hint and AUTO / FIGHT. Tap one of your dice to spend
//  Focus (reroll 2, set a face 4) in a bottom sheet.
//

import SwiftUI

struct DiceBattleView: View {
    @Bindable var vm: DiceBattleViewModel
    var onFinished: ((DiceBattleViewModel.Phase) -> Void)? = nil

    @Environment(GameDataCache.self) private var cache

    /// Dungeon boss fights put the boss on a stage instead of the duel
    /// header: full-body art, a long HP bar, the player as a slim strip.
    private var boss: BossInfo? {
        guard vm.opponentType == .dungeonBoss, let name = vm.defenderProfile?.name else { return nil }
        return EnemyPortraitResolver.bossInfo(for: name, cache: cache)
    }

    /// The kill overlay holds from the KO through `.finished`, so it is
    /// still up while the battle screen pops back to the dungeon.
    private var showsKillOverlay: Bool {
        guard vm.endWon == true else { return false }
        switch vm.phase {
        case .ending, .completing, .finished: return true
        default: return false
        }
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 760
            let stageHeight = bossStageHeight(geo.size)
            ZStack(alignment: .top) {
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()

                VStack(spacing: compact ? LayoutConstants.spaceSM : LayoutConstants.spaceMS) {
                    if let boss {
                        bossHeader(boss, stageHeight: stageHeight)
                    } else {
                        duelHeader(compact: compact)
                    }
                    roundStrip
                    DiceTableView(
                        vm: vm,
                        dieSize: dieSize(geo.size, header: boss != nil
                                         ? stageHeight + Self.playerStripHeight + LayoutConstants.spaceSM
                                         : (compact ? 172 : 236)),
                        hideEndCard: boss != nil && vm.endWon == true
                    )
                    hintLine
                    bottomBar
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceSM)

                if case .intro = vm.phase {
                    ConnectingPillStrip(label: "Connecting · rolling the dice")
                        .padding(.top, LayoutConstants.spaceMD)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                CombatVFXOverlay(vfxManager: vm.vfxManager, speedMultiplier: 1.0)
                    .allowsHitTesting(false)
                CombatFXImageOverlay(fxManager: vm.fxImageManager)
                    .allowsHitTesting(false)

                if let banner = vm.banner {
                    DiceBannerView(banner: banner) { vm.banner = nil }
                        .id(banner.id)
                        .frame(maxHeight: .infinity)
                        .allowsHitTesting(false)
                }

                if vm.sheetDie != nil {
                    DiceActionSheet(vm: vm)
                        .transition(.opacity)
                        .zIndex(10)
                }

                // Killing blow on a dungeon boss — replaces the in-table
                // VICTORY card while the match settles.
                if let boss, showsKillOverlay {
                    BossKillOverlay(
                        boss: boss,
                        rounds: min(vm.round, vm.maxRounds),
                        dealt: vm.stats.dealt,
                        taken: vm.stats.taken,
                        counting: vm.phase == .completing
                    )
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .animation(.easeOut(duration: 0.2), value: vm.sheetDie)
            .animation(.easeOut(duration: 0.25), value: showsKillOverlay)
        }
        .overlayPreferenceValue(FighterAnchorKey.self) { entries in
            GeometryReader { proxy in
                Color.clear
                    .onAppear { publishAnchors(entries, proxy: proxy) }
                    .onChange(of: proxy.size.width) { _, _ in publishAnchors(entries, proxy: proxy) }
            }
            .allowsHitTesting(false)
        }
        .onAppear { vm.startMatch() }
        .onChange(of: phaseKey(vm.phase)) { _, _ in
            switch vm.phase {
            case .finished, .unavailable, .error: onFinished?(vm.phase)
            default: break
            }
        }
    }

    /// Die edge in points: fits two dice + chip + labels per lane in the
    /// space under the header, capped at 112 (the face tile's design size).
    private func dieSize(_ size: CGSize, header: CGFloat) -> CGFloat {
        let chrome: CGFloat = 24 + 40 + 56 + 5 * LayoutConstants.spaceMS + 2 * LayoutConstants.spaceSM
        let lane = size.height - header - chrome
        let byHeight = (lane - 104) / 2
        let byWidth = (size.width - 2 * LayoutConstants.screenPadding - LayoutConstants.spaceMD) / 2 - 24
        return max(64, min(112, byHeight, byWidth))
    }

    // MARK: - Header

    private func duelHeader(compact: Bool) -> some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .player,
                    profile: vm.attackerProfile,
                    currentHp: vm.playerHp,
                    maxHp: vm.playerMaxHp,
                    slideX: vm.playerSlideX,
                    flash: vm.playerFlash,
                    popups: vm.damagePopups.filter { !$0.onDefender },
                    compact: compact
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .player, bounds: $0)]
                }
                FocusPipsView(focus: vm.playerFocus, max: vm.focusMax)
            }
            .frame(maxWidth: .infinity, alignment: .top)

            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .enemy,
                    profile: vm.defenderProfile,
                    currentHp: vm.enemyHp,
                    maxHp: vm.enemyMaxHp,
                    slideX: vm.enemySlideX,
                    flash: vm.enemyFlash,
                    popups: vm.damagePopups.filter { $0.onDefender },
                    compact: compact
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .enemy, bounds: $0)]
                }
                FocusPipsView(focus: vm.enemyFocus, max: vm.focusMax)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    // MARK: - Boss header (dungeon boss fights)

    static let playerStripHeight: CGFloat = 56

    /// Stage height for the boss: whatever the dice can spare at their
    /// target size, between a small-phone floor and a large-phone ceiling.
    private func bossStageHeight(_ size: CGSize) -> CGFloat {
        let chrome: CGFloat = 24 + 40 + 56 + 5 * LayoutConstants.spaceMS + 2 * LayoutConstants.spaceSM
        let dice: CGFloat = 104 + 2 * 96
        let spare = size.height - chrome - dice - Self.playerStripHeight - LayoutConstants.spaceSM
        return max(130, min(240, spare))
    }

    /// The boss, full height and facing left, over a long souls-style HP
    /// bar; the player below as a slim strip. Hit flash, damage popups and
    /// lunges use the same VM state as the duel header.
    private func bossHeader(_ boss: BossInfo, stageHeight: CGFloat) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ZStack(alignment: .bottom) {
                BossStageArt(boss: boss, mirrored: true, hitFlash: vm.enemyFlash)
                    .offset(x: vm.enemySlideX)
                    .overlay(alignment: .top) {
                        ZStack {
                            ForEach(vm.damagePopups.filter { $0.onDefender }) { popup in
                                DamagePopupBubble(popup: popup)
                            }
                        }
                        .padding(.top, stageHeight * 0.2)
                        .allowsHitTesting(false)
                    }
                    .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                        [FighterAnchorKey.Entry(side: .enemy, bounds: $0)]
                    }

                bossNameplate(boss)
            }
            .frame(height: stageHeight)
            .frame(maxWidth: .infinity)

            playerStrip
        }
    }

    private func bossNameplate(_ boss: BossInfo) -> some View {
        let fraction = Double(vm.enemyHp) / Double(max(vm.enemyMaxHp, 1))

        return VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceSM) {
                Text(boss.name.uppercased())
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("LV \(boss.level)")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer(minLength: LayoutConstants.spaceXS)
                Text("\(vm.enemyHp) / \(vm.enemyMaxHp)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.dungeonHpGradient)
                        .frame(width: geo.size.width * max(0, min(1, fraction)))
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        .animation(.easeOut(duration: 0.35), value: vm.enemyHp)
                }
            }
            .frame(height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .stroke(DarkFantasyTheme.danger.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
            )

            FocusPipsView(focus: vm.enemyFocus, max: vm.focusMax)
        }
        .padding(.top, LayoutConstants.spaceLG)
        .background(
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.bgPrimary.opacity(0.9), DarkFantasyTheme.bgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(boss.name), level \(boss.level), \(vm.enemyHp) of \(vm.enemyMaxHp) HP"))
    }

    private var playerStrip: some View {
        let profile = vm.attackerProfile
        return HStack(spacing: LayoutConstants.spaceSM) {
            ZStack {
                DarkFantasyTheme.bgSecondary
                if let profile {
                    AvatarImageView(
                        skinKey: profile.avatar,
                        characterClass: profile.characterClass,
                        size: 44,
                        deterministicSeed: profile.id
                    )
                }
                DarkFantasyTheme.danger
                    .opacity(vm.playerFlash ? 0.35 : 0)
                    .allowsHitTesting(false)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(DarkFantasyTheme.gold, lineWidth: 2)
            )
            .overlay(alignment: .top) {
                ZStack {
                    ForEach(vm.damagePopups.filter { !$0.onDefender }) { popup in
                        DamagePopupBubble(popup: popup)
                    }
                }
                .allowsHitTesting(false)
            }
            .offset(x: vm.playerSlideX)
            .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                [FighterAnchorKey.Entry(side: .player, bounds: $0)]
            }

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(profile?.name ?? "You")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                    if let level = profile?.level {
                        Text("· Lv \(level)")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                }
                HPBarView(
                    currentHp: vm.playerHp,
                    maxHp: vm.playerMaxHp,
                    size: .compact,
                    showTextInside: true,
                    pulseOnCritical: true
                )
            }

            FocusPipsView(focus: vm.playerFocus, max: vm.focusMax)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .frame(height: Self.playerStripHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var roundStrip: some View {
        HStack {
            Text("ROUND \(min(vm.round, vm.maxRounds))")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.gold)
            if let fatigue = vm.fatigueLabel {
                Text("FATIGUE \(fatigue)")
                    .font(DarkFantasyTheme.badge)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
            Spacer(minLength: LayoutConstants.spaceSM)
            Text(phaseLabel)
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(height: 20)
        .padding(.horizontal, LayoutConstants.space2XS)
    }

    private var phaseLabel: String {
        switch vm.phase {
        case .intro: return "ROLLING…"
        case .decide: return vm.hasActed ? "LOCKED IN" : "YOUR MOVE"
        case .busy: return "CLASH"
        case .ending, .completing, .finished: return vm.endWon == true ? "VICTORY" : "DEFEAT"
        default: return ""
        }
    }

    private var hintLine: some View {
        Text(vm.hint)
            .font(DarkFantasyTheme.uiLabel)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, minHeight: 36)
            .animation(.easeInOut(duration: 0.2), value: vm.hint)
    }

    private var bottomBar: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button { vm.toggleAuto() } label: {
                Text("AUTO")
                    .frame(minWidth: 72)
            }
            .buttonStyle(.combatToggle(isActive: vm.autoMode))
            .accessibilityLabel("Auto battle")
            .accessibilityValue(vm.autoMode ? "On" : "Off")

            DiceFightButton(
                remainingFraction: vm.windowSeconds > 0 ? vm.timeRemaining / vm.windowSeconds : 0,
                isCritical: vm.phase.isDeciding && vm.timeRemaining <= 2,
                enabled: vm.phase.isDeciding,
                action: { vm.fight() }
            )
        }
    }

    // MARK: - Anchors / phase

    private func publishAnchors(_ entries: [FighterAnchorKey.Entry], proxy: GeometryProxy) {
        let screen = proxy.size
        guard screen.width > 0, screen.height > 0 else { return }
        for entry in entries {
            let rect = proxy[entry.bounds]
            let p = CGPoint(x: rect.midX / screen.width, y: (rect.minY + rect.height * 0.30) / screen.height)
            switch entry.side {
            case .player: vm.playerAvatarPos = p
            case .enemy: vm.enemyAvatarPos = p
            }
        }
    }

    private func phaseKey(_ p: DiceBattleViewModel.Phase) -> String {
        switch p {
        case .intro: return "intro"
        case .decide: return "decide"
        case .busy: return "busy"
        case .ending: return "ending"
        case .completing: return "completing"
        case .finished(let id): return "finished:\(id)"
        case .unavailable: return "unavailable"
        case .error(let m): return "error:\(m)"
        }
    }
}

// MARK: - Dice table (two lanes)

struct DiceTableView: View {
    @Bindable var vm: DiceBattleViewModel
    let dieSize: CGFloat
    /// The boss kill overlay takes over the victory beat in dungeon fights.
    var hideEndCard: Bool = false

    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
                lane(mine: true)
                lane(mine: false)
            }
            .padding(.vertical, LayoutConstants.spaceSM)
            .padding(.horizontal, LayoutConstants.spaceSM)

            if !hideEndCard {
                if case .ending = vm.phase { endCard }
                if case .completing = vm.phase { endCard }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
    }

    @ViewBuilder
    private func lane(mine: Bool) -> some View {
        let active = vm.activeLane == (mine ? .player : .enemy)
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Text(mine ? "YOUR STRIKE" : "ENEMY STRIKE")
                    .font(DarkFantasyTheme.badge)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if vm.match != nil, vm.playerStrikesFirst == mine {
                    Text("1ST")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .badgeCapsule(color: DarkFantasyTheme.gold)
                }
            }
            .frame(height: 22)

            if mine {
                caption("THEIR GUARD")
                die(.od, kind: .guardDie, mine: false)
                chipRow(vm.chipP, arrowUp: true)
                die(.pa, kind: .attack, mine: true)
                caption("YOUR ATTACK")
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    caption("THEIR ATTACK")
                    if let next = vm.match?.bossNext {
                        Text("NEXT: \(DiceZone.of(face: next).label.uppercased())")
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(DarkFantasyTheme.danger)
                    }
                }
                ZStack(alignment: .bottomTrailing) {
                    die(.oa, kind: .attack, mine: false)
                    if vm.face(.oa2) != nil {
                        DiceDieView(kind: .attack, face: vm.face(.oa2), runeAsset: vm.runeAsset(.oa2),
                                    size: dieSize * 0.5, tumbling: vm.tumbling.contains(.oa2),
                                    runePulse: vm.pulses[.oa2] ?? 0, faceRunes: vm.faceRunes(.oa2))
                            .offset(x: dieSize * 0.32, y: dieSize * 0.1)
                            .offset(y: vm.lunging == .oa2 ? dieSize * 0.25 : 0)
                            .animation(.easeInOut(duration: 0.2), value: vm.lunging)
                    }
                }
                chipRow(vm.chipO, arrowUp: false)
                die(.pd, kind: .guardDie, mine: true)
                caption("YOUR GUARD")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(DarkFantasyTheme.gold.opacity(active ? 0.06 : 0))
        )
        .animation(.easeInOut(duration: 0.2), value: active)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(DarkFantasyTheme.badge)
            .tracking(1.5)
            .foregroundStyle(DarkFantasyTheme.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    @ViewBuilder
    private func die(_ slot: DiceBattleViewModel.Slot, kind: DiceKind, mine: Bool) -> some View {
        let m = vm.match
        let side = slot == .pa || slot == .pd ? m?.p : m?.o
        let isGuard = kind == .guardDie
        let view = DiceDieView(
            kind: kind,
            face: vm.face(slot),
            runeAsset: vm.runeAsset(slot),
            size: dieSize,
            tumbling: vm.tumbling.contains(slot),
            runePulse: vm.pulses[slot] ?? 0,
            opened: isGuard && (side?.opened ?? false),
            frozen: !isGuard && (side?.frozen ?? false),
            stunned: !isGuard && (side?.stunned ?? false),
            highlighted: mine && vm.canAct,
            faceRunes: vm.faceRunes(slot)
        )
        .overlay {
            if vm.changed.contains(slot) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.goldBright, lineWidth: 2)
                    .padding(-5)
                    .allowsHitTesting(false)
            }
        }
        .offset(y: lungeOffset(slot))
        .animation(.easeInOut(duration: 0.2), value: vm.lunging)

        if mine {
            Button { vm.tapDie(kind) } label: { view }
                .buttonStyle(.plain)
                .disabled(!vm.phase.isDeciding)
                .accessibilityHint(Text("Spend Focus to change this die"))
        } else {
            view
        }
    }

    private func lungeOffset(_ slot: DiceBattleViewModel.Slot) -> CGFloat {
        guard vm.lunging == slot else { return 0 }
        return slot == .pa ? -dieSize * 0.35 : dieSize * 0.35
    }

    private func chipRow(_ chip: DiceBattleViewModel.Chip, arrowUp: Bool) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Image(arrowUp ? "ui-arrow-up" : "ui-arrow-down")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .opacity(0.6)
            DiceChipView(chip: chip)
        }
        .frame(minHeight: 44)
    }

    private var endCard: some View {
        let won = vm.endWon == true
        return ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.86))
            VStack(spacing: LayoutConstants.spaceSM) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("dice-showcase-attack")
                        .resizable().scaledToFit()
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(-8))
                    Image("dice-showcase-guard")
                        .resizable().scaledToFit()
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(7))
                        .offset(y: 6)
                }
                Text(won ? "VICTORY" : "DEFEAT")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .tracking(4)
                    .foregroundStyle(won ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                Text("\(min(vm.round, vm.maxRounds)) rounds · dealt \(vm.stats.dealt) · took \(vm.stats.taken)")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                if case .completing = vm.phase {
                    Text("COUNTING THE SPOILS…")
                        .font(DarkFantasyTheme.badge)
                        .tracking(2)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Small pieces

struct DiceChipView: View {
    let chip: DiceBattleViewModel.Chip

    private var color: Color {
        switch chip.style {
        case .crit: return DarkFantasyTheme.goldBright
        case .hit: return DarkFantasyTheme.textPrimary
        case .pierce: return DarkFantasyTheme.cyan
        case .blocked: return DarkFantasyTheme.info
        case .miss, .wait: return DarkFantasyTheme.textTertiary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(chip.text)
                .font(chip.big ? DarkFantasyTheme.cardTitle : DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.2)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let detail = chip.detail {
                Text(detail)
                    .font(DarkFantasyTheme.badge)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(chip.style == .wait ? DarkFantasyTheme.borderSubtle : color.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: chip.style == .wait ? [4, 3] : []))
        )
        .animation(.easeOut(duration: 0.15), value: chip)
        .accessibilityLabel(Text([chip.text, chip.detail].compactMap { $0 }.joined(separator: ", ")))
    }
}

struct FocusPipsView: View {
    let focus: Int
    let max: Int

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<Swift.max(1, max), id: \.self) { i in
                Rectangle()
                    .fill(i < focus ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderMedium)
                    .frame(width: 9, height: 9)
                    .rotationEffect(.degrees(45))
                    .shadow(color: i < focus ? DarkFantasyTheme.gold.opacity(0.6) : .clear, radius: 3)
            }
        }
        .frame(height: 14)
        .animation(.easeOut(duration: 0.2), value: focus)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Focus \(focus) of \(max)"))
    }
}

struct DiceFightButton: View {
    let remainingFraction: Double
    let isCritical: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("FIGHT")
                .font(DarkFantasyTheme.buttonLabel)
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
        }
        .buttonStyle(.primary(enabled: enabled))
        .disabled(!enabled)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(Color.black.opacity(0.25))
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(isCritical ? DarkFantasyTheme.danger : DarkFantasyTheme.gold.opacity(0.9))
                        .frame(width: geo.size.width * max(0, min(1, remainingFraction)))
                        .animation(.linear(duration: 0.1), value: remainingFraction)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceXS)
            .allowsHitTesting(false)
            .opacity(enabled ? 1 : 0)
        }
        .accessibilityLabel(Text("Fight"))
    }
}

/// Short centered slam for OMEN — fades itself out.
struct DiceBannerView: View {
    let banner: DiceBattleViewModel.Banner
    let onDone: () -> Void
    @State private var shown = false

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(banner.title)
                .font(DarkFantasyTheme.combatCallout)
                .tracking(4)
                .foregroundStyle(DarkFantasyTheme.goldBright)
            if let sub = banner.subtitle {
                Text(sub.uppercased())
                    .font(DarkFantasyTheme.badge)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
            }
        }
        .shadow(color: DarkFantasyTheme.bgAbyss, radius: 12)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { shown = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.1))
                withAnimation(.easeIn(duration: 0.3)) { shown = false }
                try? await Task.sleep(for: .seconds(0.3))
                onDone()
            }
        }
    }
}

// MARK: - Action sheet (reroll / set face)

struct DiceActionSheet: View {
    @Bindable var vm: DiceBattleViewModel

    var body: some View {
        if let kind = vm.sheetDie {
            ZStack(alignment: .bottom) {
                DarkFantasyTheme.bgAbyss.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { vm.closeSheet() }
                content(kind)
            }
        }
    }

    private func content(_ kind: DiceKind) -> some View {
        let slot: DiceBattleViewModel.Slot = kind == .attack ? .pa : .pd
        let current = vm.face(slot) ?? 0
        let runes = kind == .attack ? (vm.match?.p.atk ?? []) : (vm.match?.p.grd ?? [])
        let canReroll = vm.playerFocus >= vm.rerollCost && !(kind == .attack && vm.playerFrozen)
        let canSet = vm.playerFocus >= vm.setFaceCost && !(kind == .attack && vm.playerFrozen)
        // One button per distinct face (same zone + same rune collapse).
        let faces = (0..<6).filter { f in
            !(0..<f).contains { g in DiceZone.of(face: g) == DiceZone.of(face: f) && runes[safe: g] == runes[safe: f] }
        }

        return VStack(spacing: LayoutConstants.spaceMS) {
            HStack(alignment: .firstTextBaseline) {
                Text(kind.title.uppercased())
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Spacer()
                Text("Now: \(DiceZone.of(face: current).label) · Focus \(vm.playerFocus)/\(vm.focusMax)")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            Button { vm.reroll(kind) } label: {
                actionRow(title: "REROLL", sub: "Random face from this die", cost: vm.rerollCost)
            }
            .buttonStyle(.plain)
            .disabled(!canReroll)
            .opacity(canReroll ? 1 : 0.4)

            VStack(spacing: LayoutConstants.spaceSM) {
                actionRow(title: "SET FACE", sub: canSet ? "Pick exactly the face you want" : "Needs \(vm.setFaceCost) Focus", cost: vm.setFaceCost)
                    .opacity(canSet ? 1 : 0.45)
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(faces, id: \.self) { f in
                        let isCurrent = DiceZone.of(face: f) == DiceZone.of(face: current) && runes[safe: f] == runes[safe: current]
                        Button { vm.setFace(kind, face: f) } label: {
                            VStack(spacing: LayoutConstants.space2XS) {
                                DiceDieView(kind: kind, face: f,
                                            runeAsset: DiceBattleViewModel.asset(for: runes[safe: f] ?? nil, info: [:]),
                                            size: 50, highlighted: isCurrent)
                                Text(isCurrent ? "NOW" : (vm.rune(runes[safe: f] ?? nil)?.name.uppercased() ?? DiceZone.of(face: f).label.uppercased()))
                                    .font(DarkFantasyTheme.badge)
                                    .foregroundStyle(isCurrent ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.gold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSet || isCurrent)
                        .opacity(!canSet || isCurrent ? 0.4 : 1)
                        .accessibilityLabel(Text("Set \(DiceZone.of(face: f).label)"))
                    }
                }
            }

            runeStrip(runes)

            Button("CANCEL") { vm.closeSheet() }
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .frame(minHeight: 44)
        }
        .padding(LayoutConstants.spaceMD)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.modalRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 18, thickness: 1.5)
        .compositingGroup()
        .transition(.move(edge: .bottom))
    }

    private func actionRow(title: String, sub: String, cost: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(title)
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(sub)
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            Spacer()
            HStack(spacing: LayoutConstants.space2XS) {
                Text("\(cost)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Rectangle()
                    .fill(DarkFantasyTheme.goldBright)
                    .frame(width: 9, height: 9)
                    .rotationEffect(.degrees(45))
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .frame(minHeight: 56)
        .background(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG).fill(DarkFantasyTheme.bgTertiary))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG).stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
    }

    @ViewBuilder
    private func runeStrip(_ runes: [String?]) -> some View {
        let placed = runes.enumerated().compactMap { i, k in k.map { (i, $0) } }
        if !placed.isEmpty {
            HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                ForEach(placed, id: \.0) { face, key in
                    HStack(alignment: .top, spacing: LayoutConstants.spaceXS) {
                        Image(DiceBattleViewModel.asset(for: key, info: [:]) ?? "rune-socket-empty")
                            .resizable().scaledToFit()
                            .frame(width: 30, height: 34)
                        VStack(alignment: .leading, spacing: 0) {
                            Text((vm.rune(key)?.name ?? key).uppercased())
                                .font(DarkFantasyTheme.badge)
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                            Text("\(DiceZone.of(face: face).label) · \(vm.rune(key)?.desc ?? "")")
                                .font(DarkFantasyTheme.caption)
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Boss killing blow

/// Full-screen beat after the KO on a dungeon boss, while the match settles:
/// the boss goes grey, a red slash cuts across, DEFEATED stamps down, then
/// the fight in three numbers. Opacity-only motion.
struct BossKillOverlay: View {
    let boss: BossInfo
    let rounds: Int
    let dealt: Int
    let taken: Int
    let counting: Bool

    @State private var slashShown = false
    @State private var stampShown = false

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                VStack(spacing: LayoutConstants.space2XS) {
                    Text("LV \(boss.level)")
                        .font(DarkFantasyTheme.body)
                        .tracking(3)
                        .foregroundStyle(DarkFantasyTheme.goldDim)
                    Text(boss.name.uppercased())
                        .font(DarkFantasyTheme.cinematicTitle)
                        .tracking(1)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.top, LayoutConstants.spaceXL)

                ZStack {
                    BossStageArt(boss: boss, style: .defeated, mirrored: true, light: DarkFantasyTheme.danger)

                    KillSlashShape()
                        .fill(DarkFantasyTheme.danger)
                        .opacity(slashShown ? 1 : 0)
                        .allowsHitTesting(false)

                    Text("DEFEATED")
                        .font(DarkFantasyTheme.combatCallout)
                        .tracking(6)
                        .foregroundStyle(DarkFantasyTheme.danger)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, LayoutConstants.spaceLG)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                                .fill(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                                .stroke(DarkFantasyTheme.danger, lineWidth: 4)
                        )
                        .rotationEffect(.degrees(-12))
                        .opacity(stampShown ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: LayoutConstants.spaceSM) {
                    statTile("\(rounds)", rounds == 1 ? "round" : "rounds", DarkFantasyTheme.textPrimary)
                    statTile("\(dealt)", "dealt", DarkFantasyTheme.goldBright)
                    statTile("\(taken)", "taken", taken == 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)

                Text("Counting the spoils…")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .opacity(counting ? 1 : 0)
                    .padding(.bottom, LayoutConstants.spaceLG)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(boss.name) defeated in \(rounds) rounds. Dealt \(dealt), took \(taken)."))
        .onAppear {
            withAnimation(.easeOut(duration: 0.15).delay(0.05)) { slashShown = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                HapticManager.stamp()
                withAnimation(.easeOut(duration: 0.15)) { stampShown = true }
            }
        }
    }

    private func statTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(color.opacity(DarkFantasyTheme.opacityMedium), lineWidth: 1)
        )
    }
}

/// A thin blade-stroke from lower left to upper right, tapered at both ends.
private struct KillSlashShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY - rect.height * 0.08)
        let end = CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.minY + rect.height * 0.10)
        let half: CGFloat = 5
        path.move(to: start)
        path.addLine(to: CGPoint(x: (start.x + end.x) / 2 - half, y: (start.y + end.y) / 2 - half))
        path.addLine(to: end)
        path.addLine(to: CGPoint(x: (start.x + end.x) / 2 + half, y: (start.y + end.y) / 2 + half))
        path.closeSubpath()
        return path
    }
}
