import SwiftUI

/// Reusable avatar image that resolves the character's skinKey via GameDataCache + AssetManager.
/// Uses 3-tier resolution: bundle → disk cache → network.
///
/// When `skinKey` cannot be resolved and a `deterministicSeed` is provided, the view picks a
/// stable portrait from a per-class skin pool (deterministic via the seed hash). Only when
/// both the primary skin and the pool fallback fail does it show the class icon fallback.
struct AvatarImageView: View {
    @Environment(GameDataCache.self) private var cache

    let skinKey: String?
    let characterClass: CharacterClass
    let size: CGFloat
    /// Stable seed (e.g. character id) used to pick a deterministic pool portrait when
    /// the primary skinKey cannot be resolved. If nil, falls through to the class icon.
    var deterministicSeed: String? = nil

    @State private var resolvedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        let resolvedKey = cache.skinImageKey(for: skinKey)
        if let image = resolvedImage ?? AssetManager.shared.image(forKey: resolvedKey) {
            renderedImage(image)
        } else if let poolKey = classPoolKey,
                  let poolImage = AssetManager.shared.image(forKey: poolKey) {
            // Deterministic class-based pool fallback
            renderedImage(poolImage)
        } else if isLoading {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(width: size, height: size)
                .overlay {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textTertiary)
                        .scaleEffect(0.6)
                }
        } else {
            fallbackIcon
        }
    }

    // MARK: - Rendered Image

    private func renderedImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()
    }

    // MARK: - Class Pool Fallback

    /// Resolved asset key from the per-class skin pool, picked deterministically by seed.
    private var classPoolKey: String? {
        guard let seed = deterministicSeed else { return nil }
        let pool = Self.skinPool(for: characterClass)
        guard !pool.isEmpty else { return nil }
        let idx = Self.stableHash(seed) % pool.count
        return pool[idx]
    }

    /// Unified pool of bundled hero portraits used as random-but-stable avatars for
    /// opponents that do not have a dedicated skin. Sourced from `Assets.xcassets/Skins/`
    /// (`hero_portrait_01` … `hero_portrait_16`) — see `docs/07_ui_ux/ASSET_CONSISTENCY_AUDIT.md`.
    ///
    /// The pool is class-agnostic by design: backend bots often don't carry a gender/
    /// class-appropriate skin key, and deterministic seed-hash picking keeps the same
    /// opponent id → same portrait across sessions, so varying per class adds no value.
    private static func skinPool(for characterClass: CharacterClass) -> [String] {
        heroPortraitPool
    }

    /// Shared hero portrait pool. 16 portraits is enough for visual variety on any
    /// single Arena/Leaderboard screen (≤ 6 opponents visible) while keeping bundle
    /// size small. If you grow this, bump the last index here and add matching
    /// imagesets under `Assets.xcassets/Skins/`.
    private static let heroPortraitPool: [String] = (1...16).map {
        String(format: "hero_portrait_%02d", $0)
    }

    /// Stable djb2 hash — unlike Swift's `String.hashValue`, this is deterministic across
    /// process launches, so the same character always gets the same portrait.
    private static func stableHash(_ s: String) -> Int {
        var h = 5381
        for scalar in s.unicodeScalars {
            h = ((h << 5) &+ h) &+ Int(scalar.value)
        }
        return abs(h)
    }

    // MARK: - Class Icon Fallback

    private var fallbackIcon: some View {
        // Show class icon instead of generic shield when no avatar is available
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
            Image(characterClass.iconAsset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size * 0.5, height: size * 0.5)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(width: size, height: size)
            .task {
                // Try to fetch from network in background
                let resolvedKey = cache.skinImageKey(for: skinKey)
                let resolvedURL = cache.skinImageURL(for: skinKey)?.absoluteString
                guard resolvedKey != nil || resolvedURL != nil else { return }

                isLoading = true
                resolvedImage = await AssetManager.shared.fetchIfNeeded(
                    key: resolvedKey,
                    url: resolvedURL
                )
                isLoading = false
            }
    }
}
