#!/usr/bin/env node
// Generate wiki/_generated/api-routes.json from backend Next.js route files.
//
// Source: backend/src/app/api/**/route.ts
// Output: wiki/_generated/api-routes.json
//
// For each route file, extract:
//   - URL path (derived from folder structure, [param] → :param)
//   - HTTP methods exported (GET/POST/PATCH/PUT/DELETE)
//   - requiresAuth (true if file imports getAuthUser / requireAuth / requireAdminAuth)
//   - adminOnly (true if file imports requireAdminAuth)
//   - rateLimit (true if file imports rateLimit)
//
// Best-effort. Does not run TypeScript — pure text heuristics.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readdirSync, statSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..', '..');

const apiRoot = resolve(repoRoot, 'backend/src/app/api');
const outFile = resolve(repoRoot, 'wiki/_generated/api-routes.json');

function walk(dir) {
  const results = [];
  for (const entry of readdirSync(dir)) {
    const full = resolve(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) {
      results.push(...walk(full));
    } else if (entry === 'route.ts' || entry === 'route.tsx') {
      results.push(full);
    }
  }
  return results;
}

function filePathToUrl(filePath) {
  const rel = relative(apiRoot, dirname(filePath));
  if (!rel) return '/api';
  const segments = rel.split(sep).map(seg => {
    // Next.js dynamic segments: [id] → :id, [...slug] → :slug*
    const dyn = seg.match(/^\[(\.\.\.)?(\w+)\]$/);
    if (dyn) return dyn[1] ? `:${dyn[2]}*` : `:${dyn[2]}`;
    // Route groups in parentheses are ignored by Next.js URL structure
    if (seg.startsWith('(') && seg.endsWith(')')) return null;
    return seg;
  }).filter(Boolean);
  return '/api/' + segments.join('/');
}

function analyzeFile(filePath) {
  const src = readFileSync(filePath, 'utf8');

  const methods = [];
  for (const m of ['GET', 'POST', 'PATCH', 'PUT', 'DELETE']) {
    const re = new RegExp(`export\\s+(?:async\\s+)?function\\s+${m}\\b`);
    if (re.test(src)) methods.push(m);
  }

  const requiresAuth = /\b(getAuthUser|requireAuth|requireAdminAuth|getSession|getCurrentUser)\b/.test(src);
  const adminOnly = /\b(requireAdminAuth|requireAdmin|isAdmin|adminAuth)\b/.test(src)
                 || filePath.includes(sep + 'admin' + sep);
  const rateLimited = /\brateLimit\b/.test(src);
  const idempotencyKey = /idempotencyKey|Idempotency-Key/i.test(src);
  const hasTransaction = /prisma\.\$transaction/.test(src);

  return { methods, requiresAuth, adminOnly, rateLimited, idempotencyKey, hasTransaction };
}

function main() {
  const files = walk(apiRoot).sort();
  const routes = [];

  for (const f of files) {
    const url = filePathToUrl(f);
    const analysis = analyzeFile(f);
    routes.push({
      url,
      file: relative(repoRoot, f),
      ...analysis,
    });
  }

  // Group by top-level namespace for easier scanning.
  const byNamespace = {};
  for (const r of routes) {
    const parts = r.url.split('/').filter(Boolean);
    const ns = parts[1] ?? 'root';
    if (!byNamespace[ns]) byNamespace[ns] = [];
    byNamespace[ns].push(r);
  }

  const out = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    $generatedFrom: 'backend/src/app/api/**/route.ts',
    $doNotEdit: 'Regenerate with scripts/wiki/generate-api-routes.mjs',
    counts: {
      total: routes.length,
      withAuth: routes.filter(r => r.requiresAuth).length,
      admin: routes.filter(r => r.adminOnly).length,
      rateLimited: routes.filter(r => r.rateLimited).length,
      transactional: routes.filter(r => r.hasTransaction).length,
      namespaces: Object.keys(byNamespace).length,
    },
    routes: byNamespace,
  };

  writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
  console.log(`✓ api-routes.json: ${out.counts.total} routes, ${out.counts.withAuth} with auth, ${out.counts.admin} admin, ${out.counts.rateLimited} rate-limited`);
}

main();
