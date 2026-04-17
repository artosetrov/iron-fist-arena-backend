#!/usr/bin/env node
// Generate wiki/_generated/ios-screens.json from the iOS SwiftUI navigation graph + views.
//
// Sources:
//   - Hexbound/Hexbound/App/AppRouter.swift         (routes + destination mapping)
//   - Hexbound/Hexbound/Views/**/*.swift            (screen inventory)
//
// Output: wiki/_generated/ios-screens.json
//
// What this emits:
//   - `routes`: every `AppRoute` case with its associated values, the View struct it
//               lands on, and whether it lives in Main or Auth router.
//   - `tabs`:   the HubTab enum (bottom-tab destinations).
//   - `screens`: every View struct declared under Views/, indexed by name, with path,
//                category (folder), and whether it backs a route.
//
// Regex-based parser — tuned for the current Hexbound AppRouter style. If the router
// structure changes, update this generator.

import { readFileSync, writeFileSync } from 'node:fs';
import { readdirSync, statSync } from 'node:fs';
import { resolve, dirname, relative, join, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..', '..');

const routerFile = resolve(repoRoot, 'Hexbound/Hexbound/App/AppRouter.swift');
const viewsRoot = resolve(repoRoot, 'Hexbound/Hexbound/Views');
const outFile = resolve(repoRoot, 'wiki/_generated/ios-screens.json');

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function findBlockEnd(src, startIdx) {
  let depth = 0;
  let inString = null;
  let i = startIdx;
  while (i < src.length) {
    const ch = src[i];
    const prev = src[i - 1];
    if (inString) {
      if (ch === inString && prev !== '\\') inString = null;
      i++;
      continue;
    }
    if (ch === '"' || ch === "'") {
      inString = ch;
      i++;
      continue;
    }
    if (ch === '/' && src[i + 1] === '/') {
      while (i < src.length && src[i] !== '\n') i++;
      continue;
    }
    if (ch === '/' && src[i + 1] === '*') {
      i += 2;
      while (i < src.length && !(src[i] === '*' && src[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    if (ch === '{') depth++;
    else if (ch === '}') {
      depth--;
      if (depth === 0) return i;
    }
    i++;
  }
  return -1;
}

function listSwiftFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const s = statSync(full);
    if (s.isDirectory()) out.push(...listSwiftFiles(full));
    else if (s.isFile() && name.endsWith('.swift')) out.push(full);
  }
  return out;
}

// -----------------------------------------------------------------------------
// Router parsing
// -----------------------------------------------------------------------------

function parseAppRoute(src) {
  // Isolate the `enum AppRoute` block.
  const enumHdr = src.match(/enum\s+AppRoute[^\{]*\{/);
  if (!enumHdr) return [];
  const start = enumHdr.index + enumHdr[0].length - 1; // points to '{'
  const end = findBlockEnd(src, start);
  const body = src.slice(start + 1, end);

  const routes = [];
  const lines = body.split('\n');
  let pendingComment = [];
  for (const raw of lines) {
    const line = raw.trim();
    if (line.startsWith('//')) {
      pendingComment.push(line.replace(/^\/\/\s?/, '').trim());
      continue;
    }
    if (line.startsWith('///')) {
      pendingComment.push(line.replace(/^\/\/\/\s?/, '').trim());
      continue;
    }
    if (line === '' || line.startsWith('/*') || line.endsWith('*/')) {
      if (line === '') pendingComment = [];
      continue;
    }
    const m = line.match(/^case\s+([A-Za-z_]\w*)(?:\(([^)]*)\))?/);
    if (!m) continue;
    const name = m[1];
    const assocRaw = m[2];
    const assoc = assocRaw
      ? assocRaw.split(',').map((p) => {
          // e.g. "characterId: String", "initialTab: Int = 0"
          const partMatch = p.trim().match(/^([A-Za-z_]\w*)\s*:\s*(.+?)(?:\s*=\s*.+)?$/);
          if (!partMatch) return { raw: p.trim() };
          return { label: partMatch[1], type: partMatch[2].trim() };
        })
      : [];
    routes.push({
      name,
      associatedValues: assoc,
      doc: pendingComment.length ? pendingComment.join(' ') : undefined,
    });
    pendingComment = [];
  }
  return routes;
}

function parseHubTab(src) {
  const enumHdr = src.match(/enum\s+HubTab[^\{]*\{/);
  if (!enumHdr) return [];
  const start = enumHdr.index + enumHdr[0].length - 1;
  const end = findBlockEnd(src, start);
  const body = src.slice(start + 1, end);

  const tabs = [];
  for (const line of body.split('\n')) {
    const m = line.trim().match(/^case\s+(\w+)(?:\s*=\s*(\d+))?/);
    if (m) tabs.push({ name: m[1], rawValue: m[2] ? Number(m[2]) : null });
  }
  // Extract label + icon maps.
  const labelMatches = [...body.matchAll(/case\s+\.(\w+):\s*"([^"]+)"/g)];
  // The first cluster is icon, second is label (per file ordering). We only capture labels here by
  // selecting matches AFTER the `label:` property declaration.
  const labelIdx = body.indexOf('var label:');
  const labelScope = labelIdx > 0 ? body.slice(labelIdx) : body;
  const labelMap = {};
  for (const mm of labelScope.matchAll(/case\s+\.(\w+):\s*"([^"]+)"/g)) {
    labelMap[mm[1]] = mm[2];
  }
  const iconIdx = body.indexOf('var icon:');
  const iconEnd = labelIdx > iconIdx ? labelIdx : body.length;
  const iconScope = iconIdx >= 0 ? body.slice(iconIdx, iconEnd) : '';
  const iconMap = {};
  for (const mm of iconScope.matchAll(/case\s+\.(\w+):\s*"([^"]+)"/g)) {
    iconMap[mm[1]] = mm[2];
  }

  return tabs.map((t) => ({
    ...t,
    label: labelMap[t.name] ?? null,
    icon: iconMap[t.name] ?? null,
  }));
}

function parseDestinationMap(src) {
  // We want every `case .NAME: SomeView()`, `case .NAME(let ...): SomeView(...)`,
  // AND multi-case `case .A, .B, .C: SomeView()` forms.
  // Works for both MainRouterView.destination(for:) and the AuthRouterView body switch.
  const map = {};

  // 1) Single-case matches (supports optional associated-value pattern).
  const singleRe = /case\s+\.([A-Za-z_]\w*)(?:\(([^)]*)\))?\s*:\s*([^\n]+)/g;
  let m;
  while ((m = singleRe.exec(src)) !== null) {
    const routeName = m[1];
    const body = m[3].trim();
    const ctor = body.match(/^([A-Z][\w.]*)\s*\(/);
    const entry = { view: ctor ? ctor[1] : null, raw: body.replace(/\s+/g, ' ').trim() };
    const existing = map[routeName];
    if (!existing || (entry.view && !existing.view)) map[routeName] = entry;
  }

  // 2) Multi-case matches: `case .a, .b, .c: View()` (possibly wrapping across lines).
  //    Accept everything between `case ` and the first `:` as a comma-list of dotted refs,
  //    then the body on the same line (or across lines until a newline breaks it).
  const multiRe = /case\s+((?:\.[A-Za-z_]\w*\s*,\s*)+\.[A-Za-z_]\w*)\s*:\s*([^\n]+(?:\n\s*[^\n]+)?)/g;
  while ((m = multiRe.exec(src)) !== null) {
    const names = m[1].split(',').map((n) => n.trim().replace(/^\./, ''));
    const body = m[2].trim();
    const ctor = body.match(/^([A-Z][\w.]*)\s*\(/);
    const entry = { view: ctor ? ctor[1] : null, raw: body.replace(/\s+/g, ' ').trim(), multiCase: true };
    for (const routeName of names) {
      const existing = map[routeName];
      // Prefer a single-case with a resolved view over a multi-case PlaceholderView fallback.
      if (!existing) map[routeName] = entry;
      else if (entry.view && !existing.view) map[routeName] = entry;
    }
  }

  return map;
}

function locateRouter(src) {
  // Identify if a route was matched under MainRouterView's destination or AuthRouterView body.
  const mainStart = src.indexOf('struct MainRouterView');
  const authStart = src.indexOf('struct AuthRouterView');
  const ranges = [];
  if (mainStart >= 0) {
    const braceIdx = src.indexOf('{', mainStart);
    const end = findBlockEnd(src, braceIdx);
    ranges.push({ name: 'main', start: mainStart, end });
  }
  if (authStart >= 0) {
    const braceIdx = src.indexOf('{', authStart);
    const end = findBlockEnd(src, braceIdx);
    ranges.push({ name: 'auth', start: authStart, end });
  }
  return ranges;
}

function classifyRoute(src, routerRanges, routeName) {
  // Prefer a single-case `case .routeName:` (with associated pattern optional) over a
  // multi-case fallback like `case .a, .b, .routeName:`. This makes `.login` classify as
  // `auth` (where it has its own arm) rather than `main` (where it falls through).
  const singleRe = new RegExp(`case\\s+\\.${routeName}(?:\\([^)]*\\))?\\s*:`);
  const anyRe = new RegExp(`\\.${routeName}\\b`);

  const rangeFor = (needle) => {
    const idx = src.search(needle);
    if (idx < 0) return null;
    for (const r of routerRanges) {
      if (idx >= r.start && idx <= r.end) return r.name;
    }
    return null;
  };

  return rangeFor(singleRe) ?? rangeFor(anyRe);
}

// -----------------------------------------------------------------------------
// Screen inventory
// -----------------------------------------------------------------------------

function parseViewFile(path) {
  const src = readFileSync(path, 'utf8');
  // Identify `struct X: View`, `struct X<...>: View`.
  const views = [];
  const re = /struct\s+([A-Z][A-Za-z0-9_]*)(?:<[^>]+>)?\s*:\s*([^{]+)\{/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    const name = m[1];
    const protocols = m[2].split(',').map((p) => p.trim());
    if (protocols.includes('View')) {
      views.push(name);
    }
  }
  return views;
}

// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

function main() {
  const routerSrc = readFileSync(routerFile, 'utf8');
  const routes = parseAppRoute(routerSrc);
  const tabs = parseHubTab(routerSrc);
  const destMap = parseDestinationMap(routerSrc);
  const routerRanges = locateRouter(routerSrc);

  // Inventory all View structs.
  const files = listSwiftFiles(viewsRoot).sort();
  const viewIndex = {}; // viewName → [{ path, category }]
  const screens = {};
  for (const f of files) {
    const rel = relative(repoRoot, f).split(sep).join('/');
    const parts = relative(viewsRoot, f).split(sep);
    const category = parts.length > 1 ? parts[0] : 'root';
    const views = parseViewFile(f);
    for (const v of views) {
      (viewIndex[v] ??= []).push({ path: rel, category });
      if (!screens[v]) screens[v] = { name: v, path: rel, category, routes: [] };
    }
  }

  // Wire routes → views.
  const enrichedRoutes = routes.map((r) => {
    const dest = destMap[r.name];
    const routerName = classifyRoute(routerSrc, routerRanges, r.name) ?? 'main';
    let viewFile = null;
    if (dest?.view && viewIndex[dest.view]) {
      viewFile = viewIndex[dest.view][0].path;
      // Record route on the screen.
      if (screens[dest.view]) screens[dest.view].routes.push(r.name);
    }
    return {
      case: r.name,
      associatedValues: r.associatedValues,
      doc: r.doc,
      destinationView: dest?.view ?? null,
      destinationRaw: dest?.raw ?? null,
      viewFile,
      router: routerName,
    };
  });

  const out = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    $generatedFrom: [
      'Hexbound/Hexbound/App/AppRouter.swift',
      'Hexbound/Hexbound/Views/**/*.swift',
    ],
    $doNotEdit: 'Regenerate with scripts/wiki/generate-ios-screens.mjs',
    counts: {
      routes: enrichedRoutes.length,
      tabs: tabs.length,
      screens: Object.keys(screens).length,
      viewFiles: files.length,
      routesWithDestination: enrichedRoutes.filter((r) => r.destinationView).length,
    },
    tabs,
    routes: enrichedRoutes,
    screens,
  };

  writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
  const missing = enrichedRoutes.filter((r) => !r.destinationView).map((r) => r.case);
  const missingNote = missing.length ? ` (⚠ ${missing.length} routes without a resolved View: ${missing.join(', ')})` : '';
  console.log(
    `✓ ios-screens.json: ${out.counts.routes} routes → ${out.counts.routesWithDestination} resolved, ` +
    `${out.counts.screens} View structs across ${out.counts.viewFiles} files${missingNote}`,
  );
}

main();
