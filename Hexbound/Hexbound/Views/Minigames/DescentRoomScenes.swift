import SwiftUI

// MARK: - Combat

struct DescentCombatStage: View {
    let combat: DescentCombat
    let hitToken: Int
    let isActive: Bool
    /// Back to the fork for 8% HP. Shown on the scene so the panel keeps one row
    /// of buttons; a guardian cannot be fled (`canFlee` false — a trait chip says so).
    var onFlee: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spriteHeightFraction: CGFloat {
        if combat.isBoss { return 0.8 }
        switch combat.size {
        case "small": return 0.52
        case "big": return 0.78
        default: return combat.isElite ? 0.74 : 0.68
        }
    }

    private var nameColor: Color {
        combat.isBoss ? DarkFantasyTheme.textDanger : combat.isElite ? DarkFantasyTheme.btnOrangeBright : DarkFantasyTheme.textPrimary
    }

    private var kindLabel: String {
        combat.isBoss ? "Guardian" : combat.isElite ? "Elite" : "Level \(combat.level)"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // A dark stage, as on the arena: the painting sits low, the floor
                // fades into the panel and the foe stands on its own shadow.
                DescentBackdrop(asset: combat.bg, dim: DescentStyle.combatDim(combat.bg))
                DescentVignette(strength: 0.6)
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.7),
                        .init(color: DarkFantasyTheme.bgAbyss.opacity(0.55), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .allowsHitTesting(false)
                Ellipse()
                    .fill(RadialGradient(
                        colors: [DarkFantasyTheme.bgAbyss.opacity(0.85), .clear],
                        center: .center, startRadius: 0, endRadius: geo.size.width * 0.3
                    ))
                    .frame(width: geo.size.width * 0.6, height: max(12, geo.size.height * 0.06))
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.955)
                    .allowsHitTesting(false)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let bob = CGFloat(DescentMotion.wave(t, period: 3.4)) * 6
                    Image(combat.art)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            // Hit flash, as on the arena: the foe's own shape washes red for a beat.
                            Image(combat.art)
                                .resizable()
                                .scaledToFit()
                                .colorMultiply(DarkFantasyTheme.danger)
                                .modifier(DescentHitWash(token: hitToken))
                                .allowsHitTesting(false)
                        }
                        .frame(height: geo.size.height * spriteHeightFraction)
                        .frame(maxWidth: geo.size.width * 0.94)
                        .offset(y: -bob)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.96 - geo.size.height * spriteHeightFraction / 2)
                        .modifier(DescentHitReaction(token: hitToken))
                        .dualShadow(glowColor: combat.isBoss ? DarkFantasyTheme.danger.opacity(0.25) : .clear, glowRadius: 24, depth: .elevated)
                }
                .accessibilityLabel(combat.name)

                VStack(spacing: LayoutConstants.spaceXS) {
                    Text(kindLabel.uppercased())
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(3)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text(combat.name.uppercased())
                        .font(DarkFantasyTheme.section)
                        .tracking(1.5)
                        .foregroundStyle(nameColor)
                        .shadow(color: DarkFantasyTheme.bgAbyss, radius: 3, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    DescentEnemyHPBar(fraction: combat.hpFraction, hp: combat.hp, maxHp: combat.maxHp)
                    DescentTraitChips(combat: combat)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.top, LayoutConstants.spaceSM)
                .frame(maxHeight: .infinity, alignment: .top)

                if combat.canFlee, let onFlee {
                    fleeButton(onFlee)
                        .padding(.leading, LayoutConstants.spaceMS)
                        .padding(.bottom, LayoutConstants.spaceMS)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
    }

    private func fleeButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                Text("FLEE")
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                Text("−8% HP")
                    .foregroundStyle(DarkFantasyTheme.textDanger)
            }
            .frame(minHeight: 28)
        }
        .buttonStyle(.compactOutline(color: DarkFantasyTheme.textSecondary))
        // Opaque under the outline: it floats over the painting.
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .accessibilityLabel("Flee to the fork, costs 8% of your health")
    }
}

/// A small knock-back and a red rim each time the enemy is hit. No brightening:
/// the pale ink sprites blow out to white when lifted.
private struct DescentHitReaction: ViewModifier {
    let token: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGFloat(0), trigger: token) { view, v in
            view
                .offset(x: v * 10, y: -v * 3)
                .shadow(color: DarkFantasyTheme.danger.opacity(Double(v) * 0.6), radius: 14 * v)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1, duration: 0.06)
                SpringKeyframe(0, duration: 0.3)
            }
        }
    }
}

