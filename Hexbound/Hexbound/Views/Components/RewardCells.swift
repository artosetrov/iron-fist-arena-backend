import SwiftUI

// MARK: - Reward cells

/// Gold, gems and XP won, side by side — the currency block of a reward card
/// (docs/07_ui_ux/REWARD_CARDS.md, "Reward cells").
///
/// Each cell counts up with its window's own tick-up (`RewardCell.Item.shown`)
/// and fills with its colour from left to right as it does; when the count
/// lands the cell glows once. Under the amount it shows where the reward went:
/// the balance after it ("Total 12,480"), or the level bar the XP pushed, which
/// spills into the next level — LEVEL UP — when it fills.
///
/// Two cells share a row. With three, gold and gems share the first row and XP
/// takes the second, so its level bar has room. Cells in a row are the same
/// height whatever their content.
struct RewardCells: View {
    let items: [RewardCell.Item]

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                RewardCellRow(items: row)
            }
        }
    }

    private var rows: [[RewardCell.Item]] {
        let cells = items.filter { $0.amount > 0 }
        guard cells.count > 2 else { return cells.isEmpty ? [] : [cells] }
        let currencies = cells.filter { $0.kind != .xp }
        let xp = cells.filter { $0.kind == .xp }
        return [currencies, xp].filter { !$0.isEmpty }
    }
}

/// One row of cells: each as tall as the tallest, and a cell beside one with a
/// balance or a level bar keeps the room for it, so the rows of text line up.
private struct RewardCellRow: View {
    let items: [RewardCell.Item]

