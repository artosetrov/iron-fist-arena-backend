import SwiftUI

// MARK: - Panel container

/// The action panel under the scene. Hugs its content and scrolls only when it
/// would take more than `maxHeight` (relic picks on a small phone).
struct DescentPanel<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: () -> Content
    @State private var contentHeight: CGFloat = 220

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LayoutConstants.spaceSM) {
                content()
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceMS)
            .padding(.bottom, LayoutConstants.spaceMD)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: DescentPanelHeightKey.self, value: g.size.height)
                }
            )
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(max(contentHeight, 80), maxHeight))
        .onPreferenceChange(DescentPanelHeightKey.self) { contentHeight = $0 }
        .background(DarkFantasyTheme.bgPrimary)
        .overlay(alignment: .top) {
            Rectangle().fill(DarkFantasyTheme.borderSubtle).frame(height: 1)
        }
    }
}

private struct DescentPanelHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Rows

/// Which way a fork option lies — a small badge on its medallion.
enum DescentDirection {
    case left, ahead, right

    init(side: String) {
        switch side.lowercased() {
        case "left": self = .left
        case "right": self = .right
        default: self = .ahead
        }
    }

    var degrees: Double {
        switch self {
        case .left: 180
        case .ahead: -90
        case .right: 0
        }
    }
}

/// A tappable option: passage, chest action, event choice, camp pick, ware, relic.
///
/// A chamfered iron plate with a bronze medallion breaking its left edge; the
/// room's own colour (`accent`) lights the plate from the medallion. The chosen
/// row turns gold and glows in its colour.
struct DescentChoiceRow<Icon: View>: View {
    let title: String
    let subtitle: String?
    var suffix: String?
    var trailing: String?
    var selected = false
    var disabled = false
    var accent: Color = DarkFantasyTheme.gold
    var direction: DescentDirection?
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: action) {
            DescentPlateContent(
                title: title,
                subtitle: subtitle,
                suffix: suffix,
                trailing: trailing,
                selected: selected,
                muted: disabled,
                accent: accent,
                direction: direction,
                icon: icon
            )
        }
        .buttonStyle(DescentRowPressStyle())
        .disabled(disabled)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The same plate, read-only (rules, tips).
struct DescentInfoPlate<Icon: View>: View {
    let title: String
    let text: String
    var accent: Color = DarkFantasyTheme.gold
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        DescentPlateContent(title: title, subtitle: text, accent: accent, icon: icon)
            .accessibilityElement(children: .combine)
    }
}

/// Medallion, title, story line and the plate behind them.
struct DescentPlateContent<Icon: View>: View {
    let title: String
    let subtitle: String?
    var suffix: String?
    var trailing: String?
    var selected = false
    var muted = false
    var accent: Color = DarkFantasyTheme.gold
    var direction: DescentDirection?
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            DescentMedallion(accent: accent, lit: selected, direction: direction, content: icon)
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceSM) {
                    Text(title.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .tracking(2)
                        .foregroundStyle(titleStyle)
                        .shadow(color: selected ? accent.opacity(0.7) : .clear, radius: 8)
                        .lineLimit(2)
                    if let suffix, !suffix.isEmpty {
                        Text(suffix.uppercased())
                            .font(DarkFantasyTheme.buttonLabelCompact)
                            .tracking(2)
                            .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                            .fixedSize()
                    }
                }
                if let subtitle, !subtitle.isEmpty {
                    Text(DescentText.attributed(subtitle, base: DarkFantasyTheme.textSecondary))
                        .font(DarkFantasyTheme.tale)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing {
                Text(trailing)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textGold)
                    .monospacedDigit()
            }
        }
        .padding(.trailing, selected ? 32 : 18)
        .padding(.vertical, 11)
        .frame(minHeight: 76)
        .background {
            DescentPlate(accent: accent, selected: selected)
                .padding(.leading, DescentMedallionMetrics.overhang)
        }
        .saturation(muted ? 0.3 : 1)
        .opacity(muted ? 0.6 : 1)
        .contentShape(Rectangle())
    }

    /// Enamel title: cream at the top, the room's colour below.
    private var titleStyle: AnyShapeStyle {
        if muted { return AnyShapeStyle(DarkFantasyTheme.textTertiaryAA) }
        return AnyShapeStyle(LinearGradient(
            colors: [DarkFantasyTheme.vfxStunGlow, selected ? accent.opacity(0.85) : accent.opacity(0.7)],
            startPoint: .top, endPoint: .bottom
        ))
    }
}

