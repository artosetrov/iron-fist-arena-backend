import SwiftUI

// MARK: - Hexbound crest
//
// The game logo, assembled from painted layers (Assets.xcassets/Crest; prompts
// and job ids in docs/08_prompts/CREST_LAYERS_PROMPTS.md) so it can be animated:
// two chains, the frame plate, a pair of bony hands, the gem, the wordmark and
// the tagline banner. Every glow and light pass is drawn here — the PNGs carry
// none (ART_STYLE_GUIDE: "AI paints, code rules"), and the tagline is typeset.
//
// The layout is in fractions of `width`, so the crest scales as one piece.
// Designed for widths of about 280–320 pt: below that the tagline (16 pt, the
// minimum text size) no longer fits its banner.

struct HexboundCrest: View {
    enum Mode {
        /// Assembles itself on appear — the cold-launch intro.
        case intro
        /// Already assembled.
        case still
    }

    let width: CGFloat
    let mode: Mode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Intro state. `.still` starts with every layer in place.
    @State private var plateIn: Bool
    @State private var chainsIn: Bool
    @State private var clawsIn: Bool
    @State private var gemIn: Bool
    @State private var gemLight: Double
    @State private var wordReveal: CGFloat
    @State private var wordGlow: Double
    @State private var bannerIn: Bool
    @State private var taglineIn: Bool
    @State private var sheenPhase: CGFloat = 0

    /// Height of the crest box, in units of its width (the bony hands fade
    /// out below the plate).
    static let aspect: CGFloat = 1.16

    /// Light the gem and the wordmark keep once the crest has settled.
    private static let restingGemLight: Double = 0.35
    private static let restingWordGlow: Double = 0.3

    init(width: CGFloat = 300, mode: Mode = .still) {
        self.width = width
        self.mode = mode
        let assembled = mode == .still
        _plateIn = State(initialValue: assembled)
        _chainsIn = State(initialValue: assembled)
        _clawsIn = State(initialValue: assembled)
        _gemIn = State(initialValue: assembled)
        _gemLight = State(initialValue: assembled ? Self.restingGemLight : 0)
        _wordReveal = State(initialValue: assembled ? 1 : 0)
        _wordGlow = State(initialValue: assembled ? Self.restingWordGlow : 0)
        _bannerIn = State(initialValue: assembled)
        _taglineIn = State(initialValue: assembled)
    }

    // MARK: Layout

    /// Centre and width of a layer, in units of the crest width.
    private struct Spot {
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
    }

    private enum Spots {
        static let plate = Spot(x: 0.50, y: 0.48, w: 0.80)
        static let gem = Spot(x: 0.50, y: 0.186, w: 0.16)        // in the plate's top socket
        static let wordmark = Spot(x: 0.50, y: 0.45, w: 1.00)
        static let banner = Spot(x: 0.50, y: 0.665, w: 0.80)
        static let chainLeft = Spot(x: 0.165, y: 0.80, w: 0.075) // from the plate's lower corners
        static let chainRight = Spot(x: 0.835, y: 0.80, w: 0.075)
        static let claws = Spot(x: 0.50, y: 0.90, w: 0.52)       // fingertips over the bottom edges
    }

    // MARK: Body

    var body: some View {
        ZStack {
            lightPool

            // Chains hang behind the plate and swing into place.
            chain(Spots.chainLeft, side: -1)
            chain(Spots.chainRight, side: 1)

            layer("crest-plate", Spots.plate)
                .blur(radius: plateIn || reduceMotion ? 0 : 8)
                .offset(y: plateIn || reduceMotion ? 0 : 10)
                .opacity(plateIn ? 1 : 0)

            claws
            gem
            wordmark
            banner
        }
        .frame(width: width, height: width * Self.aspect)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hexbound. Forge your fate.")
        .accessibilityAddTraits(.isHeader)
        .task { await playIntroIfNeeded() }
    }

    private func layer(_ asset: String, _ spot: Spot) -> some View {
        Image(asset)
            .resizable()
            .scaledToFit()
            .frame(width: width * spot.w)
            .position(x: width * spot.x, y: width * spot.y)
    }

