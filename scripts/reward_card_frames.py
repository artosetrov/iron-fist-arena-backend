#!/usr/bin/env python3
"""
Build the stretchable reward-card frames (docs/08_prompts/REWARD_CARD_FRAMES_PROMPTS.md).

Every generated frame (flat #00FF00 key, plain side rails) is cut into three pieces that
rebuild it at any height:

  top    - crest, top corners, top border and the first bit of the rails
  mid    - a strip of plain rail, repeated to fill whatever height the content needs
  bottom - the last bit of the rails, bottom corners, bottom border and its ornament

The strip's first rows are cross-faded with the rows that follow its end, so copies of
the strip meet without a seam. The client also cross-fades both caps into the strip.

Usage:
  python3 scripts/reward_card_frames.py <frames_dir> [--pt 360] [--only arena-gold,mine-iron]
  python3 scripts/reward_card_frames.py --remeasure   # re-read the geometry of the shipped caps

<frames_dir> holds the raws as <family>-<tier>.png. Writes
  Hexbound/Hexbound/Resources/Assets.xcassets/RewardFrames/
      reward-frame-<family>-<tier>-{top,mid,bottom}.imageset   (@1x/@2x/@3x)
  Hexbound/Hexbound/Views/Components/RewardCardFrameMetrics.swift   (measured geometry)
"""
import argparse, json, os, sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from ingest_generated_sprite import key_out, unmix_key_haze, bleed, to_image  # noqa: E402

try:
    import imagequant
except ImportError:
    imagequant = None

ROOT = os.path.dirname(HERE)
XC = os.path.join(ROOT, "Hexbound", "Hexbound", "Resources", "Assets.xcassets", "RewardFrames")
SWIFT = os.path.join(ROOT, "Hexbound", "Hexbound", "Views", "Components", "RewardCardFrameMetrics.swift")
FAMILIES = ["arena", "dungeon", "fortune", "mine", "merchant", "tribute", "glory", "ascension"]
TIERS = ["iron", "bronze", "silver", "gold", "mythic"]
# Weathered planks have ragged edges: their rails need a looser "is this row plain" test.
TOLERANCE = {"merchant-iron": 0.07, "glory-iron": 0.07}
TILE = 0.22    # strip height as a share of the width
BLEND = 0.35   # cross-fade share of the strip
CONTENT_BAND = 0.08  # text/buttons sit this far (share of width) inside the rails


def runs(row):
    d = np.diff(np.concatenate([[0], row.astype(np.int8), [0]]))
    return list(zip(np.where(d == 1)[0], np.where(d == -1)[0]))


