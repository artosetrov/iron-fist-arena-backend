#!/usr/bin/env python3
"""
Remove background from images using rembg (U²-Net).
Usage:
    python remove_bg.py <input_path> [output_path] [--model MODEL] [--format FORMAT]

Models: u2net (default), u2netp (fast/lightweight), u2net_human_seg (people), isnet-general-use
Formats: png (default, transparent), white (white bg), black (black bg)
"""

import argparse
import os
import sys
import subprocess
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(SCRIPT_DIR)


def ensure_deps():
    """Install rembg if missing."""
    try:
        from rembg import remove
        from PIL import Image
    except ImportError:
        print("[remove-bg] Installing rembg + Pillow...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "rembg[cpu]", "Pillow", "--break-system-packages", "-q"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        from rembg import remove
        from PIL import Image
    return remove, Image


def ensure_model(model_name):
    """
    Ensure the model .onnx file is in rembg's cache (~/.u2net/).
    Searches for a local copy in:
      1. The workspace root (../../.. from skill dir, i.e. project root)
      2. SKILL_DIR itself
    If found, copies it to the cache so rembg doesn't need to download.
    """
    cache_dir = os.path.join(os.path.expanduser("~"), ".u2net")
    os.makedirs(cache_dir, exist_ok=True)
    cached = os.path.join(cache_dir, f"{model_name}.onnx")
    if os.path.isfile(cached):
        return  # already cached

    # Search for local .onnx file
    search_dirs = [
        os.path.dirname(os.path.dirname(SKILL_DIR)),  # workspace root (e.g. PVP RPG/)
        SKILL_DIR,
    ]
    for d in search_dirs:
        candidate = os.path.join(d, f"{model_name}.onnx")
        if os.path.isfile(candidate):
            print(f"[remove-bg] Found local model: {candidate}")
            shutil.copy2(candidate, cached)
            print(f"[remove-bg] Cached to: {cached}")
            return

    print(f"[remove-bg] Warning: model {model_name}.onnx not found locally. rembg will try to download it (~170MB).")


def main():
    parser = argparse.ArgumentParser(description="Remove background from image")
    parser.add_argument("input", help="Path to input image")
    parser.add_argument("output", nargs="?", help="Path to output image (default: input_nobg.png)")
    parser.add_argument("--model", default="u2net",
                        choices=["u2net", "u2netp", "u2net_human_seg", "isnet-general-use"],
                        help="Model to use (default: u2net)")
    parser.add_argument("--format", default="png", choices=["png", "white", "black"],
                        help="Output format: png (transparent), white (white bg), black (black bg)")
    parser.add_argument("--alpha-matting", action="store_true",
                        help="Enable alpha matting for cleaner edges")
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"Error: file not found: {args.input}")
        sys.exit(1)

    remove, Image = ensure_deps()
    ensure_model(args.model)

    # Default output path
    if not args.output:
        base, _ = os.path.splitext(args.input)
        args.output = f"{base}_nobg.png"

    print(f"[remove-bg] Input:  {args.input}")
    print(f"[remove-bg] Model:  {args.model}")
    print(f"[remove-bg] Format: {args.format}")

    inp = Image.open(args.input).convert("RGBA")

    from rembg import new_session
    session = new_session(args.model)
    result = remove(
        inp,
        session=session,
        alpha_matting=args.alpha_matting,
    )

    # Apply background if requested
    if args.format in ("white", "black"):
        bg_color = (255, 255, 255, 255) if args.format == "white" else (0, 0, 0, 255)
        bg = Image.new("RGBA", result.size, bg_color)
        bg.paste(result, mask=result.split()[3])
        result = bg.convert("RGB")

    result.save(args.output)
    print(f"[remove-bg] Output: {args.output}")
    print("[remove-bg] Done!")


if __name__ == "__main__":
    main()
