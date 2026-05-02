//
//  InteractiveBattleView.swift
//  Hexbound
//
//  Interactive Combat v1 — host screen.
//
//  Layout (mirrors the reference old-combat screen):
//    • Duel header — YOU (green frame) / ENEMY (red frame) portraits with
//      class + level + HP bar inline. Reserved FX slot over each avatar.
//    • Zone badges — last picked Attack / Defend zones.
//    • Predict panel — big ornamental timer, zone pickers, STRIKE + SKIP.
//
//  Combat log is intentionally NOT rendered here — per product decision
//  2026-04-13 it surfaces only in the post-match result modal, so players
//  can review who struck which stance. Data still accumulates on the VM
//  (`combatLogRows`) and is consumed by the result screen in Commit 2.
//
//  VFX burst overlays + result modal are Commit 2 (wired in separately).
//

import SwiftUI

// MARK: - Outcome Role

/// Applied to a fighter card during `.reveal` for peak verdicts only.
/// Drives loser dim + winner gold shadow. `nil` = default look (middle
/// outcomes and any phase other than a peak-verdict reveal).
enum OutcomeRole: Sendable, Equatable {
    case winner
    case loser
}

// MARK: - Host Screen

struct InteractiveBattleView: View {
    @Bindable var vm: InteractiveBattleViewModel

