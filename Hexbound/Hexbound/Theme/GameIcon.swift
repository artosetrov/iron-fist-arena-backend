import SwiftUI

/// SF Symbol names that the game refers to by meaning rather than by symbol.
///
/// This exists because of one bug. `"swords"` is not an SF Symbol — it never
/// has been — and thirteen surfaces passed it to `Image(systemName:)`: the
/// arena empty state and opponent cards, both hub battle banners, the guild
/// hall's duel list and its accept button, two inbox rows, the combat
/// preparation screen, the BACK TO ARENA button on the result screen, the
/// achievement card for the PvP category, the dungeon rush combat room and
/// the combat NPC hint. Every one of them rendered nothing, and the only
/// trace was a console line — `No symbol named 'swords' found in system
/// symbol set` — which is easy to scroll past.
///
/// A name that does not resolve costs nothing at compile time, so the
/// compiler cannot help here. Naming the few symbols the game picks by
/// meaning at least puts the next wrong guess in one place.
enum GameIcon {
    /// Battle, duel, PvP. SF Symbols has no crossed swords; the fencing
    /// figure is the closest thing that exists. Swap this one line if the
    /// art team would rather use `icon-fights` from the asset catalogue —
    /// note that an asset `Image` needs `.resizable()` and a frame, where
    /// a symbol takes `.font()`.
    static let battle = "figure.fencing"
}