def slice_frame(path, tol):
    rgba = key_out(Image.open(path), (0, 255, 0))
    rgba = unmix_key_haze(rgba, (0, 255, 0))
    rgba = bleed(rgba)
    alpha = rgba[..., 3]
    ys, xs = np.where(alpha > 0.02)
    rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    alpha = rgba[..., 3]
    H, W = alpha.shape

    mid = H // 2
    r = runs(alpha[mid] > 0.5)
    if len(r) < 2:
        raise SystemExit(f"{path}: no side rails on the middle row")
    left, right = r[0], r[-1]
    inner_l, inner_r = left[1], right[0]
    pad = max(4, W // 100)
    cols = np.zeros(W, bool)
    cols[max(0, left[0] - pad):left[1] + pad] = True
    cols[right[0] - pad:min(W, right[1] + pad)] = True
    ref = alpha[mid, cols]

    def plain(y):
        return (np.mean(np.abs(alpha[y, cols] - ref)) < tol
                and alpha[y, inner_l + pad:inner_r - pad].max() < 0.1)

    y0 = mid
    while y0 > 0 and plain(y0 - 1):
        y0 -= 1
    y1 = mid
    while y1 < H - 1 and plain(y1 + 1):
        y1 += 1
    L = int(round(TILE * W)); K = int(round(BLEND * L)); margin = max(8, W // 60)
    if y1 - y0 < L + K + 2 * margin:
        raise SystemExit(f"{path}: plain rail span {y1 - y0}px too short for a {L}px strip")

    rgb = rgba[..., :3]
    best = best_s = None
    for s in range(y0 + margin, y1 - margin - L - K, 2):
        cost = np.mean(np.abs(rgb[s:s + K, cols] - rgb[s + L:s + L + K, cols]))
        if best is None or cost < best:
            best, best_s = cost, s
    s = best_s
    strip = rgba[s:s + L].copy()
    w = (np.arange(K) / K)[:, None, None]
    strip[:K] = rgba[s + L:s + L + K] * (1 - w) + strip[:K] * w
    top = rgba[:y0 + margin]
    bottom = rgba[y1 - margin:]

    # Geometry. The window edges are read at a column clear of the crest; the content
    # edges are the deepest reach of any ornament into the band where text and buttons go.
    cx = inner_l + (inner_r - inner_l) // 6
    col = alpha[:, cx]
    win_top = next(y for y in range(mid, -1, -1) if col[y] > 0.5) + 1
    win_bot = next(y for y in range(mid, H) if col[y] > 0.5)
    xa, xb = inner_l + int(CONTENT_BAND * W), inner_r - int(CONTENT_BAND * W)
    band = alpha[:, xa:xb] > 0.5
    top_rows = np.where(band[:mid].any(axis=1))[0]
    bot_rows = np.where(band[mid:].any(axis=1))[0]
    content_top = (top_rows.max() + 1) if len(top_rows) else win_top
    content_bottom = H - (mid + bot_rows.min()) if len(bot_rows) else H - win_bot
    geo = {
        "top": top.shape[0] / W, "mid": L / W, "bottom": bottom.shape[0] / W,
        "insetL": inner_l / W, "insetR": (W - inner_r) / W,
        "windowTop": win_top / W, "contentTop": content_top / W,
        "windowBottom": (H - win_bot) / W, "contentBottom": content_bottom / W,
        "crestBottom": crest_bottom(alpha[:mid], inner_l, inner_r, win_top) / W,
    }
    return {"top": top, "mid": strip, "bottom": bottom}, geo, W


def crest_bottom(alpha, inner_l, inner_r, win_top):
    """Lowest row the crest reaches in the middle of the window (rows from the top),
    so the illustration can keep its subject's head below it."""
    ca = int(inner_l + (inner_r - inner_l) * 0.3)
    cb = int(inner_l + (inner_r - inner_l) * 0.7)
    rows = np.where((alpha[:, ca:cb] > 0.5).any(axis=1))[0]
    return max((rows.max() + 1) if len(rows) else win_top, win_top)


def remeasure(metrics):
    """Fill in the crest reach of every shipped frame from its @3x top cap, without
    cutting the frames again."""
    for key, g in metrics.items():
        path = os.path.join(XC, f"reward-frame-{key}-top.imageset", f"reward-frame-{key}-top@3x.png")
        alpha = np.asarray(Image.open(path).convert("RGBA"))[..., 3] / 255.0
        W = alpha.shape[1]
        g["crestBottom"] = round(crest_bottom(alpha, g["insetL"] * W, (1 - g["insetR"]) * W, g["windowTop"] * W) / W, 4)
        print(f"{key}: crestBottom={g['crestBottom']:.3f} (window top {g['windowTop']:.3f})")


def write_imageset(name, arr, src_w, pt):
    out_dir = os.path.join(XC, f"{name}.imageset")
    os.makedirs(out_dir, exist_ok=True)
    im = to_image(arr)
    images = []
    for scale in (3, 2, 1):
        w = pt * scale
        h = max(1, round(arr.shape[0] * w / src_w))
        imx = im.resize((w, h), Image.LANCZOS)
        if imagequant is not None:
            try:
                imx = imagequant.quantize_pil_image(imx, dithering_level=1.0, max_colors=256, min_quality=70, max_quality=92)
            except RuntimeError:
                pass
        fn = f"{name}@{scale}x.png" if scale > 1 else f"{name}.png"
        imx.save(os.path.join(out_dir, fn), optimize=True)
        images.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
    images.reverse()
    with open(os.path.join(out_dir, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)


def write_swift(metrics):
    lines = [
        "import CoreGraphics",
        "",
        "// GENERATED by scripts/reward_card_frames.py from the shipped frame art. Do not edit by hand;",
        "// regenerate the frames and run the script again (docs/08_prompts/REWARD_CARD_FRAMES_PROMPTS.md).",
        "",
        "/// Measured geometry of one stretchable reward-card frame, as shares of the card width.",
        "struct RewardCardFrameMetrics {",
        "    /// Heights of the three pieces: the top cap, one repeat of the rail strip, the bottom cap.",
        "    let top: CGFloat, mid: CGFloat, bottom: CGFloat",
        "    /// Inner edges of the side rails.",
        "    let insetL: CGFloat, insetR: CGFloat",
        "    /// Inner edge of the top border, and the lowest any crest or corner piece reaches into",
        "    /// the column where text and buttons go (both from the top of the top cap).",
        "    let windowTop: CGFloat, contentTop: CGFloat",
        "    /// The same two edges at the bottom, measured from the bottom of the bottom cap.",
        "    let windowBottom: CGFloat, contentBottom: CGFloat",
        "    /// The lowest the crest reaches into the middle of the window (from the top of the top",
        "    /// cap): the illustration keeps its subject below it.",
        "    let crestBottom: CGFloat",
        "",
        "    static func of(_ family: RewardCardFamily, _ tier: RewardCardTier) -> RewardCardFrameMetrics {",
        "        table[\"\\(family.rawValue)-\\(tier.assetKey)\"] ?? fallback",
        "    }",
        "",
        "    private static let fallback = RewardCardFrameMetrics(top: 0.35, mid: 0.22, bottom: 0.25, insetL: 0.09, insetR: 0.09,",
        "        windowTop: 0.19, contentTop: 0.34, windowBottom: 0.12, contentBottom: 0.17, crestBottom: 0.32)",
        "",
        "    private static let table: [String: RewardCardFrameMetrics] = [",
    ]
    for key in sorted(metrics, key=lambda k: (FAMILIES.index(k.split("-")[0]), TIERS.index(k.split("-")[1]))):
        g = metrics[key]
        f = lambda v: f"{v:.4f}"
        lines.append(
            f'        "{key}": .init(top: {f(g["top"])}, mid: {f(g["mid"])}, bottom: {f(g["bottom"])}, '
            f'insetL: {f(g["insetL"])}, insetR: {f(g["insetR"])}, windowTop: {f(g["windowTop"])}, '
            f'contentTop: {f(g["contentTop"])}, windowBottom: {f(g["windowBottom"])}, '
            f'contentBottom: {f(g["contentBottom"])}, crestBottom: {f(g["crestBottom"])}),')
    lines += ["    ]", "}", ""]
    with open(SWIFT, "w") as fh:
        fh.write("\n".join(lines))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames_dir", nargs="?")
    ap.add_argument("--pt", type=int, default=360, help="card width at @1x in points")
    ap.add_argument("--only", default="")
    ap.add_argument("--remeasure", action="store_true", help="re-read geometry from the shipped caps only")
    a = ap.parse_args()
    if a.remeasure:
        metrics_path = os.path.join(HERE, "reward_card_frames.metrics.json")
        metrics = json.load(open(metrics_path))
        remeasure(metrics)
        with open(metrics_path, "w") as f:
            json.dump(metrics, f, indent=1, sort_keys=True)
        write_swift(metrics)
        print(f"remeasured {len(metrics)} frames, {SWIFT}")
        return
    if not a.frames_dir:
        ap.error("frames_dir is required (or pass --remeasure)")
    os.makedirs(XC, exist_ok=True)
    with open(os.path.join(XC, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": False}}, f, indent=2)

    metrics_path = os.path.join(HERE, "reward_card_frames.metrics.json")  # measured geometry, the source of the Swift table
    metrics = json.load(open(metrics_path)) if os.path.exists(metrics_path) else {}
    only = set(filter(None, a.only.split(",")))
    for fam in FAMILIES:
        for tier in TIERS:
            key = f"{fam}-{tier}"
            if only and key not in only:
                continue
            raw = os.path.join(a.frames_dir, key + ".png")
            if not os.path.exists(raw):
                print(f"missing {raw}")
                continue
            parts, geo, src_w = slice_frame(raw, TOLERANCE.get(key, 0.03))
            for part, arr in parts.items():
                write_imageset(f"reward-frame-{key}-{part}", arr, src_w, a.pt)
            metrics[key] = {k: round(v, 4) for k, v in geo.items()}
            print(f"{key}: " + ", ".join(f"{k}={v:.3f}" for k, v in geo.items()))
    with open(metrics_path, "w") as f:
        json.dump(metrics, f, indent=1, sort_keys=True)
    write_swift(metrics)
    print(f"wrote {len(metrics)} frames, {SWIFT}")


if __name__ == "__main__":
    main()
