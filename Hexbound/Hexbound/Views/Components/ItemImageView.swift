import SwiftUI

/// Reusable item image view with 3-tier fallback chain via AssetManager:
/// 1. `imageKey` → bundle asset OR disk cache (instant, offline)
/// 2. `imageUrl` → network download via AssetManager (cached to disk for next time)
/// 3. `systemIcon` + `systemIconColor` → SF Symbol (e.g. consumable icons)
/// 4. `fallbackIcon` → emoji/text icon
struct ItemImageView: View {
    let imageKey: String?
    let imageUrl: String?
    var systemIcon: String? = nil
    var systemIconColor: Color? = nil
    let fallbackIcon: String

    @State private var resolvedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        if let image = resolvedImage ?? AssetManager.shared.image(forKey: imageKey) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if isLoading {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .overlay {
                    ProgressView()
                        .tint(DarkFantasyTheme.textTertiary)
                        .scaleEffect(0.6)
                }
        } else if let sfIcon = systemIcon {
            Image(systemName: sfIcon)
                .font(.system(size: 32))
                .foregroundStyle(systemIconColor ?? DarkFantasyTheme.gold)
        } else {
            Text(fallbackIcon)
                .font(.system(size: 32))
        }
    }

    /// Triggers background fetch if not in bundle/cache
    func loadImage() async {
        // Already have it
        if AssetManager.shared.image(forKey: imageKey) != nil { return }

        // Need network fetch
        guard imageKey != nil || imageUrl != nil else { return }
        isLoading = true
        resolvedImage = await AssetManager.shared.fetchIfNeeded(key: imageKey, url: imageUrl)
        isLoading = false
    }
}

extension ItemImageView {
    /// Modifier that triggers async loading. Apply to the view: `ItemImageView(...).autoLoad()`
    func autoLoad() -> some View {
        self.task(id: imageKey ?? imageUrl ?? "") {
            await loadImage()
        }
    }
}
