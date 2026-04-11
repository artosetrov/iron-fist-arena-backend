import Foundation

/// Common read-only shape used by UI that renders a character portrait + equipment card.
/// Conformed to by both `Character` (own hero) and `OpponentProfile` (other player).
///
/// Reusability rule #1: UI components must depend on this protocol, NOT on concrete
/// model types, so a single `IntegratedCharacterCard` can render both hero and opponent.
///
/// Variable data that isn't present on both sides (XP, stat points, gold, gems, rank/rating)
/// is NOT part of this protocol — it is injected into the card via ViewBuilder slots by the
/// call site (see `IntegratedCharacterCard.portraitInfo` and `footer`).
protocol CharacterDisplay {
    var characterName: String { get }
    var characterClass: CharacterClass { get }
    var avatar: String? { get }
    var level: Int { get }
    var currentHp: Int { get }
    var maxHp: Int { get }
    var hpPercentage: Double { get }
    var prestigeLevel: Int? { get }
}

// MARK: - Character conformance

extension Character: CharacterDisplay {
    /// `Character.prestige` is stored as `prestige` but serialized as `prestigeLevel`.
    /// Expose it under the protocol name so both conformers read the same way from UI.
    var prestigeLevel: Int? { prestige }
}

// MARK: - OpponentProfile conformance

extension OpponentProfile: CharacterDisplay {
    // All required members already exist with matching names — no bridging needed.
}
