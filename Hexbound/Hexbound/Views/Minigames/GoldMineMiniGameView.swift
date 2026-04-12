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

    /// Weighted random drop factory. 3% gem, otherwise weighted gold.
    static func random(xFraction: CGFloat, spawnedAt: Date) -> FallingDrop {
        let gemRoll = Int.random(in: 0..<100)
        if gemRoll < MinigameDropValue.gemDropWeight {
            return FallingDrop(
                kind: .gem,
                xFraction: xFraction,
                spawnedAt: spawnedAt,
                fallDurationSec: Double.random(in: 1.6...2.2)
            )
        }
        // Weighted pick across gold values.
        let total = MinigameDropValue.goldDrops.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for entry in MinigameDropValue.goldDrops {
            if roll < entry.weight {
                return FallingDrop(
                    kind: .gold(entry.value),
                    xFraction: xFraction,
                    spawnedAt: spawnedAt,
                    fallDurationSec: Double.random(in: 1.4...2.0)
                )
            }
            roll -= entry.weight
        }
        // Fallback — should never hit.
        return FallingDrop(
            kind: .gold(1),
            xFraction: xFraction,
            spawnedAt: spawnedAt,
            fallDurationSec: 1.8
        )
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

// MARK: - Mini hero card

/// Minimal hero strip used at the bottom of the mini-game. Just avatar +
/// class/level. Keeps the player grounded without dominating the play area.
struct MinigameHeroCard: View {
    let characterName: String
    let className: String
    let characterClass: CharacterClass
    let level: Int
    let avatarKey: String?

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar
            Group {
                if let avatarKey, !avatarKey.isEmpty {
                    AvatarImageView(
                        skinKey: avatarKey,
                        characterClass: characterClass,
                        size: 48
                    )
                } else {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(characterName)
                    .font(DarkFantasyTheme.uiLabel.bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                Text("\(className.uppercased()) • LV \(level)")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(1.0)
            }
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Mini-game view

/// 15-second falling-drops mini-game triggered after a Collect All.
/// Server-authoritative: the final reward is capped in /minigame-bonus.
///
/// Lifecycle:
///   onAppear  → start spawn timer
///   tick      → move drops, remove expired, spawn new
///   tap drop  → mark caught, add to totals
///   onEnd/skip→ call bonus endpoint, dismiss
struct GoldMineMiniGameView: View {
    let session: MinigameSessionInfo
    let character: Character?
    /// Called with the raw /slot-minigame/submit response dict so the VM can
    /// patch gold/gems/slots without a strict Codable hop. Shaft state is
    /// owned by /collect-all and /collect — this payload never touches it.
    let onFinish: ([String: Any]) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var drops: [FallingDrop] = []
    @State private var caughtGold: Int = 0
    @State private var caughtGems: Int = 0
    @State private var spawnedCount: Int = 0
    @State private var caughtCount: Int = 0
    @State private var remainingSec: Double = 15
    @State private var startedAt: Date = Date()
    @State private var lastTick: Date = Date()
    @State private var isSubmitting: Bool = false
    @State private var showSkipConfirm: Bool = false
    @State private var showResults: Bool = false
    @State private var serverResponse: [String: Any]?

    private let totalSec: Double = 15
    private let spawnIntervalSec: Double = 0.3
    @State private var lastSpawn: Date = Date()

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()
            playField
                .ignoresSafeArea()
            if !showResults {
                VStack(spacing: LayoutConstants.spaceMD) {
                    topHud
                    Spacer(minLength: 0)
                    bottomBar
                }
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceMD)
                .transition(.opacity)
            }

            if showResults {
                resultsOverlay
                    .transition(.opacity)
            }
        }
        .animation(MotionConstants.smooth, value: showResults)
        .onAppear {
            startedAt = Date()
            lastTick = startedAt
            lastSpawn = startedAt
        }
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { now in
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
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.bgPrimary.opacity(0.55),
                        DarkFantasyTheme.bgPrimary.opacity(0.85),
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
                        .foregroundStyle(remainingSec < 3 ? DarkFantasyTheme.danger : DarkFantasyTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(MotionConstants.smooth, value: Int(remainingSec))
                }
                Spacer()
                // Caught counter
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
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.25), lineWidth: 1)
            )

            CapMeterView(filled: min(caughtGold, session.capGold), total: session.capGold)
        }
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
        .position(x: x, y: y)
        .contentShape(Rectangle().size(width: 56, height: 56))
        .onTapGesture {
            catchDrop(drop.id)
        }
        .allowsHitTesting(progress < 1.0)
    }

    private func goldDropView(value: Int) -> some View {
        let (assetName, size) = goldDropAsset(for: value)
        return Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 8, y: 4)
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

    private var bottomBar: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let character {
                MinigameHeroCard(
                    characterName: character.characterName,
                    className: character.characterClass.displayName,
                    characterClass: character.characterClass,
                    level: character.level,
                    avatarKey: character.avatar
                )
            }
            HStack(spacing: LayoutConstants.spaceSM) {
                Button {
                    showSkipConfirm = true
                } label: {
                    Text("SKIP")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.borderMedium, fillOpacity: 0.15))
                .disabled(isSubmitting)
            }
        }
    }

    // MARK: - Results overlay

    private var accuracy: Int {
        guard spawnedCount > 0 else { return 0 }
        return Int((Double(caughtCount) / Double(spawnedCount) * 100).rounded())
    }

    private var resultsOverlay: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            // Kicker
            Text("SESSION COMPLETE")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.gold)
                .tracking(3)

            // Title
            Text("LOOT!")
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(DarkFantasyTheme.goldBright)

            // Accuracy
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

            // Result rows
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

            // Collect button
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

            Spacer()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            DarkFantasyTheme.bgPrimary.opacity(0.92)
                .ignoresSafeArea()
        )
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

    // MARK: - Game loop

    private func tick(now: Date) {
        let delta = now.timeIntervalSince(lastTick)
        lastTick = now
        let elapsedTotal = now.timeIntervalSince(startedAt)
        remainingSec = max(0, totalSec - elapsedTotal)

        // Remove expired drops that were not caught.
        drops.removeAll { !$0.caught && $0.progress(at: now) >= 1.0 }

        // Spawn new drop on cadence, bounded by spawnPerSession.
        if remainingSec > 0 && spawnedCount < MinigameDropValue.spawnPerSession {
            if now.timeIntervalSince(lastSpawn) >= spawnIntervalSec {
                let x = CGFloat.random(in: 0.1...0.9)
                drops.append(FallingDrop.random(xFraction: x, spawnedAt: now))
                spawnedCount += 1
                lastSpawn = now
            }
        }

        // End of session.
        if remainingSec <= 0 && !isSubmitting {
            Task { await submit(skipped: false) }
        }

        _ = delta
    }

    private func catchDrop(_ id: UUID) {
        guard let idx = drops.firstIndex(where: { $0.id == id && !$0.caught }) else { return }
        drops[idx].caught = true
        caughtCount += 1
        switch drops[idx].kind {
        case .gold(let v):
            caughtGold = min(caughtGold + v, session.passiveGoldAmount)
        case .gem:
            caughtGems = min(caughtGems + 1, session.gemCap)
        }
        HapticManager.light()
    }

    // MARK: - Submit

    private func submit(skipped: Bool) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        do {
            // Variant D Phase 2: submit against the per-slot endpoint. This
            // is the only flow that unlocks a slot's collection. `slot_index`
            // must be present — the session is created with one by
            // /slot-minigame/start. Legacy aggregate /minigame-bonus is kept
            // server-side for rollback only and is no longer reachable here.
            var body: [String: Any] = [
                "character_id": character?.id ?? "",
                "session_id": session.id,
                "caught_count": caughtCount,
                "spawned_count": spawnedCount,
                "gold_claimed_in_session": caughtGold,
                "gems_claimed_in_session": caughtGems,
                "skipped": skipped,
            ]
            if let slotIndex = session.slotIndex {
                body["slot_index"] = slotIndex
            }
            let data = try await APIClient.shared.postRaw(
                APIEndpoints.goldMineSlotMinigameSubmit,
                body: body
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