/// Opacity of the red wash over the foe's shape on a hit (peak as on the arena boss, 0.45).
private struct DescentHitWash: ViewModifier {
    let token: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 0.0, trigger: token) { view, v in
            view.opacity(v)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(0.45, duration: 0.05)
                LinearKeyframe(0.45, duration: 0.07)
                LinearKeyframe(0, duration: 0.25)
            }
        }
    }
}

struct DescentEnemyHPBar: View {
    let fraction: Double
    let hp: Int
    let maxHp: Int

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.75))
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.hpCriticalGradient)
                    .frame(width: geo.size.width * max(0, min(1, fraction)))
                    .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    .animation(.easeOut(duration: MotionConstants.normal), value: fraction)
            }
        }
        .frame(height: 12)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Enemy health \(hp) of \(maxHp)")
    }
}

struct DescentTraitChips: View {
    let combat: DescentCombat

    var body: some View {
        DescentFlowLayout(spacing: LayoutConstants.spaceXS) {
            ForEach(combat.traits) { trait in
                chip(trait.label, color: DarkFantasyTheme.textSecondary)
            }
            if !combat.canFlee {
                chip("No escape", color: DarkFantasyTheme.textSecondary)
            }
            if combat.windup {
                chip("Crushing blow next round", color: DarkFantasyTheme.textDanger)
            }
            if combat.enraged {
                chip("Frenzied", color: DarkFantasyTheme.btnOrangeBright)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func chip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.buttonLabelCompact)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.7)))
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

/// Wraps chips onto as many centred rows as they need.
struct DescentFlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.reduce(CGFloat(0)) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, proposal.width ?? width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for (index, size) in row.items {
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var items: [(Int, CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let current = rows[rows.count - 1]
            if !current.items.isEmpty && current.width + spacing + size.width > maxWidth {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.items.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.items.append((index, size))
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.items.isEmpty }
    }
}

// MARK: - Title cards (depth card, depth cleared, result)

struct DescentTitleCard: View {
    let eyebrow: String
    let title: String
    let text: String?
    var titleColor: Color = DarkFantasyTheme.textPrimary

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text(eyebrow.uppercased())
                .font(DarkFantasyTheme.cardTitle)
                .tracking(4)
                .foregroundStyle(DarkFantasyTheme.gold)
            Text(title.uppercased())
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(titleColor)
                .shadow(color: DarkFantasyTheme.bgAbyss, radius: 4, y: 2)
                .shadow(color: titleColor.opacity(0.35), radius: 16)
                .minimumScaleFactor(0.6)
            if let text {
                Text(DescentText.attributed(text, base: DarkFantasyTheme.textSecondary))
                    .font(DarkFantasyTheme.tale)
                    .multilineTextAlignment(.center)
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 3)
                    .padding(.horizontal, LayoutConstants.spaceLG)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Chest

struct DescentChestStage: View {
    let chest: DescentChest
    let openToken: Int
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var glow: Color {
        switch chest.tier {
        case "gold": DarkFantasyTheme.goldBright
        case "iron": DarkFantasyTheme.glowTreasure
        default: DarkFantasyTheme.glowEmber
        }
    }

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width * 0.72, geo.size.height * 0.85)
            ZStack {
                DescentBackdrop(asset: "rush2-bg-treasure", dim: 0.4)
                DescentVignette(strength: 0.55)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    ZStack {
                        if chest.opened {
                            DescentChestRays(color: glow, t: t)
                                .frame(width: width * 1.6, height: width * 1.6)
                                .position(x: geo.size.width / 2, y: geo.size.height * 0.58)
                        }
                        Ellipse()
                            .fill(EllipticalGradient(colors: [glow.opacity(chest.opened ? 0.55 : 0.22), glow.opacity(0)],
                                                     center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5))
                            .frame(width: width * 1.3, height: width * 0.7)
                            .opacity(0.75 + 0.25 * DescentMotion.wave(t, period: 2.6))
                            .blendMode(.screen)
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.66)
                    }
                }
                .allowsHitTesting(false)

                Image(chest.opened ? "rush2-chest-\(chest.tier)-open" : "rush2-chest-\(chest.tier)-closed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.62)
                    .dualShadow(glowColor: glow.opacity(chest.opened ? 0.45 : 0.15), glowRadius: 28, depth: .elevated)
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: openToken) { view, v in
                        view.offset(y: -v * 14).rotationEffect(.degrees(Double(v) * 2.5))
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(1, duration: 0.08)
                            LinearKeyframe(-0.6, duration: 0.1)
                            SpringKeyframe(0, duration: 0.35)
                        }
                    }
                    .accessibilityLabel(chest.name)

                Text(chest.name.uppercased())
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(3)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 3)
                    .padding(.top, LayoutConstants.spaceMD)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