    /// Called when the battle finishes (winner or unavailable). Host presents
    /// the result or falls back to classic flow.
    var onFinished: ((InteractiveBattleViewModel.Phase) -> Void)? = nil

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                duelHeader
                roundStrip
                InteractiveMicroLogView(entries: vm.microLogEntries)
                Spacer(minLength: 0)
                predictPanel
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceLG)

            // Canvas particle VFX — mounted behind PNG FX so sparks sit
            // under the slash/crit/text layer but above the UI chrome.
            CombatVFXOverlay(vfxManager: vm.vfxManager, speedMultiplier: vm.speedMultiplier)
                .allowsHitTesting(false)

            // PNG image FX overlay — slash, crit text, shield, heal.
            CombatFXImageOverlay(fxManager: vm.fxImageManager)
                .allowsHitTesting(false)

            // Verdict flash — screen-level radial tint keyed to the current
            // round's verdict. Fires once per resolved exchange.
            CombatVerdictFlash(
                verdict: vm.currentExchange?.verdict,
                triggerId: vm.currentExchange?.id
            )
        }
        // Resolve fighter-card anchors in screen coordinates and push them
        // to the VM so VFX/FX land on the right avatar. Attached to the root
        // so `proxy.size` === screen size.
        .overlayPreferenceValue(FighterAnchorKey.self) { entries in
            GeometryReader { proxy in
                Color.clear
                    .onAppear { publishAnchors(entries: entries, proxy: proxy) }
                    .onChange(of: proxy.size.width) { _, _ in
                        publishAnchors(entries: entries, proxy: proxy)
                    }
            }
            .allowsHitTesting(false)
        }
        .onAppear { vm.startMatch() }
        .onChange(of: phaseKey(vm.phase)) { _, _ in
            switch vm.phase {
            case .finished, .unavailable, .error:
                onFinished?(vm.phase)
            default:
                break
            }
        }
    }

    // MARK: - Round Strip

    /// Small tracking strip between the duel header and the predict panel.
    /// Left: current round number (mirrors the prototype "ROUND 3" marker).
    /// Right: short phase label so the player always knows what they are
    /// being asked to do. Hidden in terminal / summary phases where it
    /// would compete with the VICTORY / DEFEAT chrome.
    @ViewBuilder
    private var roundStrip: some View {
        if shouldShowRoundStrip {
            HStack {
                Text("ROUND \(vm.currentRoundNumber)")
                    .font(DarkFantasyTheme.badge)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Spacer(minLength: LayoutConstants.spaceSM)
                Text(phaseTagLabel)
                    .font(DarkFantasyTheme.badge)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LayoutConstants.space2XS)
        }
    }

    private var shouldShowRoundStrip: Bool {
        switch vm.phase {
        case .predict, .resolving, .reveal: return true
        default: return false
        }
    }

    private var phaseTagLabel: String {
        switch vm.phase {
        case .predict:   return "CHOOSE YOUR STRIKE"
        case .resolving: return "STRIKING…"
        case .reveal:    return "REVEAL"
        default:         return ""
        }
    }

    // MARK: - Duel Header (YOU vs ENEMY)

    /// Duel header with live avatar anchor reporting. After layout, each
    /// `DuelFighterCard` publishes its frame via an anchor preference; the
    /// root `overlayPreferenceValue` resolves those anchors in screen
    /// coordinates and feeds the VM so VFX/FX land on the correct avatar.
    /// Slide-in offsets + hit flash also live here.
    private var duelHeader: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceMD) {
            // YOU
            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .player,
                    profile: vm.attackerProfile,
                    currentHp: vm.state.attackerHp,
                    maxHp: vm.state.attackerMaxHp,
                    slideX: vm.playerSlideX,
                    flash: vm.playerFlash,
                    popups: vm.damagePopups.filter { !$0.onDefender },
                    compact: vm.phase.isSummary,
                    outcomeRole: vm.playerOutcomeRole
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .player, bounds: $0)]
                }
                // Long-press own portrait → skip this round. Gesture only
                // fires during `.predict`; any other phase is a no-op inside
                // the VM's `skipAndSubmit()` guard.
                .onLongPressGesture(minimumDuration: 0.5) {
                    guard vm.phase.isPredicting else { return }
                    HapticManager.medium()
                    vm.skipAndSubmit()
                }
                // Player stance always resolves to a confirmed selection:
                // the VM defaults to .chest and the picker keeps a current
                // choice at all times, so both chips are always .confirmed.
                // Hidden in `.summary` — the post-battle log is the focus there
                // and the stance chips add noise without informing the recap.
                if !vm.phase.isSummary {
                    StanceBonusChipStack(
                        attackMode: .confirmed(vm.selectedAttackZone),
                        defendMode: .confirmed(vm.selectedDefendZone)
                    )
                }
                if let playerLabel = vm.lastActiveFiredLabel {
                    ActiveFireBanner(actionType: playerLabel, isOpponent: false)
                        .id("you-fire-\(playerLabel)")
                }
                if let potionType = vm.lastPlayerConsumableFired {
                    ConsumableFireBanner(consumableType: potionType, isOpponent: false)
                        .id("you-potion-\(potionType)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)

            // FOE
            VStack(spacing: LayoutConstants.spaceXS) {
                DuelFighterCard(
                    side: .enemy,
                    profile: vm.defenderProfile,
                    currentHp: vm.state.defenderHp,
                    maxHp: vm.state.defenderMaxHp,
                    slideX: vm.enemySlideX,
                    flash: vm.enemyFlash,
                    popups: vm.damagePopups.filter { $0.onDefender },
                    compact: vm.phase.isSummary,
                    outcomeRole: vm.opponentOutcomeRole
                )
                .anchorPreference(key: FighterAnchorKey.self, value: .bounds) {
                    [FighterAnchorKey.Entry(side: .enemy, bounds: $0)]
                }
                // Opponent chips cover three phases:
                //   • `.predict` + last strike revealed          → confirmed (last round's zones)
                //   • `.predict` before any reveal + history OK  → predicted ATK (heuristic), hidden DEF
                //   • `.reveal` / `.resolving`                   → confirmed (fresh reveal)
                // We don't know the opponent's upcoming DEF from the
                // intent heuristic alone, so DEF stays hidden during
                // predict. ATK is where the tell lives.
                // Hidden in `.summary` — see player-side comment above.
                if !vm.phase.isSummary {
                    StanceBonusChipStack(
                        attackMode: opponentAttackChipMode,
                        defendMode: opponentDefendChipMode
                    )
                }
                if !vm.opponentActives.isEmpty {
                    OpponentActivesPreview(actives: vm.opponentActives)
                }
                if let oppLabel = vm.lastOpponentActiveFiredLabel {
                    ActiveFireBanner(actionType: oppLabel, isOpponent: true)
                        .id("opp-fire-\(oppLabel)")
                }
                if let oppPotion = vm.lastOpponentConsumableFired {
                    ConsumableFireBanner(consumableType: oppPotion, isOpponent: true)
                        .id("opp-potion-\(oppPotion)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.lastActiveFiredLabel)
        .animation(.easeInOut(duration: 0.2), value: vm.lastOpponentActiveFiredLabel)
        .animation(.easeInOut(duration: 0.2), value: vm.lastPlayerConsumableFired)
        .animation(.easeInOut(duration: 0.2), value: vm.lastOpponentConsumableFired)
        .animation(.easeInOut(duration: 0.25), value: vm.likelyOpponentAttack)
        .animation(.easeInOut(duration: 0.25), value: vm.selectedAttackZone)
        .animation(.easeInOut(duration: 0.25), value: vm.selectedDefendZone)
        .animation(.easeInOut(duration: 0.25), value: vm.lastOpponentZones?.attack)
        .animation(.easeInOut(duration: 0.25), value: vm.lastOpponentZones?.defend)
    }

    // MARK: - Opponent chip mode derivation

    /// ATK chip for the opponent side. Priority order:
    ///   1. If `lastOpponentZones` is known (post-reveal)  → confirmed
    ///   2. Else if predicting and we have a heuristic tell → predicted
    ///   3. Else → hidden
    private var opponentAttackChipMode: StanceBonusChip.Mode {
        if let zones = vm.lastOpponentZones {
            return .confirmed(zones.attack)
        }
        if vm.phase.isPredicting, let likely = vm.likelyOpponentAttack {
            return .predicted(likely)
        }
        return .hidden
    }

    /// DEF chip for the opponent side. We never "predict" defense —
    /// the tell lives on attack only. During predict: hidden.
    /// After reveal: confirmed.
    private var opponentDefendChipMode: StanceBonusChip.Mode {
        if let zones = vm.lastOpponentZones {
            return .confirmed(zones.defend)
        }
        return .hidden
    }

    /// Convert each fighter's anchor bounds → normalized screen-space position,
    /// then write into the VM for VFX placement. Called from the root-attached
    /// `overlayPreferenceValue`, where `proxy.size` equals the screen size.
    private func publishAnchors(entries: [FighterAnchorKey.Entry],
                                proxy: GeometryProxy) {
        let screen = proxy.size
        guard screen.width > 0, screen.height > 0 else { return }
        for entry in entries {
            let rect = proxy[entry.bounds]
            // Aim FX at the avatar tile: card mid-x, card top third.
            let p = CGPoint(
                x: rect.midX / screen.width,
                y: (rect.minY + rect.height * 0.30) / screen.height
            )
            switch entry.side {
            case .player: vm.playerAvatarPos = p
            case .enemy:  vm.enemyAvatarPos  = p
            }
        }
    }

    // MARK: - Predict Panel (pickers + actives + bottom bar)

    @ViewBuilder
    private var predictPanel: some View {
        switch vm.phase {
        case .intro:
            HexPulseLoader(.standard, message: "PREPARING DUEL")
                .frame(maxWidth: .infinity, minHeight: 180)
        case .unavailable:
            unavailableBanner
        case .error(let message):
            errorBanner(message: message)
        case .finished(let winnerId):
            finishedBanner(winnerId: winnerId)
        case .completing:
            HexPulseLoader(.standard, message: "FINALIZING")
                .frame(maxWidth: .infinity, minHeight: 180)
        case .summary:
            // Finishing blow landed — replace the predict panel with the
            // full-battle log + CONTINUE button. Avatars (YOU/ENEMY cards)
            // above this panel stay on screen.
            BattleSummaryView(vm: vm)
        default:
            // .predict / .resolving / .reveal — controls stay mounted so layout
            // doesn't jump, but get disabled while the server is resolving.
            // Timer is integrated into the STRIKE button (TimerRingStrikeButton)
            // — no separate PredictTimerBar anymore.
            InteractivePredictView(vm: vm)
                .disabled(vm.phase.isBusy)
                .opacity(vm.phase.isBusy ? 0.6 : 1.0)
        }
    }

    // MARK: - Terminal Banners

    private func finishedBanner(winnerId: String) -> some View {
        let won = (winnerId == vm.state.attackerId)
        return VStack(spacing: LayoutConstants.spaceSM) {
            Text(won ? "VICTORY" : "DEFEAT")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(won ? DarkFantasyTheme.gold : DarkFantasyTheme.danger)
            Text("\(vm.state.strikes.count) strike\(vm.state.strikes.count == 1 ? "" : "s")")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var unavailableBanner: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Interactive mode unavailable")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
            Text("Falling back to classic battle")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private func errorBanner(message: String) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Strike failed")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.danger)
            Text(message)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    // MARK: - Phase Diffing

    /// `Phase` has associated values — reduce to a stable string key for `onChange`.
    private func phaseKey(_ p: InteractiveBattleViewModel.Phase) -> String {
        switch p {
        case .intro: return "intro"
        case .predict: return "predict"
        case .resolving: return "resolving"
        case .reveal: return "reveal"
        case .summary: return "summary"
        case .completing: return "completing"
        case .finished(let id): return "finished:\(id)"
        case .unavailable: return "unavailable"
        case .error(let m): return "error:\(m)"
        }
    }
}

// MARK: - Duel Fighter Card

enum DuelSide { case player, enemy }

/// Preference key that carries each fighter card's layout anchor up to the
/// screen root, so we can normalize its position into (0…1) coordinates
/// and feed the VFX/FX overlay managers.
struct FighterAnchorKey: PreferenceKey {
    struct Entry: Equatable {
        let side: DuelSide
        let bounds: Anchor<CGRect>
        // Anchor<CGRect> is not Equatable; we compare by side identity only,
        // which is enough to dedupe two player-side or two enemy-side anchors.
        static func == (lhs: Entry, rhs: Entry) -> Bool { lhs.side == rhs.side }
    }
    static var defaultValue: [Entry] = []
    static func reduce(value: inout [Entry], nextValue: () -> [Entry]) {
        value.append(contentsOf: nextValue())
    }
}

private struct DuelFighterCard: View {
    typealias Side = DuelSide

    @Environment(GameDataCache.self) private var cache

    let side: Side
    let profile: FighterProfile?
    let currentHp: Int
    let maxHp: Int
    var slideX: CGFloat = 0
    var flash: Bool = false
    var popups: [DamagePopup] = []
    /// When true the avatar tile renders at the compact 80pt square.
    /// Used by the `.summary` phase so the post-battle log gets the
    /// vertical room it needs without dropping the YOU/ENEMY identity.
    var compact: Bool = false
    /// Peak-verdict framing (Phase 4). `nil` for middle outcomes and any
    /// non-reveal phase — keeps the default look.
    var outcomeRole: OutcomeRole? = nil

    private var borderColor: Color {
        side == .player ? DarkFantasyTheme.success : DarkFantasyTheme.danger
    }

    private var sideLabel: String {
        side == .player ? "YOU" : "ENEMY"
    }

    /// Explicit square dimension. Replaces the previous
    /// `.aspectRatio(1, .fit) + .frame(maxWidth:)` chain — that combo
    /// was leaking the inner `AvatarImageView`'s fixed 200pt frame
    /// through aspectRatio's `.fit` proposal and producing portrait
    /// (taller-than-wide) tiles in summary on some devices. Matches
    /// the classic combat header sizing in `CombatDetailView`.
    private var tileSize: CGFloat { compact ? 80 : 130 }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(sideLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(borderColor)

            avatarTile
                // Force a true square — width AND height locked.
                .frame(width: tileSize, height: tileSize)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(borderColor, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                // Hit flash — mirrors CombatDetailView
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.danger.opacity(flash ? 0.35 : 0.0))
                        .allowsHitTesting(false)
                )
                // Floating damage / heal popups over the avatar
                .overlay(alignment: .top) {
                    ZStack {
                        ForEach(popups) { popup in
                            DamagePopupBubble(popup: popup)
                        }
                    }
                    .allowsHitTesting(false)
                }
                // Attacker slide-in X offset (per side)
                .offset(x: slideX)
                // Outer centering frame — keeps the tile horizontally
                // centered inside its (wider) column.
                .frame(maxWidth: .infinity)

            Text(profile?.name.uppercased() ?? "…")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(profileSubtitle)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            HPBarView(
                currentHp: currentHp,
                maxHp: maxHp,
                size: .compact,
                showTextInside: false,
                pulseOnCritical: true
            )

            // HP numeric readout uses the side-specific border color so a
            // quick glance at the number alone already tells you whose HP
            // you're reading. Low-HP tint overrides with `hpBlood` to warn
            // regardless of side when either fighter is near death.
            Text("\(currentHp) / \(maxHp)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(hpTextColor)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.25), value: currentHp)
        }
        .opacity(outcomeOpacity)
        .shadow(color: outcomeShadowColor, radius: outcomeShadowRadius, y: 0)
        .animation(.easeOut(duration: 0.4), value: outcomeRole)
    }

    private var outcomeOpacity: Double {
        outcomeRole == .loser ? 0.72 : 1.0
    }

    /// HP text color. Side-tinted until HP drops low, then flips to
    /// blood red so the "I'm about to die" signal reads the same for
    /// both fighters.
    private var hpTextColor: Color {
        let ratio = maxHp > 0 ? Double(currentHp) / Double(maxHp) : 0
        if ratio <= 0.25 { return DarkFantasyTheme.hpBlood }
        return borderColor
    }

    private var outcomeShadowColor: Color {
        outcomeRole == .winner ? DarkFantasyTheme.gold.opacity(0.4) : .clear
    }

    private var outcomeShadowRadius: CGFloat {
        outcomeRole == .winner ? 16 : 0
    }

    private var profileSubtitle: String {
        guard let profile else { return "—" }
        return "Lv.\(profile.level) \(profile.characterClass.displayName)"
    }

    @ViewBuilder
    private var avatarTile: some View {
        ZStack {
            DarkFantasyTheme.bgSecondary
            if let profile {
                avatarContent(for: profile)
            } else {
                HexPulseLoader(.compact)
            }
        }
    }

    /// Resolution order for the rendered portrait:
    ///   1. Dungeon-boss portrait by name (enemy side only)
    ///   2. Rush-mob portrait by name    (enemy side only)
    ///   3. AvatarImageView with `deterministicSeed: profile.id` so
    ///      bots without a `skinKey` still get a stable hero portrait
    ///      from the shared pool instead of falling all the way through
    ///      to the class-icon fallback.
    /// Mirrors the resolution order used in `CombatDetailView` (classic
    /// combat) so both surfaces show the same enemy art.
    @MainActor
    @ViewBuilder
    private func avatarContent(for profile: FighterProfile) -> some View {
        let isEnemy = side == .enemy
        let mirrorScale: CGFloat = isEnemy ? -1 : 1

        if isEnemy,
           let bossAsset = EnemyPortraitResolver.bossPortraitImage(for: profile.name, cache: cache),
           UIImage(named: bossAsset) != nil {
            Image(bossAsset)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .scaleEffect(x: mirrorScale, y: 1)
        } else if isEnemy,
                  let rushAsset = EnemyPortraitResolver.rushEnemyPortrait(for: profile.name) {
            Image(rushAsset)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .scaleEffect(x: mirrorScale, y: 1)
        } else {
            AvatarImageView(
                skinKey: profile.avatar,
                characterClass: profile.characterClass,
                size: 200,
                deterministicSeed: profile.id
            )
            .scaleEffect(x: mirrorScale, y: 1)
        }
    }
}

// MARK: - Predict View (zone pickers + actives + commit bar)

struct InteractivePredictView: View {
    @Bindable var vm: InteractiveBattleViewModel

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // 1+2) Pickers + Active skills OR Round Exchange log card.
            //      During .resolving / .reveal the VM publishes a
            //      `currentExchange`, which swaps the stance picker
            //      surface for the gold-bordered log card. The CTA
            //      row below morphs in lock-step.
            ZStack(alignment: .top) {
                if let exchange = vm.currentExchange {
                    InteractiveRoundLogCard(exchange: exchange) {
                        vm.dismissExchange()
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal:   .opacity.combined(with: .move(edge: .top))
                    ))
                } else {
                    predictControls
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal:   .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.currentExchange?.id)

            // 3) Bottom bar — SKIP on the left, STRIKE (with integrated
            //    radial timer) on the right. Equal-weight so the CTAs
            //    form a balanced commit row. While a round exchange is
            //    on screen, STRIKE morphs into the locked YOUR CHOICE
            //    badge and SKIP dims to avoid double-dismiss.
            HStack(spacing: LayoutConstants.spaceSM) {
                SkipButtonWithTooltip(
                    disabled: vm.currentExchange != nil,
                    action: { vm.skipAndSubmit() }
                )
                .frame(maxWidth: .infinity)

                ZStack {
                    if vm.currentExchange == nil {
                        TimerRingStrikeButton(
                            remainingFraction: timerFraction,
                            isCritical: vm.predictTimeRemaining <= 1.5,
                            isBusy: false,
                            action: { vm.submitStrike() }
                        )
                        .transition(.opacity)
                    } else {
                        YourChoiceButton(
                            attackZone: vm.selectedAttackZone,
                            defendZone: vm.selectedDefendZone
                        )
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: vm.currentExchange?.id)
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// Stance pickers + active-skills HUD. Extracted so it can live
    /// inside the ZStack that swaps it for the Round Exchange log card.
    @ViewBuilder
    private var predictControls: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            zonePicker(
                title: "ATTACK",
                selection: Binding(
                    get: { vm.selectedAttackZone },
                    set: { vm.pickAttack($0) }
                )
            )
            zonePicker(
                title: "DEFEND",
                selection: Binding(
                    get: { vm.selectedDefendZone },
                    set: { vm.pickDefend($0) }
                )
            )

            if !vm.playerActives.isEmpty {
                VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                    Text("ACTIVE SKILLS")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    ActiveSkillsHUD(
                        actives: vm.playerActives,
                        pendingSlot: vm.pendingActiveSlot,
                        isInteractive: true,
                        onTap: { vm.toggleActiveSlot($0) }
                    )
                }
            }
        }
    }

    private var timerFraction: Double {
        let total = InteractiveBattleViewModel.predictWindowSeconds
        guard total > 0 else { return 0 }
        return max(0, min(1, vm.predictTimeRemaining / total))
    }

    private func zonePicker(title: String, selection: Binding<InteractiveBodyZone>) -> some View {
        let isAttack = title == "ATTACK"
        return VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text(title)
                .font(DarkFantasyTheme.uiLabel)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(InteractiveBodyZone.allCases, id: \.self) { zone in
                    zoneTile(
                        zone: zone,
                        isSelected: selection.wrappedValue == zone,
                        isAttack: isAttack
                    ) {
                        selection.wrappedValue = zone
                    }
                }
            }
        }
    }

    private func zoneTile(zone: InteractiveBodyZone,
                          isSelected: Bool,
                          isAttack: Bool,
                          action: @escaping () -> Void) -> some View {
        let bonusText = isAttack
            ? InteractiveStanceBonuses.attackBonusText(for: zone)
            : InteractiveStanceBonuses.defendBonusText(for: zone)
        return ZoneTileButton(
            zone: zone,
            isSelected: isSelected,
            isAttack: isAttack,
            bonusText: bonusText,
            fallbackIcon: fallbackIconForZone(zone),
            action: action
        )
    }

    /// SF Symbol fallback used by `CachedAssetImage` if the zone asset
    /// isn't available in the bundle yet (keeps the tile from flashing
    /// a broken-image icon during a cold cache).
    private func fallbackIconForZone(_ zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head: return "brain.head.profile"
        case .chest: return "heart.fill"
        case .legs: return "figure.walk"
        }
    }
}

