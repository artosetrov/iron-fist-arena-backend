import SwiftUI

/// Gold Mine payout celebration: a Collect All haul, a bonus run, and — when
/// the haul filled the expedition — the chest.
///
/// The chest is opened by a tap and plays a short scene (approved exception
/// to the opacity-only motion rule, like the Dungeon Rush treasure chest):
/// it rattles, the lock gives and light leaks from the crack, the lid flies
/// open over spinning rays with a particle burst, coins and gems spout out
/// and fly into the reward counters, which tick up as they land.
/// Reduce Motion keeps only the cross-fades and the count.
struct MineClaimRewardView: View {
    let reward: GoldMineViewModel.ClaimRewardData
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shownGold = 0
    @State private var shownGems = 0
    /// Latest amounts (a Collect All shows its own count first, then the
    /// server's) — the delayed count-up reads these, not the first `reward`.
    @State private var targetGold = 0
    @State private var targetGems = 0
    @State private var counted = false
    @State private var showHaul = false
    @State private var showChest = false
    @State private var showButton = false
    @State private var isClosing = false

    // Chest scene
    @State private var stage: MineChestStage = .closed
    @State private var shakeTrigger = 0
    @State private var popTrigger = 0
    @State private var burst = false
    @State private var lightLevel: Double = 0
    @State private var fountainStart: Date?
    @State private var chestRowVisible = false
    @State private var chestGold = 0
    @State private var chestGems = 0
    @State private var chestDone = false
    @State private var anchors: [MineChestAnchor: CGPoint] = [:]

    private static let space = "mineClaimReward"

    private var hasHaul: Bool { reward.goldEarned > 0 || reward.gemsEarned > 0 }
    private var chestWaiting: Bool { reward.chest != nil && stage == .closed }
    /// The chest is mid-scene: nothing closes the modal until it settles.
    private var chestPlaying: Bool { reward.chest != nil && stage != .closed && !chestDone }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { primaryAction() }

            VStack(spacing: LayoutConstants.spaceLG) {
                if showHaul {
                    haulBlock
                        .transition(.opacity)
                }
                if showChest, let chest = reward.chest {
                    chestBlock(chest)
                        .transition(.opacity)
                }
                if showButton {
                    Button(action: primaryAction) {
                        Text(chestWaiting ? "OPEN CHEST" : "CONTINUE")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, LayoutConstants.spaceLG)
                    .opacity(chestPlaying ? 0 : 1)
                    .disabled(chestPlaying)
                    .transition(.opacity)
                }
            }
            .padding(LayoutConstants.spaceLG)

