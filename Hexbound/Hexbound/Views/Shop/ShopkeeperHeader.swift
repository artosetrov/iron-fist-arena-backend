import SwiftUI

/// Signboard + keeper header for the keeper screens (2026-10-16, design
/// canvas "Shop vs Black Market headers", concept A): Shop, Black Market and
/// the Gold Mine (foreman, 2026-10-17).
///
/// The title hangs on a signboard on the left, the keeper stands on the right
/// and says one line in a speech bubble. The currency bar directly below is
/// styled as the counter (`ShopCounterBackground`), so the keeper reads as
/// standing behind it. Shop = warm oak and gold with Sterling the goblin;
/// Black Market = charred board, crimson and the Scavenger with his lantern —
/// the two places are told apart at a glance.
struct ShopkeeperHeader: View {
    enum Style {
        case shop
        case blackMarket
        case goldMine
    }

    let style: Style
    let title: String
    let tagline: String
    let keeperName: String
    let keeperImage: String
    let lines: [String]
    /// First line to show; nil = a random one (the shops). The mine passes 0
    /// because its first line is about what is happening right now.
    var startIndex: Int? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lineIndex = 0
    @State private var lanternLit = false

    static let height: CGFloat = 196

    var body: some View {
        GeometryReader { geo in
            let signWidth = min(212, geo.size.width * 0.56)

            ZStack(alignment: .topLeading) {
                if style == .blackMarket {
                    lanternGlow
                        .frame(width: 300, height: 300)
                        .position(x: geo.size.width - 70, y: Self.height * 0.45)
                }

                keeper
                    .frame(width: geo.size.width, height: Self.height, alignment: .bottomTrailing)

                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    signboard(width: signWidth)
                    bubble
                        .frame(maxWidth: signWidth, alignment: .leading)
                }
                .padding(.leading, LayoutConstants.screenPadding)
            }
        }
        .frame(height: Self.height)
        .onAppear {
            lineIndex = lines.isEmpty ? 0 : (startIndex.map { min(max($0, 0), lines.count - 1) } ?? Int.random(in: 0..<lines.count))
            if !reduceMotion { lanternLit = true }
            // Greets once per launch; tapping the keeper always speaks.
            if lines.indices.contains(lineIndex) { NPCVoice.shared.speakOnce(lines[lineIndex]) }
        }
        .onDisappear {
            if lines.indices.contains(lineIndex) { NPCVoice.shared.stop(lines[lineIndex]) }
        }
    }

    // MARK: - Signboard

    private func signboard(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            chains
                .frame(width: width * 0.72, height: 26)

            VStack(spacing: LayoutConstants.space2XS) {
                Text(title)
                    .font(DarkFantasyTheme.title)
                    .tracking(4)
                    .foregroundStyle(titleColor)
                    .shadow(color: titleGlow, radius: style == .blackMarket ? 10 : 0)
                    .shadow(color: signEdge, radius: 0, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(tagline.uppercased())
                    .font(style == .goldMine ? DarkFantasyTheme.body.weight(.semibold) : DarkFantasyTheme.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(taglineColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceSM)
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(LinearGradient(colors: signColors, startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(signEdge, lineWidth: 2)
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.75), radius: 8, y: 5)
        }
        .rotationEffect(.degrees(style == .blackMarket ? -4 : 0), anchor: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(tagline)")
        .accessibilityAddTraits(.isHeader)
    }

    private var chains: some View {
        Canvas { context, size in
            let dash = StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
            // The black-market board hangs from one short chain — it sits crooked.
            let rightDrop = style == .blackMarket ? size.height * 0.55 : size.height
            var left = Path()
            left.move(to: CGPoint(x: 0, y: 0))
            left.addLine(to: CGPoint(x: 0, y: size.height))
            var right = Path()
            right.move(to: CGPoint(x: size.width, y: 0))
            right.addLine(to: CGPoint(x: size.width, y: rightDrop))
            context.stroke(left, with: .color(chainColor), style: dash)
            context.stroke(right, with: .color(chainColor), style: dash)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Keeper

    private var keeper: some View {
        Button {
            guard lines.count > 1 else { return }
            SFXManager.shared.play(.uiTap)
            withAnimation(MotionConstants.snappy) {
                lineIndex = (lineIndex + 1) % lines.count
            }
            NPCVoice.shared.speak(lines[lineIndex])
        } label: {
            Image(keeperImage)
                .resizable()
                .scaledToFit()
                .frame(height: Self.height + 8)
                .scaleEffect(x: -1, y: 1) // face the content on the left
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.85), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .offset(x: 18)
        .accessibilityLabel(keeperName)
        .accessibilityHint("Says something else")
    }

    private var lanternGlow: some View {
        RadialGradient(
            colors: [DarkFantasyTheme.contrabandAccent.opacity(0.45), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 150
        )
        .opacity(lanternLit ? 1 : 0.7)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
            value: lanternLit
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Speech bubble

    @ViewBuilder
    private var bubble: some View {
        if lines.indices.contains(lineIndex) {
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: LayoutConstants.radiusLG,
                bottomLeadingRadius: LayoutConstants.space2XS,
                bottomTrailingRadius: LayoutConstants.radiusLG,
                topTrailingRadius: LayoutConstants.radiusLG
            )
            Text("“\(lines[lineIndex])”")
                .font(bubbleFont)
                .foregroundStyle(style == .blackMarket ? DarkFantasyTheme.contrabandInk : DarkFantasyTheme.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, LayoutConstants.spaceMS)
                .padding(.vertical, LayoutConstants.spaceSM)
                .background(shape.fill(bubbleFill))
                .overlay(shape.stroke(bubbleBorder, lineWidth: 1))
                .id(lineIndex)
                .transition(.opacity)
                .accessibilityLabel("\(keeperName) says: \(lines[lineIndex])")
        }
    }

    // MARK: - Palette

    private var titleColor: Color {
        switch style {
        case .shop, .goldMine: return DarkFantasyTheme.goldBright
        case .blackMarket: return DarkFantasyTheme.contrabandBright
        }
    }
    private var titleGlow: Color { DarkFantasyTheme.contrabandAccent.opacity(0.7) }
    private var taglineColor: Color {
        switch style {
        case .shop: return DarkFantasyTheme.shopSignTagline
        case .blackMarket: return DarkFantasyTheme.contrabandMuted
        case .goldMine: return DarkFantasyTheme.mineSignTagline
        }
    }
    private var signColors: [Color] {
        switch style {
        case .shop: return [DarkFantasyTheme.shopSignTop, DarkFantasyTheme.shopSignBottom]
        case .blackMarket: return [DarkFantasyTheme.bmSignTop, DarkFantasyTheme.bmSignBottom]
        case .goldMine: return [DarkFantasyTheme.mineSignTop, DarkFantasyTheme.mineSignBottom]
        }
    }
    private var signEdge: Color {
        switch style {
        case .shop: return DarkFantasyTheme.shopSignEdge
        case .blackMarket: return DarkFantasyTheme.bmSignEdge
        case .goldMine: return DarkFantasyTheme.mineSignEdge
        }
    }
    private var chainColor: Color {
        switch style {
        case .shop: return DarkFantasyTheme.shopChain
        case .blackMarket: return DarkFantasyTheme.bmChain
        case .goldMine: return DarkFantasyTheme.mineChain
        }
    }
    private var bubbleFill: Color {
        style == .blackMarket ? DarkFantasyTheme.bmBubble.opacity(0.94) : DarkFantasyTheme.bgSecondary.opacity(0.92)
    }
    private var bubbleBorder: Color {
        style == .blackMarket ? DarkFantasyTheme.contrabandAccent.opacity(0.55) : DarkFantasyTheme.gold.opacity(0.45)
    }
    /// The mine keeps the 16 pt minimum; the shops keep their original look.
    private var bubbleFont: Font {
        switch style {
        case .shop: return DarkFantasyTheme.uiLabel
        case .blackMarket: return DarkFantasyTheme.uiLabel.italic()
        case .goldMine: return DarkFantasyTheme.body
        }
    }
}

// MARK: - Keeper lines

/// What the keepers say in `ShopkeeperHeader`. Voiced: these arrays are read
/// by `scripts/npc_voice/build_catalog.py` (section 7) — re-voice a line
/// whenever you change its wording.
enum ShopkeeperLines {
    static let merchant = [
        "Steel, leather, potions — all honest. Mostly.",
        "Gold first. Then we talk.",
        "Touch it, you've bought it.",
        "Fresh stock every dawn."
    ]

    static let scavenger = [
        "Psst. Fell off a wagon. Don't ask which.",
        "Keep your voice down.",
        "You didn't see me.",
        "Everything's for sale. Even the lamp."
    ]
}

// MARK: - Counter (currency bar background)

/// The currency bar under `ShopkeeperHeader`, dressed as the counter the
/// keeper stands behind.
struct ShopCounterBackground: View {
    let style: ShopkeeperHeader.Style

    var body: some View {
        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(topEdge)
                .frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(bottomEdge)
                .frame(height: 1)
        }
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 8, y: -4)
    }

    private var colors: [Color] {
        switch style {
        case .shop: return [DarkFantasyTheme.shopCounterTop, DarkFantasyTheme.shopCounterBottom]
        case .blackMarket: return [DarkFantasyTheme.bmCounterTop, DarkFantasyTheme.bmCounterBottom]
        case .goldMine: return [DarkFantasyTheme.mineCounterTop, DarkFantasyTheme.mineCounterBottom]
        }
    }

    private var topEdge: Color {
        switch style {
        case .shop: return DarkFantasyTheme.shopCounterEdge
        case .blackMarket: return DarkFantasyTheme.bmCounterEdge
        case .goldMine: return DarkFantasyTheme.mineCounterEdge
        }
    }

    private var bottomEdge: Color {
        switch style {
        case .shop: return DarkFantasyTheme.shopSignEdge
        case .blackMarket: return DarkFantasyTheme.bmSignEdge
        case .goldMine: return DarkFantasyTheme.mineSignEdge
        }
    }
}

// MARK: - Screen backdrop

/// Lets the room art show behind the header and darkens it under the content.
struct ShopRoomScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: DarkFantasyTheme.bgAbyss.opacity(0.35), location: 0),
                .init(color: DarkFantasyTheme.bgAbyss.opacity(0.55), location: 0.2),
                .init(color: DarkFantasyTheme.bgAbyss.opacity(0.88), location: 0.36),
                .init(color: DarkFantasyTheme.bgAbyss.opacity(0.94), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }
}