    var body: some View {
        let reservesContext = items.contains { $0.hasContext }
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(items) { item in
                RewardCell(item: item, reservesContext: reservesContext)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Cell

struct RewardCell: View {
    struct Item: Identifiable {
        enum Kind: Hashable { case gold, gems, xp }

        let kind: Kind
        /// The amount won.
        let amount: Int
        /// What the counter shows now: the window's tick-up, 0 → `amount`.
        let shown: Int
        /// The balance after this reward; nil hides the "Total" line.
        var total: Int? = nil
        /// XP only: the level bar this XP fills; nil hides it.
        var level: RewardCellLevel? = nil
        /// The cell is laid out from the start and faded in on its beat.
        var isVisible: Bool = true

        var id: Kind { kind }
        var hasContext: Bool { total != nil || level != nil }
    }

    let item: Item
    var reservesContext: Bool = false

    @State private var landedGlow = false
    @State private var levelFlash = false

    private let radius = LayoutConstants.panelRadius
    /// The bar row and the "Total" ornament row share this height.
    private let contextRowHeight = LayoutConstants.spaceLG

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
                Text("+\(item.shown)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(label)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(spilled ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                .lineLimit(1)

            if reservesContext {
                context
                    .padding(.top, LayoutConstants.spaceXS)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, LayoutConstants.spaceMS)
        .padding(.horizontal, LayoutConstants.spaceSM)
        .background { background }
        .overlay { levelUpFlash }
        .surfaceLighting(cornerRadius: radius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: radius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.4), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: color.opacity(landedGlow ? 0.55 : 0.08), radius: landedGlow ? 14 : 4)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.35), radius: 4, y: 2)
        .opacity(item.isVisible ? 1 : 0)
        .onChange(of: landed) { _, didLand in
            guard didLand else { return }
            pulse($landedGlow)
        }
        .onChange(of: spilled) { _, didSpill in
            guard didSpill else { return }
            pulse($levelFlash)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spokenLabel))
        .accessibilityHidden(!item.isVisible)
    }

    // MARK: Reading the item

    /// How much of the reward has counted up, 0…1.
    private var progress: Double {
        guard item.amount > 0 else { return 1 }
        return min(max(Double(item.shown) / Double(item.amount), 0), 1)
    }

    private var landed: Bool { item.amount > 0 && item.shown >= item.amount }

    private var bar: RewardCellLevel.Bar? { item.level?.bar(at: progress) }

    /// The XP has finished the old level and runs on in the next one.
    private var spilled: Bool { bar?.spilled ?? false }

    private var icon: String {
        switch item.kind {
        case .gold: return "reward-gold"
        case .gems: return "icon-gems"
        case .xp:   return "reward-xp"
        }
    }

    private var color: Color {
        switch item.kind {
        case .gold: return DarkFantasyTheme.goldBright
        case .gems: return DarkFantasyTheme.purple
        case .xp:   return DarkFantasyTheme.xpRing
        }
    }

    private var label: String {
        switch item.kind {
        case .gold: return "GOLD"
        case .gems: return "GEMS"
        case .xp:   return spilled ? "LEVEL UP" : "XP"
        }
    }

    private var spokenLabel: String {
        let total = item.total.map { ", total \($0.formatted())" } ?? ""
        switch item.kind {
        case .gold: return "\(item.amount) gold\(total)"
        case .gems: return "\(item.amount) gems\(total)"
        case .xp:
            guard let level = item.level else { return "\(item.amount) XP" }
            if level.levelsUp { return "\(item.amount) XP, level up to \(level.after.level)" }
            return "\(item.amount) XP, level \(level.after.level), \(level.after.xp) of \(level.after.needed)"
        }
    }

    // MARK: Background: the fill

    /// The cell's panel, and the colour that fills it left to right as the count runs.
    private var background: some View {
        ZStack(alignment: .leading) {
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: radius
            )
            GeometryReader { geo in
                LinearGradient(
                    colors: [color.opacity(0.04), color.opacity(0.18)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * progress)
                .overlay(alignment: .trailing) {
                    // The bright leading edge, while it is still moving.
                    Rectangle()
                        .fill(color.opacity(0.9))
                        .frame(width: 2)
                        .opacity(progress > 0.001 && progress < 0.999 ? 1 : 0)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    private var levelUpFlash: some View {
        RadialGradient(
            colors: [DarkFantasyTheme.goldBright.opacity(0.38), .clear],
            center: UnitPoint(x: 0.5, y: 0.75),
            startRadius: 0,
            endRadius: 90
        )
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .opacity(levelFlash ? 1 : 0)
        .allowsHitTesting(false)
    }

    // MARK: Context: where the reward went

    @ViewBuilder
    private var context: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            if let bar {
                levelBar(bar)
                Text("\(bar.xp.formatted()) / \(bar.needed.formatted())")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
            } else if let total = item.total {
                GoldDivider()
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .frame(height: contextRowHeight)
                // The balance counts up with the reward.
                let shownTotal = total - item.amount + item.shown
                ViewThatFits(in: .horizontal) {
                    totalLine(shownTotal, withWord: true)
                    totalLine(shownTotal, withWord: false)
                }
            } else {
                // Nothing to show here, but keep the row's lines level.
                Color.clear.frame(height: contextRowHeight)
                Text(verbatim: " ")
                    .font(DarkFantasyTheme.body)
                    .hidden()
            }
        }
    }

    private func totalLine(_ total: Int, withWord: Bool) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            if withWord {
                Text("Total")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            Text(total.formatted())
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .monospacedDigit()
        }
        .lineLimit(1)
    }

    /// `12 ▓▓▓▓░░░ 13`: what the hero had (dim), what this reward added (bright).
    private func levelBar(_ bar: RewardCellLevel.Bar) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Text("\(bar.level)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .monospacedDigit()
            GeometryReader { geo in
                let width = geo.size.width
                let had = bar.fraction(of: bar.from)
                let now = bar.fraction(of: bar.xp)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DarkFantasyTheme.xpRingTrack)
                    Rectangle()
                        .fill(DarkFantasyTheme.xpRing.opacity(0.45))
                        .frame(width: width * had)
                    Rectangle()
                        .fill(DarkFantasyTheme.xpGradient)
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                        .frame(width: width * max(0, now - had))
                        .offset(x: width * had)
                    Rectangle()
                        .fill(DarkFantasyTheme.textPrimary)
                        .opacity(levelFlash ? 0.85 : 0)
                }
                .clipShape(Capsule())
                .frame(height: 6)
                .frame(maxHeight: .infinity)
            }
            Text("\(bar.level + 1)")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .monospacedDigit()
        }
        .frame(height: contextRowHeight)
    }

    // MARK: Motion

    /// A quick rise and a slower fade (opacity and glow only, no scale).
    private func pulse(_ flag: Binding<Bool>) {
        withAnimation(.easeOut(duration: 0.15)) { flag.wrappedValue = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeIn(duration: 0.5)) { flag.wrappedValue = false }
        }
    }
}

