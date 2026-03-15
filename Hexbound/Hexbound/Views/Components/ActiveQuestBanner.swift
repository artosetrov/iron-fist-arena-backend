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

    /// Matching unclaimed quests from cache
    private var activeQuests: [Quest] {
        guard let quests = appState.cachedTypedQuests else { return [] }
        return quests.filter { q in
            questTypes.contains(q.type) && !q.rewardClaimed
        }
    }

    private var needsReload: Bool {
        appState.cachedTypedQuests == nil
    }

    var body: some View {
        ForEach(activeQuests) { quest in
            questBanner(quest)
        }
        .onAppear {
            if needsReload {
                Task { await reloadQuests() }
            }
        }
        .onChange(of: needsReload) { _, isNil in
            if isNil {
                Task { await reloadQuests() }
            }
        }
    }

    // MARK: - Reload

    private func reloadQuests() async {
        let service = QuestService(appState: appState)
        _ = await service.loadQuests()
    }

    // MARK: - Banner

    @ViewBuilder
    private func questBanner(_ quest: Quest) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Icon
            Text(quest.icon)
                .font(.system(size: 22))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text(quest.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Progress / Claim
            if quest.canClaim {
                Button {
                    Task { await claimQuest(quest) }
                } label: {
                    if claimingId == quest.id {
                        ProgressView()
                            .tint(DarkFantasyTheme.textOnGold)
                            .scaleEffect(0.7)
                    } else {
                        Text("Claim")
                    }
                }
                .frame(width: 56, height: 26)
                .buttonStyle(.compactPrimary)
                .disabled(claimingId == quest.id)
            } else {
                // Progress pill
                Text("\(quest.progress)/\(quest.target)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.cyan)
                    .monospacedDigit()

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DarkFantasyTheme.bgTertiary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DarkFantasyTheme.cyan)
                            .frame(width: geo.size.width * quest.progressFraction)
                    }
                }
                .frame(width: 40, height: 5)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS + 2)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.cyan.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.cyan.opacity(0.25), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Claim

    private func claimQuest(_ quest: Quest) async {
        claimingId = quest.id
        let service = QuestService(appState: appState)
        let success = await service.claimQuest(questId: quest.id)
        claimingId = nil
        if success {
            // Update cached quest in-place
            if let idx = appState.cachedTypedQuests?.firstIndex(where: { $0.id == quest.id }) {
                withAnimation(.easeOut(duration: 0.3)) {
                    appState.cachedTypedQuests?[idx].rewardClaimed = true
                }
            }
            appState.showToast("Quest Complete! \(quest.title)", type: .quest)
        }
    }
}