// MARK: - Skip Button with Tooltip
//
// Wraps the `SKIP` CTA with a long-press tooltip so players learn what it
// actually does. Spec: tapping SKIP picks random zones and submits — NO
// penalty, NO damage hit, NO stamina cost. It's a "I'm not sure, just
// roll the dice" button. The tooltip makes that explicit so it stops
// reading as a scary escape-hatch with hidden downsides.

private struct SkipButtonWithTooltip: View {
    let disabled: Bool
    let action: () -> Void
    @State private var showTooltip = false

    var body: some View {
        Button(action: action) {
            Text("SKIP")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .frame(maxWidth: .infinity, minHeight: LayoutConstants.buttonHeightLG)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
        .onLongPressGesture(minimumDuration: 0.35) {
            guard !disabled else { return }
            HapticManager.selection()
            showTooltip = true
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            CombatInfoTooltipContent(
                title: "SKIP",
                message: "Picks random attack and defense zones, then submits. No penalty — safe pick if you can't decide in time."
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityHint(Text("Long press for details"))
    }
}

// MARK: - Zone Tile Button
//
// Extracted from `zoneTile(...)` so it can own a `@State` for the long-press
// tooltip. SwiftUI view-builder methods can't own state; promoting the tile
// into a struct unlocks the popover without refactoring the parent view.

private struct ZoneTileButton: View {
    let zone: InteractiveBodyZone
    let isSelected: Bool
    let isAttack: Bool
    let bonusText: String
    let fallbackIcon: String
    let action: () -> Void

    @State private var showTooltip = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.space2XS) {
                CachedAssetImage(
                    key: InteractiveStanceBonuses.assetName(for: zone),
                    url: nil,
                    systemIcon: fallbackIcon,
                    contentMode: .fit
                )
                .frame(width: 28, height: 28)

                Text(zone.rawValue.uppercased())
                    .font(DarkFantasyTheme.badge)

                Text(bonusText)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(
                        isSelected
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.textTertiary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceSM)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(isSelected ? DarkFantasyTheme.gold.opacity(0.2) : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.borderSubtle,
                            lineWidth: isSelected ? 2 : 1)
            )
            .foregroundStyle(isSelected ? DarkFantasyTheme.gold : DarkFantasyTheme.textPrimary)
            .opacity(isSelected ? 1.0 : 0.85)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.35) {
            HapticManager.selection()
            showTooltip = true
        }
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            CombatInfoTooltipContent(
                title: tooltipTitle,
                message: tooltipMessage
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityHint(Text("Long press for details"))
    }

    private var tooltipTitle: String {
        let channel = isAttack ? "ATTACK" : "DEFENSE"
        return "\(channel) · \(zone.rawValue.uppercased())"
    }

    private var tooltipMessage: String {
        isAttack
            ? InteractiveStanceBonuses.attackTooltip(for: zone)
            : InteractiveStanceBonuses.defendTooltip(for: zone)
    }
}

// MARK: - Route Wrapper

/// Thin wrapper that owns the `InteractiveBattleViewModel` lifecycle and wires
/// the terminal phases back into AppState navigation. Mounted by `AppRouter`
/// for the `.interactiveBattle` route.
struct InteractiveBattleRouteView: View {
    @Environment(AppState.self) private var appState
    let characterId: String
    let opponentId: String
    let attackerMaxHp: Int
    let defenderMaxHp: Int
    let opponentType: InteractiveOpponentType
    let dungeonRunId: String?

