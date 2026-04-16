import SwiftUI

// MARK: - Top Currency Bar

struct TopCurrencyBar: View {
    let character: Character?
    var onTapCurrency: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            // Gold (animated tick-up)
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gold")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    NumberTickUpText(
                        value: character?.gold ?? 0,
                        color: DarkFantasyTheme.goldBright,
                        font: DarkFantasyTheme.section
                    )
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))
            .accessibilityLabel("Gold: \(character?.gold ?? 0)")

            Spacer()

            // Gems (animated tick-up)
            Button {
                onTapCurrency?()
            } label: {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gems")
                        .resizable()
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    NumberTickUpText(
                        value: character?.gems ?? 0,
                        color: DarkFantasyTheme.cyan,
                        font: DarkFantasyTheme.section
                    )
                }
                .frame(minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.95))
            .accessibilityLabel("Gems: \(character?.gems ?? 0)")

        }
    }
}

// MARK: - Daily Quests Card

struct DailyQuestsCard: View {
    @Environment(AppState.self) private var appState

    private var completed: Int {
        appState.cachedTypedQuests?.filter(\.completed).count ?? 0
    }
    private var total: Int {
        appState.cachedTypedQuests?.count ?? 0
    }

    private func timeUntilReset() -> String {
        let now = Date()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        guard let tomorrow = utc.date(byAdding: .day, value: 1, to: now),
              let midnight = utc.date(from: utc.dateComponents([.year, .month, .day], from: tomorrow))
        else { return "" }
        let remaining = Int(midnight.timeIntervalSince(now))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        return "\(h)h \(m)m"
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image("hud-daily-quests")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY QUESTS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.gold)
                if appState.cachedBonusClaimedToday {
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        Text("✓ Bonus claimed • \(timeUntilReset())")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.success)
                    }
                } else {
                    Text(total > 0 ? "\(completed)/\(total) completed" : "Loading...")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    if total > 0 {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success : DarkFantasyTheme.gold)
                            .frame(width: geo.size.width * max(0, min(1, Double(completed) / Double(total))))
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                    }
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(appState.cachedBonusClaimedToday ? DarkFantasyTheme.success.opacity(0.4) : DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
        .cornerBrackets(color: appState.cachedBonusClaimedToday ? DarkFantasyTheme.success.opacity(0.5) : DarkFantasyTheme.gold.opacity(0.5), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Battle Pass Card

struct BattlePassCard: View {
    @Environment(GameDataCache.self) private var cache

    private var battlePass: BattlePassData? {
        cache.cachedBattlePass()
    }

    private var level: Int {
        battlePass?.currentLevel ?? 0
    }

    private var maxLevel: Int {
        let freeMax = battlePass?.freeRewards.map(\.level).max() ?? 0
        let premiumMax = battlePass?.premiumRewards.map(\.level).max() ?? 0
        return max(max(freeMax, premiumMax), 1)
    }

    private var subtitle: String {
        guard let battlePass else { return "Loading battle pass..." }
        return "\(battlePass.seasonName) • Level \(level)/\(maxLevel)"
    }

    private var progress: Double {
        guard maxLevel > 0 else { return 0 }
        return min(max(Double(level) / Double(maxLevel), 0), 1)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image(systemName: "medal.fill")
                .font(DarkFantasyTheme.iconLarge)
                .foregroundStyle(DarkFantasyTheme.gold)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("BATTLE PASS")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.bgTertiary)
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: geo.size.width * progress)
                        .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusXS))
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.5), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Daily Login Card

struct DailyLoginCard: View {
    let canClaim: Bool

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image("hud-daily-login")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold)
                Text(canClaim ? "Tap to claim today's reward!" : "Reward claimed today ✓")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(canClaim ? DarkFantasyTheme.goldBright : DarkFantasyTheme.success)
            }

            Spacer()

            if canClaim {
                Circle()
                    .fill(DarkFantasyTheme.goldBright)
                    .frame(width: 10, height: 10)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.6), radius: 4)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(cornerRadius: LayoutConstants.panelRadius - 2, inset: 2, color: canClaim ? DarkFantasyTheme.goldDim.opacity(0.12) : DarkFantasyTheme.borderMedium.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(
                    canClaim ? DarkFantasyTheme.goldBright.opacity(0.7) : DarkFantasyTheme.success.opacity(0.4),
                    lineWidth: canClaim ? 1.5 : 1
                )
        )
        .cornerBrackets(color: canClaim ? DarkFantasyTheme.goldBright.opacity(0.6) : DarkFantasyTheme.success.opacity(0.4), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 1)
    }
}

// MARK: - Nav Tile

struct NavTile: View {
    let icon: String
    let label: String
    var asset: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LayoutConstants.spaceXS) {
                if let asset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else {
                    AssetPlaceholderView(systemIcon: "scroll.fill")
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                }
                Text(label)
            }
        }
        .buttonStyle(.navGrid)
        .accessibilityLabel(label)
    }
}
