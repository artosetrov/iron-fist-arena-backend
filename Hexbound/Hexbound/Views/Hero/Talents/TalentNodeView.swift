//
//  TalentNodeView.swift
//  Hexbound
//
//  Single passive-tree node. Shape + color driven by bonusType and unlock state.
//  Uses DarkFantasyTheme tokens only — no hardcoded colors.
//

import SwiftUI

struct TalentNodeView: View {
    enum State {
        case unlocked
        case unlockable
        case locked
    }

    let node: PassiveNode
    let state: State

    // Tier-based size (tier 5 ultimate > tier 3 keystone > rest).
    // Kept below `minNeighborDistance` (20px in TalentTreeCanvas) so
    // adjacent nodes never overlap at the tightest packing.
    var size: CGFloat {
        if node.tier >= 5 { return 22 }   // ultimate
        if node.tier == 3 { return 18 }   // keystone
        return 16
    }

    private var strokeColor: Color {
        switch state {
        case .unlocked:  DarkFantasyTheme.goldBright
        case .unlockable: DarkFantasyTheme.gold
        case .locked:     DarkFantasyTheme.borderSubtle
        }
    }

    private var fillColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.gold.opacity(0.28)
        case .unlockable: DarkFantasyTheme.bgElevated
        case .locked:     DarkFantasyTheme.bgSecondary
        }
    }

    private var iconColor: Color {
        switch state {
        case .unlocked:   DarkFantasyTheme.goldBright
        case .unlockable: DarkFantasyTheme.textPrimary
        case .locked:     DarkFantasyTheme.textDisabled
        }
    }

    private var strokeWidth: CGFloat {
        switch state {
        case .unlocked:   3
        case .unlockable: 2
        case .locked:     1
        }
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
                .frame(width: size * 0.38, height: size * 0.38)

            // Cost badge for unlockable, non-start nodes
            if state == .unlockable && !node.isStartNode {
                costBadge
                    .offset(x: size * 0.6, y: -size * 0.6)
            }
        }
        .frame(width: size, height: size)
        .shadow(
            color: state == .unlocked ? DarkFantasyTheme.goldGlow : Color.clear,
            radius: 8,
            x: 0,
            y: 0
        )
        .accessibilityLabel(node.name)
        .accessibilityHint(node.description)
    }

    @ViewBuilder
    private var shapeBody: some View {
        switch node.bonusType {
        case "ultimate":
            Rectangle()
                .fill(fillColor)
                .overlay(Rectangle().stroke(strokeColor, lineWidth: strokeWidth))
                .frame(width: size * 0.72, height: size * 0.72)
                .rotationEffect(.degrees(45))
        case "keystone":
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
        default:
            Circle()
                .fill(fillColor)
                .overlay(Circle().stroke(strokeColor, lineWidth: strokeWidth))
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
                .stroke(DarkFantasyTheme.gold, lineWidth: 1)
            Text("\(node.cost)")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.gold)
        }
        .frame(width: 12, height: 12)
    }
}
