#!/usr/bin/env bash
# export-assets-for-figma.sh
# Собирает изображения из Assets.xcassets в папки по категориям для импорта в Figma
# Запуск: bash scripts/export-assets-for-figma.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ASSETS_DIR="$REPO_DIR/Hexbound/Hexbound/Resources/Assets.xcassets"
OUT_DIR="$REPO_DIR/figma-assets"
TMP_OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hexbound-figma-assets.XXXXXX")"

trap 'rm -rf "$TMP_OUT_DIR"' EXIT

mkdir -p "$TMP_OUT_DIR/01_Characters"
mkdir -p "$TMP_OUT_DIR/02_Enemies"
mkdir -p "$TMP_OUT_DIR/03_Items"
mkdir -p "$TMP_OUT_DIR/04_Icons"
mkdir -p "$TMP_OUT_DIR/05_UI_Backgrounds"
mkdir -p "$TMP_OUT_DIR/06_FX"
mkdir -p "$TMP_OUT_DIR/07_Buildings"

find_visual_file() {
  local imageset="$1"
  local name="$2"
  local candidate

  for candidate in \
    "$imageset/$name.png" \
    "$imageset/$name.jpg" \
    "$imageset/$name.jpeg" \
    "$imageset/$name.pdf"
  do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  find "$imageset" -maxdepth 1 -type f \( \
    -iname "*.png" -o \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.pdf" \
  \) | LC_ALL=C sort | head -n 1
}

copy_visual() {
  local imageset="$1"
  local dest="$2"
  local name
  local found
  local ext

  name=$(basename "$imageset" .imageset)
  found="$(find_visual_file "$imageset" "$name")"
  if [ -n "$found" ] && [ -f "$found" ]; then
    ext="${found##*.}"
    cp "$found" "$dest/$name.$ext"
  fi
}

echo "📦 Экспорт ассетов в $OUT_DIR/ ..."

# 01 Characters — аватары, скины
for d in "$ASSETS_DIR/Skins"/*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/01_Characters"; done
for d in "$ASSETS_DIR"/avatar-*.imageset; do [ -d "$d" ] && copy_visual "$d" "$TMP_OUT_DIR/01_Characters"; done

# 02 Enemies — dungeon rush мобы + боссы (без buff/event — они в FX)
for d in "$ASSETS_DIR/rush-"*.imageset; do
  name=$(basename "$d" .imageset)
  [[ "$name" == rush-buff-* || "$name" == rush-event-* ]] && continue
  copy_visual "$d" "$TMP_OUT_DIR/02_Enemies"
done
for d in "$ASSETS_DIR/Bosses"/*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/02_Enemies"; done

# 03 Items (skip pot_health aliases — same art as health_potion)
for d in "$ASSETS_DIR/Items"/*.imageset; do
  name=$(basename "$d" .imageset)
  [[ "$name" == pot_health_* ]] && continue
  copy_visual "$d" "$TMP_OUT_DIR/03_Items"
done

# 04 Icons
for d in "$ASSETS_DIR/icon-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/race-icon-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/hud-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/reward-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/result-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/ui-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done
for d in "$ASSETS_DIR/shop-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/04_Icons"; done

# 05 UI / Backgrounds
for d in "$ASSETS_DIR/bg-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"; done
for d in "$ASSETS_DIR/fortune-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"; done
for d in "$ASSETS_DIR/mine-slot"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"; done
for d in "$ASSETS_DIR/shell_"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"; done
for d in "$ASSETS_DIR/cloud-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"; done
for d in "$ASSETS_DIR/moon.imageset" "$ASSETS_DIR/hexbound-logo.imageset" "$ASSETS_DIR/hub-terrain.imageset" "$ASSETS_DIR/lady-fortuna.imageset" "$ASSETS_DIR/shopkeeper.imageset"; do
  [ -d "$d" ] && copy_visual "$d" "$TMP_OUT_DIR/05_UI_Backgrounds"
done

# 06 FX — боевые эффекты
for d in "$ASSETS_DIR/fx-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/06_FX"; done
for d in "$ASSETS_DIR/rush-buff-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/06_FX"; done
for d in "$ASSETS_DIR/rush-event-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/06_FX"; done

# 07 Buildings
for d in "$ASSETS_DIR/building-"*.imageset; do copy_visual "$d" "$TMP_OUT_DIR/07_Buildings"; done

if [ -d "$OUT_DIR" ]; then
  rm -rf "$OUT_DIR"
fi
mv "$TMP_OUT_DIR" "$OUT_DIR"
trap - EXIT

echo ""
echo "✅ Готово! Содержимое $OUT_DIR/:"
for cat in "$OUT_DIR"/*/; do
  count=$(find "$cat" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.pdf" \) | wc -l | tr -d ' ')
  echo "  $(basename "$cat"): $count assets"
done
echo ""
echo "👉 Как импортировать в Figma:"
echo "   1. Открой нужную страницу в Figma DS"
echo "   2. Меню: Main menu → Place image... (или Cmd+Shift+K)"
echo "   3. Выдели все изображения из нужной категории → Place"
echo "   4. Кликни для размещения каждого на canvas"
