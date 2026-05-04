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
        ZStack(alignment: .top) {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                duelHeader
                roundStrip
                intentLine
                InteractiveMicroLogView(entries: vm.microLogEntries)
                Spacer(minLength: 0)
                predictPanel
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceLG)

            // Cold-start "Connecting" pill — visible only during `.intro`,
            // when /match/start is in flight. Replaces the old full-screen
            // HexPulseLoader. Fades out the moment we transition to .predict.
            if case .intro = vm.phase {
                ConnectingPillStrip(label: "Connecting · round 1 incoming")
                    .padding(.top, LayoutConstants.spaceMD)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

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

    // MARK: - Intent Line
    //
    // Single-line tell about the opponent's likely next attack zone.
    // Combat v3.1 (2026-05-03): replaces the per-side StanceBonusChipStack
    // that used to render the same heuristic as a "predicted" chip under
    // the enemy avatar. One pill, plain English, only visible during
    // `.predict` and only when the heuristic has enough rounds to be
    // confident (see `InteractiveBattleViewModel.intentMinimumRounds`).

    @ViewBuilder
    private var intentLine: some View {
        if vm.phase.isPredicting, let likely = vm.likelyOpponentAttack {
            HStack(spacing: LayoutConstants.spaceXS) {
                Spacer(minLength: 0)
                Text("Enemy may aim · \(likely.rawValue.capitalized)".uppercased())
                    .font(DarkFantasyTheme.badge)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.danger.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(DarkFantasyTheme.danger.opacity(0.4), lineWidth: 1)
                    )
                Spacer(minLength: 0)
            }
            .transition(.opacity)
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
                // Combat v3.1: removed StanceBonusChipStack here. The
                // matrix tile gold-highlight already shows the player's
                // current Hit/Guard zones; rendering the same info as
                // chips under the avatar was a duplicate (and the chip
                // codes "OFF +10%" / "DEF +10%" duplicated the new
                // word-labeled stat on the matrix tiles too).
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
                // Combat v3.1: removed StanceBonusChipStack on the
                // opponent side too. The intent-tell ("Enemy may aim
                // Head") moved to a single pill above the predict panel,
                // and the post-reveal opponent zones are visible inside
                // the round verdict card.
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

    // Note (combat v3.1): the per-side StanceBonusChipStack was removed
    // 2026-05-03 because it duplicated information already shown in the
    // matrix selection. The chip-mode derivation helpers that used to
    // live here (`opponentAttackChipMode`, `opponentDefendChipMode`) are
    // gone with it. The single surviving "intent tell" — "Enemy may
    // aim · {zone}" — is rendered as a pill in `intentLine` above the
    // predict panel and reads `vm.likelyOpponentAttack` directly.

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
            // Optimistic shell: render the predict UI in disabled state so
            // the layout is identical to .predict. The thin "Connecting"
            // pill at the top of the screen carries the loading semantics.
            // No full-panel HexPulseLoader anymore — that was loader #2 of
            // the 3-loader cold-start.
            InteractivePredictView(vm: vm)
                .disabled(true)
                .opacity(0.55)
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
        // Compact duel header (combat v3.1 — 2026-05-03 Variant B):
        //   • YOU/ENEMY moved from a dedicated row above the avatar into a
        //     small corner ribbon on the avatar itself (top-leading).
        //   • HP fraction "currentHp / maxHp" moved INSIDE the bar via
        //     `showTextInside: true` instead of a standalone Text below.
        // Net effect: 2 fewer rows per fighter, ~30pt vertical savings.
        VStack(spacing: LayoutConstants.spaceXS) {
            avatarTile
                // Force a true square — width AND height locked.
                .frame(width: tileSize, height: tileSize)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(borderColor, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                // YOU / ENEMY corner ribbon — replaces the old dedicated
                // side-label row above the avatar. Hidden in `.summary`
                // because the post-fight log already has its own framing
                // and the ribbon would compete with the verdict chrome.
                .overlay(alignment: .topLeading) {
                    if !compact {
                        SideLabelRibbon(text: sideLabel, color: borderColor)
                            .padding(LayoutConstants.spaceXS)
                            .allowsHitTesting(false)
                    }
                }
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

            // HP bar with fraction overlaid inside (showTextInside: true).
            // The standalone `Text("\(currentHp) / \(maxHp)")` row that
            // used to sit beneath the bar is gone — that information is
            // now rendered by HPBarView itself when HP < 100%. At full HP
            // the bar reads as obviously full and the missing fraction
            // is acceptable.
            HPBarView(
                currentHp: currentHp,
                maxHp: maxHp,
                size: .compact,
                showTextInside: true,
                pulseOnCritical: true
            )
        }
        .opacity(outcomeOpacity)
        .shadow(color: outcomeShadowColor, radius: outcomeShadowRadius, y: 0)
        .animation(.easeOut(duration: 0.4), value: outcomeRole)
    }

    private var outcomeOpacity: Double {
        outcomeRole == .loser ? 0.72 : 1.0
    }

    // Note: the standalone hpTextColor helper was removed when the HP
    // fraction moved inside the bar (combat v3.1 — Variant B). HPBarView
    // owns its own color treatment now (canonical gradient + critical
    // pulse), so the side-tinted/hpBlood text logic is no longer needed.

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
                // Quiet skeleton — no spinner, no jitter. Triggers only in
                // the rare case where pre-fight cache didn't have the
                // opponent (e.g. revenge fight against a fighter not in
                // the local cache). The empty silhouette resolves the
                // moment /match/start fills in `defenderProfile`.
                AvatarSkeletonFill()
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

    /// Stance pickers + active-skills HUD. Combat v3.1 (2026-05-03):
    /// the actives row no longer has its own section heading
    /// ("ACTIVE SKILLS"). It now sits as the trailing row inside the
    /// same predict block as the matrix — one unit instead of two
    /// stacked sections — fronted by a small inline "Actives" label
    /// that reads at the same visual weight as the ATTACK / DEFEND row
    /// captions.
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
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("ACTIVES")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Spacer(minLength: 0)
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
        // Combat v3.1: tile renders one big stat + plain-English label
        // sourced from the new structured `attackPrimary` / `defendPrimary`
        // helpers. The old comma-separated bonus string is gone.
        let stat = isAttack
            ? InteractiveStanceBonuses.attackPrimary(for: zone)
            : InteractiveStanceBonuses.defendPrimary(for: zone)
        return ZoneTileButton(
            zone: zone,
            isSelected: isSelected,
            isAttack: isAttack,
            statValue: stat.value,
            statLabel: stat.label,
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
    /// Big single stat for combat v3.1 — e.g. "+10%" / "−10%" / "+8%".
    let statValue: String
    /// Plain-English label rendered under the stat — e.g. "Damage" /
    /// "Damage taken" / "Dodge chance". Replaces the cryptic comma-
    /// separated bonus text ("OFF +10%  CRIT +5%") that used to live here.
    let statLabel: String
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

                // Big stat — one cinematic-feeling number per tile, in
                // gold when selected, near-white otherwise so it remains
                // the visual anchor of the tile.
                Text(statValue)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(
                        isSelected
                            ? DarkFantasyTheme.gold
                            : DarkFantasyTheme.textPrimary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Plain-English label — small, secondary. Tells the
                // player WHAT the percentage is in human language.
                Text(statLabel)
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
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
///
/// Cold-start contract (combat v3.1, 2026-05-03):
/// pre-fight data is already cached when this route mounts (the player came
/// from Arena / Opponent Profile / Dungeon, so `appState.currentCharacter`
/// and the opponent row in `cache.opponents` are warm). We pass those into
/// the VM init as optimistic profiles so `InteractiveBattleView` paints the
/// duel header on the very first frame — no big "PREPARING DUEL" spinner,
/// no per-avatar loaders. Only a thin "Connecting" pill (rendered inside the
/// host view during `.intro`) signals that `/match/start` is in flight.
struct InteractiveBattleRouteView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
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
                // Single-frame placeholder until `.onAppear` assigns the VM.
                // Intentionally empty (no spinner) — the actual loading state
                // lives inside `InteractiveBattleView` once the VM is mounted,
                // and is now an optimistic shell rather than a full-screen
                // pulse loader.
                DarkFantasyTheme.bgPrimary.ignoresSafeArea()
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
                    dungeonRunId: dungeonRunId,
                    attackerProfile: optimisticAttackerProfile(),
                    defenderProfile: optimisticDefenderProfile()
                )
            }
        }
        .onDisappear {
            vm?.cancel()
        }
        .navigationBarBackButtonHidden(true)
    }

    /// Build an optimistic `FighterProfile` for the player from the cached
    /// `Character` in `AppState`. Returns nil only if we somehow opened
    /// combat without a current character (defensive — shouldn't happen
    /// in normal flows because the route is gated on character selection).
    private func optimisticAttackerProfile() -> FighterProfile? {
        guard let character = appState.currentCharacter,
              character.id == characterId else { return nil }
        return FighterProfile(character: character)
    }

    /// Build an optimistic `FighterProfile` for the opponent. Looks up the
    /// id in `cache.opponents` (warm if the player came from Arena) and
    /// falls back to nil — the per-avatar skeleton handles that case
    /// without flashing a spinner.
    private func optimisticDefenderProfile() -> FighterProfile? {
        if let opp = cache.opponents.first(where: { $0.id == opponentId }) {
            return FighterProfile(opponent: opp)
        }
        return nil
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

// MARK: - Cold-Start Optimistic Shell
//
// Two tiny views that replace the 3-loader cold-start (combat v3.1, 2026-05-03):
//   • ConnectingPillStrip — thin opacity-pulse pill at the top of the screen,
//     visible only during `.intro` while /match/start is in flight. Replaces
//     the full-screen "PREPARING DUEL" HexPulseLoader.
//   • AvatarSkeletonFill  — quiet gradient fill used by DuelFighterCard when
//     a profile hasn't been resolved yet. Replaces HexPulseLoader(.compact)
//     so the avatar tile doesn't flash a spinner mid-screen.
//
// Both intentionally use only opacity-based motion (per project rule:
// no scale grow/shrink animations).

struct ConnectingPillStrip: View {
    let label: String
    @State private var dimmed: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Circle()
                .fill(DarkFantasyTheme.gold)
                .frame(width: 6, height: 6)
                .opacity(dimmed ? 0.3 : 1.0)
                .shadow(color: DarkFantasyTheme.gold.opacity(0.6), radius: 4, y: 0)
            Text(label.uppercased())
                .font(DarkFantasyTheme.badge)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.bgPrimary.opacity(0.94))
        )
        .overlay(
            Capsule()
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dimmed = true
            }
        }
    }
}

struct AvatarSkeletonFill: View {
    @State private var pulsed: Bool = false
    var body: some View {
        DarkFantasyTheme.bgSecondary
            .opacity(pulsed ? 0.55 : 0.85)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulsed = true
                }
            }
    }
}

/// Tiny corner ribbon overlaid on the duel-card avatar. Replaces the old
/// dedicated YOU/ENEMY row (combat v3.1 — Variant B). Uses side-tinted
/// fill + white text so it reads against any portrait. Sized to land
/// inside the LayoutConstants.spaceXS overlay padding without crowding
/// the portrait subject.
struct SideLabelRibbon: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.badge)
            .tracking(1.5)
            .foregroundStyle(.white)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(color.opacity(0.92))
            )
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
