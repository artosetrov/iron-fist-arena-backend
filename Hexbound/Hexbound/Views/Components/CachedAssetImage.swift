import SwiftUI

/// Drop-in replacement for `AsyncImage` that uses the 3-tier asset resolution chain:
/// Bundle → Disk Cache → Network (via `AssetManager`).
///
/// Shows the image instantly if available in bundle or cache.
/// Triggers a background download if only available on network.
///
/// Usage:
/// ```swift
/// CachedAssetImage(key: item.imageKey, url: item.imageUrl, fallback: "⚔️")
///     .frame(width: 64, height: 64)
///     .clipShape(RoundedRectangle(cornerRadius: 8))
/// ```
struct CachedAssetImage: View {
    let key: String?
    let url: String?
    let fallback: String
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage ?? AssetManager.shared.image(forKey: key) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                // Skeleton placeholder while downloading
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)
                    .overlay {
                        ProgressView()
                            .tint(DarkFantasyTheme.textTertiary)
                            .scaleEffect(0.7)
                    }
            } else {
                // Fallback emoji/text
                Text(fallback)
                    .font(.system(size: 32))
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
            fallback: characterClass.icon
        )
        .frame(width: size, height: size)
        .clipped()
    }
}
