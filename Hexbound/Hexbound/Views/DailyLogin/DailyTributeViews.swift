import SwiftUI

// MARK: - Chest tiers

/// The tribute week climbs the Descent's chests (`rush2-chest-*`):
/// days 1–3 wood, 4–5 iron, 6–7 gold. Purely presentational — what is inside
/// comes from the server's 7-day table.
enum TributeChestTier {
    case wood, iron, gold

    init(day: Int) {
        switch day {
        case ..<4: self = .wood
        case 4..<6: self = .iron
        default: self = .gold
        }
    }

    var closedAsset: String {
        switch self {
        case .wood: "rush2-chest-wood-closed"
        case .iron: "rush2-chest-iron-closed"
        case .gold: "rush2-chest-gold-closed"
        }
    }

    var openAsset: String {
        switch self {
        case .wood: "rush2-chest-wood-open"
        case .iron: "rush2-chest-iron-open"
        case .gold: "rush2-chest-gold-open"
        }
    }

    /// "wooden" in "Tomorrow: 300 Gold · wooden chest".
    var adjective: String {
        switch self {
        case .wood: "wooden"
        case .iron: "iron"
        case .gold: "golden"
        }
    }

    /// Day 7 closes the week: the gem chest, lit violet instead of gold.
    static func isBonusDay(_ day: Int) -> Bool { day == 7 }
}

// MARK: - Reward icon

/// The reward's own art (coin, gem, potion), with the gift as a fallback.
struct TributeRewardIcon: View {
    let reward: DailyReward?
    let size: CGFloat

