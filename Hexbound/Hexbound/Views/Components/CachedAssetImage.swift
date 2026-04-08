import SwiftUI

/// Drop-in replacement for `AsyncImage` that uses the 3-tier asset resolution chain:
/// Bundle → Disk Cache → Network (via `AssetManager`).
///
/// Shows the image instantly if available in bundle or cache.
/// Triggers a background download if only available on network.
///
/// Usage:
/// ```swift
/// CachedAssetImage(key: item.imageKey, url: item.imageUrl, systemIcon: "shield.fill")
///     .frame(width: 64, height: 64)
///     .clipShape(RoundedRectangle(cornerRadius: 8))
/// ```
struct CachedAssetImage: View {
    let key: String?
    let url: String?
    var systemIcon: String = "questionmark"
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage ?? AssetManager.shared.image(forKey: key) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                // Skeleton placeholder while downloading
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay {
                        HexPulseLoader(.compact)
                            .tint(DarkFantasyTheme.textTertiary)
                            .scaleEffect(0.7)
                    }
            } else {
                // Fallback asset placeholder
                AssetPlaceholderView(systemIcon: systemIcon)
            }
        }
        .task(id: key) {
            // Try to resolve from AssetManager caches first
            if let key, AssetManager.shared.image(forKey: key) != nil {
                return // Already available
            }

            // Need to fetch from network
            isLoading = true
            loadedImage = await AssetManager.shared.fetchIfNeeded(key: key, url: url)
            isLoading = false
        }
    }
}

/// Convenience variant for avatar/skin images that resolves via GameDataCache
struct CachedAvatarImage: View {
    @Environment(GameDataCache.self) private var cache

    let skinKey: String?
    let characterClass: CharacterClass
    let size: CGFloat

    var body: some View {
        let resolvedKey = cache.skinImageKey(for: skinKey)
        let resolvedURL = cache.skinImageURL(for: skinKey)?.absoluteString

        CachedAssetImage(
            key: resolvedKey,
            url: resolvedURL,
            systemIcon: "shield.fill"
        )
        .frame(width: size, height: size)
        .clipped()
    }
}
