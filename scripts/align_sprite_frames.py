#!/usr/bin/env python3
"""
Ingest several frames of ONE animated sprite (e.g. a chest closed / ajar /
open) onto a single shared canvas, so cross-fading between them never jumps.

Each frame is keyed like ingest_generated_sprite.py, then registered to the
first frame: the lower 30% of the content (the object's base) is matched by
bottom edge, horizontal centre and width. All frames are cropped to the union
box and written at the same size into <out>/<name>.imageset (@1x/@2x/@3x).

Usage:
  python3 scripts/align_sprite_frames.py --out <dir> [--pt 160] [--margin 18] \
      raw/closed.png:mine-chest-closed raw/ajar.png:mine-chest-ajar raw/open.png:mine-chest-open
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ingest_generated_sprite as ing  # noqa: E402


def base_metrics(rgba):
    a = rgba[..., 3] > 0.5
    ys, _ = np.where(a)
    top, bottom = ys.min(), ys.max()
    band = a[bottom - int((bottom - top) * 0.30):bottom + 1]
    bx = np.where(band.any(0))[0]
    return bottom, (bx.min() + bx.max()) / 2, max(1, bx.max() - bx.min())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames", nargs="+", help="raw.png:asset-name (first = reference)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--pt", type=int, default=160)
    ap.add_argument("--margin", type=int, default=18)
    ap.add_argument("--key", default="FF00FF")
    a = ap.parse_args()
    key = tuple(int(a.key[i:i + 2], 16) for i in (0, 2, 4))

    keyed = []
    for spec in a.frames:
        raw, name = spec.rsplit(":", 1)
        rgba = ing.bleed(ing.unmix_key_haze(ing.key_out(Image.open(raw), key), key))
        keyed.append((name, rgba))

    ref_bottom, ref_cx, ref_w = base_metrics(keyed[0][1])
    pad = 600
    placed = []
    for name, rgba in keyed:
        bottom, cx, w = base_metrics(rgba)
        s = ref_w / w
        im = ing.to_image(rgba)
        im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
        canvas = Image.new("RGBA", (rgba.shape[1] + 2 * pad, rgba.shape[0] + 2 * pad), (0, 0, 0, 0))
        canvas.paste(im, (round(pad + ref_cx - cx * s), round(pad + ref_bottom - bottom * s)), im)
        placed.append((name, canvas))
        print(f"{name}: scale {s:.3f}")

    alpha = np.maximum.reduce([np.asarray(c)[..., 3] for _, c in placed])
    ys, xs = np.where(alpha > 5)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)

    for name, canvas in placed:
        crop = canvas.crop(box)
        s = (a.pt * 3 - 2 * a.margin) / max(crop.width, crop.height)
        size3 = (round(crop.width * s), round(crop.height * s))
        c3 = Image.new("RGBA", (size3[0] + 2 * a.margin, size3[1] + 2 * a.margin), (0, 0, 0, 0))
        c3.paste(crop.resize(size3, Image.LANCZOS), (a.margin, a.margin))
        d = os.path.join(a.out, f"{name}.imageset")
        os.makedirs(d, exist_ok=True)
        for old in os.listdir(d):
            if old.endswith(".png"):
                os.remove(os.path.join(d, old))
        images = []
        for scale in (3, 2, 1):
            imx = c3 if scale == 3 else c3.resize((round(c3.width * scale / 3), round(c3.height * scale / 3)), Image.LANCZOS)
            fn = f"{name}@{scale}x.png" if scale > 1 else f"{name}.png"
            if ing.imagequant is not None:
                try:
                    imx = ing.imagequant.quantize_pil_image(imx, dithering_level=1.0, max_colors=256, min_quality=70, max_quality=90)
                except RuntimeError:
                    pass
            imx.save(os.path.join(d, fn), optimize=True)
            images.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
        images.reverse()
        with open(os.path.join(d, "Contents.json"), "w") as f:
            json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
        print(f"wrote {d} {c3.size}")


if __name__ == "__main__":
    main()
