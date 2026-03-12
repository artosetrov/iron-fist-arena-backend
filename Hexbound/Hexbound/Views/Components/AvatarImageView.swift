import SwiftUI

/// Reusable avatar image that resolves the character's skinKey via GameDataCache.
/// Falls back to the class icon when no skin image is available.
struct AvatarImageView: View {
    @Environment(GameDataCache.self) private var cache

    let skinKey: String?
    let characterClass: CharacterClass
    let size: CGFloat

    var body: some View {
        if let key = cache.skinImageKey(for: skinKey), UIImage(named: key) != nil {
            // Local bundled asset — instant, offline
            Image(key)
                .resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipped()
        } else if let url = cache.skinImageURL(for: skinKey) {
            // Remote fallback
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    fallbackIcon
                case .empty:
                    ProgressView().tint(DarkFantasyTheme.textTertiary)
                @unknown default:
                    fallbackIcon
                }
            }
            .frame(width: size, height: size)
            .clipped()
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Text(characterClass.icon)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
    }
}
