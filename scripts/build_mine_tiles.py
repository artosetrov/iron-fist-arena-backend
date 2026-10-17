#!/usr/bin/env python3
"""Build the Gold Mine's seamless tiles from two generated raws (2026-10-17).

    python3 scripts/build_mine_tiles.py --rail <mine-rail-raw.png> --ladder <mine-ladder-raw.png> \
        --out Hexbound/Hexbound/Resources/Assets.xcassets/GoldMine

mine-rail-tile   24 x 14 pt — rail beam on top (first row = rail top, the cart's
                 wheels stand on it), two sleepers per tile. The raw's sleepers
                 are unevenly spaced, so the tile is rebuilt: a seamless stretch
                 of rail (slow brightness drift flattened) + two copies of one
                 sleeper at an even pitch.
mine-ladder-tile 30 x 12 pt — one rung period of the raw ladder, its plain side
                 rails stretched so the rungs are not too dense at 30 pt wide.

Both tiles get exact @1x/@2x/@3x pixel sizes (integer points at every scale),
otherwise `resizable(resizingMode: .tile)` drifts between scales.
Raws are keyed with scripts/ingest_generated_sprite.py helpers (magenta #FF00FF).
"""
import argparse, json, os, sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ingest_generated_sprite as ing  # noqa: E402

KEY = (255, 0, 255)


def keyed(path):
    rgba = ing.key_out(Image.open(path), KEY)
    rgba = ing.unmix_key_haze(rgba, KEY)
    return ing.bleed(rgba)


def runs(mask):
    out, start = [], None
    for i, v in enumerate(mask):
        if v and start is None:
            start = i
        if not v and start is not None:
            out.append((start, i)); start = None
    if start is not None:
        out.append((start, len(mask)))
    return out


def smooth(v, k):
    k = max(3, k | 1); pad = k // 2
    vp = np.pad(v, (pad, pad), mode="reflect")
    c = np.concatenate([[0.0], np.cumsum(vp)])
    return (c[k:] - c[:-k]) / k


def write_exact(out, name, im, w_pt, h_pt):
    d = os.path.join(out, f"{name}.imageset"); os.makedirs(d, exist_ok=True)
    for old in os.listdir(d):
        if old.endswith(".png"):
            os.remove(os.path.join(d, old))
    images = []
    for scale in (1, 2, 3):
        fn = f"{name}@{scale}x.png" if scale > 1 else f"{name}.png"
        im.resize((w_pt * scale, h_pt * scale), Image.LANCZOS).save(os.path.join(d, fn), optimize=True)
        images.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    print(f"wrote {name} {w_pt}x{h_pt} pt")


def build_ladder(raw, out, w_pt=30, h_pt=12):
    lad = keyed(raw)
    a = lad[..., 3] > 0.5
    xs = np.where(a.any(0))[0]; x0, x1 = xs.min(), xs.max() + 1
    cx = (x0 + x1) // 2
    rungs = [r for r in runs(a[:, cx - 3:cx + 4].all(1)) if r[1] - r[0] > 8]
    centers = [(s + e) / 2 for s, e in rungs]
    period = float(np.median(np.diff(centers)))
    c = centers[len(centers) // 2]
    top = int(round(c - period / 2)); bot = int(round(top + period))
    tile = lad[top:bot, x0:x1].copy()
    # Seam: the first rows fade in from the rows that follow the tile in the raw.
    b = max(4, int(period * 0.08))
    w = np.linspace(0, 1, b)[:, None, None]
    tile[:b] = tile[:b] * w + lad[bot:bot + b, x0:x1] * (1 - w)
    width = x1 - x0
    extra = int(round(width * h_pt / w_pt)) - tile.shape[0]
    plain = int(period * 0.16)  # rows above the rung: side rails only
    head = ing.to_image(tile[:plain]).resize((width, plain + max(extra, 0)), Image.LANCZOS)
    tile = np.concatenate([np.asarray(head).astype(np.float64) / 255.0, tile[plain:]], axis=0)
    write_exact(out, "mine-ladder-tile", ing.to_image(tile), w_pt, h_pt)


def build_rail(raw, out, w_pt=24, h_pt=14):
    rl = keyed(raw)
    a = rl[..., 3] > 0.5
    ybot = np.where(a.any(1))[0].max() + 1
    width = a.shape[1]
    full = a[:, int(width * 0.05):int(width * 0.95)].mean(1) > 0.97
    r0, r1 = max(runs(full), key=lambda r: r[1] - r[0])          # the rail beam
    sleepers = [r for r in runs(a[r1 + 20:ybot - 10].mean(0) > 0.5) if r[1] - r[0] > 40]
    th = ybot - r0
    tw = int(round(th * w_pt / h_pt))
    pitch = tw / 2
    ax = width // 2 - tw // 2
    seg = rl[r0:r1, ax:ax + tw + tw // 4].copy()
    col = seg[..., :3].mean(axis=(0, 2))
    seg[..., :3] = np.clip(seg[..., :3] * (col.mean() / np.maximum(smooth(col, tw // 3), 1e-3))[None, :, None], 0, 1)
    bw = tw // 4
    main = seg[:, :tw].copy()
    w = np.linspace(0, 1, bw)[None, :, None]
    main[:, :bw] = main[:, :bw] * w + seg[:, tw:tw + bw] * (1 - w)
    tile = np.zeros((th, tw, 4)); tile[:r1 - r0] = main
    clip_top = r1 - 12  # keep the iron chair between rail and sleeper
    mid = len(sleepers) // 2
    for i, (s0, s1) in enumerate([sleepers[mid - 1], sleepers[mid]]):
        sl = rl[clip_top:ybot, max(0, s0 - 6):s1 + 6]
        sx = max(0, min(tw - sl.shape[1], int(round(pitch * (i + 0.5) - sl.shape[1] / 2))))
        region = tile[clip_top - r0:, sx:sx + sl.shape[1]]
        al = sl[..., 3:4]
        region[..., :3] = sl[..., :3] * al + region[..., :3] * (1 - al)
        region[..., 3:4] = np.maximum(al, region[..., 3:4])
    write_exact(out, "mine-rail-tile", ing.to_image(tile), w_pt, h_pt)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rail"); ap.add_argument("--ladder"); ap.add_argument("--out", required=True)
    args = ap.parse_args()
    if args.ladder:
        build_ladder(args.ladder, args.out)
    if args.rail:
        build_rail(args.rail, args.out)


if __name__ == "__main__":
    main()
