#!/usr/bin/env bash
# Shop redesign art (2026-10-15): gem tiers 1–5 + Protection Scroll / Legendary
# Shard item icons, generated on Higgsfield (nano_banana_2_1, green key 00FF00).
# Prompts: docs/08_prompts/CURRENCY_GEMS_PROMPTS.md (tiers) + ACHIEVEMENT_ITEM_ICONS_PROMPTS.md template.
#
# Run from the repo root on the Mac:  bash scripts/fetch_shop_gems.sh
# Only downloads the raw PNGs — the CDN is unreachable from Claude's sandbox.
# Keying + @1x/@2x/@3x imagesets are done afterwards with scripts/ingest_generated_sprite.py.
set -euo pipefail
RAW=_audit_tmp/shop_gems_raw; mkdir -p "$RAW"
CDN=https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P
get() { [ -s "$RAW/$1.png" ] || curl -fsSL --retry 2 -o "$RAW/$1.png" "$CDN/$2"; echo "ok  $1"; }
get shop-gems-tier1        hf_20261015_170151_ff07d963-5d22-4924-8307-c5ce0b1864fb.png
get shop-gems-tier2        hf_20261015_170149_1fe650f1-aef8-4c3c-b824-712fc79e264c.png
get shop-gems-tier3        hf_20261015_170149_b4a5c5cc-332b-4b0a-bcac-905a4e205a21.png
get shop-gems-tier4        hf_20261015_170149_57e2c6dd-7fb7-4ba6-ae62-29e73a9a2976.png
get shop-gems-tier5        hf_20261015_170150_0c04c483-20c3-4798-a98c-f3d5df6d46ba.png
get icon-protection-scroll hf_20261015_170151_e8910e8f-5145-4ce3-8bee-0284ffde7108.png
get icon-legendary-shard   hf_20261015_170150_71994e6e-3387-427f-ac4b-9db8ff83ac8c.png
echo "Done: $(ls "$RAW" | wc -l | tr -d ' ') files in $RAW"
