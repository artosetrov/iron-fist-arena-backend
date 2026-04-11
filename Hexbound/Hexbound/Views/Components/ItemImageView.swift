import SwiftUI
import UIKit

/// Reusable item image view with 3-tier fallback chain via AssetManager:
/// 1. `imageKey` → bundle asset OR disk cache (instant, offline)
/// 2. `imageUrl` → network download via AssetManager (cached to disk for next time)
/// 3. `systemIcon` + `systemIconColor` → SF Symbol (e.g. consumable icons)
/// 4. `placeholderIcon` → DS-compliant placeholder
///
/// **Uniform item size:** UIImages are alpha-trimmed to their opaque bounding box
/// before display, so items with varying transparent padding inside source PNGs
/// render at the same visual size inside the parent frame. Trim result is cached
/// per UIImage instance via associated object (computed once per asset).
struct ItemImageView: View {
    let imageKey: String?
    let imageUrl: String?
    var systemIcon: String? = nil
    var systemIconColor: Color? = nil
    var placeholderIcon: String = "questionmark"

    @State private var resolvedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        if let image = resolvedImage ?? AssetManager.shared.image(forKey: imageKey) {
            Image(uiImage: image.alphaTrimmed())
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else if isLoading {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .overlay {
                    HexPulseLoader(.compact)
                        .tint(DarkFantasyTheme.textTertiary)
                        .scaleEffect(0.6)
                }
        } else if let sfIcon = systemIcon {
            Image(systemName: sfIcon)
                .font(DarkFantasyTheme.title)
                .foregroundStyle(systemIconColor ?? DarkFantasyTheme.gold)
        } else {
            AssetPlaceholderView(systemIcon: placeholderIcon)
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

// MARK: - Alpha-Trim Extension (uniform item sizing)

private var alphaTrimmedAssocKey: UInt8 = 0

extension UIImage {
    /// Returns this image cropped to the non-transparent bounding box.
    /// Used by `ItemImageView` so items with varying transparent padding
    /// inside source PNGs render at a uniform visual size when placed
    /// inside a square card frame via `.aspectRatio(.fit)`.
    ///
    /// Result is cached per-instance via associated object — the same
    /// `UIImage` pointer (e.g. AssetManager-cached) only computes once.
    /// Scans pixels on the calling thread; expected source ≤256×256.
    fileprivate func alphaTrimmed() -> UIImage {
        if let cached = objc_getAssociatedObject(self, &alphaTrimmedAssocKey) as? UIImage {
            return cached
        }
        guard let cgImage = self.cgImage else { return self }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return self }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = ctx.data else { return self }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width
        var maxX = -1
        var minY = height
        var maxY = -1
        let alphaThreshold: UInt8 = 16

        for y in 0..<height {
            let rowStart = y * bytesPerRow
            for x in 0..<width {
                let alpha = pixels[rowStart + x * bytesPerPixel + 3]
                if alpha > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        // Fully transparent or invalid — cache self to avoid rescanning
        guard maxX >= minX, maxY >= minY else {
            objc_setAssociatedObject(self, &alphaTrimmedAssocKey, self, .OBJC_ASSOCIATION_RETAIN)
            return self
        }

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return self }
        let result = UIImage(
            cgImage: cropped,
            scale: self.scale,
            orientation: self.imageOrientation
        )
        objc_setAssociatedObject(self, &alphaTrimmedAssocKey, result, .OBJC_ASSOCIATION_RETAIN)
        return result
    }
}
