#!/usr/bin/env node
// Generate wiki/_generated/prisma-models.json from Prisma schema.
//
// Source: backend/prisma/schema.prisma
// Output: wiki/_generated/prisma-models.json
//
// For each model, extract:
//   - name, tableName (@@map), fields (name, type, attributes, isRelation)
//   - unique + index constraints (best-effort)
//
// For each enum, extract: name + values.
//
// Best-effort regex parser. Does NOT handle: views, composite types, generator blocks, datasources.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..', '..');

const schemaFile = resolve(repoRoot, 'backend/prisma/schema.prisma');
const outFile = resolve(repoRoot, 'wiki/_generated/prisma-models.json');

function parseFieldLine(line, enumNames) {
  // Field format: name type[?][]  [attributes]
  // Example:    id           Int       @id @default(autoincrement())
  // Example:    referrerId   String    @map("referrer_id")
  // Example:    tags         String[]
  // Example:    owner        User      @relation(fields: [ownerId], references: [id])
  const m = line.match(/^\s*(\w+)\s+(\w+)(\?)?(\[\])?\s*(.*)$/);
  if (!m) return null;

  const [, name, rawType, optional, array, attrs] = m;
  // Skip block directives like @@map or @@index
  if (name.startsWith('@')) return null;

  const isRelation = /@relation\b/.test(attrs);
  const isScalar = !isRelation && /^(String|Int|BigInt|Float|Decimal|Boolean|DateTime|Json|Bytes)$/.test(rawType);
  const isEnum = enumNames.has(rawType);
  const isModelRef = !isScalar && !isEnum && /^[A-Z]/.test(rawType);

  const field = {
    name,
    type: rawType,
    optional: !!optional,
    array: !!array,
  };

  const mapMatch = attrs.match(/@map\("([^"]+)"\)/);
  if (mapMatch) field.dbColumn = mapMatch[1];

  if (/@id\b/.test(attrs)) field.isId = true;
  if (/@unique\b/.test(attrs)) field.isUnique = true;
  if (/@updatedAt\b/.test(attrs)) field.isUpdatedAt = true;
  const defaultMatch = attrs.match(/@default\(([^)]+)\)/);
  if (defaultMatch) field.default = defaultMatch[1];

  if (isRelation) field.relation = true;
  if (isEnum) field.isEnum = true;
  if (isModelRef && !isRelation) field.modelRef = true;

  return field;
}

function parseSchema(src) {
  const lines = src.split('\n');
  const enums = {};
  const models = {};
  const enumNames = new Set();

  // First pass: collect enum names (needed to classify fields).
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^enum\s+(\w+)\s*\{/);
    if (m) enumNames.add(m[1]);
  }

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    // Enum block
    const enumStart = line.match(/^enum\s+(\w+)\s*\{/);
    if (enumStart) {
      const name = enumStart[1];
      const values = [];
      i++;
      while (i < lines.length && !lines[i].match(/^\s*\}/)) {
        const v = lines[i].trim();
        if (v && !v.startsWith('//') && !v.startsWith('@')) {
          values.push(v.replace(/\s+.*$/, '')); // strip trailing comments
        }
        i++;
      }
      enums[name] = values;
      i++;
      continue;
    }

    // Model block
    const modelStart = line.match(/^model\s+(\w+)\s*\{/);
    if (modelStart) {
      const name = modelStart[1];
      const fields = [];
      const indexes = [];
      const uniques = [];
      let tableName = null;

      i++;
      while (i < lines.length && !lines[i].match(/^\s*\}/)) {
        const raw = lines[i];
        const tm = raw.match(/@@map\("([^"]+)"\)/);
        if (tm) {
          tableName = tm[1];
          i++;
          continue;
        }
        const idxm = raw.match(/@@index\(\[([^\]]+)\]/);
        if (idxm) {
          indexes.push(idxm[1].split(',').map(s => s.trim()));
          i++;
          continue;
        }
        const uniqm = raw.match(/@@unique\(\[([^\]]+)\]/);
        if (uniqm) {
          uniques.push(uniqm[1].split(',').map(s => s.trim()));
          i++;
          continue;
        }
        // Skip block-level directives and empty/comment lines.
        if (raw.trim().startsWith('//') || raw.trim() === '' || raw.trim().startsWith('@@')) {
          i++;
          continue;
        }
        const field = parseFieldLine(raw, enumNames);
        if (field) fields.push(field);
        i++;
      }
      models[name] = {
        name,
        tableName,
        fields,
        indexes,
        uniques,
      };
      i++;
      continue;
    }

    i++;
  }

  return { enums, models };
}

function main() {
  const src = readFileSync(schemaFile, 'utf8');
  const { enums, models } = parseSchema(src);

  const out = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    $generatedFrom: 'backend/prisma/schema.prisma',
    $doNotEdit: 'Regenerate with scripts/wiki/generate-prisma-models.mjs',
    counts: {
      models: Object.keys(models).length,
      enums: Object.keys(enums).length,
      totalFields: Object.values(models).reduce((a, m) => a + m.fields.length, 0),
    },
    enums,
    models,
  };

  writeFileSync(outFile, JSON.stringify(out, null, 2) + '\n');
  console.log(`✓ prisma-models.json: ${out.counts.models} models, ${out.counts.enums} enums, ${out.counts.totalFields} fields`);
}

main();
