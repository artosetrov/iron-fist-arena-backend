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

    // Tier-based size
    var size: CGFloat {
        switch node.bonusType {
        case "ultimate": return 76
        case "keystone": return 64
        default: return 52
        }
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
                    .offset(x: size * 0.35, y: -size * 0.35)
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
        switch node.bonusType {
        case "ultimate": return "crown.fill"
        case "keystone": return "star.fill"
        default:
            // Map common stat keys to SF symbols as a safe fallback.
            switch node.bonusStat {
            case "maxHp":      return "heart.fill"
            case "armor":      return "shield.fill"
            case "magicResist": return "wand.and.stars"
            case "strength":   return "figure.strengthtraining.traditional"
            case "dexterity":  return "hare.fill"
            case "intelligence": return "brain.head.profile"
            case "vitality":   return "cross.case.fill"
            default:           return "circle.grid.2x2.fill"
            }
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
        .frame(width: 18, height: 18)
    }
}
