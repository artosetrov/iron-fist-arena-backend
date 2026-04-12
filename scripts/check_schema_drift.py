#!/usr/bin/env python3
"""
check_schema_drift.py — Prisma schema ↔ migrations drift detector.

Catches the class of bug where a developer adds a field to `schema.prisma`
but forgets to create a `migration.sql`. On Vercel, `prisma migrate deploy`
then no-ops while `prisma generate` happily builds a TS client that queries
columns the DB doesn't have → prod 500s.

Root cause of the 2026-04-11 Gold Mine Variant D Phase 2 incident
(commit d4450b4): 11 columns + 2 indexes added to schema.prisma without
a migration file. This script would have caught it in ~0.2s.

Usage:
  python3 scripts/check_schema_drift.py             # exit 1 on any drift
  python3 scripts/check_schema_drift.py --verbose   # list every expected column

What it checks:
  1. Every `@map("col_name")` inside a model field is present somewhere in
     `prisma/migrations/**/migration.sql` (either via CREATE TABLE or
     ALTER TABLE ADD COLUMN).
  2. Every `@@index([...])` is present as a CREATE INDEX in the migrations.
  3. Every `@@unique([...])` is present as a UNIQUE constraint/index.

Schema qualifiers: accepts both `"table"` and `"public"."table"` in SQL.
Field→column translation: indexes/uniques use Prisma field names, which
this script translates via the field's own `@map` declaration.

Exit codes:
  0 — no drift
  1 — drift detected (missing columns / indexes)
  2 — parse error or missing files
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
SCHEMA_PATH = REPO_ROOT / "backend" / "prisma" / "schema.prisma"
MIGRATIONS_DIR = REPO_ROOT / "backend" / "prisma" / "migrations"

VERBOSE = "--verbose" in sys.argv or "-v" in sys.argv


# ─────────────────────────────────────────────────────────────────────────────
# Parse schema.prisma
# ─────────────────────────────────────────────────────────────────────────────

MODEL_RE = re.compile(r"^model\s+(\w+)\s*\{", re.MULTILINE)

# Field line with @map — MUST NOT match @@map. Using (?<!@) lookbehind.
FIELD_LINE_RE = re.compile(
    r"^\s*(\w+)\s+[^\n]*?(?<!@)@map\(\"([^\"]+)\"\)",
    re.MULTILINE,
)

# Table-level @@map (the table name for the model)
TABLE_MAP_RE = re.compile(r'@@map\("([^"]+)"\)')

INDEX_RE = re.compile(r"@@index\(\[([^\]]+)\]")
UNIQUE_RE = re.compile(r"@@unique\(\[([^\]]+)\]")


def _clean_field(s: str) -> str:
    """Strip whitespace and field modifiers like `(sort: Desc)`."""
    s = s.strip()
    s = re.sub(r"\(.*?\)", "", s)  # strip parenthesized modifiers
    return s.strip()


def parse_schema(schema_text: str) -> Dict[str, Dict]:
    """
    Return a dict keyed by DB table name (as it appears in migrations):
        {
          "characters": {
            "model_name": "Character",
            "columns": set[str],               # snake_case DB columns
            "field_to_col": {prismaField: col},# for index translation
            "indexes": [[col1, col2], ...],    # already translated to snake_case
            "uniques": [[col1, col2], ...],    # already translated
          },
          ...
        }
    """
    results: Dict[str, Dict] = {}

    # Split schema into model blocks
    blocks: List[Tuple[str, str]] = []
    for m in MODEL_RE.finditer(schema_text):
        start = m.end()
        depth = 1
        i = start
        while i < len(schema_text) and depth > 0:
            c = schema_text[i]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            i += 1
        blocks.append((m.group(1), schema_text[start : i - 1]))

    for model_name, body in blocks:
        tmap = TABLE_MAP_RE.search(body)
        table = tmap.group(1) if tmap else model_name

        # Build field_name -> column_name via per-field @map
        field_to_col: Dict[str, str] = {}
        for fm in FIELD_LINE_RE.finditer(body):
            field_to_col[fm.group(1)] = fm.group(2)

        # For fields without @map, Prisma uses the field name as-is as column name.
        # We can't enumerate all fields reliably without a full parser, but we
        # only need the mapping for fields that appear in @@index/@@unique.
        # Fallback: if an index references a field we didn't see with @map,
        # assume column name == field name.

        columns: Set[str] = set(field_to_col.values())

        def translate(field_names: List[str]) -> List[str]:
            return [field_to_col.get(f, f) for f in field_names]

        indexes: List[List[str]] = []
        for im in INDEX_RE.finditer(body):
            fields = [_clean_field(c) for c in im.group(1).split(",")]
            indexes.append(translate(fields))

        uniques: List[List[str]] = []
        for um in UNIQUE_RE.finditer(body):
            fields = [_clean_field(c) for c in um.group(1).split(",")]
            uniques.append(translate(fields))

        results[table] = {
            "model_name": model_name,
            "columns": columns,
            "field_to_col": field_to_col,
            "indexes": indexes,
            "uniques": uniques,
        }

    return results


# ─────────────────────────────────────────────────────────────────────────────
# Parse migrations
# ─────────────────────────────────────────────────────────────────────────────

# Table refs in SQL: "table" or "public"."table" or bare `table`
# Three alternatives wrapped in a non-capturing group, capturing the bare name once.
_TBL = r'(?:"(?:public)"\."([^"]+)"|"([^"]+)"|(\w+))'

# CREATE TABLE [IF NOT EXISTS] ["public".]"table" ( ... );
CREATE_TABLE_RE = re.compile(
    rf'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?{_TBL}\s*\((.*?)\);',
    re.IGNORECASE | re.DOTALL,
)

# Whole-statement ALTER TABLE ... ; so we can pick up multi-column forms:
#   ALTER TABLE "characters"
#     ADD COLUMN "shards_common" INTEGER ...,
#     ADD COLUMN "shards_rare"   INTEGER ...;
ALTER_TABLE_STMT_RE = re.compile(
    rf'ALTER\s+TABLE\s+(?:ONLY\s+)?{_TBL}\s+(.*?);',
    re.IGNORECASE | re.DOTALL,
)
ADD_COL_INSIDE_ALTER_RE = re.compile(
    r'ADD\s+COLUMN\s+(?:IF\s+NOT\s+EXISTS\s+)?"([^"]+)"',
    re.IGNORECASE,
)

# CREATE [UNIQUE] INDEX [IF NOT EXISTS] <name> ON <table> ( ... )
# Name and table may or may not be quoted.
_IDX_NAME = r'(?:"([^"]+)"|(\w+))'
CREATE_INDEX_RE = re.compile(
    rf'CREATE\s+(UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?{_IDX_NAME}\s+ON\s+{_TBL}\s*\(([^)]+)\)',
    re.IGNORECASE,
)
# Column name inside CREATE TABLE body: quoted "col_name" TYPE ... or bare col_name TYPE ...
# The bare-word form must NOT match SQL keywords that appear at line-start inside a body.
_SQL_KEYWORDS = {"CONSTRAINT", "PRIMARY", "UNIQUE", "CHECK", "FOREIGN", "EXCLUDE", "REFERENCES"}
COL_IN_CREATE_QUOTED_RE = re.compile(r'^\s*"([^"]+)"\s+', re.MULTILINE)
COL_IN_CREATE_BARE_RE = re.compile(r'^\s*(\w+)\s+(?:TEXT|INTEGER|BOOLEAN|TIMESTAMP|BIGINT|FLOAT|DOUBLE|REAL|JSONB?|SERIAL|UUID|SMALLINT|NUMERIC|DECIMAL|BYTEA|DATE|TIME)', re.MULTILINE | re.IGNORECASE)


def _pick_tbl(groups: tuple, start: int = 0) -> str:
    """Given a match, return the first non-empty of the 3 table-name alternatives starting at offset."""
    return groups[start] or groups[start + 1] or groups[start + 2] or ""


def parse_migrations(
    migrations_dir: Path,
) -> Tuple[Dict[str, Set[str]], Dict[str, List[Tuple[List[str], bool]]]]:
    tables: Dict[str, Set[str]] = {}
    indexes: Dict[str, List[Tuple[List[str], bool]]] = {}

    if not migrations_dir.is_dir():
        print(f"ERROR: migrations dir not found: {migrations_dir}", file=sys.stderr)
        sys.exit(2)

    migration_files = sorted(migrations_dir.glob("*/migration.sql"))
    if not migration_files:
        print(f"ERROR: no migration.sql files found under {migrations_dir}", file=sys.stderr)
        sys.exit(2)

    for f in migration_files:
        sql = f.read_text(errors="replace")

        for m in CREATE_TABLE_RE.finditer(sql):
            g = m.groups()
            table = _pick_tbl(g, 0)
            body = g[3]
            # Extract column names: try quoted first, then bare-word form
            cols = set(COL_IN_CREATE_QUOTED_RE.findall(body))
            for bare_match in COL_IN_CREATE_BARE_RE.finditer(body):
                name = bare_match.group(1)
                if name.upper() not in _SQL_KEYWORDS:
                    cols.add(name)
            tables.setdefault(table, set()).update(cols)

            # Also extract inline UNIQUE constraints from CREATE TABLE body
            # e.g.: UNIQUE(character_id, milestone_level)
            for uq in re.finditer(r'UNIQUE\s*\(([^)]+)\)', body, re.IGNORECASE):
                ucols = [c.strip().strip('"') for c in uq.group(1).split(",")]
                indexes.setdefault(table, []).append((ucols, True))

        # Multi-column-aware ALTER TABLE ... ; parser
        for m in ALTER_TABLE_STMT_RE.finditer(sql):
            g = m.groups()
            table = _pick_tbl(g, 0)
            stmt_body = g[3]
            for cm in ADD_COL_INSIDE_ALTER_RE.finditer(stmt_body):
                tables.setdefault(table, set()).add(cm.group(1))

        for m in CREATE_INDEX_RE.finditer(sql):
            g = m.groups()
            is_unique = bool(g[0])
            # g[1..2] = index name alternatives (unused)
            # g[3..5] = table name alternatives (via _TBL)
            table = _pick_tbl(g, 3)
            col_expr = g[6]
            cols: List[str] = []
            for raw in col_expr.split(","):
                c = raw.strip().strip('"')
                c = re.sub(r'"\s*(ASC|DESC)\s*$', "", c, flags=re.IGNORECASE)
                c = re.sub(r"\s+(ASC|DESC)\s*$", "", c, flags=re.IGNORECASE)
                c = c.strip().strip('"')
                cols.append(c)
            indexes.setdefault(table, []).append((cols, is_unique))

    return tables, indexes


# ─────────────────────────────────────────────────────────────────────────────
# Diff
# ─────────────────────────────────────────────────────────────────────────────


def diff(
    expected: Dict[str, Dict],
    actual_cols: Dict[str, Set[str]],
    actual_indexes: Dict[str, List[Tuple[List[str], bool]]],
) -> Tuple[List[str], List[str], List[str]]:
    missing_cols: List[str] = []
    missing_idx: List[str] = []
    missing_tables: List[str] = []

    for table, info in sorted(expected.items()):
        if table not in actual_cols:
            missing_tables.append(f"{table}  (model {info['model_name']})")
            continue

        for col in sorted(info["columns"]):
            if col not in actual_cols[table]:
                missing_cols.append(f"{table}.{col}  (model {info['model_name']})")

        existing_idx_sets = [frozenset(cols) for cols, _ in actual_indexes.get(table, [])]

        for idx_cols in info["indexes"]:
            if frozenset(idx_cols) not in existing_idx_sets:
                missing_idx.append(
                    f"{table}  INDEX({', '.join(idx_cols)})  (model {info['model_name']})"
                )
        for idx_cols in info["uniques"]:
            if frozenset(idx_cols) not in existing_idx_sets:
                missing_idx.append(
                    f"{table}  UNIQUE({', '.join(idx_cols)})  (model {info['model_name']})"
                )

    return missing_cols, missing_idx, missing_tables


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────


def main() -> int:
    if not SCHEMA_PATH.is_file():
        print(f"ERROR: {SCHEMA_PATH} not found", file=sys.stderr)
        return 2

    schema_text = SCHEMA_PATH.read_text()
    expected = parse_schema(schema_text)
    actual_cols, actual_indexes = parse_migrations(MIGRATIONS_DIR)

    missing_cols, missing_idx, missing_tables = diff(expected, actual_cols, actual_indexes)

    total_expected_cols = sum(len(v["columns"]) for v in expected.values())
    total_expected_idx = sum(len(v["indexes"]) + len(v["uniques"]) for v in expected.values())

    if VERBOSE:
        print(
            f"[schema-drift] schema.prisma: {len(expected)} models, "
            f"{total_expected_cols} @map columns, {total_expected_idx} @@index/@@unique decls"
        )
        print(
            f"[schema-drift] migrations:    {len(actual_cols)} tables, "
            f"{sum(len(v) for v in actual_cols.values())} columns, "
            f"{sum(len(v) for v in actual_indexes.values())} indexes"
        )

    if not missing_cols and not missing_idx and not missing_tables:
        print(
            f"[schema-drift] OK — {len(expected)} models / "
            f"{total_expected_cols} columns all have matching migrations"
        )
        return 0

    print()
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║           PRISMA SCHEMA DRIFT DETECTED (would 500 in prod)        ║")
    print("╚══════════════════════════════════════════════════════════════════╝")
    print()

    if missing_tables:
        print(f"MISSING TABLES ({len(missing_tables)}):")
        for t in missing_tables:
            print(f"  ✗ {t}")
        print()

    if missing_cols:
        print(f"MISSING COLUMNS ({len(missing_cols)}):")
        for c in missing_cols:
            print(f"  ✗ {c}")
        print()

    if missing_idx:
        print(f"MISSING INDEXES ({len(missing_idx)}):")
        for i in missing_idx:
            print(f"  ✗ {i}")
        print()

    print("FIX:")
    print("  1. cd backend")
    print("  2. Create migrations/$(date +%Y%m%d)_<name>/migration.sql")
    print('  3. Add `ALTER TABLE "..." ADD COLUMN IF NOT EXISTS "..." <type>;`')
    print("     for each missing column, and `CREATE INDEX IF NOT EXISTS ...`")
    print("     for each missing index.")
    print("  4. Apply to prod via Supabase MCP or `npm run db:migrate:deploy`.")
    print("  5. Commit the migration file so Vercel picks it up.")
    print()
    return 1


if __name__ == "__main__":
    sys.exit(main())
