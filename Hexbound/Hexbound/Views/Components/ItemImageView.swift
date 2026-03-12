import SwiftUI

/// Reusable item image view with local-asset-first fallback chain:
/// 1. `imageKey` → local asset from bundle (instant, offline)
/// 2. `imageUrl` → remote AsyncImage (network, cached by URLSession)
/// 3. `fallbackIcon` → emoji/text icon
struct ItemImageView: View {
    let imageKey: String?
    let imageUrl: String?
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
        } else {
            Text(fallbackIcon)
                .font(.system(size: 32))
        }
    }
}
