import SwiftUI

/// The project's stacking scale, for `.zIndex(_:)` **inside a screen**.
///
/// Before this existed the numbers were invented per file: 10, 100, 200, 900
/// and 999 all appear, and nothing said how they related. Worse, four of them
/// could never have had any effect — see the note below.
///
/// ## Where `.zIndex` works and where it does not
///
/// `.zIndex` only orders *siblings inside one stacking context*. A `ZStack`
/// with several children is such a context, so a screen that layers content,
/// a HUD and a modal can order them with these constants.
///
/// `.overlay { }` is **not**: each one wraps a single child in its own
/// context, so a `.zIndex` inside it is compared against nothing and does
/// nothing. A chain of `.overlay` modifiers is ordered purely by the order
/// the modifiers are written — later means on top. `App/HexboundApp.swift`
/// is that case, and it says so there instead of carrying numbers that look
/// like they decide something.
enum ZLayer {
    /// Screen content. The default; rarely written out.
    static let content: Double = 0
    /// A screen's own HUD or header, kept above content that animates
    /// underneath it (the hub map, a scrolling list).
    static let hud: Double = 10
    /// In-screen modals, sheets and hint overlays — `GameModal` call sites,
    /// NPC hints, the contextual-hint overlay, detail sheets.
    static let modal: Double = 100
    /// A reward or unlock ceremony, which has to sit above a modal that is
    /// already open (claiming from an item sheet, a building unlocking over
    /// the hub).
    static let ceremony: Double = 200
    /// A full-screen takeover owned by one screen rather than by the app
    /// root — the gold mine's shaft picker.
    static let takeover: Double = 900
}
