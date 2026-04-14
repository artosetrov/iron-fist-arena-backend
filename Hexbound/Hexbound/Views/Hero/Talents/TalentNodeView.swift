//
//  TalentNodeView.swift
//  Hexbound
//
//  Single passive-tree node. Shape + color driven by bonusType and unlock state.
//  Uses DarkFantasyTheme tokens only — no hardcoded colors.
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

    // Explicit init — `@State private var pulse` would otherwise make the
    // auto-synthesized memberwise init `private`, breaking callers like
    // `TalentTreeCanvas`.
    init(node: PassiveNode, state: NodeState) {
        self.node = node
        self.state = state
    }

    // Tier-based size — bumped to ≥ 44pt touch target per Apple HIG.
    // Kept below `minNeighborDistance` (64pt in TalentTreeCanvas) so
    // adjacent nodes never overlap at the tightest packing.
    var size: CGFloat {
        if node.tier >= 5 { return 56 }   // ultimate
        if node.tier == 3 { return 50 }   // keystone
        return 44
    }

    // MARK: - Pulse for pending state
    @State private var pulse: Bool = false

    private var strokeColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.goldBright
        case .pending:    DarkFantasyTheme.goldBright
        case .unlockable: DarkFantasyTheme.gold
        case .locked:     DarkFantasyTheme.borderSubtle
        }
    }

    private var fillColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.gold.opacity(0.28)
        case .pending:    DarkFantasyTheme.gold.opacity(0.18)
        case .unlockable: DarkFantasyTheme.bgElevated
        case .locked:     DarkFantasyTheme.bgSecondary
        }
    }

    private var iconColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.goldBright
        case .pending:    DarkFantasyTheme.goldBright
        case .unlockable: DarkFantasyTheme.textPrimary
        case .locked:     DarkFantasyTheme.textDisabled
        }
    }

    private var strokeWidth: CGFloat {
        switch state {
        case .unlocked:   3
        case .pending:    3
        case .unlockable: 2
        case .locked:     1
        }
    }

    private var dashPattern: [CGFloat]? {
        state == .pending ? [4, 3] : nil
    }

    var body: some View {
        ZStack {
            shapeBody

            // Icon or fallback glyph
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .foregroundStyle(iconColor)
                .frame(width: size * 0.42, height: size * 0.42)

            // Cost badge for unlockable AND pending non-start nodes
            if (state == .unlockable || state == .pending) && !node.isStartNode {
                costBadge
                    .offset(x: size * 0.42, y: -size * 0.42)
            }
        }
        .frame(width: size, height: size)
        .opacity(state == .pending && pulse ? 0.7 : 1.0)
        .shadow(
            color: shadowColor,
            radius: state == .pending ? 6 : 8,
            x: 0,
            y: 0
        )
        .onAppear {
            guard state == .pending else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityLabel(node.name)
        .accessibilityHint(node.description)
    }

    private var shadowColor: Color {
        switch state {
        case .unlocked: DarkFantasyTheme.goldGlow
        case .pending:  DarkFantasyTheme.gold.opacity(0.4)
        default:        Color.clear
        }
    }

    @ViewBuilder
    private var shapeBody: some View {
        switch node.bonusType {
        case "ultimate":
            Rectangle()
                .fill(fillColor)
                .overlay(
                    Rectangle()
                        .strokeBorder(
                            strokeColor,
                            style: StrokeStyle(lineWidth: strokeWidth, dash: dashPattern ?? [])
                        )
                )
                .frame(width: size * 0.72, height: size * 0.72)
                .rotationEffect(.degrees(45))
        case "keystone":
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .strokeBorder(
                            strokeColor,
                            style: StrokeStyle(lineWidth: strokeWidth, dash: dashPattern ?? [])
                        )
                )
        default:
            Circle()
                .fill(fillColor)
                .overlay(
                    Circle()
                        .strokeBorder(
                            strokeColor,
                            style: StrokeStyle(lineWidth: strokeWidth, dash: dashPattern ?? [])
                        )
                )
        }
    }

    private var symbolName: String {
        // Ultimate/keystone hero symbols come from tier
        if node.tier >= 5 { return "crown.fill" }

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

    private var costBadge: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.bgAbyss)
            Circle()
                .stroke(DarkFantasyTheme.gold, lineWidth: 1.5)
            Text("\(node.cost)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.gold)
        }
        .frame(width: 18, height: 18)
    }
}
