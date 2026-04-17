#!/usr/bin/env node
// Generate wiki/_generated/balance-constants.json from backend/src/lib/game/balance.ts.
//
// Source: backend/src/lib/game/balance.ts
// Output: wiki/_generated/balance-constants.json
//
// Strategy: brace-matching walker that finds each `export const NAME(: Type)? = <value>;`
// block, strips TS-only tokens (`as const`, `as readonly X[]`, `satisfies ...`), and
// evaluates the remaining JS literal in a sandboxed `new Function`. If a value can't
// be evaluated, the raw source is kept as a string under `__raw`.
//
// Functions are captured as `{ signature, body }` only — we don't execute them.
//
// Best-effort: tuned for this file's style. If balance.ts grows complex control flow
// or imports, this generator needs updating.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..', '..');

const srcFile = resolve(repoRoot, 'backend/src/lib/game/balance.ts');
const outFile = resolve(repoRoot, 'wiki/_generated/balance-constants.json');

// -----------------------------------------------------------------------------
// Scanner — walks the source, emits top-level `export const` and `export function`
// declarations.
// -----------------------------------------------------------------------------

function findBlockEnd(src, startIdx, openCh, closeCh) {
  let depth = 0;
  let inString = null; // '"', "'", "`"
  let i = startIdx;
  while (i < src.length) {
    const ch = src[i];
    const prev = src[i - 1];
    if (inString) {
      if (ch === inString && prev !== '\\') inString = null;
      i++;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') {
      inString = ch;
      i++;
      continue;
    }
    // skip line comment
    if (ch === '/' && src[i + 1] === '/') {
      while (i < src.length && src[i] !== '\n') i++;
      continue;
    }
    // skip block comment
    if (ch === '/' && src[i + 1] === '*') {
      i += 2;
      while (i < src.length && !(src[i] === '*' && src[i + 1] === '/')) i++;
      i += 2;
      continue;
    }
    if (ch === openCh) depth++;
    else if (ch === closeCh) {
      depth--;
      if (depth === 0) return i;
    }
    i++;
  }
  return -1;
}

function findStatementEnd(src, startIdx) {
  // Walk forward until we see a top-level `;` (depth 0 braces/brackets/parens) or EOF.
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
    if (ch === '"' || ch === "'" || ch === '`') {
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
    if (ch === '{' || ch === '[' || ch === '(') depth++;
    else if (ch === '}' || ch === ']' || ch === ')') depth--;
    else if (ch === ';' && depth === 0) return i;
    i++;
  }
  return -1;
}

// -----------------------------------------------------------------------------
// Value evaluator — strips TS-only syntax from an expression and evaluates.
// -----------------------------------------------------------------------------

function stripTypeScript(expr) {
  let s = expr;

  // Remove `satisfies Record<...>` and `satisfies Foo` clauses.
  // Matches ` satisfies ` followed by a type, up to a comma / close-brace / close-bracket / EOS.
  s = s.replace(/\s+satisfies\s+[A-Za-z_][\w.]*(\s*<[^>]+>)?(\s*\[\s*\])?/g, '');

  // Remove `as const`, `as readonly SomeType[]`, `as SomeType`.
  s = s.replace(/\s+as\s+readonly\s+[A-Za-z_][\w.]*(\s*\[\s*\])?/g, '');
  s = s.replace(/\s+as\s+const\b/g, '');
  s = s.replace(/\s+as\s+[A-Za-z_][\w.]*(\s*<[^>]+>)?(\s*\[\s*\])?/g, '');

  return s;
}

function tryEval(expr, name) {
  const stripped = stripTypeScript(expr).trim();
  try {
    // eslint-disable-next-line no-new-func
    const fn = new Function(`"use strict"; return (${stripped});`);
    return { ok: true, value: fn() };
  } catch (err) {
    return { ok: false, raw: stripped, error: err.message, originalName: name };
  }
}

// -----------------------------------------------------------------------------
// Parser — emits list of declarations.
// -----------------------------------------------------------------------------