enum DescentMedallionMetrics {
    static let size: CGFloat = 60
    /// How far the medallion breaks out past the plate's left edge.
    static let overhang: CGFloat = 10
}

/// A bronze medallion holding an icon, lit from within by the row's colour.
struct DescentMedallion<Content: View>: View {
    let accent: Color
    var lit = false
    var direction: DescentDirection?
    @ViewBuilder let content: () -> Content

    private let size = DescentMedallionMetrics.size

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [accent.opacity(lit ? 0.6 : 0.42), DarkFantasyTheme.bgAbyss],
                    center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: size * 0.36
                ))
                .padding(3)
            content()
                .frame(width: 42, height: 42)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.85), radius: 2, y: 2)
            // Recessed rim, then the bronze ring and its four rivets.
            Circle()
                .stroke(DarkFantasyTheme.bgAbyss.opacity(0.8), lineWidth: 2)
                .padding(4)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [DarkFantasyTheme.rankChallenger, DarkFantasyTheme.borderOrnament, DarkFantasyTheme.goldDim, DarkFantasyTheme.gold],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i == 0 ? DarkFantasyTheme.rankChallenger : DarkFantasyTheme.gold)
                    .frame(width: 3, height: 3)
                    .offset(y: -(size / 2 - 1.5))
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .frame(width: size, height: size)
        .background(Circle().stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5))
        .overlay(alignment: .bottomTrailing) {
            if let direction {
                ZStack {
                    Circle().fill(DarkFantasyTheme.bgAbyss)
                    Circle().strokeBorder(DarkFantasyTheme.borderOrnament, lineWidth: 1.5)
                    DescentTriangleShape()
                        .fill(DarkFantasyTheme.goldBright)
                        .frame(width: 9, height: 10)
                        .rotationEffect(.degrees(direction.degrees))
                }
                .frame(width: 22, height: 22)
                .offset(x: 6, y: 4)
                .accessibilityHidden(true)
            }
        }
        .shadow(color: lit ? accent.opacity(0.8) : .clear, radius: 9)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 5, y: 4)
    }
}

/// The iron plate behind a row: a gradient body lit by the row's colour, an
/// engraved inner line, four studs; gold frame and a chevron when chosen.
struct DescentPlate: View {
    let accent: Color
    var selected = false
    var chamfer: CGFloat = 12

    var body: some View {
        let shape = DescentChamferShape(chamfer: chamfer)
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                shape.fill(LinearGradient(
                    colors: selected
                        ? [DarkFantasyTheme.bgCardGradientEnd, DarkFantasyTheme.bgDarkPanel, DarkFantasyTheme.bgDungeonDeep]
                        : [DarkFantasyTheme.bgCardGradientStart, DarkFantasyTheme.bgDarkPanel, DarkFantasyTheme.bgDungeonDeep],
                    startPoint: .top, endPoint: .bottom
                ))
                shape.fill(RadialGradient(
                    colors: [accent.opacity(selected ? 0.36 : 0.15), accent.opacity(selected ? 0.1 : 0.04), accent.opacity(0)],
                    center: UnitPoint(x: 16 / max(w, 1), y: 0.5),
                    startRadius: 0, endRadius: max(w * 0.66, 130)
                ))
                Path { p in
                    p.move(to: CGPoint(x: chamfer, y: 2))
                    p.addLine(to: CGPoint(x: w - chamfer, y: 2))
                }
                .stroke(selected ? DarkFantasyTheme.goldBright.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1)
                shape.inset(by: 5)
                    .stroke(selected ? DarkFantasyTheme.goldBright.opacity(0.42) : Color.white.opacity(0.06), lineWidth: 1)
                shape.strokeBorder(frameStyle, lineWidth: selected ? 2 : 1.5)
                ForEach(Array(studs(w: w, h: h).enumerated()), id: \.offset) { _, point in
                    Rectangle()
                        .fill(selected ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderStrong)
                        .frame(width: 4.6, height: 4.6)
                        .rotationEffect(.degrees(45))
                        .position(point)
                }
                if selected {
                    Path { p in
                        p.move(to: CGPoint(x: w - 20, y: h / 2 - 7))
                        p.addLine(to: CGPoint(x: w - 13, y: h / 2))
                        p.addLine(to: CGPoint(x: w - 20, y: h / 2 + 7))
                    }
                    .stroke(DarkFantasyTheme.goldBright, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .compositingGroup()
        .shadow(color: selected ? accent.opacity(0.55) : .clear, radius: 10)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 5, y: 3)
        .accessibilityHidden(true)
    }

    private var frameStyle: LinearGradient {
        LinearGradient(
            colors: selected
                ? [DarkFantasyTheme.rankChallenger, DarkFantasyTheme.gold, DarkFantasyTheme.goldDim]
                : [DarkFantasyTheme.borderStrong, DarkFantasyTheme.borderSubtle],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// One stud in the middle of each cut corner.
    private func studs(w: CGFloat, h: CGFloat) -> [CGPoint] {
        let k = 1 + chamfer / 2
        return [CGPoint(x: k, y: k), CGPoint(x: w - k, y: k), CGPoint(x: w - k, y: h - k), CGPoint(x: k, y: h - k)]
    }
}

/// Rows dim slightly while pressed (no scale — DS rule).
struct DescentRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { SFXManager.shared.play(.uiTap) }
            }
    }
}

