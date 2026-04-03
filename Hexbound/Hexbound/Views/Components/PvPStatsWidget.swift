import SwiftUI

// MARK: - PvP Stats Data Protocol

/// Unified data source for PvP stats widget.
/// Both `Character` and `OpponentProfile` conform to this.
protocol PvPStatsProvider {
    var pvpRating: Int { get }
    var pvpWins: Int { get }
    var pvpLosses: Int { get }
    var pvpWinStreak: Int? { get }
    var pvpLossStreak: Int? { get }
}

extension PvPStatsProvider {
    var pvpTotalGames: Int { pvpWins + pvpLosses }

    var pvpWinRate: Int {
        guard pvpTotalGames > 0 else { return 0 }
        return Int(round(Double(pvpWins) / Double(pvpTotalGames) * 100))
    }

    /// Positive = win streak, negative = loss streak, 0 = none
    var pvpCurrentStreak: Int {
        let winS = pvpWinStreak ?? 0
        let lossS = pvpLossStreak ?? 0
        if winS > 0 { return winS }
        if lossS > 0 { return -lossS }
        return 0
    }

    var pvpRank: PvPRank {
        PvPRank.fromRating(pvpRating)
    }

    var pvpRankColor: Color {
        DarkFantasyTheme.rankColor(for: pvpRating)
    }

    var pvpWinRateColor: Color {
        let rate = pvpWinRate
        if rate >= 60 { return DarkFantasyTheme.success }
        if rate >= 45 { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.danger
    }
}

// MARK: - Layout Mode

enum PvPStatsLayout {
    /// Single-row compact bar for Arena lobby
    case compact
    /// Card with tier progress for Hero Profile / Character Profile
    case full
}

// MARK: - PvPStatsWidget

/// Unified PvP stats widget used across Arena, Hero Profile, and Character Profile.
/// Single source of truth for PvP stat display.
struct PvPStatsWidget: View {
    let data: any PvPStatsProvider
    let layout: PvPStatsLayout
    /// Leaderboard position (nil if unknown, e.g. for opponents)
    let leaderboardRank: Int?
    let totalPlayers: Int?

    init(
        _ layout: PvPStatsLayout,
        data: any PvPStatsProvider,
        leaderboardRank: Int? = nil,
        totalPlayers: Int? = nil
    ) {
        self.layout = layout
        self.data = data
        self.leaderboardRank = leaderboardRank
        self.totalPlayers = totalPlayers
    }

    var body: some View {
        switch layout {
        case .compact:
            compactLayout
        case .full:
            fullLayout
        }
    }

    // MARK: - Compact Layout (Arena)

    private var compactLayout: some View {
        HStack(spacing: 0) {
            // Rating — hero element
            HStack(spacing: LayoutConstants.spaceXS + 2) {
                Image(systemName: data.pvpRank.icon)
                    .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                    .foregroundStyle(data.pvpRankColor)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(data.pvpRating)")
                        .font(DarkFantasyTheme.section(size: 20))
                        .foregroundStyle(data.pvpRankColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("RATING")
                        .font(DarkFantasyTheme.body(size: 9))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)
                }
            }
            .frame(minWidth: 85, alignment: .leading)

            compactDivider

            // Record
            compactStat(
                label: "W / L",
                content: {
                    HStack(spacing: 2) {
                        Text("\(data.pvpWins)")
                            .foregroundStyle(DarkFantasyTheme.success)
                        Text("/")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                        Text("\(data.pvpLosses)")
                            .foregroundStyle(DarkFantasyTheme.danger)
                    }
                    .font(DarkFantasyTheme.section(size: 13))
                }
            )

            compactDivider

            // Win Rate
            compactStat(label: "RATE") {
                Text("\(data.pvpWinRate)%")
                    .font(DarkFantasyTheme.section(size: 13))
                    .foregroundStyle(data.pvpWinRateColor)
            }

            compactDivider

            // Streak
            compactStat(label: "STREAK") {
                streakBadge(compact: true)
            }

            // Rank (if available)
            if let rank = leaderboardRank {
                compactDivider

                compactStat(label: "RANK") {
                    Text("#\(rank)")
                        .font(DarkFantasyTheme.section(size: 13))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, LayoutConstants.spaceSM)
        .padding(.horizontal, LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .overlay(alignment: .top) {
            // Tier accent line at top
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, data.pvpRankColor.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        }
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: data.pvpRankColor.opacity(0.06))
        .cornerBrackets(color: data.pvpRankColor.opacity(0.2), length: 10, thickness: 1)
        .cardShadow()
    }

    // MARK: - Full Layout (Hero/Character Profile)

    private var fullLayout: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Header: PVP STATS + Tier badge + Rank
            HStack {
                Text("PVP")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)

                // Tier badge
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: data.pvpRank.icon)
                        .font(DarkFantasyTheme.badge.weight(.semibold))
                    Text(data.pvpRank.rawValue)
                        .font(DarkFantasyTheme.body(size: 11))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(data.pvpRankColor)
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(data.pvpRankColor.opacity(0.1))
                )

                Spacer()