function parse(src) {
  const decls = [];
  // Match declarations anchored at the start of a line.
  const declRe = /^export\s+(const|function|interface|type)\s+(\w+)/gm;
  let m;
  while ((m = declRe.exec(src)) !== null) {
    const kind = m[1];
    const name = m[2];
    const declStart = m.index;

    if (kind === 'const') {
      // Find `=` then the value
      const eqIdx = src.indexOf('=', m.index);
      if (eqIdx < 0) continue;
      // The type annotation, if any, lives between the name and the `=`.
      const header = src.slice(m.index, eqIdx);
      const typeMatch = header.match(/:\s*(.+?)\s*$/s);
      const typeAnnotation = typeMatch ? typeMatch[1].trim() : null;

      const valueStart = eqIdx + 1;
      const stmtEnd = findStatementEnd(src, valueStart);
      if (stmtEnd < 0) continue;
      const rawValue = src.slice(valueStart, stmtEnd).trim();

      // Capture the preceding comment block (contiguous `//` lines + `/** */`).
      const comment = extractPrecedingComment(src, declStart);

      decls.push({
        kind: 'const',
        name,
        typeAnnotation,
        rawValue,
        comment,
      });
      declRe.lastIndex = stmtEnd + 1;
      continue;
    }

    if (kind === 'function') {
      // Grab signature up to the opening `{`
      const braceIdx = src.indexOf('{', m.index);
      if (braceIdx < 0) continue;
      const signature = src.slice(m.index, braceIdx).trim();
      const end = findBlockEnd(src, braceIdx, '{', '}');
      if (end < 0) continue;
      const body = src.slice(braceIdx + 1, end).trim();
      const comment = extractPrecedingComment(src, declStart);
      decls.push({
        kind: 'function',
        name,
        signature,
        body,
        comment,
      });
      declRe.lastIndex = end + 1;
      continue;
    }

    if (kind === 'interface' || kind === 'type') {
      // Skip the block; these are TS-only and have no runtime value.
      const braceIdx = src.indexOf('{', m.index);
      const semiIdx = src.indexOf(';', m.index);
      let end;
      if (braceIdx > 0 && (semiIdx < 0 || braceIdx < semiIdx)) {
        end = findBlockEnd(src, braceIdx, '{', '}');
      } else {
        end = semiIdx;
      }
      if (end < 0) continue;
      declRe.lastIndex = end + 1;
      continue;
    }
  }
  return decls;
}

function extractPrecedingComment(src, declStart) {
  // Walk backward from declStart collecting contiguous comment lines + doc blocks.
  let i = declStart - 1;
  // Skip trailing whitespace before the decl.
  while (i >= 0 && (src[i] === ' ' || src[i] === '\t')) i--;
  if (i < 0 || src[i] !== '\n') return null;

  const commentLines = [];
  // Walk up line by line.
  let lineEnd = i; // at the '\n' right before the decl
  while (lineEnd > 0) {
    const lineStart = src.lastIndexOf('\n', lineEnd - 1) + 1;
    const line = src.slice(lineStart, lineEnd).trimEnd();
    const trimmed = line.trim();
    if (trimmed.startsWith('//')) {
      commentLines.unshift(trimmed.replace(/^\/\/\s?/, ''));
      lineEnd = lineStart - 1;
      continue;
    }
    if (trimmed.endsWith('*/')) {
      // Capture multi-line block comment.
      const blockEnd = lineEnd;
      const blockStartIdx = src.lastIndexOf('/*', blockEnd);
      if (blockStartIdx < 0) break;
      const block = src.slice(blockStartIdx, blockEnd);
      const cleaned = block
        .replace(/^\/\*+/, '')
        .replace(/\*+\/$/, '')
        .split('\n')
        .map((l) => l.replace(/^\s*\*\s?/, '').trim())
        .filter((l) => l.length > 0);
      for (let j = cleaned.length - 1; j >= 0; j--) commentLines.unshift(cleaned[j]);
      lineEnd = src.lastIndexOf('\n', blockStartIdx - 1);
      continue;
    }
    if (trimmed === '') {
      // Stop at blank line — it breaks comment/code association.
      break;
    }
    break;
  }
  if (commentLines.length === 0) return null;
  return commentLines.join('\n');
}

// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

function main() {
  const src = readFileSync(srcFile, 'utf8');
  const decls = parse(src);

  const constants = {};
  const functions = {};
  const unevaluated = [];

  for (const d of decls) {
    if (d.kind === 'const') {
      const res = tryEval(d.rawValue, d.name);
      if (res.ok) {
        constants[d.name] = {
          value: res.value,
          typeAnnotation: d.typeAnnotation || undefined,
          doc: d.comment || undefined,
        };
      } else {
        unevaluated.push({ name: d.name, error: res.error, rawValue: d.rawValue });
        constants[d.name] = {
          __raw: res.raw,
          error: res.error,
          typeAnnotation: d.typeAnnotation || undefined,
          doc: d.comment || undefined,
        };
      }
    } else if (d.kind === 'function') {
      functions[d.name] = {
        signature: d.signature.replace(/\s+/g, ' '),
        body: d.body,
        doc: d.comment || undefined,
      };
    }
  }

  const out = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    $generatedFrom: 'backend/src/lib/game/balance.ts',
    $doNotEdit: 'Regenerate with scripts/wiki/generate-balance-constants.mjs',
    counts: {
      constants: Object.keys(constants).length,
      functions: Object.keys(functions).length,
      unevaluated: unevaluated.length,
    },
    constants,
    functions,
  };

  writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
  const ueNote = unevaluated.length > 0
    ? ` (⚠ ${unevaluated.length} unevaluated: ${unevaluated.map((u) => u.name).join(', ')})`
    : '';
  console.log(`✓ balance-constants.json: ${out.counts.constants} constants, ${out.counts.functions} functions${ueNote}`);
}

main();
