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

/// A tappable option: passage, chest action, event choice, camp pick, ware.
struct DescentChoiceRow<Icon: View>: View {
    let title: String
    let subtitle: String?
    var trailing: String?
    var selected = false
    var disabled = false
    var tone: Color = DarkFantasyTheme.textPrimary
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: action) {
            HStack(spacing: LayoutConstants.spaceMS) {
                icon()
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .fill(DarkFantasyTheme.bgAbyss)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(title.uppercased())
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(1.5)
                        .foregroundStyle(disabled ? DarkFantasyTheme.textTertiaryAA : tone)
                        .lineLimit(2)
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
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textGold)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceSM)
            .frame(minHeight: LayoutConstants.touchComfortable)
            .background(
                RadialGlowBackground(
                    baseColor: selected ? DarkFantasyTheme.bgElevated : DarkFantasyTheme.bgSecondary,
                    glowColor: selected ? DarkFantasyTheme.gold.opacity(0.12) : DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(selected ? DarkFantasyTheme.borderGold : DarkFantasyTheme.borderSubtle, lineWidth: selected ? 1.5 : 1)
            )
            .compositingGroup()
            .dualShadow(glowColor: selected ? DarkFantasyTheme.goldGlow : .clear, glowRadius: 8, depth: .panel)
            .opacity(disabled ? 0.55 : 1)
        }
        .buttonStyle(DescentRowPressStyle())
        .disabled(disabled)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
    var size: CGFloat = 32

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

struct DescentDiceTray: View {
    let round: DescentRound?

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Text("YOU")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .fixedSize()
            die(round?.pa, label: "STRIKE", state: round?.pHit == true ? .hit : .idle)
            die(round?.pg, label: "GUARD", state: round?.pBlock == true ? .blocked : .idle)
            Text("vs")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .frame(maxWidth: .infinity)
            die(round?.ea, label: "STRIKE", state: round?.eHit == true ? .hurt : .idle)
            die(round?.eg, label: "GUARD", state: round?.eBlock == true ? .blocked : .idle)
            Text("FOE")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .fixedSize()
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgDarkPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.bgDarkPanelBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private enum DieState { case idle, hit, hurt, blocked }

    private func die(_ zone: String?, label: String, state: DieState) -> some View {
        let edge: Color = switch state {
        case .idle: DarkFantasyTheme.borderMedium
        case .hit: DarkFantasyTheme.success
        case .hurt: DarkFantasyTheme.danger
        case .blocked: DarkFantasyTheme.info
        }
        return VStack(spacing: LayoutConstants.space2XS) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.shopSignTagline)
                if let zone {
                    Image(DescentStyle.zoneAsset(zone))
                        .resizable()
                        .scaledToFit()
                        .padding(7)
                } else {
                    Text("?")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.shopSignBottom.opacity(0.5))
                }
            }
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(edge, lineWidth: state == .idle ? 1 : 2.5)
            )
            .shadow(color: state == .idle ? .clear : edge.opacity(0.6), radius: 8)
            .id("\(label)-\(zone ?? "none")")
            .transition(.opacity)
        }
        .animation(.easeOut(duration: MotionConstants.fast), value: zone)
    }

    private var accessibilitySummary: String {
        guard let r = round else { return "No dice rolled yet" }
        return "You struck \(r.pa) and guarded \(r.pg). The foe struck \(r.ea) and guarded \(r.eg)."
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