// MARK: - Level bar data

/// The level bar an XP reward fills: where the hero was and where it left them.
struct RewardCellLevel: Equatable {
    struct Point: Equatable {
        let level: Int
        /// XP into `level`.
        let xp: Int
        /// XP that finishes `level`.
        let needed: Int
    }

    /// The bar at one moment of the count.
    struct Bar: Equatable {
        let level: Int
        /// Where the bar started in this level (0 once it spilled into the next).
        let from: Int
        let xp: Int
        let needed: Int
        /// The old level is finished; this is the next one.
        let spilled: Bool

        func fraction(of value: Int) -> CGFloat {
            guard needed > 0 else { return 0 }
            return CGFloat(min(max(Double(value) / Double(needed), 0), 1))
        }
    }

    let before: Point
    let after: Point

    var levelsUp: Bool { after.level > before.level }

    /// From the hero after `gained` XP (level and XP into it), with the
    /// client's mirror of the XP curve (`Character.xpToNextLevel`). nil when
    /// there is nothing to fill (no XP, the level cap). A reward worth more
    /// than one level reads as one.
    ///
    /// Takes either the server's hero or an optimistic one: an optimistic
    /// credit (`AppState.creditRewardOptimistically`) adds the XP without
    /// levelling up, so XP past the level's end is carried into the next level.
    static func after(level: Int, xp: Int, gained: Int) -> RewardCellLevel? {
        guard gained > 0, level >= 1 else { return nil }
        var level = level
        var xp = max(xp, 0)
        while level < Character.maxLevel, xp >= Character.xpToNextLevel(level) {
            xp -= Character.xpToNextLevel(level)
            level += 1
        }
        guard level < Character.maxLevel else { return nil }
        let needed = Character.xpToNextLevel(level)
        let now = Point(level: level, xp: xp, needed: needed)
        if xp >= gained || level == 1 {
            return RewardCellLevel(before: Point(level: level, xp: xp - min(gained, xp), needed: needed), after: now)
        }
        let previousNeeded = Character.xpToNextLevel(level - 1)
        let before = Point(level: level - 1, xp: max(0, previousNeeded - (gained - xp)), needed: previousNeeded)
        return RewardCellLevel(before: before, after: now)
    }

    /// The bar when `progress` (0…1) of the reward has counted up: it first
    /// finishes the old level, then fills the new one.
    func bar(at progress: Double) -> Bar {
        let p = min(max(progress, 0), 1)
        guard levelsUp else {
            let xp = before.xp + Int((Double(after.xp - before.xp) * p).rounded())
            return Bar(level: before.level, from: before.xp, xp: xp, needed: before.needed, spilled: false)
        }
        let toFinish = Double(max(before.needed - before.xp, 0))
        let span = toFinish + Double(after.xp)
        let split = span > 0 ? toFinish / span : 1
        if p < split {
            let xp = before.xp + Int((toFinish * p / split).rounded())
            return Bar(level: before.level, from: before.xp, xp: min(xp, before.needed), needed: before.needed, spilled: false)
        }
        let rest = split < 1 ? (p - split) / (1 - split) : 1
        return Bar(level: after.level, from: 0, xp: Int((Double(after.xp) * rest).rounded()), needed: after.needed, spilled: true)
    }
}
