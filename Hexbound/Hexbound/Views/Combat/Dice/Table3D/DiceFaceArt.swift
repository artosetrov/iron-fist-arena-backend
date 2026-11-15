//
//  DiceFaceArt.swift
//  Hexbound
//
//  Face textures for the 3D dice: the same pieces DiceDieView stacks in 2D
//  (face tile, zone emblem, socketed rune stone), flattened into one image
//  per face. The corners are filled with the die body colour so the art
//  plane can stay opaque.
//

import RealityKit
import UIKit

@MainActor
enum DiceFaceArt {
    private static var cache: [String: TextureResource] = [:]
    private static let pixels: CGFloat = 384

    /// Body colour of each die — the metal around the face art.
    static func bodyColor(_ kind: DiceKind) -> UIColor {
        kind == .attack
            ? UIColor(red: 0.25, green: 0.16, blue: 0.12, alpha: 1)
            : UIColor(red: 0.14, green: 0.16, blue: 0.23, alpha: 1)
    }

    /// Texture for one server face (0…5) of a die, with its rune if any.
    static func texture(kind: DiceKind, serverFace: Int, runeAsset: String?) -> TextureResource? {
        let key = "\(kind.rawValue)|\(serverFace)|\(runeAsset ?? "-")"
        if let hit = cache[key] { return hit }
        guard let cg = image(kind: kind, serverFace: serverFace, runeAsset: runeAsset).cgImage else { return nil }
        guard let tex = try? TextureResource.generate(from: cg, options: .init(semantic: .color)) else { return nil }
        cache[key] = tex
        return tex
    }

    static func image(kind: DiceKind, serverFace: Int, runeAsset: String?) -> UIImage {
        let size = CGSize(width: pixels, height: pixels)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            bodyColor(kind).setFill()
            ctx.fill(rect)
            UIImage(named: kind.tileAsset)?.draw(in: rect)

            let emblemSide = pixels * 0.56
            let emblemRect = CGRect(x: (pixels - emblemSide) / 2, y: (pixels - emblemSide) / 2,
                                    width: emblemSide, height: emblemSide)
            ctx.cgContext.saveGState()
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: pixels * 0.012), blur: pixels * 0.02,
                                    color: UIColor.black.withAlphaComponent(0.7).cgColor)
            UIImage(named: DiceZone.of(face: serverFace).emblemAsset)?.draw(in: emblemRect)
            ctx.cgContext.restoreGState()

            if let runeAsset, let rune = UIImage(named: runeAsset) {
                let w = pixels * 0.38, h = pixels * 0.42
                let runeRect = CGRect(x: pixels - w - pixels * 0.01, y: pixels - h - pixels * 0.01, width: w, height: h)
                ctx.cgContext.saveGState()
                ctx.cgContext.setShadow(offset: CGSize(width: 0, height: pixels * 0.008), blur: pixels * 0.015,
                                        color: UIColor.black.withAlphaComponent(0.85).cgColor)
                rune.draw(in: runeRect)
                ctx.cgContext.restoreGState()
            }
        }
    }
}
