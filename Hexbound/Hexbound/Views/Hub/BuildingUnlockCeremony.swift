import SwiftUI

// MARK: - Unlock Ceremony Payload
//
// Generic description of an "a new thing just unlocked" moment. Used by both
// building and boss unlock ceremonies so they share animation, timing, and
// visual language. Adding a new kind of unlock (mini-game, class, mount…)
// = just build a new payload, the view never changes.
struct UnlockCeremonyPayload: Equatable {
    /// xcassets name of the hero artwork (e.g. `building-shop` or the boss
    /// `fullImage`). `nil` or missing asset → fall back to the SF Symbol.
    let assetName: String?
    /// SF Symbol fallback if the asset is missing.
    let fallbackIcon: String
    /// Big gold headline (uppercase).
    let headline: String
    /// Smaller NPC voice line under the headline.
    let barkline: String
    /// Accent color for the glow ring, accents and lock tint.
    let accent: Color
    /// Accessibility label prefix ("Building", "Boss", …).
    let accessibilityKind: String
}

// MARK: - Unlock Ceremony
//
// W2.D4 → W3 — Ceremonial overlay that plays when a new piece of content
// unlocks. Shows the hero artwork INITIALLY in its locked state (grayscale,
// dimmed, with a gold padlock overlay — exactly how the locked building
// looks in the hub), then runs a reveal animation: padlock fades out and
// drifts up, saturation/brightness/opacity ramp to full, and a gold glow
// ring pulses behind the artwork. Mirrors what the player sees in the hub
// so the "it was locked, now it's yours" moment reads instantly.
//
// Animation: opacity + filter-based reveal, NO scale transforms (per user
// preference — see MEMORY `feedback_no_scale_animations`).
// Total duration: ~4.2s (fade-in → locked hold → reveal → hold → fade-out).
struct UnlockCeremony: View {
    let payload: UnlockCeremonyPayload
    let onDismiss: () -> Void

    // Entry / exit
    @State private var backdropOpacity: Double = 0
    @State private var iconOpacity: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var headlineOpacity: Double = 0
    @State private var barkOpacity: Double = 0
    @State private var didDismiss = false

    // Reveal state
    @State private var isRevealed = false
    @State private var lockOpacity: Double = 1.0
    @State private var lockYOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Dim backdrop — taps dismiss early
            Color.black
                .opacity(0.75 * backdropOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissEarly() }

            // Radial accent glow behind the icon — ramps with reveal
            RadialGradient(
                colors: [payload.accent.opacity(0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .opacity(ringOpacity * (isRevealed ? 1.0 : 0.25))
            .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Icon badge with locked → revealed artwork swap
                badge
                    .opacity(iconOpacity)

                // Headline
                Text(payload.headline)
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 10)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .opacity(headlineOpacity)

                // Snarky NPC line
                Text(payload.barkline)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .opacity(barkOpacity)

                Spacer()

                Text("Tap to continue")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary.opacity(0.7))
                    .padding(.bottom, LayoutConstants.spaceLG)
                    .opacity(barkOpacity)
            }
        }
        .onAppear(perform: playCeremony)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(payload.accessibilityKind) unlocked: \(payload.headline). \(payload.barkline). Tap to continue.")
    }

    // MARK: - Badge (glow ring + artwork + lock overlay)

    private var badge: some View {
        ZStack {
            // Outer gold glow ring — matches ring used on building success cards
            Circle()
                .stroke(payload.accent.opacity(isRevealed ? 0.9 : 0.3), lineWidth: 2)
                .frame(width: 176, height: 176)
                .opacity(ringOpacity)
                .shadow(color: payload.accent.opacity(isRevealed ? 0.6 : 0), radius: 18)

            // Dark disc background — same vignette we use in the hub when a
            // building is still locked so the locked state of the ceremony
            // matches the hub exactly.
            Circle()
                .fill(Color.black.opacity(0.55))
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .stroke(payload.accent.opacity(isRevealed ? 0.9 : 0.4), lineWidth: 1)
                )

            // Artwork — starts desaturated + dim (locked look), ramps to full
            // colour when `isRevealed` flips.
            artwork
                .frame(width: 132, height: 132)
                // Formula mirrors `CityBuildingView`'s locked sprite so the
                // "before" state of the ceremony looks identical to the hub.
                .saturation(isRevealed ? 1.0 : 0.0)
                .brightness(isRevealed ? 0.0 : -0.25)
                .opacity(isRevealed ? 1.0 : 0.45)
                .shadow(color: payload.accent.opacity(isRevealed ? 0.6 : 0), radius: 14)

            // Lock overlay — sits ABOVE the artwork and fades away at reveal.
            // Mirrors `BuildingLockOverlay` padlock style so the ceremony's
            // locked state is visually identical to what the player sees in
            // the hub.
            lockBadge
                .opacity(lockOpacity)
                .offset(y: lockYOffset)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let name = payload.assetName, UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: payload.fallbackIcon)
                .font(DarkFantasyTheme.cinematicTitle)
                .foregroundStyle(payload.accent)
        }
    }

    /// Gold padlock disc — copy of the one used in `BuildingLockOverlay` so
    /// the ceremony's locked state matches the hub padlock 1:1.
    private var lockBadge: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.gold)
                .frame(width: 56, height: 56)
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 4)
                .overlay(
                    Circle()
                        .stroke(DarkFantasyTheme.bgAbyss.opacity(0.5), lineWidth: 1.5)
                )

            Image(systemName: "lock.fill")
                .font(DarkFantasyTheme.section.weight(.bold))
                .foregroundStyle(DarkFantasyTheme.textOnGold)
        }
    }

    // MARK: - Animation

    private func playCeremony() {
        HapticManager.rankUp()
        SFXManager.shared.play(.uiConfirm)

        // Phase 1 — backdrop
        withAnimation(.easeOut(duration: 0.4)) {
            backdropOpacity = 1
        }
        Task { @MainActor in
            // Phase 2 — locked badge appears (grayscale + padlock visible)
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.4)) {
                ringOpacity = 1
                iconOpacity = 1
            }

            // Phase 3 — headline reads the moment ("THE SHOP OPENS")
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.4)) {
                headlineOpacity = 1
            }

            // Phase 4 — REVEAL. Short wind-up so the eye has time to register
            // the locked state first, then lock pops up and out while the
            // artwork goes full colour.
            try? await Task.sleep(for: .milliseconds(450))
            HapticManager.heavy()
            SFXManager.shared.play(.dungeonUnlock)
            withAnimation(.easeOut(duration: 0.55)) {
                isRevealed = true
                lockOpacity = 0
                lockYOffset = -48
            }

            // Phase 5 — bark appears after reveal settles
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.35)) {
                barkOpacity = 1
            }

            // Phase 6 — hold, then auto-dismiss
            try? await Task.sleep(for: .milliseconds(2200))
            await MainActor.run { dismissEarly() }
        }
    }

    private func dismissEarly() {
        guard !didDismiss else { return }
        didDismiss = true
        HapticManager.light()
        withAnimation(.easeIn(duration: 0.35)) {
            backdropOpacity = 0
            iconOpacity = 0
            headlineOpacity = 0
            barkOpacity = 0
            ringOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            onDismiss()
        }
    }
}

