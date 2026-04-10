import SwiftUI

/// Reusable avatar image that resolves the character's skinKey via GameDataCache + AssetManager.
/// Uses 3-tier resolution: bundle → disk cache → network.
/// Falls back to the class icon when no skin image is available.
struct AvatarImageView: View {
    @Environment(GameDataCache.self) private var cache

    let skinKey: String?
    let characterClass: CharacterClass
    let size: CGFloat

    @State private var resolvedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        let resolvedKey = cache.skinImageKey(for: skinKey)
        if let image = resolvedImage ?? AssetManager.shared.image(forKey: resolvedKey) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
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