/// An asset icon for a row, or a muted dot when there is none.
struct DescentRowIcon: View {
    let asset: String?
    var size: CGFloat = 38

    var body: some View {
        if let asset, !asset.isEmpty {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Circle()
                .fill(DarkFantasyTheme.borderMedium)
                .frame(width: 6, height: 6)
        }
    }
}

/// The "darkness" glyph for an unknown passage: a closed eye.
struct DescentDarkGlyph: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            var lid = Path()
            lid.move(to: CGPoint(x: w * 0.14, y: h * 0.42))
            lid.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.42), control: CGPoint(x: w * 0.5, y: h * 0.78))
            var lashes = Path()
            let strokes: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(0.3, 0.58, 0.24, 0.72), (0.5, 0.63, 0.5, 0.78), (0.7, 0.58, 0.76, 0.72)]
            for (x0, y0, x1, y1) in strokes {
                lashes.move(to: CGPoint(x: w * x0, y: h * y0))
                lashes.addLine(to: CGPoint(x: w * x1, y: h * y1))
            }
            let style = StrokeStyle(lineWidth: 1.8, lineCap: .round)
            ctx.stroke(lid, with: .color(DarkFantasyTheme.textTertiaryAA), style: style)
            ctx.stroke(lashes, with: .color(DarkFantasyTheme.textTertiaryAA), style: style)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}

