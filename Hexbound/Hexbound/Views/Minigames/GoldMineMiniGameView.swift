import SwiftUI

// MARK: - Drop model

/// A single falling drop in the Gold Mine mini-game. Visual-only — the final
/// reward is always capped server-side. `id` must be stable so SwiftUI can
/// track the view across frames.
struct FallingDrop: Identifiable, Equatable {
    enum Kind: Equatable {
        case gold(Int)
        case gem
    }

    let id: UUID = UUID()
    let kind: Kind
    let xFraction: CGFloat   // 0..1 horizontal position
    let spawnedAt: Date
    let fallDurationSec: Double
    var caught: Bool = false

    /// Progress 0..1 from top to bottom based on elapsed time.
    func progress(at now: Date) -> CGFloat {
        let elapsed = now.timeIntervalSince(spawnedAt)
        return max(0, min(1, CGFloat(elapsed / fallDurationSec)))
    }

    /// Visual coin value or nil for gems.
    var goldValue: Int {
        if case .gold(let v) = kind { return v }
        return 0
    }

    /// Whether this is a "rare" drop (5+ gold or a gem).
    var isRare: Bool {
        switch kind {
        case .gold(let v): return v >= 5
        case .gem: return true
        }
    }

    /// Weighted random drop factory. Gem chance and gold weights vary by wave.
    static func random(
        xFraction: CGFloat,
        spawnedAt: Date,
        wave: MinigameWave
    ) -> FallingDrop {
        let gemRoll = Int.random(in: 0..<100)
        if gemRoll < wave.gemChancePercent {
            return FallingDrop(
                kind: .gem,
                xFraction: xFraction,
                spawnedAt: spawnedAt,
                fallDurationSec: Double.random(in: wave.gemFallRange)
            )
        }
        // Weighted pick across gold values.
        let drops = wave.goldDrops
        let total = drops.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for entry in drops {
            if roll < entry.weight {
                return FallingDrop(
                    kind: .gold(entry.value),
                    xFraction: xFraction,
                    spawnedAt: spawnedAt,
                    fallDurationSec: Double.random(in: wave.goldFallRange)
                )
            }
            roll -= entry.weight
        }
        // Fallback — should never hit.
        return FallingDrop(
            kind: .gold(1),
            xFraction: xFraction,
            spawnedAt: spawnedAt,
            fallDurationSec: 3.0
        )
    }
}

// MARK: - Wave system

/// Defines pacing waves within the 60-second minigame. Each wave has its
/// own spawn rate, drop weights, gem chance, and fall speed.
enum MinigameWave: CaseIterable {
    case warmup       // 0–15s: Easy intro
    case building     // 15–30s: Faster, richer
    case goldRush     // 30–45s: Peak action
    case gemStorm     // 45–52s: High gem chance
    case finalFrenzy  // 52–60s: Maximum speed

    /// Which wave is active at a given elapsed time.
    static func current(elapsed: Double) -> MinigameWave {
        switch elapsed {
        case ..<15: return .warmup
        case ..<30: return .building
        case ..<45: return .goldRush
        case ..<52: return .gemStorm
        default:    return .finalFrenzy
        }
    }

    var spawnInterval: Double {
        switch self {
        case .warmup:      return 0.50
        case .building:    return 0.40
        case .goldRush:    return 0.32
        case .gemStorm:    return 0.38
        case .finalFrenzy: return 0.25
        }
    }

    var goldDrops: [(value: Int, weight: Int)] {
        switch self {
        case .warmup:
            return [(1, 55), (2, 25), (3, 12), (5, 6), (10, 2)]
        case .building:
            return [(1, 40), (2, 28), (3, 18), (5, 10), (10, 4)]
        case .goldRush:
            return [(1, 25), (2, 25), (3, 22), (5, 18), (10, 10)]
        case .gemStorm:
            return [(1, 35), (2, 25), (3, 20), (5, 14), (10, 6)]
        case .finalFrenzy:
            return [(1, 20), (2, 22), (3, 25), (5, 20), (10, 13)]
        }
    }

