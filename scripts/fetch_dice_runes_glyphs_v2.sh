#!/usr/bin/env bash
# Glyphs v2 (2026-10-14): runes whose first sigil read like a letter, regenerated
# as pictograms (docs/08_prompts/DICE_RUNES_PROMPTS.md → "Glyphs v2").
# Run from the repo root on the Mac:  bash scripts/fetch_dice_runes_glyphs_v2.sh
# Endurance, Challenge, Unbreakable failed to generate twice — still v1.
set -euo pipefail
RAW=_audit_tmp/dice_runes_raw_v2; mkdir -p "$RAW"
CDN=https://d8j0ntlcm91z4.cloudfront.net/user_37tZgqm2g7MCfz186sGRW3qGd5P
get() { [ -s "$RAW/$1.png" ] || curl -fsSL -o "$RAW/$1.png" "$CDN/$2"; python3 scripts/ingest_generated_sprite.py "$RAW/$1.png" "$1" --pt 64 --key "$3"; }
get rune-warrior-bulwark   hf_20261014_172835_42a04ed2-9391-4003-8536-7d788ec4876f.png FF00FF
get rune-mage-mana         hf_20261014_172834_f233e93d-83cc-4920-8123-f40e8419db3d.png 00FF00
get rune-tank-fortify      hf_20261014_172835_0160e299-14e7-42ae-a8fe-3f32aea5b475.png FF00FF
get rune-tank-earthshatter hf_20261014_172836_7bd7378e-2609-4fcd-a473-e914f109a387.png FF00FF
