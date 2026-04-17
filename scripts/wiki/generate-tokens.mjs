#!/usr/bin/env node
// Generate wiki/_generated/tokens.json from Swift theme files.
//
// Source files:
//   - Hexbound/Hexbound/Theme/DarkFantasyTheme.swift  → colors
//   - Hexbound/Hexbound/Theme/LayoutConstants.swift   → spacing, radius, icon sizes, typography
//
// Output: wiki/_generated/tokens.json
//
// Best-effort parser. Handles:
//   - Color(hex: 0xABCDEF)
//   - Color(hex: 0xABCDEF).opacity(N)
//   - aliases to other Swift symbols (stored as {alias: "symbolName"})
//   - CGFloat literals
//
// Does NOT handle: complex gradients, runtime-computed colors, conditional tokens.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..', '..');

const themeFile = resolve(repoRoot, 'Hexbound/Hexbound/Theme/DarkFantasyTheme.swift');
const layoutFile = resolve(repoRoot, 'Hexbound/Hexbound/Theme/LayoutConstants.swift');
const outFile = resolve(repoRoot, 'wiki/_generated/tokens.json');

function parseColorLine(line) {
  // Match: static let NAME = Color(hex: 0xHEX) [.opacity(N)] [// comment]
  const hexMatch = line.match(/static\s+let\s+(\w+)\s*=\s*Color\(hex:\s*0x([0-9A-Fa-f]+)\)(?:\.opacity\(([\d.]+)\))?/);
  if (hexMatch) {
    const [, name, hex, opacity] = hexMatch;
    return {
      name,
      type: 'color',
      hex: '#' + hex.toUpperCase().padStart(6, '0'),
      opacity: opacity ? parseFloat(opacity) : 1.0,
    };
  }

  // Match: static let NAME = Color.black.opacity(N) / Color.white.opacity(N)
  const systemMatch = line.match(/static\s+let\s+(\w+)\s*=\s*Color\.(black|white|clear|red|orange|green|blue|gray)(?:\.opacity\(([\d.]+)\))?/);
  if (systemMatch) {
    const [, name, systemColor, opacity] = systemMatch;
    return {
      name,
      type: 'color',
      system: systemColor,
      opacity: opacity ? parseFloat(opacity) : 1.0,
    };
  }

  // Match: static let NAME = someOtherSymbol [.opacity(N)]
  const aliasMatch = line.match(/static\s+let\s+(\w+)\s*=\s*(\w+)(?:\.opacity\(([\d.]+)\))?(?:\s*\/\/|$)/);
  if (aliasMatch) {
    const [, name, target, opacity] = aliasMatch;
    // Ignore declarations that are not simple aliases (Int, Bool, etc.)
    if (target === 'true' || target === 'false' || /^\d/.test(target)) return null;
    return {
      name,
      type: 'color',
      alias: target,
      opacity: opacity ? parseFloat(opacity) : 1.0,
    };
  }

  return null;
}

function parseCGFloatLine(line) {
  // Match: static let NAME: CGFloat = N
  const m = line.match(/static\s+let\s+(\w+)\s*:\s*CGFloat\s*=\s*([\d.]+)/);
  if (!m) return null;
  return { name: m[1], value: parseFloat(m[2]) };
}

function detectSection(line) {
  const m = line.match(/\/\/\s*MARK:\s*-?\s*(.+?)\s*$/);
  return m ? m[1].trim() : null;
}

function parseTheme() {
  const src = readFileSync(themeFile, 'utf8');
  const lines = src.split('\n');
  const colors = [];
  let currentSection = null;

  for (const line of lines) {
    const section = detectSection(line);
    if (section) currentSection = section;

    const color = parseColorLine(line);
    if (color) {
      color.section = currentSection;
      colors.push(color);
    }
  }
  return colors;
}

function parseLayout() {
  const src = readFileSync(layoutFile, 'utf8');
  const lines = src.split('\n');
  const sections = {};
  let currentSection = null;

  for (const line of lines) {
    const section = detectSection(line);
    if (section) currentSection = section;

    const v = parseCGFloatLine(line);
    if (v) {
      if (!sections[currentSection ?? 'Other']) {
        sections[currentSection ?? 'Other'] = [];
      }
      sections[currentSection ?? 'Other'].push(v);
    }
  }
  return sections;
}

function main() {
  const colors = parseTheme();
  const layout = parseLayout();

  // Group colors by section for readability.
  const colorsBySection = {};
  for (const c of colors) {
    const key = c.section ?? 'Uncategorized';
    if (!colorsBySection[key]) colorsBySection[key] = [];
    colorsBySection[key].push({ ...c, section: undefined });
  }
  // Strip undefined keys
  for (const s of Object.values(colorsBySection)) {
    s.forEach(t => { delete t.section; });
  }

  const out = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    $generatedFrom: [
      'Hexbound/Hexbound/Theme/DarkFantasyTheme.swift',
      'Hexbound/Hexbound/Theme/LayoutConstants.swift',
    ],
    $doNotEdit: 'Regenerate with scripts/wiki/generate-tokens.mjs',
    colors: colorsBySection,
    layout,
    counts: {
      colors: colors.length,
      layoutGroups: Object.keys(layout).length,
      layoutTokens: Object.values(layout).reduce((a, b) => a + b.length, 0),
    },
  };

  writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
  console.log(`✓ tokens.json: ${out.counts.colors} colors, ${out.counts.layoutTokens} layout tokens in ${out.counts.layoutGroups} groups`);
}

main();