    var gemChancePercent: Int {
        switch self {
        case .warmup:      return 3
        case .building:    return 4
        case .goldRush:    return 5
        case .gemStorm:    return 10
        case .finalFrenzy: return 6
        }
    }

    var goldFallRange: ClosedRange<Double> {
        switch self {
        case .warmup:      return 2.6...3.4
        case .building:    return 2.3...3.1
        case .goldRush:    return 2.0...2.8
        case .gemStorm:    return 2.2...3.0
        case .finalFrenzy: return 1.8...2.5
        }
    }

    var gemFallRange: ClosedRange<Double> {
        switch self {
        case .warmup:      return 3.0...3.8
        case .building:    return 2.6...3.4
        case .goldRush:    return 2.4...3.2
        case .gemStorm:    return 2.2...3.0
        case .finalFrenzy: return 2.0...2.6
        }
    }

    var bannerText: String? {
        switch self {
        case .warmup: return nil
        case .building: return nil
        case .goldRush: return "GOLD RUSH!"
        case .gemStorm: return "GEM STORM!"
        case .finalFrenzy: return "FINAL FRENZY!"
        }
    }
}

// MARK: - Cap meter

/// Indicator showing how much of the 15% gold cap has been filled.
/// Opacity-based feedback only (no scale animation — per project rule).
struct CapMeterView: View {
    let filled: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1.0, Double(filled) / Double(total))
    }

    private var isFull: Bool { filled >= total && total > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            HStack {
                Text("BONUS GOLD CAP")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("\(filled)/\(total)")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(isFull ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(MotionConstants.smooth, value: filled)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .frame(height: LayoutConstants.mineCapBarHeight)
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.goldGradient)
                        .frame(width: proxy.size.width * CGFloat(fraction), height: 8)
                        .animation(MotionConstants.smooth, value: fraction)
                }
                .frame(height: LayoutConstants.mineCapBarHeight)
            }
            .frame(height: LayoutConstants.mineCapBarHeight)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(isFull ? 0.5 : 0.2), lineWidth: 1)
        )
    }
}

// MARK: - Mini-game view

/// 60-second falling-drops mini-game triggered after a Collect All.
/// Server-authoritative: the final reward is capped in /slot-minigame/submit.
///
/// Lifecycle:
///   onAppear  → start spawn timer, preload SFX
///   tick      → move drops, remove expired, spawn new, check wave transitions
///   tap drop  → catch effect + burst + coin fly + SFX + combo
///   onEnd/skip→ call bonus endpoint, dismiss
struct GoldMineMiniGameView: View {
    let session: MinigameSessionInfo
    let character: Character?
    /// Called with the raw /slot-minigame/submit response dict so the VM can
    /// patch gold/gems/slots without a strict Codable hop. Shaft state is
    /// owned by /collect-all and /collect — this payload never touches it.
    let onFinish: (GoldMineSlotMinigameSubmitResponse) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: Game state
    @State private var drops: [FallingDrop] = []
    @State private var caughtGold: Int = 0
    @State private var caughtGems: Int = 0
    @State private var spawnedCount: Int = 0
    @State private var caughtCount: Int = 0
    @State private var remainingSec: Double = 60
    @State private var startedAt: Date = Date()
    @State private var lastTick: Date = Date()
    @State private var lastSpawn: Date = Date()
    @State private var gameEnded: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showSkipConfirm: Bool = false
    @State private var showResults: Bool = false
    @State private var serverResponse: GoldMineSlotMinigameSubmitResponse?

    // MARK: Wave state
    @State private var currentWave: MinigameWave = .warmup
    @State private var showWaveBanner: Bool = false
    @State private var waveBannerText: String = ""