// MARK: - Building Unlock Ceremony (typed wrapper)

/// W2.D4 — Ceremonial overlay that plays when a new building unlocks.
///
/// Thin wrapper around `UnlockCeremony` that resolves the right payload
/// from a `BuildingUnlockCatalog.Entry` + building id. Kept as a separate
/// type so call sites stay semantic.
struct BuildingUnlockCeremony: View {
    let entry: BuildingUnlockCatalog.Entry
    /// CityBuilding.id — used to resolve the `building-<id>` PNG asset.
    let buildingId: String?
    let onDismiss: () -> Void

    var body: some View {
        UnlockCeremony(
            payload: UnlockCeremonyPayload(
                assetName: buildingId.map { "building-\($0)" },
                fallbackIcon: entry.icon,
                headline: entry.headline,
                barkline: entry.barkline,
                accent: entry.accent,
                accessibilityKind: "Building"
            ),
            onDismiss: onDismiss
        )
    }
}

// MARK: - Ceremony Queue Host (buildings)

/// Host view that consumes `appState.pendingBuildingUnlocks` one at a time
/// and plays a BuildingUnlockCeremony for each. Attach as an overlay on
/// HubView so the ceremonies appear above the map.
struct BuildingUnlockCeremonyHost: View {
    @Environment(AppState.self) private var appState
    @State private var currentBuildingId: String?

    var body: some View {
        ZStack {
            if let id = currentBuildingId {
                let label = defaultCityBuildings.first { $0.id == id }?.label ?? id
                BuildingUnlockCeremony(
                    entry: BuildingUnlockCatalog.entry(for: id, fallbackLabel: label),
                    buildingId: id,
                    onDismiss: advance,
                )
                .transition(.opacity)
                .id(id) // force re-mount per building
            }
        }
        .onAppear(perform: primeIfNeeded)
        .onChange(of: appState.pendingBuildingUnlocks) { _, new in
            // If something else pushed new unlocks while idle, pick them up.
            if currentBuildingId == nil && !new.isEmpty {
                primeIfNeeded()
            }
        }
    }

    private func primeIfNeeded() {
        guard currentBuildingId == nil else { return }
        guard !appState.pendingBuildingUnlocks.isEmpty else { return }
        let next = appState.pendingBuildingUnlocks.removeFirst()
        withAnimation(.easeOut(duration: 0.35)) {
            currentBuildingId = next
        }
    }

    private func advance() {
        withAnimation(.easeIn(duration: 0.3)) {
            currentBuildingId = nil
        }
        // Short gap before the next ceremony feels less jarring
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            primeIfNeeded()
        }
    }
}

// MARK: - Boss Unlock Ceremony (typed wrapper)

/// Ceremony that plays after the player defeats boss N and boss N+1 becomes
/// available. Reuses `UnlockCeremony` with a payload built from `BossInfo`.
struct BossUnlockCeremony: View {
    let boss: BossInfo
    let onDismiss: () -> Void

    var body: some View {
        UnlockCeremony(
            payload: UnlockCeremonyPayload(
                assetName: bestAssetName(for: boss),
                fallbackIcon: "flame.fill",
                headline: "\(boss.name.uppercased()) AWAKENS",
                barkline: boss.description.isEmpty
                    ? "A new challenger stirs in the depths."
                    : boss.description,
                accent: DarkFantasyTheme.bossBorderPurple,
                accessibilityKind: "Boss"
            ),
            onDismiss: onDismiss
        )
    }

    /// Prefer the full body pose for the ceremony; fall back to the portrait
    /// if the full image asset is missing. Same lookup order as
    /// `DungeonBossCard.bossImageLayer`.
    private func bestAssetName(for boss: BossInfo) -> String? {
        if UIImage(named: boss.fullImage) != nil { return boss.fullImage }
        if UIImage(named: boss.portraitImage) != nil { return boss.portraitImage }
        return nil
    }
}
