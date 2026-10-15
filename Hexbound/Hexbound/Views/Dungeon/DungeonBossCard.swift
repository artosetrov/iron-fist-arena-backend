import SwiftUI

// MARK: - Boss art primitives
//
// Every boss has two pieces of art (see `EnemyPortraitResolver`): a portrait
// (head & shoulders) for medallions and result cards, and a full-body cutout
// for anything that puts the boss on a stage. These views are the shared
// building blocks of the dungeon flow — the dungeon screen, the pre-fight
// intro, the dossier, dice combat, the killing blow and the victory screen
// all stand the same boss on the same lit floor.
//
// This file used to hold `DungeonBossCard`, the 2-column grid cell the
// dungeon stage replaced (2026-10-15).

/// How a boss is drawn: lit, dimmed after defeat, a silhouette while
/// locked, or `hit` — the boss's shape in solid red, laid over the lit art
/// for the hit flash in combat.
enum BossArtStyle {
    case lit
    case defeated
    case silhouette
    case hit

    init(_ state: BossState) {
        switch state {
        case .current: self = .lit
        case .defeated: self = .defeated
        case .locked: self = .silhouette
        }
    }
}

/// One piece of boss art in a given style. The art is a transparent cutout,
/// so a template render of it is a clean silhouette.
struct BossArtImage: View {
    enum Kind { case full, portrait }

    let boss: BossInfo
    var kind: Kind = .full
    var style: BossArtStyle = .lit
    var contentMode: ContentMode = .fit

    private var asset: String? {
        kind == .full
            ? EnemyPortraitResolver.fullBodyAsset(boss)
            : EnemyPortraitResolver.portraitAsset(boss)
    }

    var body: some View {
        if let asset {
            switch style {
            case .lit:
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
            case .defeated:
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
                    .grayscale(1)
                    .brightness(-0.2)
            case .silhouette:
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
                    .foregroundStyle(DarkFantasyTheme.bgTertiary)
            case .hit:
                Image(asset)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
                    .foregroundStyle(DarkFantasyTheme.danger)
            }
        } else {
            AssetPlaceholderView(systemIcon: "flame.fill")
        }
    }
}

/// Full-body boss standing in a pool of light on a dark floor. Static light
/// only — no idle glow, no pulsing.
struct BossStageArt: View {
    let boss: BossInfo
    var style: BossArtStyle = .lit
    /// Face left, the enemy side in combat.
    var mirrored: Bool = false
    var light: Color = DarkFantasyTheme.gold
    /// Combat hit flash: the boss's own shape washes red for a beat.
    var hitFlash: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .bottom) {
                // Pool of light behind the figure
                RadialGradient(
                    colors: [
                        light.opacity(style == .lit ? 0.28 : 0.10),
                        light.opacity(style == .lit ? 0.08 : 0.03),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.55),
                    startRadius: 0,
                    endRadius: max(w, h) * 0.5
                )
                .frame(width: w, height: h)

                // Contact shadow on the floor
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [DarkFantasyTheme.bgAbyss.opacity(0.9), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.32
                        )
                    )
                    .frame(width: w * 0.64, height: max(12, h * 0.08))

                BossArtImage(boss: boss, kind: .full, style: style)
                    .overlay {
                        BossArtImage(boss: boss, kind: .full, style: .hit)
                            .opacity(hitFlash ? 0.45 : 0)
                            .animation(.easeOut(duration: 0.12), value: hitFlash)
                            .allowsHitTesting(false)
                    }
                    .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                    .frame(width: w * 0.92, height: h * 0.95, alignment: .bottom)
                    .padding(.bottom, h * 0.03)
            }
            .frame(width: w, height: h)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(style == .silhouette ? "Unknown enemy" : boss.name))
    }
}

/// Round portrait medallion used on the dungeon path, the victory screen and
/// teasers. Defeated bosses go grey with a check, locked ones are silhouettes.
struct BossMedallion: View {
    let boss: BossInfo
    let state: BossState
    let size: CGFloat
    var isSelected: Bool = false

    private var ringColor: Color {
        switch state {
        case .defeated: return DarkFantasyTheme.success
        case .current: return DarkFantasyTheme.goldBright
        case .locked: return isSelected ? DarkFantasyTheme.textSecondary : DarkFantasyTheme.borderMedium
        }
    }

    var body: some View {
        ZStack {
            Circle().fill(DarkFantasyTheme.bgSecondary)
            BossArtImage(boss: boss, kind: .portrait, style: BossArtStyle(state), contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(ringColor, lineWidth: state == .current || isSelected ? 2.5 : 1.5)
        )
        .overlay(alignment: .bottomTrailing) {
            if state == .defeated {
                Image(systemName: "checkmark")
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.bgAbyss)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(DarkFantasyTheme.success))
                    .offset(x: 4, y: 4)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// The dungeon as a path of medallions: defeated, the current boss (larger),
/// then silhouettes. Tapping a medallion puts that boss on the stage.
struct BossPathRow: View {
    let bosses: [BossInfo]
    let state: (Int) -> BossState
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    private let smallSize: CGFloat = 30
    private let currentSize: CGFloat = 46

    var body: some View {
        let currentIndex = bosses.indices.first { state($0) == .current }
        HStack(spacing: 0) {
            ForEach(Array(bosses.enumerated()), id: \.element.id) { index, boss in
                let s = state(index)
                Button {
                    onSelect(index)
                } label: {
                    BossMedallion(
                        boss: boss,
                        state: s,
                        size: s == .current ? currentSize : smallSize,
                        isSelected: index == selectedIndex
                    )
                    .frame(maxWidth: .infinity, minHeight: LayoutConstants.touchMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(medallionLabel(boss: boss, index: index, state: s)))
                .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            }
        }
        .background(alignment: .center) {
            GeometryReader { geo in
                let step = geo.size.width / CGFloat(max(bosses.count, 1))
                let reached = CGFloat(currentIndex ?? bosses.count - 1)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DarkFantasyTheme.borderMedium)
                        .frame(height: 2)
                    Rectangle()
                        .fill(DarkFantasyTheme.gold)
                        .frame(width: max(0, step * reached), height: 2)
                }
                .padding(.horizontal, step / 2)
                .frame(maxHeight: .infinity)
            }
            .allowsHitTesting(false)
        }
    }

    private func medallionLabel(boss: BossInfo, index: Int, state: BossState) -> String {
        switch state {
        case .defeated: return "Stage \(index + 1), \(boss.name), defeated"
        case .current: return "Stage \(index + 1), \(boss.name), next fight"
        case .locked: return "Stage \(index + 1), locked"
        }
    }
}

extension BossInfo {
    /// One-line hook for stage and teaser copy: the authored tagline, else
    /// the description when it is short, else its first sentence.
    var hookLine: String {
        if let tagline, !tagline.isEmpty { return tagline }
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count <= 110 { return text }
        if let end = text.firstIndex(where: { ".!?".contains($0) }) {
            return String(text[...end])
        }
        return text
    }
}
