import SwiftUI

/// Signboard + keeper header for the two trading screens (2026-10-16,
/// design canvas "Shop vs Black Market headers", concept A).
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
    }

    let style: Style
    let title: String
    let tagline: String
    let keeperName: String
    let keeperImage: String
    let lines: [String]

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
            lineIndex = lines.isEmpty ? 0 : Int.random(in: 0..<lines.count)
            if !reduceMotion { lanternLit = true }
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
                    .font(DarkFantasyTheme.caption.weight(.semibold))
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
                .font(style == .blackMarket ? DarkFantasyTheme.uiLabel.italic() : DarkFantasyTheme.uiLabel)
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

    private var titleColor: Color { style == .shop ? DarkFantasyTheme.goldBright : DarkFantasyTheme.contrabandBright }
    private var titleGlow: Color { DarkFantasyTheme.contrabandAccent.opacity(0.7) }
    private var taglineColor: Color { style == .shop ? DarkFantasyTheme.shopSignTagline : DarkFantasyTheme.contrabandMuted }
    private var signColors: [Color] {
        style == .shop
            ? [DarkFantasyTheme.shopSignTop, DarkFantasyTheme.shopSignBottom]
            : [DarkFantasyTheme.bmSignTop, DarkFantasyTheme.bmSignBottom]
    }
    private var signEdge: Color { style == .shop ? DarkFantasyTheme.shopSignEdge : DarkFantasyTheme.bmSignEdge }
    private var chainColor: Color { style == .shop ? DarkFantasyTheme.shopChain : DarkFantasyTheme.bmChain }
    private var bubbleFill: Color {
        style == .shop ? DarkFantasyTheme.bgSecondary.opacity(0.92) : DarkFantasyTheme.bmBubble.opacity(0.94)
    }
    private var bubbleBorder: Color {
        style == .shop ? DarkFantasyTheme.gold.opacity(0.45) : DarkFantasyTheme.contrabandAccent.opacity(0.55)
    }
}

// MARK: - Counter (currency bar background)

/// The currency bar under `ShopkeeperHeader`, dressed as the counter the
/// keeper stands behind.
struct ShopCounterBackground: View {
    let style: ShopkeeperHeader.Style

    var body: some View {
        LinearGradient(
            colors: style == .shop
                ? [DarkFantasyTheme.shopCounterTop, DarkFantasyTheme.shopCounterBottom]
                : [DarkFantasyTheme.bmCounterTop, DarkFantasyTheme.bmCounterBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(style == .shop ? DarkFantasyTheme.shopCounterEdge : DarkFantasyTheme.bmCounterEdge)
                .frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(style == .shop ? DarkFantasyTheme.shopSignEdge : DarkFantasyTheme.bmSignEdge)
                .frame(height: 1)
        }
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 8, y: -4)
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
