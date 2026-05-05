//
//  ActiveSlotTile.swift
//  Hexbound
//
//  Shared visual primitive for the Active Skills loadout slot. Used in:
//    • TalentsSummaryCard.activeSkillsRow — Hero / Talents tab editor
//    • ActiveSkillsHUD                     — combat predict screen HUD
//    • InteractiveBattleView Strike screen — 4th consumable slot stub
//
//  The two existing surfaces used to ship parallel slot rendering with
//  drifting chrome (different border thickness, different empty-state
//  affordance, different number style). This file unifies the chrome
//  and lets each surface compose its own optional overlays (cooldown
//  timer for combat, premium gem cost for talents, etc.) via a
//  ViewBuilder.
//
//  Project rule (memory `feedback_reusability_first_rule`):
//  reusability of components across everything is the #1 project rule —
//  never duplicate UI, always extract.
//
//  Sizing: aspect-ratio 1:1; the tile fills whatever frame the parent
//  gives it. Combat HUD locks at 56×56 pt; talents grid stretches to
//  available width.
//

import SwiftUI

// MARK: - State + Icon

/// What the slot represents at a moment in time. Determines border
/// style, fill, and base icon. Combat-specific transient states
/// (cooldown countdown, armed border, "USED" overlay, …) ride on top
/// via the `overlay` ViewBuilder so they don't bloat this enum.
enum ActiveSlotTileState {
    /// Unequipped slot the player can tap to open the picker.
    /// Renders as dashed border + plus icon (talents-page semantics).
    case empty
    /// Slot exists but cannot be configured in the current context
    /// (e.g. the combat HUD shows locked/unavailable slots this way
    /// instead of the inviting "+" affordance). Padlock icon + dim.
    case locked
    /// Slot is populated with a talent or a consumable. Renders as
    /// gold border + 3 pt gold left bar + the supplied icon.
    case filled(ActiveSlotTileIcon)
    /// Slot is reserved as a premium upsell (4th talent slot before
    /// it is unlocked with gems). Renders as purple-tinted card with
    /// a gem glyph + cost.
    case premium(gemCost: Int)
}

/// Icon source for `.filled` slots. Surfaces choose between an asset
/// catalog image (e.g. consumable bottle art) or an SF Symbol fallback
/// (talent action verbs). Per project rule, prefer asset over symbol
/// when the asset exists.
enum ActiveSlotTileIcon: Equatable {
    case asset(String)         // bundle asset name; consumable bottles, etc.
    case sfSymbol(String)      // SF Symbol name; talent action fallback
}

// MARK: - Tile

struct ActiveSlotTile<Overlay: View>: View {
    /// 0-indexed slot position. Renders as zero-padded "01"…"04" in
    /// the top-leading corner of the tile.
    let slotNumber: Int
    let state: ActiveSlotTileState
    /// True when the host disables the whole row (e.g. talents
    /// `vm.isMutating`). Combat doesn't use it.
    var isDisabled: Bool = false
    let action: () -> Void
    /// Combat-specific overlays — cooldown countdown, armed border,
    /// "USED" stamp. Talents pages pass `EmptyView()`.
    @ViewBuilder var overlay: () -> Overlay