/// One line of loot: gold, experience, potion, torch, relic or item.
struct DescentLootRow: View {
    let loot: DescentLoot

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            icon
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgAbyss)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(title)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(DarkFantasyTheme.tale)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(accent)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: accent.opacity(0.08),
                glowIntensity: 0.5,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(isRare ? accent.opacity(0.7) : DarkFantasyTheme.borderSubtle, lineWidth: isRare ? 1.5 : 1)
        )
        .compositingGroup()
        .dualShadow(glowColor: isRare ? accent.opacity(0.25) : .clear, glowRadius: 8, depth: .panel)
        .accessibilityElement(children: .combine)
    }

    private var isRare: Bool {
        guard let item = loot.item else { return loot.kind == "relic" }
        return item.itemRarity == .epic || item.itemRarity == .legendary
    }

    private var accent: Color {
        switch loot.kind {
        case "gold": DarkFantasyTheme.goldBright
        case "xp": DarkFantasyTheme.xpRing
        case "relic": DarkFantasyTheme.rarityEpic
        case "item": DescentStyle.rarityColor(loot.item?.rarity ?? "common")
        default: DarkFantasyTheme.textGold
        }
    }

    private var titleColor: Color {
        loot.kind == "item" ? accent : DarkFantasyTheme.textPrimary
    }

    private var title: String {
        switch loot.kind {
        case "gold": "Gold"
        case "xp": "Experience"
        case "potion": "Health potion"
        case "torch": "Torch"
        case "relic": loot.relic?.name ?? "Relic"
        case "item": loot.item?.name ?? "Item"
        default: loot.kind.capitalized
        }
    }

    private var subtitle: String {
        switch loot.kind {
        case "gold": return "Goes in your bag · at risk"
        case "xp": return "Always yours"
        case "potion": return "On your belt"
        case "torch": return "Light a dark passage"
        case "relic": return loot.relic?.desc ?? ""
        case "item":
            guard let item = loot.item else { return "In your bag" }
            return item.isShard ? "Crafting shards · in your bag" : "\(item.rarity) · in your bag"
        default: return ""
        }
    }

    private var value: String {
        switch loot.kind {
        case "gold", "xp", "potion", "torch": return "+\(loot.amount)"
        case "relic": return "Relic"
        case "item": return (loot.item?.isShard ?? false) ? "×\(loot.amount)" : "Item"
        default: return ""
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch loot.kind {
        case "gold": DescentRowIcon(asset: "rush2-icon-goldpouch")
        case "xp":
            Text("XP")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.xpRing)
        case "potion": DescentRowIcon(asset: "rush2-icon-potion")
        case "torch": DescentRowIcon(asset: "rush2-icon-torch")
        case "relic": DescentRowIcon(asset: loot.relic?.icon)
        case "item":
            if let item = loot.item {
                DescentItemIcon(item: item)
            }
        default: DescentRowIcon(asset: nil)
        }
    }
}

/// A catalog item (or a shard) found in the Descent.
struct DescentItemIcon: View {
    let item: DescentBagItem
    var size: CGFloat = 34

    var body: some View {
        if item.isShard {
            Image("icon-legendary-shard")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: DescentStyle.rarityColor(item.rarity).opacity(0.6), radius: 6)
        } else {
            ItemImageView(imageKey: item.imageKey, imageUrl: item.imageUrl)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Combat dice

/// The round's dice on the arena's dice table, with the arena's own pieces
/// (`DiceDieView` tiles, `DiceChipView` results): two lanes, each an attack die
/// against the guard die that answers it. A strike lands unless the guard die
/// shows the same spot — then both dice of the lane are ringed blue.
struct DescentDiceTray: View {
    let round: DescentRound?
    /// A round is on its way to the server — the dice tumble, the chips wait.
    var rolling = false

    private typealias Chip = DiceBattleViewModel.Chip
    private let dieSize: CGFloat = 56

    var body: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            lane(
                title: "YOUR STRIKE",
                attack: round?.pa,
                guardZone: round?.eg,
                attackSpent: round.map { $0.action != "strike" } ?? false,
                blocked: round?.eBlock == true,
                chip: yourChip
            )
            lane(
                title: "FOE STRIKE",
                attack: round?.ea,
                guardZone: round?.pg,
                attackSpent: false,
                blocked: round?.pBlock == true,
                chip: foeChip
            )
        }
        .padding(LayoutConstants.spaceSM)
        .frame(maxWidth: .infinity)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    /// `attackSpent`: the hero braced or drank instead of striking — the attack die sits out.
    private func lane(title: String, attack: String?, guardZone: String?,
                      attackSpent: Bool, blocked: Bool, chip: Chip) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(title)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(1)
            HStack(spacing: LayoutConstants.spaceXS) {
                die(.attack, zone: attack, ringed: blocked)
                    .opacity(attackSpent && !rolling ? 0.4 : 1)
                Image("ui-arrow-right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .opacity(0.6)
                die(.guardDie, zone: guardZone, ringed: blocked)
            }
            DiceChipView(chip: rolling ? Chip(text: "…", style: .wait) : chip)
        }
        .frame(maxWidth: .infinity)
    }