    var body: some View {
        Group {
            if let asset = reward?.assetIcon, UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image("hud-gift")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Streak pill

/// "3-day streak · keep it lit" under the day title.
struct TributeStreakPill: View {
    let text: String
    var isLost: Bool = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image("fx-fire-flame")
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                .saturation(isLost ? 0 : 1)
                .opacity(isLost ? 0.6 : 1)
                .accessibilityHidden(true)
            Text(text)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(0.5)
                .foregroundStyle(isLost ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.leading, LayoutConstants.spaceSM)
        .padding(.trailing, LayoutConstants.spaceMS)
        .frame(height: 34)
        .background(
            Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.72))
        )
        .overlay(
            Capsule().stroke(
                (isLost ? DarkFantasyTheme.borderMedium : DarkFantasyTheme.stamina).opacity(0.5),
                lineWidth: 1
            )
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Chest stage

/// Today's chest on the vault floor. Closed, it rocks on its feet now and
/// then and is a button; opened, the lid is up, rays turn behind it and the
/// reward floats above it. The reward card follows from the view model
/// (`DailyLoginPopupViewModel.chestOpenBeat`).
struct TributeChestStage: View {
    let day: Int
    let reward: DailyReward?
    let isOpen: Bool
    let isBusy: Bool
    let onOpen: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOnScreen = false
    @State private var burst = false
    @State private var risen: Bool

    init(day: Int, reward: DailyReward?, isOpen: Bool, isBusy: Bool, onOpen: @escaping () -> Void) {
        self.day = day
        self.reward = reward
        self.isOpen = isOpen
        self.isBusy = isBusy
        self.onOpen = onOpen
        // Reopened after today's claim: the reward is already up, no replay.
        _risen = State(initialValue: isOpen)
    }

    private var tier: TributeChestTier { TributeChestTier(day: day) }
    private var glowColor: Color {
        TributeChestTier.isBonusDay(day) ? DarkFantasyTheme.purple : DarkFantasyTheme.gold
    }
    private var chestHint: String {
        guard !isOpen, let reward else { return "" }
        return "Holds \(reward.label)"
    }

    var body: some View {
        GeometryReader { geo in
            let side = max(120, min(geo.size.width * 0.6, geo.size.height - 170, 240))
            VStack(spacing: LayoutConstants.spaceSM) {
                risingReward
                    .frame(height: 92, alignment: .bottom)
                chest(side: side)
                    .frame(width: side, height: side)
                tag
                    .frame(height: 66, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        .onChange(of: isOpen) { _, opened in
            risen = opened
            // Celebrate the player's own tap only (the claim is in flight) —
            // not a status refresh that finds today already claimed elsewhere.
            // The burst brings its own haptic.
            guard opened, isBusy else { return }
            burst = true
            SFXManager.shared.play(.chestOpen)
        }
    }

    // MARK: Chest

    private func chest(side: CGFloat) -> some View {
        // One clock for the idle motion; it stops off screen and with
        // Reduce Motion (GPU rule: no endless animation on a hidden view).
        TimelineView(.animation(minimumInterval: nil, paused: !isOnScreen || reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                if isOpen {
                    rays(side: side, t: t)
                }
                Ellipse()
                    .fill(RadialGradient(
                        colors: [glowColor.opacity(0.45), glowColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.66
                    ))
                    .frame(width: side * 1.35, height: side)
                    .opacity(Self.breath(t))
                Ellipse()
                    .fill(RadialGradient(
                        colors: [DarkFantasyTheme.bgAbyss.opacity(0.85), DarkFantasyTheme.bgAbyss.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.48
                    ))
                    .frame(width: side * 0.95, height: side * 0.14)
                    .offset(y: side * 0.43)
                Button(action: onOpen) {
                    Image(isOpen ? tier.openAsset : tier.closedAsset)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: side, height: side)
                        .rotationEffect(
                            .degrees(isOpen || isBusy ? 0 : Self.wiggle(t)),
                            anchor: UnitPoint(x: 0.5, y: 0.86)
                        )
                        .shadow(color: glowColor.opacity(isOpen ? 0.35 : 0), radius: 18)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 12, y: 10)
                }
                .buttonStyle(TributeChestPressStyle())
                .disabled(isOpen || isBusy)
                .accessibilityLabel(isOpen ? "Today's chest, opened" : "Open today's chest")
                .accessibilityHint(Text(chestHint))
            }
            .overlay {
                RewardBurstView(style: TributeChestTier.isBonusDay(day) ? .epic : .gold, isActive: $burst)
                    .allowsHitTesting(false)
            }
        }
    }

    private func rays(side: CGFloat, t: Double) -> some View {
        TributeRays(count: 16)
            .fill(glowColor.opacity(0.22))
            .frame(width: side * 2.3, height: side * 2.3)
            .rotationEffect(.degrees(t.truncatingRemainder(dividingBy: 24) / 24 * 360))
            .mask {
                RadialGradient(
                    colors: [DarkFantasyTheme.bgAbyss, DarkFantasyTheme.bgAbyss.opacity(0)],
                    center: .center,
                    startRadius: side * 0.2,
                    endRadius: side * 1.1
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: Reward above the chest

    private var risingReward: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            TributeRewardIcon(reward: reward, size: 56)
                .shadow(color: glowColor.opacity(0.75), radius: 14)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)
            Text("+\(reward?.label ?? "Reward")".uppercased())
                .font(DarkFantasyTheme.section)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .shadow(color: DarkFantasyTheme.bgAbyss, radius: 0, y: 2)
                .shadow(color: DarkFantasyTheme.stamina.opacity(0.55), radius: 10)
        }
        .opacity(risen ? 1 : 0)
        .offset(y: risen ? 0 : 40)
        .animation(MotionConstants.springBouncy, value: risen)
        .accessibilityElement(children: .combine)
        .accessibilityHidden(!risen)
    }

    // MARK: Reward tag under the chest

    private var tag: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack(spacing: LayoutConstants.spaceSM) {
                TributeRewardIcon(reward: reward, size: 28)
                Text(reward?.label ?? "Today's reward")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.leading, LayoutConstants.spaceSM)
            .padding(.trailing, LayoutConstants.spaceMS)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(glowColor.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: glowColor.opacity(0.2), radius: 8)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 6, y: 3)

            Text("TAP THE CHEST")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .opacity(isOpen ? 0 : 1)
        .animation(MotionConstants.smooth, value: isOpen)
        .accessibilityHidden(true)
    }

    // MARK: Motion

    /// Rest, then a short rocking on the chest's feet — every 2.8 s.
    static func wiggle(_ t: Double) -> Double {
        let period = 2.8, rock = 0.6
        let p = t.truncatingRemainder(dividingBy: period)
        guard p > period - rock else { return 0 }
        let u = (p - (period - rock)) / rock
        return sin(u * .pi * 5) * 3.2 * (1 - u)
    }

    /// The glow under the chest breathes between 55 % and 100 %.
    static func breath(_ t: Double) -> Double {
        0.55 + 0.45 * (0.5 + 0.5 * sin(t * 2 * .pi / 2.6))
    }
}

/// Press = a touch darker (the project's press rule), no scale.
private struct TributeChestPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}

/// Light rays from the centre, for the opened chest.
struct TributeRays: Shape {
    var count: Int = 16

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = max(rect.width, rect.height) / 2
        let step = 2 * Double.pi / Double(max(count, 1))
        let half = step * 0.22
        var path = Path()
        for i in 0..<max(count, 1) {
            let a = Double(i) * step
            path.move(to: c)
            path.addLine(to: CGPoint(x: c.x + r * cos(a - half), y: c.y + r * sin(a - half)))
            path.addLine(to: CGPoint(x: c.x + r * cos(a + half), y: c.y + r * sin(a + half)))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - The week of chests

enum TributeDayState {
    case opened, today, locked
}

/// Seven chests on a dashed trail: opened ones dim with a check, today's
/// one ringed in gold, day 7 lit violet.
struct TributeWeekStrip: View {
    let rewards: [DailyReward]
    let displayDay: Int
    let hasClaimed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceXS) {
            ForEach(rewards, id: \.day) { reward in
                TributeDayCell(reward: reward, state: state(for: reward.day))
                    .frame(maxWidth: .infinity)
            }
        }
        .background(alignment: .top) {
            TributeTrail()
                .stroke(DarkFantasyTheme.gold.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .frame(height: 2)
                .padding(.horizontal, LayoutConstants.spaceLG)
                .padding(.top, 22)
                .accessibilityHidden(true)
        }
    }

    private func state(for day: Int) -> TributeDayState {
        if day < displayDay || (day == displayDay && hasClaimed) { return .opened }
        if day == displayDay { return .today }
        return .locked
    }
}

struct TributeDayCell: View {
    let reward: DailyReward
    let state: TributeDayState

    private var tier: TributeChestTier { TributeChestTier(day: reward.day) }
    private var isBonus: Bool { TributeChestTier.isBonusDay(reward.day) }

    private var plateFill: Color {
        switch state {
        case .today: DarkFantasyTheme.gold.opacity(0.18)
        case .opened, .locked: isBonus ? DarkFantasyTheme.purple.opacity(0.16) : DarkFantasyTheme.bgSecondary.opacity(0.92)
        }
    }

    private var plateStroke: Color {
        switch state {
        case .today: DarkFantasyTheme.goldBright
        case .opened: DarkFantasyTheme.success.opacity(0.45)
        case .locked: isBonus ? DarkFantasyTheme.purple.opacity(0.6) : DarkFantasyTheme.borderMedium.opacity(0.6)
        }
    }

    private var dayColor: Color {
        switch state {
        case .today: DarkFantasyTheme.goldBright
        case .opened: DarkFantasyTheme.success
        case .locked: isBonus ? DarkFantasyTheme.purple : DarkFantasyTheme.textSecondary
        }
    }

    private var stateText: String {
        switch state {
        case .opened: "opened"
        case .today: "today"
        case .locked: "locked"
        }
    }

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(plateFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(plateStroke, lineWidth: state == .today ? 2 : 1)
                    )
                    .shadow(color: state == .today ? DarkFantasyTheme.goldGlow : .clear, radius: 8)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 3, y: 2)

                Image(state == .opened ? tier.openAsset : tier.closedAsset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(LayoutConstants.space2XS)
                    .opacity(state == .opened ? 0.55 : 1)
                    .shadow(color: isBonus && state != .opened ? DarkFantasyTheme.purple.opacity(0.8) : .clear, radius: 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if state == .opened {
                    TributeCheckBadge()
                        .offset(x: 5, y: -5)
                }
            }
            .frame(width: 44, height: 46)

            HStack(spacing: 2) {
                TributeRewardIcon(reward: reward, size: LayoutConstants.iconSM)
                Text(reward.compactAmount)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(height: 20)

            Text("\(reward.day)")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(dayColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(reward.day), \(tier.adjective) chest: \(reward.label), \(stateText)")
    }
}

/// Green check on an opened chest — drawn, not a glyph, so it can be small.
struct TributeCheckBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.success)
                .overlay(Circle().stroke(DarkFantasyTheme.bgPrimary, lineWidth: 1.5))
            TributeCheckShape()
                .stroke(DarkFantasyTheme.bgPrimary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .padding(5)
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

struct TributeCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY - rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12))
        return path
    }
}

/// The dashed trail the week's chests sit on.
struct TributeTrail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
