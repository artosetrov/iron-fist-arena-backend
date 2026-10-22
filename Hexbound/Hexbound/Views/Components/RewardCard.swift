import SwiftUI

// MARK: - Reward card
//
// Anatomy, top to bottom (see RewardCardStyle.swift for families and tiers):
//
//   crest ─┐
//   ┌──────┴──────┐  frame top cap
//   │ illustration │  painted scene + big subject, fades into the card body
//   │   TITLE      │  sits on the fade
//   │  subtitle    │
//   │  content     │  rewards, loot, progress — any height
//   │  [ action ]  │
//   └──────┬──────┘  frame bottom cap; the rails between repeat to fit
//      ornament

/// A painted reward card. Its height is its content's; the frame stretches.
/// The width comes from the caller — present cards through `RewardCardStage`.
struct RewardCard<Header: View, Content: View, Actions: View>: View {
    let family: RewardCardFamily
    let tier: RewardCardTier
    /// A defeat or a loss: the frame and the illustration lose their colour.
    var dimmed = false
    let art: RewardCardArt
    let width: CGFloat
    /// Illustration height as a share of the window width (`RewardCardLayout`).
    var artRatio: CGFloat = RewardCardLayout.artRatio
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content
    @ViewBuilder var actions: () -> Actions

    /// Set by `RewardCardStage` when even the smallest card is taller than the
    /// screen: the card takes the screen's height and its content scrolls between
    /// the title and the buttons, which stay in reach.
    @Environment(\.rewardCardScrollsContent) private var scrollsContent

    var body: some View {
        let m = RewardCardFrameMetrics.of(family, tier)
        let w = width
        let windowW = w * (1 - m.insetL - m.insetR)
        let artH = (windowW * artRatio).rounded()
        let bleed = w * RewardCardLayout.bleed
        // How far the crest hangs into the illustration (from its top edge, which
        // starts `bleed` above the window).
        let crestReach = max(0, (m.crestBottom - m.windowTop) * w) + bleed + LayoutConstants.spaceXS

        VStack(spacing: LayoutConstants.spaceSM) {
            // The illustration is drawn in the background (it bleeds under the frame);
            // this keeps its place in the layout.
            Color.clear.frame(height: artH)

            header()
                .padding(.top, -RewardCardLayout.titleOverlap)
                .padding(.horizontal, w * RewardCardLayout.contentInset)

            contentArea(width: w)

            actions()
                .padding(.horizontal, w * RewardCardLayout.actionInset)
                .padding(.top, LayoutConstants.spaceXS)
        }
        .frame(width: windowW)
        .padding(.top, m.windowTop * w)
        .padding(.bottom, m.contentBottom * w + LayoutConstants.spaceMD)
        .padding(.leading, m.insetL * w)
        .padding(.trailing, m.insetR * w)
        .frame(width: w)
        .frame(minHeight: (m.top + m.bottom) * w, alignment: .top)
        .background {
            GeometryReader { geo in
                let x0 = m.insetL * w - bleed
                let y0 = m.windowTop * w - bleed
                let bodyW = windowW + 2 * bleed
                let bodyH = max(0, geo.size.height - y0 - (m.windowBottom * w - bleed))
                ZStack(alignment: .top) {
                    RewardCardLayout.body
                    RewardCardArtPanel(art: art, family: family, tier: tier, dimmed: dimmed, crestReach: crestReach)
                        .frame(width: bodyW, height: artH + bleed)
                }
                .frame(width: bodyW, height: bodyH, alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusMD))
                .offset(x: x0, y: y0)
            }
        }
        .overlay {
            RewardCardFrame(family: family, tier: tier, dimmed: dimmed)
        }
        .compositingGroup()
        .shadow(color: (dimmed ? DarkFantasyTheme.danger : tier.light).opacity(0.25), radius: 18)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 12, y: 8)
    }

    /// The rewards: as tall as they are, or — when the stage pins the card to the
    /// screen — scrolling inside it, faded at the edges, the indicator flashed once.
    @ViewBuilder
    private func contentArea(width w: CGFloat) -> some View {
        if scrollsContent {
            ScrollView(.vertical) {
                content()
                    .padding(.horizontal, w * RewardCardLayout.contentInset)
                    .padding(.vertical, LayoutConstants.spaceSM)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicatorsFlash(onAppear: true)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.04),
                        .init(color: .black, location: 0.9),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            content()
                .padding(.horizontal, w * RewardCardLayout.contentInset)
        }
    }
}