    private func die(_ kind: DiceKind, zone: String?, ringed: Bool) -> some View {
        DiceDieView(
            kind: kind,
            face: zone.map(DescentStyle.zoneFace),
            runeAsset: nil,
            size: dieSize,
            tumbling: rolling
        )
        .overlay {
            if ringed && !rolling {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.info, lineWidth: 2)
                    .padding(-3)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Your strike against their guard.
    private var yourChip: Chip {
        guard let r = round else { return Chip(text: "—", style: .wait) }
        switch r.action {
        case "brace":
            return Chip(text: "BRACED", style: .miss, big: true)
        case "potion":
            return Chip(text: "POTION", detail: r.healed > 0 ? "+\(r.healed) HP" : nil, style: .miss, big: true)
        default:
            if r.pHit {
                return r.crit
                    ? Chip(text: "CRIT \(r.dealt)", style: .crit, big: true)
                    : Chip(text: "HIT \(r.dealt)", style: .hit, big: true)
            }
            if r.eBlock { return Chip(text: "BLOCKED", style: .blocked, big: true) }
            if r.dodged { return Chip(text: "DODGED", style: .miss, big: true) }
            return Chip(text: "—", style: .wait)
        }
    }

    /// Their strike against your guard.
    private var foeChip: Chip {
        guard let r = round else { return Chip(text: "—", style: .wait) }
        let braced = r.action == "brace" ? "BRACED" : nil
        if r.eHit {
            return r.crushing
                ? Chip(text: "CRUSH −\(r.taken)", detail: braced, style: .crit, big: true)
                : Chip(text: "HIT −\(r.taken)", detail: braced, style: .hit, big: true)
        }
        if r.pBlock { return Chip(text: "BLOCKED", style: .blocked, big: true) }
        return Chip(text: "—", style: .wait)
    }

    private var accessibilitySummary: String {
        guard let r = round else { return "No dice rolled yet" }
        return "Your strike, \(r.pa) against their guard \(r.eg): \(yourChip.text). "
            + "Their strike, \(r.ea) against your guard \(r.pg): \(foeChip.text)."
    }
}

/// The round's story under the dice.
struct DescentVerdict: View {
    let lines: [DescentLine]
    let hint: String?
    let notice: String?

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            if lines.isEmpty {
                Text("Your strike lands unless their guard covers the same spot.")
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line.text)
                    .foregroundStyle(color(line.tone))
            }
            if let hint {
                Text(hint).foregroundStyle(DarkFantasyTheme.textDanger)
            }
            if let notice {
                Text(notice).foregroundStyle(DarkFantasyTheme.textWarning)
            }
        }
        .font(DarkFantasyTheme.buttonLabelCompact)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private func color(_ tone: String) -> Color {
        switch tone {
        case "good": DarkFantasyTheme.textSuccess
        case "bad": DarkFantasyTheme.textDanger
        case "info": DarkFantasyTheme.xpRing
        default: DarkFantasyTheme.textSecondary
        }
    }
}

// MARK: - Bag summary (result + bag sheet)

struct DescentItemsList: View {
    let items: [DescentBagItem]
    var empty: String = "Nothing yet"

    var body: some View {
        if items.isEmpty {
            Text(empty)
                .font(DarkFantasyTheme.tale)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: LayoutConstants.spaceXS) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: LayoutConstants.spaceSM) {
                        DescentItemIcon(item: item, size: 28)
                        Text(item.name)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DescentStyle.rarityColor(item.rarity))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(item.isShard ? "×\(item.amount)" : item.rarity.uppercased())
                            .font(DarkFantasyTheme.buttonLabelCompact)
                            .foregroundStyle(DescentStyle.rarityColor(item.rarity))
                    }
                }
            }
        }
    }
}

struct DescentSummaryBox<Content: View>: View {
    let title: String
    var note: String?
    var danger = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack {
                Text(title.uppercased())
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Spacer(minLength: LayoutConstants.spaceSM)
                if let note {
                    Text(note.uppercased())
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(1.5)
                        .foregroundStyle(danger ? DarkFantasyTheme.textDanger : DarkFantasyTheme.textTertiaryAA)
                        .multilineTextAlignment(.trailing)
                }
            }
            content()
        }
        .padding(LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: danger ? DarkFantasyTheme.danger.opacity(0.12) : DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.5,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(danger ? DarkFantasyTheme.danger.opacity(0.45) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

struct DescentValueLine: View {
    let label: String
    let value: String
    var color: Color = DarkFantasyTheme.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
            Spacer(minLength: LayoutConstants.spaceSM)
            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
