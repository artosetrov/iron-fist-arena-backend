import SwiftUI

/// Compact banner showing an active daily quest relevant to the current screen.
/// Place at the top of ScrollView content on Arena, Dungeon, Shop, etc.
/// Automatically hides when quest is claimed or no matching quest exists.
/// Auto-reloads quests from server when cache is nil (after invalidation).
struct ActiveQuestBanner: View {
    @Environment(AppState.self) private var appState

    /// Quest types that should appear on this screen (e.g. ["pvp_wins"])
    let questTypes: [String]

    @State private var claimingId: String?
    @State private var hasLoaded = false
    /// Preserve last-known quests so the banner stays visible during background reloads
    @State private var lastKnownQuests: [Quest] = []

    /// Matching unclaimed quests from cache (nil = reload in progress → use lastKnownQuests)
    private var activeQuests: [Quest] {
        guard let quests = appState.cachedTypedQuests else { return lastKnownQuests }
        let matching = quests.filter { q in
            questTypes.contains(q.type) && !q.rewardClaimed
        }
        return matching
    }

    private var needsReload: Bool {
        appState.cachedTypedQuests == nil
    }

    var body: some View {
        // Bug #21: wrap in VStack so ForEach insert/remove transitions fire
        // cleanly and the banner has a stable layout container that fills
        // the full available width from its parent.
        VStack(spacing: LayoutConstants.spaceXS) {
            ForEach(activeQuests) { quest in
                questBanner(quest)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
            }
        }
        .animation(MotionConstants.smooth, value: activeQuests.map(\.id))
        .animation(MotionConstants.smooth, value: activeQuests.map(\.rewardClaimed))
        .onAppear {
            syncLastKnown()
            if needsReload {
                Task { await reloadQuests() }
            }
        }
        .onChange(of: appState.cachedTypedQuests) { _, newVal in
            if newVal == nil {
                // Cache invalidated — keep showing lastKnownQuests, reload in background
                Task { await reloadQuests() }
            } else {
                // Fresh data arrived — update snapshot
                syncLastKnown()
            }
        }
    }

    /// Snapshot current matching quests so they survive cache invalidation
    private func syncLastKnown() {
        guard let quests = appState.cachedTypedQuests else { return }
        lastKnownQuests = quests.filter { q in
            questTypes.contains(q.type) && !q.rewardClaimed
        }
    }

    // MARK: - Reload

    private func reloadQuests() async {
        let service = QuestService(appState: appState)
        // Silent refresh for the Hub banner — failure here just leaves the
        // previous cached banner on screen until the next successful load.
        _ = try? await service.loadQuests()
    }

    // MARK: - Banner

    @ViewBuilder
    private func questBanner(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Icon
            AssetPlaceholderView(systemIcon: "scroll.fill")
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)

            // Info
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(quest.title)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text(quest.description)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: LayoutConstants.spaceXS)

            // Progress / Claim
            if quest.canClaim {
                Button {
                    claimQuest(quest)
                } label: {
                    Text("Claim")
                }
                .buttonStyle(.compactPrimary)
            } else {
                // Progress pill
                Text("\(quest.progress)/\(quest.target)")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.cyan)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.cyan)
                            .frame(width: geo.size.width * quest.progressFraction)
                    }
                }
                .frame(width: 40, height: 5)
            }
        }
        // Bug #21: force full-width so the banner spans screen edges
        // consistently with other shop section elements. The outer
        // .padding(.horizontal, screenPadding) in ShopDetailView handles
        // the safe-area gap.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: DarkFantasyTheme.opacityStrong,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.cyan.opacity(DarkFantasyTheme.opacitySoft))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.cyan.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1.5)
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityMedium), radius: 4, y: 2)
    }

    // MARK: - Claim

    /// BUG-51 (QA 2026-04-10): previously did an optimistic commit + fired the
    /// "Quest Complete!" toast BEFORE awaiting the API — so on server failure
    /// the toast had already fired, and because the character refresh was a
    /// detached background Task the gold/XP HUD stayed stale. New flow mirrors
    /// DailyQuestsViewModel: API first, commit after, celebration uses real
    /// server reward values.
    private func claimQuest(_ quest: Quest) {
        guard claimingId == nil else { return }
        claimingId = quest.id
        let questId = quest.id
        Task {
            let service = QuestService(appState: self.appState)
            let result = await service.claimQuest(questId: questId)
            claimingId = nil

            guard let result = result else {
                self.appState.showToast("Failed to claim quest", subtitle: "Please try again", type: .error)
                return
            }

            // ── Commit on confirmed success ──
            if let idx = self.appState.cachedTypedQuests?.firstIndex(where: { $0.id == questId }) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.appState.cachedTypedQuests?[idx].rewardClaimed = true
                }
            }
            syncLastKnown()

            HapticManager.success()
            SFXManager.shared.play(.uiRewardClaim)

            // Build subtitle from SERVER reward values
            var parts: [String] = []
            if result.rewardGold > 0 { parts.append("+\(result.rewardGold)g") }
            if result.rewardXp > 0 { parts.append("+\(result.rewardXp) XP") }
            if result.rewardGems > 0 { parts.append("+\(result.rewardGems) gems") }
            let subtitle = parts.isEmpty ? quest.title : parts.joined(separator: "  ")
            self.appState.showToast("Quest Complete!", subtitle: subtitle, type: .quest)
        }
    }
}
