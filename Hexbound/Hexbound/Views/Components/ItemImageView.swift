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
            Image(uiImage: image.alphaTrimmed(key: resolvedImage == nil ? imageKey : nil))
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

// MARK: - Alpha-Trim (uniform item sizing)

/// Normalized (0…1) opaque bounds per asset key, shared across UIImage
/// instances and threads. Filled by `ItemImageView.prewarm(keys:)` in the
/// background right after inventory / shop data lands, so the Hero and Shop
/// grids usually find every rect ready and only do a cheap `cropping(to:)`.
enum ItemTrimCache {
    private static let lock = NSLock()
    private static var rects: [String: CGRect] = [:]
    private static let queue = DispatchQueue(label: "app.hexbound.item-trim", qos: .utility)

    static func rect(for key: String) -> CGRect? {
        lock.lock(); defer { lock.unlock() }
        return rects[key]
    }

    static func store(_ rect: CGRect, for key: String) {
        lock.lock(); defer { lock.unlock() }
        rects[key] = rect
    }

    /// Compute trim rects for `keys` off the main thread.
    static func prewarm(keys: [String]) {
        let pending = Array(Set(keys.filter { !$0.isEmpty && rect(for: $0) == nil }))
        guard !pending.isEmpty else { return }
        queue.async {
            for key in pending where rect(for: key) == nil {
                // UIImage(named:) is thread-safe (iOS 9+).
                guard let cg = UIImage(named: key)?.cgImage,
                      let normalized = UIImage.opaqueNormalizedBounds(of: cg) else { continue }
                store(normalized, for: key)
            }
        }
    }
}

extension ItemImageView {
    /// Warm the alpha-trim cache for a batch of item image keys.
    static func prewarm(keys: [String?]) {
        ItemTrimCache.prewarm(keys: keys.compactMap { $0 })
    }
}

private var alphaTrimmedAssocKey: UInt8 = 0

extension UIImage {
    /// Returns this image cropped to the non-transparent bounding box.
    /// Used by `ItemImageView` so items with varying transparent padding
    /// inside source PNGs render at a uniform visual size when placed
    /// inside a square card frame via `.aspectRatio(.fit)`.
    ///
    /// Result is cached per-instance via associated object — the same
    /// `UIImage` pointer (e.g. AssetManager-cached) only computes once —
    /// and per asset key in `ItemTrimCache`.
    ///
    /// Latency pass (2026-10-15): the bounds scan used to draw the FULL
    /// bitmap and visit every pixel on main inside `body` (a 30-item grid
    /// paid that 30× on first open). It now reads a pre-computed rect when
    /// one exists, and otherwise scans a ≤96 px downsample — ~1–2% of the
    /// pixels, with a 1 px safety margin mapped back to full resolution.
    fileprivate func alphaTrimmed(key: String? = nil) -> UIImage {
        if let cached = objc_getAssociatedObject(self, &alphaTrimmedAssocKey) as? UIImage {
            return cached
        }
        guard let cgImage = self.cgImage else { return self }

        let normalized: CGRect?
        if let key, let known = ItemTrimCache.rect(for: key) {
            normalized = known
        } else {
            normalized = UIImage.opaqueNormalizedBounds(of: cgImage)
            if let key, let normalized { ItemTrimCache.store(normalized, for: key) }
        }

        // Fully transparent or invalid — cache self to avoid rescanning
        guard let normalized else {
            objc_setAssociatedObject(self, &alphaTrimmedAssocKey, self, .OBJC_ASSOCIATION_RETAIN)
            return self
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropRect = CGRect(
            x: (normalized.minX * width).rounded(.down),
            y: (normalized.minY * height).rounded(.down),
            width: (normalized.width * width).rounded(.up),
            height: (normalized.height * height).rounded(.up)
        ).intersection(CGRect(x: 0, y: 0, width: width, height: height))

        guard !cropRect.isEmpty, let cropped = cgImage.cropping(to: cropRect) else { return self }
        let result = UIImage(
            cgImage: cropped,
            scale: self.scale,
            orientation: self.imageOrientation
        )
        objc_setAssociatedObject(self, &alphaTrimmedAssocKey, result, .OBJC_ASSOCIATION_RETAIN)
        return result
    }

    /// Opaque bounding box of `cgImage` as a 0…1 rect (top-left origin,
    /// matching `CGImage.cropping(to:)`), or nil if fully transparent.
    /// Thread-safe: touches no shared state.
    static func opaqueNormalizedBounds(of cgImage: CGImage) -> CGRect? {
        let fullWidth = cgImage.width
        let fullHeight = cgImage.height
        guard fullWidth > 0, fullHeight > 0 else { return nil }

        let maxSide = 96
        let factor = min(1.0, Double(maxSide) / Double(max(fullWidth, fullHeight)))
        let width = max(1, Int((Double(fullWidth) * factor).rounded(.up)))
        let height = max(1, Int((Double(fullHeight) * factor).rounded(.up)))

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .medium
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = ctx.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: height * bytesPerRow)

        var minX = width
        var maxX = -1
        var minY = height
        var maxY = -1
        let alphaThreshold: UInt8 = 16

        // Bitmap rows run top → bottom in memory, same as cropping(to:).
        for y in 0..<height {
            let rowStart = y * bytesPerRow
            for x in 0..<width where pixels[rowStart + x * bytesPerPixel + 3] > alphaThreshold {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }

        // 1 px margin in the downsample so resampling never clips an edge.
        let x0 = max(0, minX - 1)
        let y0 = max(0, minY - 1)
        let x1 = min(width, maxX + 2)
        let y1 = min(height, maxY + 2)
        return CGRect(
            x: Double(x0) / Double(width),
            y: Double(y0) / Double(height),
            width: Double(x1 - x0) / Double(width),
            height: Double(y1 - y0) / Double(height)
        )
    }
}
