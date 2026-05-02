//
//  TalentNodeView.swift
//  Hexbound
//
//  Single passive-tree node. Square tile — same visual DNA as item cards.
//  State drives left gold bar, border, and pulse/dash. Uses DarkFantasyTheme tokens only.
//

import SwiftUI

struct TalentNodeView: View {
    enum NodeState {
        case unlocked
        case pending     // staged for confirmation (gold dashed, pulse)
        case unlockable
        case locked
    }

    let node: PassiveNode
    let state: NodeState
    /// Talents v2: server-confirmed rank (1…maxRank). 0 when the node has never
    /// been unlocked. Defaults to 0 so pre-v2 callers keep compiling.
    let currentRank: Int
    /// Talents v2: locally-staged target rank (1/2/3) pending commit. 0 when
    /// nothing is staged for this node.
    let stagedRank: Int
    // Keystone gets a bigger footprint and a gold fill (like the prototype).
    var isKeystone: Bool { node.tier >= 3 || node.bonusType == "keystone" || node.bonusType == "ultimate" }

    // Explicit init — `@State private var pulse` would otherwise make the
    // auto-synthesized memberwise init `private`, breaking callers like
    // `TalentTreeCanvas`.
    init(
        node: PassiveNode,
        state: NodeState,
        currentRank: Int = 0,
        stagedRank: Int = 0
    ) {
        self.node = node
        self.state = state
        self.currentRank = currentRank
        self.stagedRank = stagedRank
    }

    /// Effective rank including staging — drives the pip strip's "bright" count.
    private var effectiveRank: Int { max(currentRank, stagedRank) }

    // Square tile footprint — uniform 56×56. Sized down from 64 so 7 tier rows
    // (foundation + 3 archetype tiers + keystone + ultimate) fit the 460pt
    // canvas frame without vertical scrolling. Emphasis on keystones/ultimates
    // is carried by stroke + glow, not size.
    var size: CGFloat { 56 }

    // MARK: - Pulse for pending / unlockable

    @State private var pulse: Bool = false

    private var cornerRadius: CGFloat { LayoutConstants.radiusMD } // 8