    // MARK: Combo & effects
    @State private var combo: Int = 0
    @State private var catchEffects: [CatchEffect] = []
    @State private var showNearMissFlash: Bool = false
    @State private var showRareCatchFlash: Bool = false
    @State private var goldCounterPosition: CGPoint = CGPoint(x: 200, y: 60)

    // MARK: Results entrance
    @State private var resultsPhase: Int = 0

    // MARK: Fading drops at game end
    @State private var endFadeOpacity: Double = 1.0

    private let totalSec: Double = 60
    private let maxSpawns: Int = 160

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            playField
                .opacity(endFadeOpacity)
                .ignoresSafeArea()

            // Catch effects (burst + float + coin-fly)
            MinigameCatchEffectOverlay(
                effects: catchEffects,
                goldCounterPosition: goldCounterPosition
            )
            .ignoresSafeArea()

            // Near-miss red flash at bottom
            NearMissFlashView(showFlash: $showNearMissFlash)

            // Rare catch golden vignette
            RareCatchFlashView(showFlash: $showRareCatchFlash)

            if !showResults {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // Standard back arrow (HubLogoButton) — matches all other
                    // screens. Triggers the skip confirmation dialog so the
                    // player can't accidentally burn the bonus round.
                    HStack {
                        HubLogoButton(action: { showSkipConfirm = true })
                            .disabled(isSubmitting)
                        Spacer()
                    }
                    topHud
                    // Wave banner
                    WaveBannerView(text: waveBannerText, isVisible: $showWaveBanner)
                    // Combo banner
                    ComboBannerView(combo: combo)
                        .animation(MotionConstants.snappy, value: combo)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceMD)
                .transition(.opacity)
            }

            if showResults {
                resultsOverlay
                    .transition(.opacity)
            }

            // "Counting loot..." interstitial while submitting
            if gameEnded && !showResults {
                submittingOverlay
                    .transition(.opacity)
            }
        }
        .animation(MotionConstants.smooth, value: showResults)
        .animation(MotionConstants.smooth, value: gameEnded)
        .onAppear {
            startedAt = Date()
            lastTick = startedAt
            lastSpawn = startedAt
            // Preload minigame SFX for instant playback
            SFXManager.shared.preload([.coinsJingle, .magicShimmer, .uiRewardClaim])
        }
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { now in
            guard !gameEnded else { return }
            tick(now: now)
        }
        .confirmationDialog(
            "Skip the bonus round?",
            isPresented: $showSkipConfirm,
            titleVisibility: .visible
        ) {
            Button("Skip", role: .destructive) {
                Task { await submit(skipped: true) }
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("Your passive gold is already credited. You'll lose only the bonus.")
        }
    }

    // MARK: - Subviews

    private var background: some View {
        GeometryReader { geo in
            ZStack {
                Image(session.shaftKey.backgroundAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                // 3× darker than the previous 0.55 → 0.85 gradient:
                // image visibility reduced from ~45%/15% → ~15%/5%, so the
                // playfield reads as a mood-lit cavern rather than a lit scene.
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgPrimary.opacity(0.85),
                        DarkFantasyTheme.bgPrimary.opacity(0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var topHud: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack {
                // Time remaining
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("TIME")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(1.2)
                    Text("\(Int(max(0, remainingSec).rounded(.up)))s")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(timerColor)
                        .contentTransition(.numericText())
                        .animation(MotionConstants.smooth, value: Int(remainingSec))
                        // Timer urgency: pulse opacity in last 10s
                        .opacity(remainingSec < 10 ? (Int(remainingSec) % 2 == 0 ? 0.7 : 1.0) : 1.0)
                        .animation(MotionConstants.snappy, value: Int(remainingSec))
                }
                Spacer()
                // Caught counter — anchor for coin-fly target
                VStack(alignment: .trailing, spacing: LayoutConstants.space2XS) {
                    Text("CAUGHT")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(1.2)
                    Text("\(caughtCount)/\(spawnedCount)")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(MotionConstants.smooth, value: caughtCount)
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: GoldCounterAnchorKey.self,
                            value: proxy.frame(in: .global).center
                        )
                    }
                )
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        remainingSec < 10
                            ? DarkFantasyTheme.danger.opacity(0.5)
                            : DarkFantasyTheme.gold.opacity(0.25),
                        lineWidth: 1
                    )
            )

            CapMeterView(filled: min(caughtGold, session.capGold), total: session.capGold)
        }
        .onPreferenceChange(GoldCounterAnchorKey.self) { point in
            if let point { goldCounterPosition = point }
        }
    }

    private var timerColor: Color {
        if remainingSec < 5 { return DarkFantasyTheme.danger }
        if remainingSec < 10 { return DarkFantasyTheme.goldBright }
        return DarkFantasyTheme.textPrimary
    }

    private var playField: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(drops) { drop in
                    if !drop.caught {
                        dropView(drop, in: proxy.size)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dropView(_ drop: FallingDrop, in size: CGSize) -> some View {
        let now = Date()
        let progress = drop.progress(at: now)
        let y = -40 + progress * (size.height + 80)
        let x = drop.xFraction * size.width
        Group {
            switch drop.kind {
            case .gold(let value):
                goldDropView(value: value)
            case .gem:
                gemDropView
            }
        }
        .frame(width: 72, height: 72)
        .contentShape(Rectangle())
        .onTapGesture {
            catchDrop(drop.id, at: CGPoint(x: x, y: y))
        }
        // Grace zone: allow tapping slightly past the bottom (progress 1.05)
        .allowsHitTesting(progress < 1.05)
        .position(x: x, y: y)
    }

    private func goldDropView(value: Int) -> some View {
        let (assetName, size) = goldDropAsset(for: value)
        return Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(
                color: value >= 5
                    ? DarkFantasyTheme.goldBright.opacity(0.7)
                    : DarkFantasyTheme.gold.opacity(0.5),
                radius: value >= 5 ? 14 : 8,
                y: 4
            )
    }

    /// Maps gold drop value → asset name + display size. Tiered from single
    /// coin to progressively larger gold bags for higher-value drops.
    private func goldDropAsset(for value: Int) -> (String, CGFloat) {
        switch value {
        case ...2:  return ("relic_old_coin",    LayoutConstants.mineDropCoinSize)
        case 3:     return ("shop-gold-tier1",   LayoutConstants.mineDropBagSmSize)
        case 4...5: return ("shop-gold-tier2",   LayoutConstants.mineDropBagMdSize)
        default:    return ("shop-gold-tier3",   LayoutConstants.mineDropBagLgSize)
        }
    }

    private var gemDropView: some View {
        Image("icon-gems")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: LayoutConstants.mineDropGemSize, height: LayoutConstants.mineDropGemSize)
            .shadow(color: DarkFantasyTheme.cyan.opacity(0.55), radius: 12, y: 4)
    }

    // MARK: - Submitting interstitial

    private var submittingOverlay: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ProgressView()
                .tint(DarkFantasyTheme.gold)
            Text("COUNTING LOOT...")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DarkFantasyTheme.bgPrimary.opacity(0.8).ignoresSafeArea())
    }

    // MARK: - Results overlay

    private var accuracy: Int {
        guard spawnedCount > 0 else { return 0 }
        return Int((Double(caughtCount) / Double(spawnedCount) * 100).rounded())
    }

    private var resultsOverlay: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Phase 1: Kicker
            if resultsPhase >= 1 {
                Text("SESSION COMPLETE")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(3)
                    .transition(.opacity)
            }

            // Phase 2: Title
            if resultsPhase >= 2 {
                Text("LOOT!")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 20)
                    .transition(.opacity)
            }

            // Phase 3: Accuracy
            if resultsPhase >= 3 {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text("Accuracy:")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("\(accuracy)%")
                        .font(DarkFantasyTheme.uiLabel.bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("•")
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("\(caughtCount)/\(spawnedCount)")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .transition(.opacity)
            }

            // Phase 4: Result rows
            if resultsPhase >= 4 {
                VStack(spacing: 0) {
                    resultRow(
                        icon: "shop-gold-tier1",
                        label: "Passive income",
                        value: "+\(session.passiveGoldAmount)",
                        color: DarkFantasyTheme.textSecondary
                    )
                    Divider().background(DarkFantasyTheme.borderSubtle)

                    resultRow(
                        icon: "shop-gold-tier2",
                        label: "Bonus gold",
                        value: "+\(caughtGold)\(caughtGold >= session.capGold ? " (cap)" : "")",
                        color: DarkFantasyTheme.goldBright
                    )
                    Divider().background(DarkFantasyTheme.borderSubtle)

                    resultRow(
                        icon: "icon-gems",
                        label: "Bonus gems",
                        value: "+\(caughtGems)",
                        color: DarkFantasyTheme.cyan
                    )
                    Divider().background(DarkFantasyTheme.gold.opacity(0.4))

                    resultRow(
                        icon: nil,
                        label: "TOTAL GOLD",
                        value: "+\(session.passiveGoldAmount + caughtGold)",
                        color: DarkFantasyTheme.goldBright,
                        isTotal: true
                    )
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .transition(.opacity)
            }

            // Phase 5: Combo bonus display
            if resultsPhase >= 5 && combo >= 3 {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("Best combo:")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                    Text("x\(combo)")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
                .transition(.opacity)
            }

            // Phase 6: Collect button
            if resultsPhase >= 6 {
                Button {
                    if let response = serverResponse {
                        onFinish(response)
                    }
                    dismiss()
                } label: {
                    Text("COLLECT")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceLG)
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            DarkFantasyTheme.bgPrimary.opacity(0.92)
                .ignoresSafeArea()
        )
        .onAppear {
            startResultsEntrance()
        }
    }

    @ViewBuilder
    private func resultRow(
        icon: String?,
        label: String,
        value: String,
        color: Color,
        isTotal: Bool = false
    ) -> some View {
        HStack {
            HStack(spacing: LayoutConstants.spaceSM) {
                if let icon {
                    Image(icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: LayoutConstants.mineResultIconSize, height: LayoutConstants.mineResultIconSize)
                }
                Text(label)
                    .font(isTotal ? DarkFantasyTheme.uiLabel.bold() : DarkFantasyTheme.uiLabel)
                    .foregroundStyle(isTotal ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textSecondary)
                    .textCase(isTotal ? .uppercase : .none)
                    .tracking(isTotal ? 1 : 0)
            }
            Spacer()
            Text(value)
                .font(isTotal ? DarkFantasyTheme.title : DarkFantasyTheme.cardTitle)
                .foregroundStyle(color)
        }
        .padding(.vertical, LayoutConstants.spaceSM)
    }

    // MARK: - Results entrance animation

    private func startResultsEntrance() {
        SFXManager.shared.play(.uiRewardClaim)
        HapticManager.success()

        let delays: [Double] = [0.2, 0.5, 0.8, 1.1, 1.4, 1.8]
        for (phase, delay) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(MotionConstants.smooth) {
                    resultsPhase = phase + 1
                }
            }
        }
    }

    // MARK: - Game loop

    private func tick(now: Date) {
        let elapsedTotal = now.timeIntervalSince(startedAt)
        remainingSec = max(0, totalSec - elapsedTotal)

        // Check wave transitions
        let newWave = MinigameWave.current(elapsed: elapsedTotal)
        if newWave != currentWave {
            currentWave = newWave
            if let banner = newWave.bannerText {
                waveBannerText = banner
                withAnimation(MotionConstants.smooth) {
                    showWaveBanner = true
                }
                // SFX for wave transition
                SFXManager.shared.play(.magicShimmer)
                HapticManager.medium()
            }
        }

        // Remove expired drops that were not caught → trigger near-miss.
        let expiredUncaught = drops.filter { !$0.caught && $0.progress(at: now) >= 1.0 }
        if !expiredUncaught.isEmpty {
            combo = 0 // Reset combo on miss
            showNearMissFlash = true
        }
        drops.removeAll { !$0.caught && $0.progress(at: now) >= 1.0 }

        // Spawn new drop on cadence, bounded by maxSpawns.
        if remainingSec > 0 && spawnedCount < maxSpawns {
            if now.timeIntervalSince(lastSpawn) >= currentWave.spawnInterval {
                let x = CGFloat.random(in: 0.1...0.9)
                drops.append(FallingDrop.random(
                    xFraction: x,
                    spawnedAt: now,
                    wave: currentWave
                ))
                spawnedCount += 1
                lastSpawn = now
            }
        }

        // Clean up expired catch effects
        catchEffects.removeAll { now.timeIntervalSince($0.spawnedAt) > $0.lifetime }

        // End of session.
        if remainingSec <= 0 && !gameEnded {
            endGame()
        }

        lastTick = now
    }

    // MARK: - Catch logic

    private func catchDrop(_ id: UUID, at position: CGPoint) {
        guard let idx = drops.firstIndex(where: { $0.id == id && !$0.caught }) else { return }
        let drop = drops[idx]
        drops[idx].caught = true
        caughtCount += 1
        combo += 1

        switch drop.kind {
        case .gold(let v):
            caughtGold = min(caughtGold + v, session.passiveGoldAmount)
        case .gem:
            caughtGems = min(caughtGems + 1, session.gemCap)
        }

        // Spawn catch effect
        catchEffects.append(CatchEffect(
            position: position,
            kind: drop.kind,
            isRare: drop.isRare,
            spawnedAt: Date()
        ))

        // SFX + haptics (tiered by rarity)
        if drop.isRare {
            SFXManager.shared.play(.magicShimmer)
            HapticManager.medium()
            showRareCatchFlash = true
        } else {
            SFXManager.shared.play(.coinsJingle)
            HapticManager.light()
        }

        // Combo SFX at milestones
        if combo == 5 || combo == 10 || combo == 15 || combo == 20 {
            HapticManager.coinCascade(count: min(combo, 8))
        }
    }

    // MARK: - End game

    private func endGame() {
        gameEnded = true
        // Fade out remaining drops
        withAnimation(.easeOut(duration: 0.3)) {
            endFadeOpacity = 0
        }
        // Submit to server
        Task { await submit(skipped: false) }
    }

    // MARK: - Submit

    private func submit(skipped: Bool) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        gameEnded = true

        do {
            let data: GoldMineSlotMinigameSubmitResponse = try await APIClient.shared.post(
                APIEndpoints.goldMineSlotMinigameSubmit,
                body: GoldMineSlotMinigameSubmitRequest(
                    characterId: character?.id ?? "",
                    slotIndex: session.slotIndex,
                    sessionId: session.id,
                    caughtCount: caughtCount,
                    spawnedCount: spawnedCount,
                    goldClaimedInSession: caughtGold,
                    gemsClaimedInSession: caughtGems,
                    skipped: skipped
                )
            )
            HapticManager.success()
            serverResponse = data
            showResults = true
        } catch {
            // On error, still show results with local data so the player
            // sees what they caught. Collect button will dismiss without
            // calling onFinish (serverResponse is nil).
            showResults = true
        }
    }
}

// MARK: - Gold Counter Anchor Preference Key

private struct GoldCounterAnchorKey: PreferenceKey {
    static let defaultValue: CGPoint? = nil
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        if let next = nextValue() { value = next }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