/// Slowly turning light rays behind an open chest.
private struct DescentChestRays: View {
    let color: Color
    let t: Double

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.0), color.opacity(0.35), color.opacity(0.0)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 18, height: 420)
                    .rotationEffect(.degrees(Double(i) * 18 + t * 6))
            }
        }
        .blur(radius: 6)
        .blendMode(.screen)
        .mask {
            RadialGradient(colors: [DarkFantasyTheme.bgAbyss, .clear], center: .center, startRadius: 20, endRadius: 210)
        }
    }
}

// MARK: - Event (with the rune door)

struct DescentEventStage: View {
    let event: DescentEvent
    let isActive: Bool
    var onRune: ((Int) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isRunes: Bool { event.runes != nil }

    var body: some View {
        GeometryReader { geo in
            let aspect = event.scene == "rush2-ev-runedoor" ? DescentGeometry.runeDoorAspect : DescentGeometry.sceneAspect
            let map = DescentSceneMapper(size: geo.size, aspect: aspect, focusY: 0.5)
            ZStack {
                DescentBackdrop(asset: event.scene, dim: 0.22, aspect: aspect, focusY: 0.5)
                DescentVignette(strength: 0.5)
                if let runes = event.runes {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        ZStack {
                            ForEach(runes) { rune in
                                runeGlow(rune, map: map, t: t)
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    ForEach(runes) { rune in
                        let center = map.point(DescentGeometry.runes[min(rune.i, 2)])
                        let side = DescentGeometry.runeRadius * map.imageRect.width * 2.2
                        Button {
                            onRune?(rune.i)
                        } label: {
                            Color.clear.frame(width: side, height: side).contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .position(center)
                        .accessibilityLabel(runeLabel(rune))
                    }
                }
            }
        }
    }

    private func runeColor(_ rune: DescentRune) -> Color {
        switch rune.state {
        case "trap": DarkFantasyTheme.danger
        case "safe": DarkFantasyTheme.success
        default: DarkFantasyTheme.rankMaster
        }
    }

    private func runeLabel(_ rune: DescentRune) -> String {
        let n = ["First", "Second", "Third"][min(rune.i, 2)]
        switch rune.state {
        case "trap": return "\(n) rune — the trap"
        case "safe": return "\(n) rune — safe"
        default: return "\(n) rune"
        }
    }

    private func runeGlow(_ rune: DescentRune, map: DescentSceneMapper, t: Double) -> some View {
        let center = map.point(DescentGeometry.runes[min(rune.i, 2)])
        let r = DescentGeometry.runeRadius * map.imageRect.width
        let color = runeColor(rune)
        let pulse = 0.55 + 0.45 * DescentMotion.wave(t, period: 2.4, phase: Double(rune.i) * 0.25)
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.8), color.opacity(0.22), color.opacity(0)],
                                     center: .center, startRadius: 0, endRadius: r * 1.63))
                .frame(width: r * 3.26, height: r * 3.26)
                .opacity(pulse)
                .blendMode(.screen)
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: r * 2, height: r * 2)
                .opacity(0.5 + 0.5 * pulse)
        }
        .position(center)
    }
}

// MARK: - Campfire

struct DescentCampStage: View {
    let rested: Bool
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let map = DescentSceneMapper(size: geo.size, focusY: 0.62)
            ZStack {
                DescentBackdrop(asset: "rush2-bg-campfire", dim: 0.2, focusY: 0.62)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    let fire = map.point(DescentGeometry.campfire)
                    ZStack {
                        DescentTorchGlow(center: fire, radius: (rested ? 560 : 440) * map.k, t: t, color: DarkFantasyTheme.glowEmber)
                        DescentTorchGlow(center: CGPoint(x: fire.x, y: fire.y - 5 * map.k), radius: 170 * map.k, t: t, phase: 0.6,
                                         color: DarkFantasyTheme.goldBright)
                    }
                }
                .allowsHitTesting(false)
                DescentVignette(strength: 0.5)
            }
        }
    }
}

// MARK: - Merchant

struct DescentMerchantStage: View {
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DescentBackdrop(asset: "rush2-bg-merchant", dim: 0.32)
                DescentVignette(strength: 0.5)
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    Image("rush2-npc-merchant")
                        .resizable()
                        .scaledToFit()
                        .frame(height: geo.size.height * 0.62)
                        .offset(y: -CGFloat(DescentMotion.wave(t, period: 4)) * 4)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.95 - geo.size.height * 0.31)
                        .depthShadow(.elevated)
                }
                .accessibilityLabel("The wandering merchant")
            }
        }
    }
}