    /// Warm light pooled behind the crest.
    private var lightPool: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        DarkFantasyTheme.gold.opacity(0.18),
                        DarkFantasyTheme.goldDim.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.64
                )
            )
            .frame(width: width * 1.28, height: width * 1.28)
            .position(x: width * Spots.plate.x, y: width * Spots.plate.y)
            .opacity(plateIn ? 1 : 0)
    }

    private func chain(_ spot: Spot, side: CGFloat) -> some View {
        Image("crest-chain")
            .resizable()
            .scaledToFit()
            .frame(width: width * spot.w)
            .rotationEffect(.degrees(chainsIn || reduceMotion ? 0 : 14 * side), anchor: .top)
            .position(x: width * spot.x, y: width * spot.y)
            .opacity(chainsIn ? 1 : 0)
    }

    private var claws: some View {
        Image("crest-claws")
            .resizable()
            .scaledToFit()
            .frame(width: width * Spots.claws.w)
            // The wrists fade into the dark below the crest.
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: DarkFantasyTheme.bgPrimary, location: 0),
                        .init(color: DarkFantasyTheme.bgPrimary, location: 0.55),
                        .init(color: DarkFantasyTheme.bgPrimary.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(y: clawsIn || reduceMotion ? 0 : 18)
            .position(x: width * Spots.claws.x, y: width * Spots.claws.y)
            .opacity(clawsIn ? 1 : 0)
    }

    private var gem: some View {
        ZStack {
            // Violet light from the stone: flares as it is set, then rests.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DarkFantasyTheme.glowMystic.opacity(0.8),
                            DarkFantasyTheme.glowMystic.opacity(0.25),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: width * 0.2
                    )
                )
                .frame(width: width * 0.4, height: width * 0.4)
                .opacity(gemLight)

            Image("crest-gem")
                .resizable()
                .scaledToFit()
                .frame(width: width * Spots.gem.w)
                .opacity(gemIn ? 1 : 0)
        }
        .position(x: width * Spots.gem.x, y: width * Spots.gem.y)
    }

    // MARK: Wordmark

    private var wordmarkImage: some View {
        Image("crest-wordmark")
            .resizable()
            .scaledToFit()
            .frame(width: width * Spots.wordmark.w)
    }

    /// Struck left to right: a wipe with a soft leading edge reveals the
    /// letters while their forge glow flares, then settles low.
    private var wordmark: some View {
        let glowRoom = width * 0.06
        let wipeWidth = width * Spots.wordmark.w + glowRoom * 2

        return ZStack {
            // The glow is the letters' own silhouette, tinted and blurred.
            Image("crest-wordmark")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: width * Spots.wordmark.w)
                .foregroundStyle(DarkFantasyTheme.glowWarm)
                .blur(radius: width * 0.03)
                .opacity(wordGlow)

            wordmarkImage
                .overlay { sheen }
        }
        .padding(glowRoom)
        .mask(alignment: .leading) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DarkFantasyTheme.bgPrimary)
                    .frame(width: wipeWidth)
                LinearGradient(
                    colors: [DarkFantasyTheme.bgPrimary, DarkFantasyTheme.bgPrimary.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: wipeWidth * 0.15)
            }
            .offset(x: wipeWidth * 1.15 * (wordReveal - 1))
        }
        .position(x: width * Spots.wordmark.x, y: width * Spots.wordmark.y)
    }

    /// One pass of storm light (the lightning's cold white) across the
    /// letters. The band sits off the art at phase 0 and 1; the letters'
    /// own alpha masks it.
    private var sheen: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.vfxLightningCore.opacity(0.35), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.2, height: geo.size.height * 1.8)
            .rotationEffect(.degrees(18))
            .offset(
                x: geo.size.width * (-0.4 + 1.6 * sheenPhase),
                y: -geo.size.height * 0.4
            )
        }
        .mask(wordmarkImage)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    // MARK: Banner

    private var banner: some View {
        ZStack {
            Image("crest-banner")
                .resizable()
                .scaledToFit()
                .frame(width: width * Spots.banner.w)

            Text("FORGE YOUR FATE")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .subtleShadow()
                .fixedSize()
                .opacity(taglineIn ? 1 : 0)
        }
        .offset(y: bannerIn || reduceMotion ? 0 : -6)
        .opacity(bannerIn ? 1 : 0)
        .position(x: width * Spots.banner.x, y: width * Spots.banner.y)
    }

    // MARK: Intro

    /// The assembly, cue by cue (seconds from appear): plate 0.10 → chains
    /// 0.30 → hands 0.40 → gem 0.55 → wordmark 0.70 → banner 1.05 →
    /// tagline 1.25 → storm-light sheen 1.30–2.50.
    private func playIntroIfNeeded() async {
        guard mode == .intro, !plateIn else { return }

        if reduceMotion {
            withAnimation(.easeInOut(duration: MotionConstants.normal)) {
                plateIn = true
                chainsIn = true
                clawsIn = true
                gemIn = true
                gemLight = Self.restingGemLight
                wordReveal = 1
                wordGlow = Self.restingWordGlow
                bannerIn = true
                taglineIn = true
            }
            return
        }

        // Cues are anchored to the start, not chained: a slow first frame
        // (big images decoding) delays one step, never every step after it.
        let start = ContinuousClock.now
        func cue(_ seconds: Double) async -> Bool {
            try? await Task.sleep(until: start.advanced(by: .seconds(seconds)), clock: .continuous)
            return !Task.isCancelled
        }

        guard await cue(0.10) else { return }
        withAnimation(.easeOut(duration: MotionConstants.normal)) { plateIn = true }

        guard await cue(0.30) else { return }
        withAnimation(MotionConstants.springBouncy) { chainsIn = true }

        guard await cue(0.40) else { return }
        withAnimation(.easeOut(duration: MotionConstants.normal)) { clawsIn = true }

        guard await cue(0.55) else { return }
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            gemIn = true
            gemLight = 1
        }

        guard await cue(0.70) else { return }
        withAnimation(.easeInOut(duration: MotionConstants.reward)) { wordReveal = 1 }
        withAnimation(.easeOut(duration: MotionConstants.normal)) { wordGlow = 1 }

        guard await cue(0.85) else { return }
        withAnimation(.easeInOut(duration: MotionConstants.reward)) { gemLight = Self.restingGemLight }

        guard await cue(1.05) else { return }
        withAnimation(.easeOut(duration: MotionConstants.normal)) { bannerIn = true }

        guard await cue(1.15) else { return }
        withAnimation(.easeInOut(duration: MotionConstants.reward)) { wordGlow = Self.restingWordGlow }

        guard await cue(1.25) else { return }
        withAnimation(.easeOut(duration: MotionConstants.normal)) { taglineIn = true }

        guard await cue(1.30) else { return }
        withAnimation(.easeInOut(duration: MotionConstants.epic)) { sheenPhase = 1 }
    }
}

#Preview("Still") {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        HexboundCrest(width: 300, mode: .still)
    }
}

#Preview("Intro") {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        HexboundCrest(width: 300, mode: .intro)
    }
}
