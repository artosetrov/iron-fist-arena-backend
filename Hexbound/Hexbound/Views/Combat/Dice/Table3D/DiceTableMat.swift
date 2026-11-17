//
//  DiceTableMat.swift
//  Hexbound
//
//  The table a dice duel is fought on — always the defender's. The server
//  picks it (`dice_table` in /pvp/match/start, backend lib/game/dice-tables.ts);
//  `resolve` mirrors that rule for older servers that don't send it.
//  Art: Assets.xcassets/DiceMats/dice-mat-*.imageset (pen-and-ink, top-down,
//  prompts in docs/06_game_systems/DICE_3D_THROW.md §7).
//

import UIKit

enum DiceTableMat: String, CaseIterable, Sendable {
    case tavern, warrior, rogue, mage, tank, arena, dungeon, dragon, frost, royal

    var asset: String { "dice-mat-\(rawValue)" }

    /// Multiplier on the felt so the pale mats don't burn out under the key light.
    var tint: CGFloat {
        switch self {
        case .tank: return 0.72
        case .arena: return 0.78
        case .frost: return 0.66
        case .warrior: return 0.84
        case .dragon: return 0.9
        case .royal: return 0.92
        default: return 1
        }
    }

    static func resolve(serverKey: String?,
                        opponentType: InteractiveOpponentType,
                        defenderClass: CharacterClass?) -> DiceTableMat {
        if let serverKey, let mat = DiceTableMat(rawValue: serverKey) { return mat }
        switch opponentType {
        case .dungeonBoss: return .dragon
        case .dungeonRush: return .dungeon
        case .pvp, .bot:
            switch defenderClass {
            case .warrior: return .warrior
            case .rogue: return .rogue
            case .mage: return .mage
            case .tank: return .tank
            default: return .tavern
            }
        }
    }
}