// MARK: - Pinned card

private struct RewardCardScrollsContentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The stage pinned the card to the screen's height; its content scrolls.
    var rewardCardScrollsContent: Bool {
        get { self[RewardCardScrollsContentKey.self] }
        set { self[RewardCardScrollsContentKey.self] = newValue }
    }
}

extension RewardCard where Header == RewardCardTitle {
    /// The usual card: a title and an optional subtitle on the illustration's fade.
    init(
        family: RewardCardFamily,
        tier: RewardCardTier,
        dimmed: Bool = false,
        art: RewardCardArt,
        width: CGFloat,
        artRatio: CGFloat = RewardCardLayout.artRatio,
        title: String,
        subtitle: String? = nil,
        titleColor: Color = DarkFantasyTheme.goldBright,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.family = family
        self.tier = tier
        self.dimmed = dimmed
        self.art = art
        self.width = width
        self.artRatio = artRatio
        self.header = { RewardCardTitle(title: title, subtitle: subtitle, color: titleColor) }
        self.content = content
        self.actions = actions
    }
}

// MARK: - Frame

/// The stretchable frame: top cap, the rail strip repeated to fill the height,
/// bottom cap. The caps cross-fade into the strip so the joins never show.
struct RewardCardFrame: View {
    let family: RewardCardFamily
    let tier: RewardCardTier
    var dimmed = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let m = RewardCardFrameMetrics.of(family, tier)
            let topH = m.top * w, botH = m.bottom * w, stripH = max(1, m.mid * w)
            let fade = min(RewardCardLayout.capFade, topH / 3, botH / 3)
            let span = max(0, h - topH - botH + 2 * fade)
            let count = Int((span / stripH).rounded(.up))

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { _ in
                        Image(asset("mid"))
                            .resizable()
                            .frame(width: w, height: stripH)
                    }
                }
                .frame(width: w, height: span, alignment: .top)
                .clipped()
                .offset(y: topH - fade)

                Image(asset("top"))
                    .resizable()
                    .frame(width: w, height: topH)
                    .mask(Self.fadeMask(fadeAtBottom: true, share: fade / topH))

                Image(asset("bottom"))
                    .resizable()
                    .frame(width: w, height: botH)
                    .mask(Self.fadeMask(fadeAtBottom: false, share: fade / botH))
                    .offset(y: h - botH)
            }
            .frame(width: w, height: h, alignment: .topLeading)
            .saturation(dimmed ? 0.15 : 1)
            .brightness(dimmed ? -0.12 : 0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func asset(_ part: String) -> String {
        "reward-frame-\(family.rawValue)-\(tier.assetKey)-\(part)"
    }

    private static func fadeMask(fadeAtBottom: Bool, share: CGFloat) -> LinearGradient {
        let s = max(0, min(1, share))
        let stops: [Gradient.Stop] = fadeAtBottom
            ? [.init(color: .black, location: 0), .init(color: .black, location: 1 - s), .init(color: .clear, location: 1)]
            : [.init(color: .clear, location: 0), .init(color: .black, location: s), .init(color: .black, location: 1)]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Illustration

/// The card's illustration: the family's scene, the tier's light, a big subject,
/// and a fade into the card body at the bottom.
struct RewardCardArtPanel: View {
    let art: RewardCardArt
    let family: RewardCardFamily
    let tier: RewardCardTier
    var dimmed = false
    /// How far the frame's crest hangs into the panel from its top edge: the
    /// subject's top stays below it, so the crest never covers a face or a chest.
    var crestReach: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .bottom) {
                ZStack(alignment: .bottom) {
                    Image(art.backdrop ?? family.backdrop)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .overlay(DarkFantasyTheme.bgAbyss.opacity(0.45))

                    RadialGradient(
                        colors: [tier.light.opacity(0.4), .clear],
                        center: UnitPoint(x: 0.5, y: 0.45),
                        startRadius: 0,
                        endRadius: w * 0.6
                    )

                    subject(width: w, height: h)
                }
                .saturation(dimmed ? 0.2 : 1)
                .brightness(dimmed ? -0.06 : 0)

                // Shade the sides and melt the bottom into the card body.
                HStack(spacing: 0) {
                    LinearGradient(colors: [DarkFantasyTheme.bgAbyss.opacity(0.6), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: w * 0.12)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.6)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: w * 0.12)
                }
                LinearGradient(
                    stops: [.init(color: .clear, location: 0.5), .init(color: RewardCardLayout.body, location: 1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    /// The subject's height: its share of the panel, but never so tall that its top
    /// reaches the crest (its base sinks `sink` below the panel). Never under a third
    /// of the panel, so a very short card still shows something.
    private func subjectHeight(_ h: CGFloat) -> CGFloat {
        min(h * art.fill, max(h * 0.34, h * (1 + art.sink) - crestReach))
    }

    @ViewBuilder
    private func subject(width w: CGFloat, height h: CGFloat) -> some View {
        switch art.subject {
        case .image(let key):
            if let image = AssetManager.shared.image(forKey: key) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: w * 1.1, maxHeight: subjectHeight(h))
                    .scaleEffect(x: art.mirrored ? -1 : 1, y: 1)
                    .offset(y: h * art.sink)
            }
        case let .avatar(skinKey, characterClass):
            AvatarImageView(skinKey: skinKey, characterClass: characterClass, size: subjectHeight(h))
                .scaleEffect(x: art.mirrored ? -1 : 1, y: 1)
                .offset(y: h * art.sink)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Title

/// Title and subtitle on the illustration's fade, with the gold divider under them.
struct RewardCardTitle: View {
    let title: String
    var subtitle: String? = nil
    var color: Color = DarkFantasyTheme.goldBright
    /// The pulse some ceremonies give the title once it has landed.
    var glow: Bool = false
    /// Letter spacing, for titles that carried their own (RANK UP).
    var tracking: CGFloat = 0

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(title)
                .font(DarkFantasyTheme.cinematicTitle)
                .tracking(tracking)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .shadow(color: color.opacity(glow ? 0.6 : 0.25), radius: glow ? 18 : 8)
                .shadow(color: DarkFantasyTheme.bgAbyss, radius: 2, y: 1)
                .accessibilityAddTraits(.isHeader)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.top, LayoutConstants.spaceXS)
        }
    }
}

// MARK: - Reward rows

/// One line of a reward list: icon, amount, what it is.
struct RewardCardRow: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = DarkFantasyTheme.goldBright

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
            Text(value)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
            if !label.isEmpty {
                Text(label)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Loot names

/// An item's name under its loot tile: two lines at most, in its rarity's colour.
/// Rows of tiles align to the top, so a one-line name leaves its tile level with
/// the others.
struct RewardCardLootName: View {
    let name: String
    let color: Color

    var body: some View {
        Text(name)
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(width: RewardCardLayout.lootCellWidth, alignment: .top)
    }
}

// MARK: - Stage

/// Puts a reward card on screen: centred, as wide as the phone allows. If the
/// full card does not fit (small phones, long loot lists) the illustration
/// shrinks, twice; if even that does not fit, the card takes the screen's height
/// and its rewards scroll inside it — the title and the buttons never leave the
/// screen.
struct RewardCardStage<Card: View>: View {
    @ViewBuilder let card: (_ width: CGFloat, _ artRatio: CGFloat) -> Card

    var body: some View {
        GeometryReader { geo in
            let width = RewardCardLayout.width(for: geo.size.width)
            ViewThatFits(in: .vertical) {
                card(width, RewardCardLayout.artRatio)
                card(width, RewardCardLayout.compactArtRatio)
                card(width, RewardCardLayout.smallArtRatio)
                card(width, RewardCardLayout.smallArtRatio)
                    .environment(\.rewardCardScrollsContent, true)
                    .frame(maxHeight: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