    private var displayNumber: String {
        String(format: "%02d", slotNumber + 1)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                base
                iconLayer
                if case .filled = state {
                    leftBar
                }
                slotNumberLabel
                overlay()
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || tapDisabled)
    }

    /// `.locked` slots aren't tappable — they signal "not configurable
    /// here" rather than "tap to equip". Other states accept taps.
    private var tapDisabled: Bool {
        if case .locked = state { return true }
        return false
    }

    // MARK: - Layered body

    @ViewBuilder
    private var base: some View {
        switch state {
        case .empty:
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgPrimary)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .strokeBorder(
                        DarkFantasyTheme.borderSubtle,
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                    )
            }

        case .locked:
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.bgElevated)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .strokeBorder(
                        DarkFantasyTheme.borderSubtle,
                        lineWidth: 1
                    )
            }

        case .filled:
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(
                        LinearGradient(
                            colors: [
                                DarkFantasyTheme.gold.opacity(0.18),
                                DarkFantasyTheme.gold.opacity(0.05)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .strokeBorder(DarkFantasyTheme.gold, lineWidth: 1.5)
            }

        case .premium:
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(
                        LinearGradient(
                            colors: [
                                Self.premiumAccent.opacity(0.08),
                                Self.premiumAccent.opacity(0.02)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .strokeBorder(Self.premiumAccent.opacity(0.35), lineWidth: 1.5)
            }
        }
    }

    @ViewBuilder
    private var iconLayer: some View {
        switch state {
        case .empty:
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .frame(width: 16, height: 16)

        case .locked:
            // Padlock asset (interactive combat v3) with SF Symbol
            // fallback. Mirrors the original ActiveSkillsHUD rendering
            // so the combat HUD looks identical to before the extract.
            CachedAssetImage(
                key: "icon-padlock",
                url: nil,
                systemIcon: "lock.fill",
                contentMode: .fit
            )
            .frame(width: 22, height: 22)
            .foregroundStyle(DarkFantasyTheme.textDisabled)
            .opacity(0.6)

        case .filled(let icon):
            switch icon {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            case .sfSymbol(let name):
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .frame(width: 20, height: 20)
            }

        case .premium(let gemCost):
            VStack(spacing: LayoutConstants.spaceXS) {
                // Diamond-shaped gem (matches TalentsSummaryCard.premiumSlotTile
                // visual exactly — no token exists for this purple gradient).
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.83, green: 0.63, blue: 0.94),
                                Color(red: 0.60, green: 0.36, blue: 0.78),
                                Color(red: 0.35, green: 0.16, blue: 0.54)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(45))
                    .shadow(color: Self.premiumAccent.opacity(0.5), radius: 6)
                Text("\(gemCost)")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(Self.premiumAccent)
            }
        }
    }

    /// 3 pt gold left bar — matches item-card DNA + the historical
    /// `TalentsSummaryCard.filledSlotTile` chrome. Skipped for empty
    /// / locked / premium states.
    private var leftBar: some View {
        HStack(spacing: 0) {
            UnevenRoundedRectangle(
                topLeadingRadius: LayoutConstants.radiusMD,
                bottomLeadingRadius: LayoutConstants.radiusMD
            )
            .fill(DarkFantasyTheme.gold)
            .frame(width: 3)
            Spacer(minLength: 0)
        }
    }

    private var slotNumberLabel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(displayNumber)
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(slotNumberColor)
                    .padding(.leading, LayoutConstants.spaceXS)
                    .padding(.top, LayoutConstants.spaceXS)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
    }

    private var slotNumberColor: Color {
        switch state {
        case .empty:                 return DarkFantasyTheme.textDisabled
        case .locked:                return DarkFantasyTheme.textDisabled
        case .filled:                return DarkFantasyTheme.gold
        case .premium:               return Self.premiumAccent.opacity(0.8)
        }
    }

    /// Epic/purple premium accent — mirror of the inline value from
    /// `TalentsSummaryCard.premiumAccent`. No DarkFantasyTheme token
    /// exists for this rarity-epic shade today.
    static let premiumAccent: Color = Color(red: 0.71, green: 0.49, blue: 0.84)
}

// MARK: - Convenience init

extension ActiveSlotTile where Overlay == EmptyView {
    /// Convenience init for surfaces that don't need any combat
    /// overlays (talents page, locked stub slots in combat).
    init(
        slotNumber: Int,
        state: ActiveSlotTileState,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            slotNumber: slotNumber,
            state: state,
            isDisabled: isDisabled,
            action: action,
            overlay: { EmptyView() }
        )
    }
}
