#!/usr/bin/env python3
"""
Ingest an AI-generated sprite (flat magenta key background) into Assets.xcassets.

Pipeline (docs/08_prompts/ART_STYLE_GUIDE.md, Generation Rules 4-5):
  key out the magenta background -> un-mix edge colour -> despill -> crop to
  content with margin -> write @3x / @2x / @1x PNGs + Contents.json.

Usage:
  python3 scripts/ingest_generated_sprite.py <raw.png> <asset-name> [--pt 512] [--key FF00FF] [--margin 24]

  --pt     longest side of the asset at @1x, in points (default 512 -> @3x is 1536 px)
  --key    key colour hex (default magenta FF00FF)
  --margin transparent margin in @3x pixels around the content (default 24)
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image
try:
    import imagequant  # libimagequant: pngquant-grade lossy palette PNG (pip install imagequant)
except ImportError:
    imagequant = None

XCASSETS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "Hexbound", "Hexbound", "Resources", "Assets.xcassets")

def srgb_to_lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)

def dilate(mask, iters):
    m = mask.copy()
    for _ in range(iters):
        m = m | np.roll(m, 1, 0) | np.roll(m, -1, 0) | np.roll(m, 1, 1) | np.roll(m, -1, 1)
    return m

def key_out(img, key_rgb, sat_t=0.80, sym_t=0.30, band_px=5):
    """Chroma key in linear RGB. A pixel is background when its colour points the same way as
    the key (the two high key channels agree and dominate the low one) at ANY brightness, so
    generator-shaded key colour in enclosed pockets is keyed too. Edge handling is restricted
    to a band around the background so interior purples/crimsons never turn transparent."""
    rgb = np.asarray(img.convert("RGB"), dtype=np.float64)
    lin = srgb_to_lin(rgb)
    k = srgb_to_lin(np.array(key_rgb, dtype=np.float64))
    hi = [i for i in range(3) if k[i] > 0.5]; lo = [i for i in range(3) if k[i] <= 0.5]
    if not ((len(hi) == 2 and len(lo) == 1) or (len(hi) == 1 and len(lo) == 2)):
        raise SystemExit("key colour must be a secondary (FF00FF, 00FFFF) or a primary (00FF00) colour")
    # Two-high keys (magenta): the high pair must agree. One-high keys (green): the low pair must agree.
    hiv = np.stack([lin[..., i] for i in hi], -1); lov = np.stack([lin[..., i] for i in lo], -1)
    mx = np.maximum(hiv.max(-1), 1e-6)
    key_sat = np.clip((hiv.min(-1) - lov.max(-1)) / mx, 0, 1)
    pair = hiv if len(hi) == 2 else lov
    sym = np.abs(pair[..., 0] - pair[..., 1]) / mx
    bg = (key_sat > sat_t) & (sym < sym_t) & (mx > 0.01)
    band = dilate(bg, band_px) & ~bg
    alpha = np.ones(bg.shape)
    alpha[bg] = 0.0
    alpha[band] = np.clip(1.0 - key_sat[band] / sat_t, 0.0, 1.0)
    # un-mix blended edge pixels against the key at the pixel's own brightness
    k_eff = np.zeros_like(lin)
    for i in hi:
        k_eff[..., i] = mx
    a3 = alpha[..., None]
    unmixed = np.where((a3 > 0.001) & (a3 < 0.999), (lin - (1 - a3) * k_eff) / np.maximum(a3, 1e-3), lin)
    unmixed = np.clip(unmixed, 0, 1)
    srgb = np.where(unmixed <= 0.0031308, unmixed * 12.92, 1.055 * unmixed ** (1 / 2.4) - 0.055)
    return np.dstack([srgb, alpha])

def unmix_key_haze(rgba, key_rgb, hue_tol=0.07, iters=400):
    """Semi-transparent neutral haze (smoke, mist, specks) painted over the key colour keeps a
    key tint after keying. For pixels whose chroma matches the key and that are connected to the
    transparent background, solve P = a*grey + (1-a)*K for a and grey (linear RGB). Interior
    accents of a similar hue (e.g. a purple cave mouth) are enclosed by other colours and are
    never reached by the flood, so they stay untouched."""
    lin = srgb_to_lin(rgba[..., :3] * 255.0)
    a = rgba[..., 3]
    k = srgb_to_lin(np.array(key_rgb, dtype=np.float64))
    # key-like chroma: the two "high" key channels agree, the "low" one is clearly below them
    hi = [i for i in range(3) if k[i] > 0.5]; lo = [i for i in range(3) if k[i] <= 0.5]
    if not ((len(hi) == 2 and len(lo) == 1) or (len(hi) == 1 and len(lo) == 2)):
        return rgba
    hiv = np.stack([lin[..., i] for i in hi], -1); lov = np.stack([lin[..., i] for i in lo], -1)
    hi_mean = hiv.mean(-1); lo_mean = lov.mean(-1)
    pair = hiv if len(hi) == 2 else lov
    keyish = (np.abs(pair[..., 0] - pair[..., 1]) < hue_tol + 0.5 * hi_mean) & \
             (hiv.min(-1) - lov.max(-1) > 0.015) & (a > 0)
    reached = keyish & dilate(a == 0, 8)   # jump over the already-unmixed edge band
    prev = -1
    for _ in range(iters):
        n = int(reached.sum())
        if n == prev:
            break
        prev = n
        reached = dilate(reached, 1) & keyish
    if prev <= 0:
        return rgba
    print(f"  haze unmix: {prev} px")
    tint = hi_mean - lo_mean
    a_new = np.clip(1.0 - tint, 0.0, 1.0)
    grey = np.clip(lo_mean / np.maximum(a_new, 1e-3), 0.0, 1.0)
    out = rgba.copy()
    g_srgb = np.where(grey <= 0.0031308, grey * 12.92, 1.055 * grey ** (1 / 2.4) - 0.055)
    for c in range(3):
        out[..., c] = np.where(reached, g_srgb, out[..., c])
    out[..., 3] = np.where(reached, a * a_new, a)
    return out

def bleed(rgba, iters=3):
    """Bleed colour into fully transparent pixels so bilinear filtering shows no dark fringe."""
    rgb, a = rgba[..., :3].copy(), rgba[..., 3]
    filled = a > 0
    for _ in range(iters):
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            src = np.roll(rgb, (dy, dx), axis=(0, 1))
            srcf = np.roll(filled, (dy, dx), axis=(0, 1))
            take = (~filled) & srcf
            rgb[take] = src[take]
            filled = filled | take
    return np.dstack([rgb, a])

def to_image(rgba):
    return Image.fromarray((np.clip(rgba, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("raw"); ap.add_argument("name")
    ap.add_argument("--pt", type=int, default=512)
    ap.add_argument("--key", default="FF00FF")
    ap.add_argument("--margin", type=int, default=24)
    ap.add_argument("--out", default=XCASSETS)
    ap.add_argument("--lossless", action="store_true", help="skip palette quantisation")
    a = ap.parse_args()

    key = tuple(int(a.key[i:i + 2], 16) for i in (0, 2, 4))
    img = Image.open(a.raw)
    rgba = key_out(img, key)
    rgba = unmix_key_haze(rgba, key)
    rgba = bleed(rgba)
    alpha = rgba[..., 3]
    # drop specks: ignore alpha < 0.02 for bbox
    ys, xs = np.where(alpha > 0.02)
    if len(ys) == 0:
        sys.exit("nothing left after keying - wrong key colour?")
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    crop = rgba[y0:y1, x0:x1]
    im = to_image(crop)

    # Residue check (2026-10-14, Shade Knight): the model sometimes paints a
    # *patterned* key background (stripes, gradient) instead of a flat one.
    # Those pixels are off-key enough to survive keying and ship as pink
    # stripes. Count opaque, strongly key-hued pixels; anything beyond a tiny
    # share means the raw must be regenerated, not shipped.
    opaque = crop[..., 3] > 0.5
    rgb = crop[..., :3]
    k = np.array(key, dtype=np.float64) / 255.0
    hi = k > 0.5
    lo = ~hi
    key_hue = opaque & (rgb[..., hi].min(axis=-1) > 0.55) & (rgb[..., lo].max(axis=-1) < 0.35)
    share = key_hue.sum() / max(1, opaque.sum())
    if share > 0.01:
        print(f"WARNING: {share:.1%} of opaque pixels are key-coloured -> background was not flat; regenerate this asset")
    elif key_hue.sum() > 0:
        print(f"  key residue: {int(key_hue.sum())} px ({share:.2%})")

    # scale so the longest side at @3x == pt*3 (minus margins), then pad
    target3 = a.pt * 3 - 2 * a.margin
    s = target3 / max(im.width, im.height)
    if s > 1.0:
        print(f"warning: source only {max(im.width, im.height)}px of content, upscaling x{s:.2f}")
    size3 = (max(1, round(im.width * s)), max(1, round(im.height * s)))
    im3 = im.resize(size3, Image.LANCZOS)
    canvas3 = Image.new("RGBA", (size3[0] + 2 * a.margin, size3[1] + 2 * a.margin), (0, 0, 0, 0))
    canvas3.paste(im3, (a.margin, a.margin))

    out_dir = os.path.join(a.out, f"{a.name}.imageset")
    os.makedirs(out_dir, exist_ok=True)
    keep = {f"{a.name}.png", f"{a.name}@2x.png", f"{a.name}@3x.png"}
    for old in os.listdir(out_dir):
        if old.endswith(".png") and old not in keep:
            try:
                os.remove(os.path.join(out_dir, old))
            except OSError as e:
                print(f"warning: could not remove stale {old}: {e}")
    images = []
    for scale in (3, 2, 1):
        w = round(canvas3.width * scale / 3); h = round(canvas3.height * scale / 3)
        imx = canvas3 if scale == 3 else canvas3.resize((w, h), Image.LANCZOS)
        fn = f"{a.name}@{scale}x.png" if scale > 1 else f"{a.name}.png"
        if imagequant is not None and not a.lossless:
            # 256-colour palette with alpha, quality floor 70: ~4x smaller, invisible at display size.
            # Wide-gamut subjects (full fire spectrum) can miss the floor: retry without it, else keep lossless.
            try:
                imx = imagequant.quantize_pil_image(imx, dithering_level=1.0, max_colors=256, min_quality=70, max_quality=90)
            except RuntimeError:
                try:
                    imx = imagequant.quantize_pil_image(imx, dithering_level=1.0, max_colors=256, min_quality=0, max_quality=100)
                    print("  note: palette quality below floor, kept best-effort quantisation")
                except RuntimeError:
                    print("  note: quantisation failed, keeping lossless RGBA")
        imx.save(os.path.join(out_dir, fn), optimize=True)
        images.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
        print(f"  {fn}: {imx.width}x{imx.height}")
    images.reverse()
    with open(os.path.join(out_dir, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    print(f"wrote {out_dir}")

if __name__ == "__main__":
    main()
