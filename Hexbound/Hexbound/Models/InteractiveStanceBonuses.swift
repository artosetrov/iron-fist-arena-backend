//
//  InteractiveStanceBonuses.swift
//  Hexbound
//
//  Client-side mirror of STANCE_ZONES in backend/src/lib/game/balance.ts.
//
//  This file is DISPLAY-ONLY. The values here exist solely to render
//  informational text like "OFF +10%  CRIT +5%" on the picker tiles and
//  under the fighter cards. Combat resolution remains server-authoritative
//  — these numbers are NEVER consumed to compute damage, crit, or any
//  other formula on the client.
//
//  Source of truth: backend/src/lib/game/balance.ts → STANCE_ZONES.
//  If backend values ever change, update this file in the same PR.
//
//  Personality per zone (mirrors backend comment block):
//    head  = high risk / high reward (glass cannon)
//    chest = balanced (steady)
//    legs  = safe / mixed (no big payoff, no big penalty)
//

import Foundation

/// Static display data for body-zone stance bonuses. Pure value type —
/// no combat logic, no side effects.
enum InteractiveStanceBonuses {

    // MARK: - Attack zone bonuses
    //
    // Matches `STANCE_ZONES.ATTACK_ZONE` in balance.ts.
    static func attackBonusText(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "OFF +10%  CRIT +5%"
        case .chest: return "OFF +5%"
        case .legs:  return "OFF +2%"
        }
    }

    /// Headline (shortest) form used for the compact chip under the
    /// fighter card, where horizontal space is tight.
    static func attackBonusHeadline(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "OFF +10%"
        case .chest: return "OFF +5%"
        case .legs:  return "OFF +2%"
        }
    }

    // MARK: - Defense zone bonuses
    //
    // Matches `STANCE_ZONES.DEFENSE_ZONE` in balance.ts.
    static func defendBonusText(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "DODGE +8%"
        case .chest: return "DEF +10%"
        case .legs:  return "DEF +5%  DODGE +3%"
        }
    }

    static func defendBonusHeadline(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "DODGE +8%"
        case .chest: return "DEF +10%"
        case .legs:  return "DEF +5%"
        }
    }

    // MARK: - Zone asset names
    //
    // The equipment-slot icons live closest to the body-zone semantics,
    // and are already part of the shipping asset catalogue. Using them
    // here (rather than SF Symbols) honors the "assets instead of icons"
    // project rule.
    static func assetName(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "icon-helmet"
        case .chest: return "icon-chest"
        case .legs:  return "icon-legs"
        }
    }

    // MARK: - Tooltip copy
    //
    // Plain-language zone tooltips shown on long-press. These are the first
    // thing a new player reads to understand the high-risk/high-reward
    // personality of each zone. Keep under ~120 chars so the tooltip fits
    // in a two-line callout on iPhone SE width.

    /// Long-press tooltip for an attack-zone tile in the picker.
    static func attackTooltip(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:
            return "High damage and crit chance. Easy to block if the enemy reads you."
        case .chest:
            return "Balanced damage. Reliable pick when you're unsure."
        case .legs:
            return "Low damage, hardest to counter. Safe poke."
        }
    }

    /// Long-press tooltip for a defense-zone tile in the picker.
    static func defendTooltip(for zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:
            return "High dodge chance — you can fully avoid the hit."
        case .chest:
            return "Solid damage reduction. The safe defensive pick."
        case .legs:
            return "Mixed defense: some damage reduction plus a small dodge."
        }
    }

    /// Long-press tooltip for the STANCE chip shown under a fighter card.
    /// Summarizes the bonus in plain words without the numeric shorthand.
    static func chipTooltip(kind: ChipKind, zone: InteractiveBodyZone?) -> String {
        guard let zone else {
            return kind == .attack
                ? "You haven't seen where they strike yet. Land 1–2 hits to reveal it."
                : "Defense is hidden until the next exchange. Keep pressuring."
        }
        switch kind {
        case .attack: return attackTooltip(for: zone)
        case .defend: return defendTooltip(for: zone)
        }
    }

    /// Small wrapper so the tooltip API is not coupled to SwiftUI. Mirrors
    /// `StanceBonusChip.Kind` without importing the view layer.
    enum ChipKind { case attack, defend }
}