    private var strokeColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.gold
        case .pending:    DarkFantasyTheme.goldBright
        case .unlockable: DarkFantasyTheme.goldDim
        case .locked:     DarkFantasyTheme.borderSubtle
        }
    }

    private var strokeWidth: CGFloat {
        switch state {
        case .unlocked:   1.5
        case .pending:    2
        case .unlockable: 1.5
        case .locked:     1.5
        }
    }

    private var fillStyle: AnyShapeStyle {
        if isKeystone && state == .unlocked {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        switch state {
        case .unlocked:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        DarkFantasyTheme.gold.opacity(0.18),
                        DarkFantasyTheme.gold.opacity(0.05)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
        case .pending:
            return AnyShapeStyle(DarkFantasyTheme.gold.opacity(0.14))
        case .unlockable, .locked:
            return AnyShapeStyle(DarkFantasyTheme.bgPrimary)
        }
    }

    private var iconColor: Color {
        if isKeystone && state == .unlocked { return DarkFantasyTheme.textOnGold }
        switch state {
        case .unlocked:   return DarkFantasyTheme.goldBright
        case .pending:    return DarkFantasyTheme.goldBright
        case .unlockable: return DarkFantasyTheme.textSecondary
        case .locked:     return DarkFantasyTheme.textDisabled
        }
    }

    private var dashPattern: [CGFloat]? {
        state == .pending ? [4, 3] : nil
    }

    private var glowColor: Color {
        switch state {
        case .unlocked:   return DarkFantasyTheme.goldGlow
        case .pending:    return DarkFantasyTheme.gold.opacity(0.40)
        case .unlockable: return DarkFantasyTheme.gold.opacity(pulse ? 0.40 : 0.20)
        case .locked:     return .clear
        }
    }

    private var glowRadius: CGFloat {
        switch state {
        case .unlocked:   return 12
        case .pending:    return 8
        case .unlockable: return pulse ? 20 : 12
        case .locked:     return 0
        }
    }

    // Left 3px gold bar — only for unlocked state (matches item-card DNA).
    @ViewBuilder
    private var leftBar: some View {
        if state == .unlocked && !isKeystone {
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(DarkFantasyTheme.gold)
            .frame(width: 3)
            .frame(maxHeight: .infinity)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fillStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            strokeColor,
                            style: StrokeStyle(lineWidth: strokeWidth, dash: dashPattern ?? [])
                        )
                )
                .overlay(alignment: .leading) { leftBar }

            // Icon
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .foregroundStyle(iconColor)
                .frame(width: size * 0.42, height: size * 0.42)

            // Rank pill (top-right) — cost chip on locked/unlockable, current
            // rank indicator on unlocked single-rank nodes. Ranked nodes (v2)
            // use the pip strip below instead of a numeric rank pill.
            if shouldShowRankPill {
                rankPill
                    .offset(x: size * 0.42, y: -size * 0.42)
            }

            // Talents v2: rank pip strip for ranked nodes (maxRank > 1).
            // Sits just above the tile and shows 1 pip per rank step, filled
            // for committed ranks, dashed for pending-staged ranks.
            if showRankPipStrip {
                rankPipStrip
                    .offset(y: -(size * 0.5) - 7)
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: glowColor, radius: glowRadius, x: 0, y: 0)
        .onAppear {
            // Pulse animation only for `.pending` and `.unlockable` — gives an
            // affordance cue without being noisy on unlocked/locked tiles.
            guard state == .pending || state == .unlockable else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear { pulse = false }
        .accessibilityLabel(node.name)
        .accessibilityHint(node.description)
    }

    // MARK: - Rank pill

    /// Ranked nodes (maxRank > 1) use the pip strip below the tile for rank
    /// progress. The numeric pill would be redundant — and in the "pending
    /// first unlock to rank 1" case it would collide visually with the pip.
    private var isRanked: Bool { node.maxRankResolved > 1 }

    private var shouldShowRankPill: Bool {
        // Never show the pill when the pip strip is already communicating rank.
        if isRanked { return false }
        switch state {
        case .unlocked: return !isKeystone // keystone doesn't show rank badge in prototype
        case .unlockable, .pending: return !node.isStartNode
        case .locked: return false
        }
    }

    private var rankPill: some View {
        let text: String = {
            switch state {
            case .unlocked:
                // Single-rank unlocked nodes still show a "1" checkmark-style chip.
                return currentRank > 0 ? "\(currentRank)" : "1"
            case .unlockable, .pending:
                // Cost to get from 0 → rank 1 for ranked nodes, full cost for flat.
                return "\(node.rankCostSchedule.first ?? node.cost)"
            case .locked:
                return ""
            }
        }()
        return Text(text)
            .font(DarkFantasyTheme.badge)
            .fontWeight(.bold)
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .frame(minWidth: 16, minHeight: 16)
            .padding(.horizontal, 4)
            .background(
                Capsule().fill(DarkFantasyTheme.gold)
            )
            .overlay(
                Capsule().stroke(DarkFantasyTheme.bgSecondary, lineWidth: 1.5)
            )
    }

    // MARK: - Rank pip strip (Talents v2)

    /// Show the pip strip for any ranked node that has at least surfaced as
    /// unlockable — keeps the tile readable even when still locked (player can
    /// see it's a multi-rank node at a glance).
    private var showRankPipStrip: Bool {
        guard isRanked else { return false }
        // Hide pips on fully-locked-and-unreachable nodes to reduce visual
        // noise in the deep-locked background.
        return state != .locked
    }

    private var rankPipStrip: some View {
        HStack(spacing: 3) {
            ForEach(0..<node.maxRankResolved, id: \.self) { i in
                pipView(index: i)
            }
        }
    }

    /// One rank pip. Three states:
    ///   - filled gold: `i < currentRank`               (server-confirmed)
    ///   - dashed gold: `currentRank ≤ i < stagedRank` (locally staged)
    ///   - empty slate: otherwise
    @ViewBuilder
    private func pipView(index i: Int) -> some View {
        let isCommitted = i < currentRank
        let isStaged = i >= currentRank && i < stagedRank
        let pipSize: CGFloat = 6

        ZStack {
            Circle()
                .fill(isCommitted ? DarkFantasyTheme.gold : Color.clear)
            Circle()
                .strokeBorder(
                    isCommitted
                        ? DarkFantasyTheme.goldBright
                        : (isStaged
                            ? DarkFantasyTheme.goldBright
                            : DarkFantasyTheme.borderSubtle),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: isStaged ? [1.5, 1.5] : []
                    )
                )
        }
        .frame(width: pipSize, height: pipSize)
        .shadow(
            color: isCommitted ? DarkFantasyTheme.goldGlow.opacity(0.6) : .clear,
            radius: 2
        )
    }

    // MARK: - Symbols

    private var symbolName: String {
        // Ultimate/keystone hero symbols come from tier
        if isKeystone { return node.tier >= 5 ? "crown.fill" : "shield.fill" }

        // Map by mechanical bonusType first
        switch node.bonusType {
        case "flat_hp", "percent_hp":                       return "heart.fill"
        case "flat_armor", "percent_armor":                 return "shield.fill"
        case "flat_magic_resist", "percent_magic_resist":   return "sparkles"
        case "flat_damage", "percent_damage":               return "bolt.fill"
        case "flat_crit_chance":                            return "scope"
        case "flat_dodge_chance":                           return "hare.fill"
        case "lifesteal":                                   return "drop.fill"
        case "cooldown_reduction":                          return "timer"
        case "damage_reduction":                            return "shield.lefthalf.filled"
        case "flat_stat", "percent_stat":
            switch node.bonusStat {
            case "str": return "figure.strengthtraining.traditional"
            case "agi": return "hare.fill"
            case "vit": return "heart.circle.fill"
            case "end": return "figure.stand"
            case "int": return "brain.head.profile"
            case "wis": return "book.fill"
            case "luk": return "die.face.5.fill"
            case "cha": return "person.fill"
            default:    return "star.fill"
            }
        default:
            return "circle.grid.2x2.fill"
        }
    }
}
