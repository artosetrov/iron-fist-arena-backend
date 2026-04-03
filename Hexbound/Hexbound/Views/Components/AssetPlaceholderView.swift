import SwiftUI

/// Universal DS-compliant placeholder for missing image assets.
/// Replaces all emoji fallbacks across the app.
///
/// Usage:
/// ```swift
/// AssetPlaceholderView()                          // default: "?" icon
/// AssetPlaceholderView(systemIcon: "shield.fill") // custom SF Symbol
/// ```
struct AssetPlaceholderView: View {
    var systemIcon: String = "questionmark"
    var iconScale: CGFloat = 0.35

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgTertiary)

                Image(systemName: systemIcon)
                    .font(.system(size: max(size * iconScale, 11), weight: .medium, design: .rounded))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
    }
}
