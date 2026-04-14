//
//  CombatLogEvent.swift
//  Hexbound
//
//  Interactive Combat v3 — one row in the "round exchange" log card.
//
//  An event is a purely presentational structure: it tells the view which
//  asset to show on the icon tile, which side (ally / enemy) to align the
//  row on, which color family the tile border should use, and a styled
//  `AttributedString` for the text line.
//
//  No damage / crit / formula math lives here. All numeric inputs come
//  from the server payload (`InteractiveStrikeResponse`) via
//  `RoundExchange.build(from:)`. Client stays server-authoritative.
//

import Foundation
import SwiftUI

/// One log row inside the Round Exchange card.
enum CombatLogEvent: Identifiable, Sendable, Equatable {

    // MARK: - Cases

    /// Normal damaging strike (not crit, not blocked).
    case strike(index: Int, side: Side, zone: InteractiveBodyZone,
                actorName: String, damage: Int, skillName: String?)

    /// Crit — styled with gold accent + glow tile.
    case crit(index: Int, side: Side, zone: InteractiveBodyZone,
              actorName: String, damage: Int, skillName: String?)

    /// Attack landed but damage was absorbed to 0.
    case blocked(index: Int, side: Side, zone: InteractiveBodyZone,
                 actorName: String, targetName: String)

    /// Defender dodged — no damage.
    case dodged(index: Int, side: Side, zone: InteractiveBodyZone,
                actorName: String, targetName: String)

    /// Attacker missed entirely.
    case missed(index: Int, side: Side, zone: InteractiveBodyZone,
                actorName: String, targetName: String)

    /// Active skill fired this round. Shown as its own row so the player
    /// sees "I fired BURST → then I hit HEAD for 220".
    case talentFired(index: Int, side: Side, action: TalentSlotAction,
                     actorName: String)

    // MARK: - Side

    enum Side: Sendable, Equatable { case ally, enemy }

    // MARK: - Icon tile kind (drives border color + glow)

    enum IconKind: Sendable, Equatable {
        case damage   // red border
        case shield   // blue border
        case talent   // gold border + glow
        case heal     // green border
        case neutral  // side-tinted (ally=green, enemy=red) low alpha
    }

    // MARK: - Identity

    /// Stable identity. The `index` slot on each case is seeded by
    /// `RoundExchange.build(from:)` so rows never shuffle during the
    /// stagger animation.
    var id: String {
        switch self {
        case .strike(let i, _, _, _, _, _):      return "strike-\(i)"
        case .crit(let i, _, _, _, _, _):        return "crit-\(i)"
        case .blocked(let i, _, _, _, _):        return "blocked-\(i)"
        case .dodged(let i, _, _, _, _):         return "dodged-\(i)"
        case .missed(let i, _, _, _, _):         return "missed-\(i)"
        case .talentFired(let i, _, _, _):       return "talent-\(i)"
        }
    }

    // MARK: - Side accessor

    var side: Side {
        switch self {
        case .strike(_, let s, _, _, _, _),
             .crit(_, let s, _, _, _, _),
             .blocked(_, let s, _, _, _),
             .dodged(_, let s, _, _, _),
             .missed(_, let s, _, _, _),
             .talentFired(_, let s, _, _):
            return s
        }
    }

    // MARK: - Icon kind

    var kind: IconKind {
        switch self {
        case .strike, .crit:   return .damage
        case .blocked:         return .shield
        case .dodged, .missed: return .neutral
        case .talentFired(_, _, let action, _):
            switch action {
            case .healSelf:   return .heal
            case .shieldSelf: return .shield
            case .burstDamage, .stunEnemy, .execute:
                return .talent
            }
        }
    }

    // MARK: - Asset name

    /// Asset catalogue name rendered inside the icon tile. Every name here
    /// must exist under `Hexbound/Resources/Assets.xcassets` as an imageset.
    var assetName: String {
        switch self {
        case .strike(_, _, let zone, _, _, _),
             .crit(_, _, let zone, _, _, _),
             .blocked(_, _, let zone, _, _),
             .dodged(_, _, let zone, _, _),
             .missed(_, _, let zone, _, _):
            return Self.zoneAsset(zone)
        case .talentFired(_, _, let action, _):
            return Self.talentAsset(action)
        }
    }

    private static func zoneAsset(_ zone: InteractiveBodyZone) -> String {
        switch zone {
        case .head:  return "icon-helmet"
        case .chest: return "icon-chest"
        case .legs:  return "icon-legs"
        }
    }

