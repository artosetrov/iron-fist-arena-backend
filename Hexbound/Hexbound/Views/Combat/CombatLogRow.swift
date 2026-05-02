//
//  CombatLogRow.swift
//  Hexbound
//
//  Interactive Combat v3 — one row inside the Round Exchange log card.
//
//  An ally row flows left→right (icon tile on the left, text reads right),
//  an enemy row flows right→left (text reads left, icon tile on the right).
//  The row animates in with opacity + tiny horizontal offset — NEVER a
//  scale/grow tween. Project motion rule: emphasis comes from opacity and
//  translation, not from scaling UI elements.
//
//  Inputs (`CombatLogEvent`, `Duration`) are pure value types — no VM,
//  no environment objects. Row is cheap and safe to stagger in a List.
//

import SwiftUI

/// Leaf view: one log line in the Round Exchange card.
struct CombatLogRow: View {

    let event: CombatLogEvent
    var staggerDelay: Duration = .zero

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .center, spacing: LayoutConstants.spaceSM) {
            if event.side == .enemy {
                Spacer(minLength: 0)
                textBlock
                iconTile
            } else {
                iconTile
                textBlock
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, LayoutConstants.space2XS)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (event.side == .enemy ? 8 : -8))
        .task {
            if staggerDelay > .zero {
                try? await Task.sleep(for: staggerDelay)
            }
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    // MARK: - Sub-views

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(iconBorderColor, lineWidth: 1)
                )

            CachedAssetImage(
                key: event.assetName,
                url: nil,
                systemIcon: "sparkle",
                contentMode: .fit
            )
            .frame(width: 28, height: 28)
        }
        .frame(width: 40, height: 40)
        .shadow(
            color: event.kind == .talent
                ? DarkFantasyTheme.gold.opacity(0.35)
                : .clear,
            radius: 6
        )
    }

    private var textBlock: some View {
        Text(event.renderedText)
            .lineLimit(2)
            .multilineTextAlignment(event.side == .enemy ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Tile border color

    private var iconBorderColor: Color {
        switch event.kind {
        case .damage: return DarkFantasyTheme.danger.opacity(0.55)
        case .shield: return DarkFantasyTheme.info.opacity(0.55)
        case .talent: return DarkFantasyTheme.gold
        case .heal:   return DarkFantasyTheme.success.opacity(0.55)
        case .neutral:
            return event.side == .ally
                ? DarkFantasyTheme.success.opacity(0.45)
                : DarkFantasyTheme.danger.opacity(0.45)
        }
    }
}

// MARK: - Preview

#Preview("Combat log rows", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
        CombatLogRow(event: .strike(
            index: 1, side: .ally, zone: .chest,
            actorName: "You", damage: 186, skillName: nil
        ))
        CombatLogRow(event: .crit(
            index: 2, side: .ally, zone: .head,
            actorName: "You", damage: 342, skillName: "Heavy Strike"
        ))
        CombatLogRow(event: .talentFired(
            index: 3, side: .ally,
            action: .burstDamage, actorName: "You"
        ))
        CombatLogRow(event: .blocked(
            index: 4, side: .enemy, zone: .chest,
            actorName: "Enemy", targetName: "You"
        ))
        CombatLogRow(event: .dodged(
            index: 5, side: .enemy, zone: .legs,
            actorName: "Enemy", targetName: "You"
        ))
        CombatLogRow(event: .missed(
            index: 6, side: .enemy, zone: .head,
            actorName: "Enemy", targetName: "You"
        ))
    }
    .padding(LayoutConstants.spaceMD)
    .background(DarkFantasyTheme.bgElevated)
}
