#!/bin/bash
# Copy landing page assets from iOS project
# Run from project root: bash hexbound-landing/copy-assets.sh

DEST="hexbound-landing/assets"
XCASSETS="Hexbound/Hexbound/Resources/Assets.xcassets"
mkdir -p "$DEST"

echo "Copying buildings..."
for f in building-arena building-battlepass building-dungeon building-gold-mine building-shop building-tavern; do
  cp "$XCASSETS/${f}.imageset/${f}.png" "$DEST/" 2>/dev/null && echo "  ✓ $f"
done

echo "Copying dungeon buildings..."
for f in building-dungeon-catacombs building-dungeon-frozen-abyss building-dungeon-infernal-throne building-dungeon-volcanic-forge; do
  cp "$XCASSETS/${f}.imageset/${f}.png" "$DEST/" 2>/dev/null && echo "  ✓ $f"
done

echo "Copying class icons..."
for f in icon-mage icon-rogue icon-tank icon-warrior; do
  src=$(find "$XCASSETS" -name "${f}.png" | head -1)
  [ -n "$src" ] && cp "$src" "$DEST/" && echo "  ✓ $f"
done

echo "Copying race icons..."
for f in race-icon-demon race-icon-dogfolk race-icon-human race-icon-orc race-icon-skeleton; do
  cp "$XCASSETS/${f}.imageset/${f}.png" "$DEST/" 2>/dev/null && echo "  ✓ $f"
done

echo "Copying boss full arts..."
for f in $(find "$XCASSETS/Bosses" -name "*-full.png" 2>/dev/null); do
  name=$(basename "$f")
  cp "$f" "$DEST/" && echo "  ✓ $name"
done

echo "Copying backgrounds..."
for f in bg-arena bg-dungeon bg-forge bg-hub bg-shell-game; do
  src=$(find "$XCASSETS" -name "${f}.*" -path "*imageset*" | head -1)
  if [ -n "$src" ]; then
    ext="${src##*.}"
    # Landing expects .jpg for backgrounds
    cp "$src" "$DEST/${f}.jpg" && echo "  ✓ $f"
  fi
done

echo ""
echo "=== Missing (need manual copy or download from Vercel) ==="
for f in logo.png appicon.png; do
  [ ! -f "$DEST/$f" ] && echo "  ✗ $f — download from https://hexbound-landing.vercel.app/assets/$f"
done

echo ""
echo "Done! Check $DEST/"
ls -la "$DEST/" | wc -l
echo "files total"