                // Leaderboard rank
                if let rank = leaderboardRank {
                    HStack(spacing: 2) {
                        Text("#\(rank)")
                            .font(DarkFantasyTheme.body(size: 12))
                            .fontWeight(.semibold)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                        if let total = totalPlayers {
                            Text("/ \(total)")
                                .font(DarkFantasyTheme.body(size: 10))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                        }
                    }
                }
            }

            // Rating — hero number with tier progress
            VStack(spacing: LayoutConstants.spaceSM) {
                // Rating value
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                    Spacer()
                    Text("\(data.pvpRating)")
                        .font(DarkFantasyTheme.title(size: 40))
                        .foregroundStyle(data.pvpRankColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .shadow(color: data.pvpRankColor.opacity(0.3), radius: 12, y: 0)
                    Spacer()
                }

                // Tier progress bar
                tierProgressBar
            }
            .padding(.vertical, LayoutConstants.spaceXS)

            // Stats grid: Record | Win Rate | Streak
            HStack(spacing: 1) {
                fullStatCell(
                    label: "RECORD",
                    content: {
                        HStack(spacing: 3) {
                            Text("\(data.pvpWins)")
                                .foregroundStyle(DarkFantasyTheme.success)
                            Text("/")
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                            Text("\(data.pvpLosses)")
                                .foregroundStyle(DarkFantasyTheme.danger)
                        }
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    },
                    subtitle: "\(data.pvpTotalGames) games"
                )

                fullStatCell(
                    label: "WIN RATE",
                    content: {
                        Text("\(data.pvpWinRate)%")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(data.pvpWinRateColor)
                    },
                    winRateBar: true
                )

                fullStatCell(
                    label: "STREAK",
                    content: {
                        streakBadge(compact: false)
                    }
                )
            }
            .background(DarkFantasyTheme.bgAbyss.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        }
        .padding(LayoutConstants.cardPadding)
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
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: data.pvpRankColor.opacity(0.3), length: 12, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 2, y: 1)
    }

    // MARK: - Subcomponents

    @ViewBuilder
    private func compactStat<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 2) {
            content()
                .lineLimit(1)
            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var compactDivider: some View {
        Rectangle()
            .fill(DarkFantasyTheme.borderMedium.opacity(0.2))
            .frame(width: 1, height: 28)
    }

    @ViewBuilder
    private func fullStatCell<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content,
        subtitle: String? = nil,
        winRateBar: Bool = false
    ) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(label)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(1.5)

            content()
                .monospacedDigit()
                .contentTransition(.numericText())

            if let subtitle {
                Text(subtitle)
                    .font(DarkFantasyTheme.body(size: 10))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }

            if winRateBar {
                // Mini win rate bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(Color.white.opacity(0.04))
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(data.pvpWinRateColor)
                            .frame(width: geo.size.width * CGFloat(data.pvpWinRate) / 100)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, LayoutConstants.spaceSM)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMS)
        .background(DarkFantasyTheme.bgPrimary.opacity(0.6))
    }

    @ViewBuilder
    private func streakBadge(compact: Bool) -> some View {
        let streak = data.pvpCurrentStreak
        if streak == 0 {
            Text("—")
                .font(DarkFantasyTheme.section(size: compact ? 12 : 14))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        } else {
            let isWin = streak > 0
            let abs = abs(streak)
            let color = isWin ? DarkFantasyTheme.success : DarkFantasyTheme.danger
            let isHot = abs >= 5

            HStack(spacing: 2) {
                Image(systemName: isWin ? "arrow.up" : "arrow.down")
                    .font(DarkFantasyTheme.badge.bold())
                Text("\(abs)")
                    .font(DarkFantasyTheme.section(size: compact ? 12 : LayoutConstants.textLabel))
                if isHot {
                    Image(systemName: "flame.fill")
                        .font(.system(size: compact ? 8 : 10, design: .rounded))
                        .foregroundStyle(DarkFantasyTheme.danger)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, compact ? 0 : LayoutConstants.spaceXS + 2)
            .padding(.vertical, compact ? 0 : 2)
            .background(
                Group {
                    if !compact {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .fill(color.opacity(0.1))
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var tierProgressBar: some View {
        let rank = data.pvpRank
        let nextRankIndex = PvPRank.allCases.firstIndex(of: rank).map { $0 + 1 }
        let nextRank = nextRankIndex.flatMap { $0 < PvPRank.allCases.count ? PvPRank.allCases[$0] : nil }

        if let nextRank {
            let rangeStart = rank.minRating
            let rangeEnd = nextRank.minRating
            let progress = Double(data.pvpRating - rangeStart) / Double(rangeEnd - rangeStart)

            VStack(spacing: 3) {
                HStack {
                    Text(rank.rawValue)
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Text("\(nextRank.rawValue) \(rangeEnd)")
                        .font(DarkFantasyTheme.body(size: 10))
                        .foregroundStyle(DarkFantasyTheme.rankColor(for: nextRank.minRating).opacity(0.6))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(Color.white.opacity(0.04))
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(
                                LinearGradient(
                                    colors: [data.pvpRankColor.opacity(0.6), DarkFantasyTheme.rankColor(for: nextRank.minRating)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(max(progress, 0), 1))
                    }
                }
                .frame(height: 3)
            }
        }
    }
}