            if let start = fountainStart, let origin = anchors[.chest], let chest = reward.chest {
                MineCoinFountain(
                    start: start,
                    origin: origin,
                    goldTarget: anchors[.gold],
                    gemTarget: anchors[.gems],
                    coinCount: chest.gold > 0 ? min(18, max(10, chest.gold / 10)) : 0,
                    gemCount: chest.gems > 0 ? min(6, max(3, chest.gems * 2)) : 0
                )
            }
        }
        .coordinateSpace(.named(Self.space))
        .onPreferenceChange(MineChestAnchorKey.self) { anchors = $0 }
        .onAppear {
            targetGold = reward.goldEarned
            targetGems = reward.gemsEarned
            runEntry()
        }
        .onChange(of: reward) { _, next in
            // The server's correction (or the chest) can land after the
            // optimistic Collect All celebration opened — or while it closes.
            targetGold = next.goldEarned
            targetGems = next.gemsEarned
            withAnimation(MotionConstants.smooth) {
                if counted {
                    shownGold = next.goldEarned
                    shownGems = next.gemsEarned
                }
                if isClosing {
                    isClosing = false
                    showHaul = true
                    showButton = true
                }
                if next.chest != nil { showChest = true }
            }
        }
    }

    // MARK: Haul

    private var haulBlock: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(reward.kind == .bonus ? "icon-mine-bonus" : MineRails.fullCart)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 120, height: 104)
                .accessibilityHidden(true)
            Text(reward.kind == .bonus ? "BONUS RUN" : "MINE HAUL")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(3)
            if hasHaul, counted {
                rewardRow(gold: reward.goldEarned > 0 ? shownGold : nil,
                          gems: reward.gemsEarned > 0 ? shownGems : nil)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Chest

    private func chestBlock(_ chest: GoldMineExpeditionChest) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("EXPEDITION COMPLETE")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)

            Button(action: openChest) {
                MineChestScene(
                    stage: stage,
                    lightLevel: lightLevel,
                    shakeTrigger: shakeTrigger,
                    popTrigger: popTrigger,
                    burst: $burst
                )
                .background { anchor(.chest, yOffset: -18) }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(stage != .closed)
            .accessibilityLabel(stage == .closed ? "Open the expedition chest" : "Expedition chest, opened")

            ZStack {
                rewardRow(
                    gold: chest.gold > 0 ? chestGold : nil,
                    gems: chest.gems > 0 ? chestGems : nil,
                    anchored: true
                )
                .opacity(chestRowVisible ? 1 : 0)
                .accessibilityHidden(!chestRowVisible)

                Text("Tap the chest")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .opacity(stage == .closed ? 1 : 0)
                    .accessibilityHidden(stage != .closed)
            }
        }
    }

    private func rewardRow(gold: Int?, gems: Int?, anchored: Bool = false) -> some View {
        HStack(spacing: LayoutConstants.spaceLG) {
            if let gold {
                rewardItem(icon: "icon-gold", value: gold, color: DarkFantasyTheme.goldBright,
                           anchor: anchored ? MineChestAnchor.gold : nil)
            }
            if let gems {
                rewardItem(icon: "icon-gems", value: gems, color: DarkFantasyTheme.cyan,
                           anchor: anchored ? MineChestAnchor.gems : nil)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func rewardItem(icon: String, value: Int, color: Color, anchor role: MineChestAnchor?) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 32, height: 32)
                .background {
                    if let role { anchor(role) }
                }
                .accessibilityHidden(true)
            Text("+\(value)")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(role == nil ? .opacity : .numericText(value: Double(value)))
        }
    }

    /// Publishes this view's centre (in the modal's space) for the coin fountain.
    private func anchor(_ role: MineChestAnchor, yOffset: CGFloat = 0) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named(Self.space))
            Color.clear.preference(
                key: MineChestAnchorKey.self,
                value: [role: CGPoint(x: frame.midX, y: frame.midY + yOffset)]
            )
        }
    }

    // MARK: Flow

    private func primaryAction() {
        if chestWaiting {
            openChest()
        } else if !chestPlaying {
            dismiss()
        }
    }

    private func runEntry() {
        SFXManager.shared.play(.uiRewardClaim)
        withAnimation(MotionConstants.smooth) { showHaul = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(MotionConstants.smooth) {
                counted = true
                shownGold = targetGold
                shownGems = targetGems
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(MotionConstants.smooth) {
                if reward.chest != nil { showChest = true }
                showButton = true
            }
        }
    }

    /// The chest scene, from the tap (t = 0):
    /// 0.00 rattle · 0.48 lock gives, lid ajar, light leaks ·
    /// 0.80 lid flies open: rays, burst, coin fountain · ~1.7 coins land, count ·
    /// ~2.5 settle, CONTINUE.
    private func openChest() {
        guard let chest = reward.chest, stage == .closed else { return }
        withAnimation(MotionConstants.smooth) { showChest = true }

        if reduceMotion {
            SFXManager.shared.play(.chestOpen)
            HapticManager.success()
            withAnimation(MotionConstants.smooth) {
                stage = .open
                lightLevel = 0.5
                chestRowVisible = true
                chestDone = true
                showButton = true
            }
            chestGold = chest.gold
            chestGems = chest.gems
            return
        }

        // Rattle
        stage = .shaking
        shakeTrigger += 1
        SFXManager.shared.play(.chainRattle)
        HapticManager.light()
        after(0.16) { HapticManager.light() }
        after(0.32) { HapticManager.light() }

        // The lock gives — lid ajar, light from the crack
        after(0.48) {
            SFXManager.shared.play(.dungeonUnlock)
            HapticManager.medium()
            withAnimation(.easeOut(duration: 0.12)) {
                stage = .ajar
                lightLevel = 1
            }
        }

        // Lid flies open
        after(0.8) {
            SFXManager.shared.play(.chestOpen)
            HapticManager.heavy()
            popTrigger += 1
            burst = true
            fountainStart = Date()
            withAnimation(.easeOut(duration: 0.15)) { stage = .open }
            withAnimation(.easeOut(duration: 1.2)) { lightLevel = 0.45 }
        }

        // Coins reach the counters — show the row and count up as they land
        after(1.55) {
            SFXManager.shared.play(.coinsJingle)
            withAnimation(.easeOut(duration: 0.15)) { chestRowVisible = true }
            countUp(gold: chest.gold, gems: chest.gems, duration: 0.7)
        }

        // Settle
        after(2.45) {
            HapticManager.success()
            fountainStart = nil
            withAnimation(MotionConstants.smooth) {
                chestDone = true
                showButton = true
            }
        }
    }

    private func countUp(gold: Int, gems: Int, duration: Double) {
        let steps = 14
        for step in 1...steps {
            after(duration * Double(step) / Double(steps)) {
                let share = Double(step) / Double(steps)
                withAnimation(.easeOut(duration: 0.08)) {
                    chestGold = Int((Double(gold) * share).rounded())
                    chestGems = Int((Double(gems) * share).rounded())
                }
                if step.isMultiple(of: 3) { HapticManager.selection() }
            }
        }
    }

    private func after(_ seconds: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func dismiss() {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(MotionConstants.snappy) {
            showHaul = false
            showChest = false
            showButton = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Chest scene

enum MineChestStage: Int, Comparable {
    case closed, shaking, ajar, open

    static func < (lhs: MineChestStage, rhs: MineChestStage) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The chest itself: three painted frames (closed / lid ajar / open) swapped
/// by stage, light from the crack, rays and a burst behind the open lid,
/// a rattle and a hop driven by the triggers.
private struct MineChestScene: View {
    let stage: MineChestStage
    let lightLevel: Double
    let shakeTrigger: Int
    let popTrigger: Int
    @Binding var burst: Bool

    private struct Shake {
        var angle: Double = 0
        var x: CGFloat = 0
    }

    private struct Hop {
        var y: CGFloat = 0
    }

    var body: some View {
        ZStack {
            // Light from the crack, then from the open chest (code, never painted).
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.goldBright,
                            DarkFantasyTheme.gold.opacity(0.45),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 86
                    )
                )
                .frame(width: 180, height: 76)
                .offset(y: -24)
                .blendMode(.plusLighter)
                .opacity(lightLevel)

            chestFrame("mine-chest-closed", visible: stage <= .shaking)
            chestFrame("mine-chest-ajar", visible: stage == .ajar)
            chestFrame("mine-chest-open", visible: stage == .open)
        }
        .frame(width: 180, height: 164)
        .rewardBurst(isActive: $burst, style: .legendary)
        .keyframeAnimator(initialValue: Shake(), trigger: shakeTrigger) { content, value in
            content
                .rotationEffect(.degrees(value.angle), anchor: .bottom)
                .offset(x: value.x)
        } keyframes: { _ in
            KeyframeTrack(\.angle) {
                CubicKeyframe(-5, duration: 0.06)
                CubicKeyframe(5, duration: 0.07)
                CubicKeyframe(-6, duration: 0.07)
                CubicKeyframe(6, duration: 0.07)
                CubicKeyframe(-4, duration: 0.07)
                CubicKeyframe(2, duration: 0.06)
                CubicKeyframe(0, duration: 0.06)
            }
            KeyframeTrack(\.x) {
                CubicKeyframe(-3, duration: 0.06)
                CubicKeyframe(3, duration: 0.07)
                CubicKeyframe(-4, duration: 0.07)
                CubicKeyframe(4, duration: 0.07)
                CubicKeyframe(-2, duration: 0.07)
                CubicKeyframe(1, duration: 0.06)
                CubicKeyframe(0, duration: 0.06)
            }
        }
        .keyframeAnimator(initialValue: Hop(), trigger: popTrigger) { content, value in
            content.offset(y: value.y)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                CubicKeyframe(-16, duration: 0.1)
                SpringKeyframe(0, duration: 0.4, spring: .bouncy)
            }
        }
        .background {
            SpinningRaysView()
                .frame(width: 360, height: 360)
                .offset(y: 30)
                .mask(
                    RadialGradient(
                        colors: [Color.black, Color.black.opacity(0.5), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 170
                    )
                )
                .opacity(stage == .open ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: stage)
                .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }

    private func chestFrame(_ name: String, visible: Bool) -> some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .opacity(visible ? 1 : 0)
    }
}

// MARK: - Coin fountain

enum MineChestAnchor: Hashable {
    case chest, gold, gems
}

struct MineChestAnchorKey: PreferenceKey {
    static var defaultValue: [MineChestAnchor: CGPoint] = [:]

    static func reduce(value: inout [MineChestAnchor: CGPoint], nextValue: () -> [MineChestAnchor: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Coins and gems spout from the chest mouth, hang for a beat, then fly
/// into their counters (VFX particles — exempt from the motion rule).
private struct MineCoinFountain: View {
    let start: Date
    let origin: CGPoint
    let goldTarget: CGPoint?
    let gemTarget: CGPoint?
    let coinCount: Int
    let gemCount: Int

    private struct Drop {
        let isGem: Bool
        let vx: Double
        let vy: Double
        let delay: Double
        let size: Double
        let flightTime: Double
    }

    private static let gravity: Double = 1150
    private static let burstTime: Double = 0.5

    private var drops: [Drop] {
        let total = coinCount + gemCount
        guard total > 0 else { return [] }
        let phi = 0.6180339887
        // Gems spread evenly through the spout instead of bunching up.
        let gemEvery = max(1, total / max(gemCount, 1))
        return (0..<total).map { i in
            let h = (Double(i) * phi).truncatingRemainder(dividingBy: 1)
            let h2 = (Double(i + 7) * phi).truncatingRemainder(dividingBy: 1)
            let isGem = gemCount > 0 && i % gemEvery == gemEvery / 2 && i / gemEvery < gemCount
            return Drop(
                isGem: isGem,
                vx: (h - 0.5) * 340,
                vy: -(380 + h2 * 200),
                delay: Double(i) * 0.03,
                size: isGem ? 22 : 24 + h * 6,
                flightTime: 0.4 + h2 * 0.15
            )
        }
    }

    var body: some View {
        let drops = self.drops
        TimelineView(.animation) { timeline in
            Canvas { context, _ in
                let t = timeline.date.timeIntervalSince(start)
                let coin = context.resolve(Image("icon-gold"))
                let gem = context.resolve(Image("icon-gems"))
                for drop in drops {
                    let local = t - drop.delay
                    guard local > 0 else { continue }

                    let tb = min(local, Self.burstTime)
                    var point = CGPoint(
                        x: origin.x + drop.vx * tb,
                        y: origin.y + drop.vy * tb + 0.5 * Self.gravity * tb * tb
                    )
                    var alpha = min(1, local / 0.06)

                    if local > Self.burstTime {
                        let u = min((local - Self.burstTime) / drop.flightTime, 1)
                        if u >= 1 { continue }
                        if let target = drop.isGem ? gemTarget : goldTarget {
                            let eased = u * u
                            point.x += (target.x - point.x) * eased
                            point.y += (target.y - point.y) * eased
                        } else {
                            point.y += 260 * u
                        }
                        if u > 0.8 { alpha = (1 - u) / 0.2 }
                    }

                    context.opacity = alpha
                    context.draw(
                        drop.isGem ? gem : coin,
                        in: CGRect(
                            x: point.x - drop.size / 2,
                            y: point.y - drop.size / 2,
                            width: drop.size,
                            height: drop.size
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