    @State private var vm: InteractiveBattleViewModel?

    var body: some View {
        Group {
            if let vm {
                InteractiveBattleView(
                    vm: vm,
                    onFinished: { phase in
                        handleTerminal(phase, vm: vm)
                    }
                )
            } else {
                ZStack {
                    DarkFantasyTheme.bgPrimary.ignoresSafeArea()
                    HexPulseLoader(.large, message: "PREPARING DUEL")
                }
            }
        }
        .onAppear {
            if vm == nil {
                vm = InteractiveBattleViewModel(
                    appState: appState,
                    attackerCharacterId: characterId,
                    defenderCharacterId: opponentId,
                    attackerMaxHp: attackerMaxHp,
                    defenderMaxHp: defenderMaxHp,
                    opponentType: opponentType,
                    dungeonRunId: dungeonRunId
                )
            }
        }
        .onDisappear {
            vm?.cancel()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func handleTerminal(_ phase: InteractiveBattleViewModel.Phase,
                                vm: InteractiveBattleViewModel) {
        switch phase {
        case .finished:
            if let data = vm.finalCombatData {
                // CombatResultDetailView reads appState.combatResult (NOT
                // combatData) — setting the wrong property triggers the
                // fallback "Battle Failed" error state. Set both so any
                // downstream consumer (in-progress playback vs result modal)
                // sees the final data.
                appState.combatResult = data
                appState.combatData = data
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
                appState.mainPath.append(AppRoute.combatResult)
            } else {
                appState.showToast("Match ended", type: .info)
                if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            }
        case .unavailable:
            // /pvp/match/start returned 404 — endpoint not deployed (feature
            // flag on client but backend rolled back, or race between deploys).
            // Disable interactive combat for the rest of this session, then
            // signal ArenaDetailView to re-run the fight in classic mode for
            // the same opponent. No user-visible "unavailable" toast — the
            // fallback should be transparent.
            appState.interactiveCombatLocallyDisabled = true
            let oppId = opponentId
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
            // Set pending id AFTER pop so ArenaDetailView's onChange fires
            // once the arena screen is back in scope.
            appState.pendingClassicFightOpponentId = oppId
        case .error(let message):
            appState.showToast("Match failed", subtitle: message, type: .error)
            if !appState.mainPath.isEmpty { appState.mainPath.removeLast() }
        default:
            break
        }
    }
}

// MARK: - Inline Micro Log
//
// A compact auto-expiring ticker shown above the predict panel. Each entry
// lives for `MicroLogEntry.ttl` then fades out. The view owns a timer that
// re-renders once every 0.3s so stale entries visibly drop even when the VM
// isn't publishing new state.

struct InteractiveMicroLogView: View {
    let entries: [MicroLogEntry]

    /// Ticking `now` so fade-out opacity recomputes without a VM prod.
    @State private var now: Date = Date()

    /// Only the entries still within their TTL — keeps the strip from
    /// showing yesterday's round when the player sits idle in `.predict`.
    private var visible: [MicroLogEntry] {
        entries.filter { now.timeIntervalSince($0.createdAt) < MicroLogEntry.ttl }
    }

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            ForEach(visible) { entry in
                MicroLogRow(entry: entry, now: now)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal:   .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.2), value: visible.map(\.id))
        .onAppear { startTicker() }
    }

