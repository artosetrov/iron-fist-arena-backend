import SwiftUI

/// Reusable item image view with local-asset-first fallback chain:
/// 1. `imageKey` → local asset from bundle (instant, offline)
/// 2. `imageUrl` → remote AsyncImage (network, cached by URLSession)
/// 3. `systemIcon` + `systemIconColor` → SF Symbol (e.g. consumable icons)
/// 4. `fallbackIcon` → emoji/text icon
struct ItemImageView: View {
    let imageKey: String?
    let imageUrl: String?
    var systemIcon: String? = nil
    var systemIconColor: Color? = nil
    let fallbackIcon: String

    var body: some View {
        if let key = imageKey, UIImage(named: key) != nil {
            Image(key)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let urlStr = imageUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Text(fallbackIcon).font(.system(size: 32))
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
}
