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
    // Keystone gets a bigger footprint and a gold fill (like the prototype).
    var isKeystone: Bool { node.tier >= 3 || node.bonusType == "keystone" || node.bonusType == "ultimate" }

    // Explicit init — `@State private var pulse` would otherwise make the
    // auto-synthesized memberwise init `private`, breaking callers like
    // `TalentTreeCanvas`.
    init(node: PassiveNode, state: NodeState) {
        self.node = node
        self.state = state
    }

    // Square tile footprint — regular 44×44, keystone 54×54.
    var size: CGFloat { isKeystone ? 54 : 44 }

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

            // Rank pill (top-right) — keeps cost visible on unlockable nodes,
            // and rank "1" on unlocked ranked nodes (for the MVP every unlocked
            // node is rank 1 — the backend doesn't support multi-rank yet).
            if shouldShowRankPill {
                rankPill
                    .offset(x: size * 0.42, y: -size * 0.42)
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

    private var shouldShowRankPill: Bool {
        switch state {
        case .unlocked: return !isKeystone // keystone doesn't show rank badge in prototype
        case .unlockable, .pending: return !node.isStartNode
        case .locked: return false
        }
    }

    private var rankPill: some View {
        let text: String = {
            switch state {
            case .unlocked:             return "1"
            case .unlockable, .pending: return "\(node.cost)"
            case .locked:               return ""
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
