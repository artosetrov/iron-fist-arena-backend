//
//  RoundVerdict.swift
//  Hexbound
//
//  Player-perspective round classification derived from server strike data.
//  Presentation-only — the backend remains authoritative for damage, crit,
//  dodge, and match state. Verdict drives the reveal card framing: verdict
//  band color, clash-chip glow, portrait winner/loser shadow, and the
//  screen-level flash overlay.
//

import Foundation

enum RoundVerdict: String, Sendable, Equatable, CaseIterable {
    case outplayed
    case struck
    case held
    case outread

    var bannerText: String {
        switch self {
        case .outplayed: return "OUTPLAYED"
        case .struck:    return "STRUCK THROUGH"
        case .held:      return "HELD THE LINE"
        case .outread:   return "OUTREAD"
        }
    }

    /// One-line plain-language description of what happened. Rendered under
    /// `bannerText` so players unfamiliar with the verdict vocabulary can
    /// parse the round instantly. Kept short enough to fit on one line on
    /// iPhone SE width.
    var subtitle: String {
        switch self {
        case .outplayed: return "You hit, enemy missed"
        case .struck:    return "Both landed hits"
        case .held:      return "Both blocked"
        case .outread:   return "Enemy read you"
        }
    }

    var isPeak: Bool {
        self == .outplayed || self == .outread
    }

    static func classify(
        playerStrike: InteractiveStrikeTurn,
        opponentStrike: InteractiveStrikeTurn?
    ) -> RoundVerdict {
        let youHit  = didLand(playerStrike)
        let theyHit = opponentStrike.map { didLand($0) } ?? false

        switch (youHit, theyHit) {
        case (true,  false): return .outplayed
        case (true,  true):  return .struck
        case (false, false): return .held
        case (false, true):  return .outread
        }
    }

    private static func didLand(_ turn: InteractiveStrikeTurn) -> Bool {
        if turn.isMiss  == true { return false }
        if turn.isDodge == true { return false }
        return turn.damage > 0
    }
}