    /// Periodic clock tick — cheap way to drive opacity fade without
    /// pushing extra state into the VM. Stops when the view disappears.
    private func startTicker() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(300))
                await MainActor.run { now = Date() }
            }
        }
    }
}

private struct MicroLogRow: View {
    let entry: MicroLogEntry
    let now: Date

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Text(sideTag)
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(sideColor)
                .frame(width: 46, alignment: .leading)

            Text(entry.zoneLabel)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            Spacer(minLength: LayoutConstants.space2XS)

            Text(resultLabel)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(resultColor)
                .lineLimit(1)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.4))
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(sideColor)
                .frame(width: 2)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
        }
        .opacity(opacity)
    }

    private var sideTag: String {
        entry.side == .you ? "YOU" : "ENEMY"
    }

    private var sideColor: Color {
        entry.side == .you ? DarkFantasyTheme.success : DarkFantasyTheme.danger
    }

    /// Entry fades out over the last 0.6s of its TTL so it doesn't snap away.
    private var opacity: Double {
        let age = now.timeIntervalSince(entry.createdAt)
        let fadeStart = MicroLogEntry.ttl - 0.6
        if age <= fadeStart { return 1.0 }
        let remaining = max(0, MicroLogEntry.ttl - age)
        return max(0, min(1, remaining / 0.6))
    }

    private var resultLabel: String {
        switch entry.kind {
        case .hit:   return "\(entry.damage) DMG"
        case .crit:  return "\(entry.damage) CRIT!"
        case .block: return "BLOCKED"
        case .dodge: return "DODGED"
        case .miss:  return "MISS"
        }
    }

    private var resultColor: Color {
        switch entry.kind {
        case .hit:   return DarkFantasyTheme.textPrimary
        case .crit:  return DarkFantasyTheme.gold
        case .block: return DarkFantasyTheme.info
        case .dodge: return DarkFantasyTheme.textTertiary
        case .miss:  return DarkFantasyTheme.textTertiary
        }
    }
}