    private static func talentAsset(_ action: TalentSlotAction) -> String {
        switch action {
        case .burstDamage: return "fx-magical-burst"
        case .healSelf:    return "fx-heal-divine"
        case .shieldSelf:  return "fx-block-hexshield"
        case .stunEnemy:   return "fx-true-lightning"
        case .execute:     return "fx-physical-explosion"
        }
    }

    // MARK: - Rendered text (AttributedString)

    /// Styled single-line log line. Uses `AttributedString` so the actor
    /// name, zone, skill, and number each get their own foreground color.
    /// All colors pulled from `DarkFantasyTheme` — zero raw hex.
    var renderedText: AttributedString {
        switch self {
        case .strike(_, let side, let zone, let actor, let damage, let skill):
            return buildStrikeText(
                side: side, zone: zone, actor: actor,
                damage: damage, skill: skill, isCrit: false
            )
        case .crit(_, let side, let zone, let actor, let damage, let skill):
            return buildStrikeText(
                side: side, zone: zone, actor: actor,
                damage: damage, skill: skill, isCrit: true
            )
        case .blocked(_, _, let zone, let actor, let target):
            var s = AttributedString("")
            s += named(actor, isAlly: side == .ally)
            s += plain(" hit ")
            s += named(target, isAlly: side != .ally)
            s += plain("'s ")
            s += zoneWord(zone)
            s += plain(" — ")
            s += muted("blocked")
            return s
        case .dodged(_, _, let zone, let actor, let target):
            var s = AttributedString("")
            s += named(actor, isAlly: side == .ally)
            s += plain(" swung at ")
            s += zoneWord(zone)
            s += plain(" — ")
            s += muted(target + " dodged")
            return s
        case .missed(_, _, let zone, let actor, _):
            var s = AttributedString("")
            s += named(actor, isAlly: side == .ally)
            s += plain(" swung at ")
            s += zoneWord(zone)
            s += plain(" — ")
            s += muted("missed")
            return s
        case .talentFired(_, _, let action, let actor):
            var s = AttributedString("")
            s += named(actor, isAlly: side == .ally)
            s += plain(" fired ")
            s += talentName(action)
            return s
        }
    }

    // MARK: - Text styling helpers

    private func buildStrikeText(side: Side,
                                 zone: InteractiveBodyZone,
                                 actor: String,
                                 damage: Int,
                                 skill: String?,
                                 isCrit: Bool) -> AttributedString {
        var s = AttributedString("")
        s += named(actor, isAlly: side == .ally)
        s += plain(" hit ")
        s += zoneWord(zone)
        s += plain(" for ")
        s += damageNumber(damage, isCrit: isCrit)
        if isCrit {
            s += plain(" ")
            s += critTag()
        }
        if let skill, !skill.isEmpty, skill.lowercased() != "attack" {
            s += muted(" · " + skill.capitalized)
        }
        return s
    }

    private func named(_ name: String, isAlly: Bool) -> AttributedString {
        var a = AttributedString(name.uppercased())
        a.font = DarkFantasyTheme.buttonLabelCompact
        a.foregroundColor = isAlly ? DarkFantasyTheme.gold : DarkFantasyTheme.danger
        return a
    }

    private func plain(_ text: String) -> AttributedString {
        var a = AttributedString(text)
        a.font = DarkFantasyTheme.body
        a.foregroundColor = DarkFantasyTheme.textPrimary
        return a
    }

    private func zoneWord(_ zone: InteractiveBodyZone) -> AttributedString {
        var a = AttributedString(zone.rawValue.uppercased())
        a.font = DarkFantasyTheme.body
        a.foregroundColor = DarkFantasyTheme.textSecondary
        return a
    }

    private func damageNumber(_ n: Int, isCrit: Bool) -> AttributedString {
        var a = AttributedString("\(n)")
        a.font = isCrit ? DarkFantasyTheme.cardTitle : DarkFantasyTheme.buttonLabelCompact
        a.foregroundColor = isCrit ? DarkFantasyTheme.gold : DarkFantasyTheme.danger
        return a
    }

    private func critTag() -> AttributedString {
        var a = AttributedString("CRIT")
        a.font = DarkFantasyTheme.badge
        a.foregroundColor = DarkFantasyTheme.gold
        return a
    }

    private func muted(_ text: String) -> AttributedString {
        var a = AttributedString(text)
        a.font = DarkFantasyTheme.uiLabel
        a.foregroundColor = DarkFantasyTheme.textSecondary
        return a
    }

    private func talentName(_ action: TalentSlotAction) -> AttributedString {
        var a = AttributedString(action.shortLabel.uppercased() + "!")
        a.font = DarkFantasyTheme.buttonLabelCompact
        a.foregroundColor = DarkFantasyTheme.gold
        return a
    }
}
