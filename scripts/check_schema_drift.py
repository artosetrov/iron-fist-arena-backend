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
  1. Every scalar / enum model field is present somewhere in
     `prisma/migrations/**/migration.sql` (either via CREATE TABLE or
     ALTER TABLE ADD COLUMN). If a field uses `@map("col_name")`, the
     mapped column name is checked; otherwise the Prisma field name is used.
  2. Every `@@index([...])` is present as a CREATE INDEX in the migrations.
  3. Every `@@unique([...])` is present as a UNIQUE constraint/index.
  4. Every Prisma enum value exists somewhere in migration history
     (either in CREATE TYPE ... AS ENUM (...) or later ALTER TYPE ... ADD VALUE).
  5. `prisma/migrations/migration_lock.toml` exists so Prisma can reason about
     the migrations directory as a valid history.
  6. Each migration directory contains exactly one root `migration.sql` and no
     hidden/nested SQL artifacts that Prisma would ignore but humans might trust.

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
MIGRATION_LOCK_PATH = MIGRATIONS_DIR / "migration_lock.toml"

VERBOSE = "--verbose" in sys.argv or "-v" in sys.argv


# ─────────────────────────────────────────────────────────────────────────────
# Parse schema.prisma
# ─────────────────────────────────────────────────────────────────────────────

MODEL_RE = re.compile(r"^model\s+(\w+)\s*\{", re.MULTILINE)

# Table-level @@map (the table name for the model)
TABLE_MAP_RE = re.compile(r'@@map\("([^"]+)"\)')
FIELD_DECL_RE = re.compile(r"^\s*(\w+)\s+([^\s]+)(?:\s+(.*))?$")
FIELD_MAP_RE = re.compile(r'(?<!@)@map\("([^"]+)"\)')

INDEX_RE = re.compile(r"@@index\(\[([^\]]+)\]")
UNIQUE_RE = re.compile(r"@@unique\(\[([^\]]+)\]")
ENUM_RE = re.compile(r"^enum\s+(\w+)\s*\{", re.MULTILINE)

SCALAR_TYPES = {
    "String",
    "Int",
    "BigInt",
    "Float",
    "Decimal",
    "Boolean",
    "DateTime",
    "Json",
    "Bytes",
}


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
    enum_names = set(ENUM_RE.findall(schema_text))

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
    model_names = {model_name for model_name, _ in blocks}

    def base_type(type_token: str) -> str:
        if type_token.endswith("?"):
            type_token = type_token[:-1]
        if type_token.endswith("[]"):
            type_token = type_token[:-2]
        return type_token

    for model_name, body in blocks:
        tmap = TABLE_MAP_RE.search(body)
        table = tmap.group(1) if tmap else model_name

        field_to_col: Dict[str, str] = {}
        columns: Set[str] = set()

        for raw_line in body.splitlines():
            line = raw_line.split("//", 1)[0].strip()
            if not line or line.startswith("@@"):
                continue

            field_match = FIELD_DECL_RE.match(line)
            if not field_match:
                continue

            field_name, type_token, tail = field_match.groups()
            tail = tail or ""
            prisma_type = base_type(type_token)

            is_scalar = (
                prisma_type in SCALAR_TYPES
                or prisma_type in enum_names
                or prisma_type.startswith("Unsupported(")
            )
            is_relation = prisma_type in model_names and "@relation" in tail

            if not is_scalar or is_relation:
                continue

            map_match = FIELD_MAP_RE.search(line)
            column_name = map_match.group(1) if map_match else field_name
            field_to_col[field_name] = column_name
            columns.add(column_name)

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


def parse_schema_enums(schema_text: str) -> Dict[str, List[str]]:
    results: Dict[str, List[str]] = {}

    for m in ENUM_RE.finditer(schema_text):
        name = m.group(1)
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

        body = schema_text[start : i - 1]
        values: List[str] = []
        for raw_line in body.splitlines():
            line = raw_line.split("//", 1)[0].strip()
            if line:
                values.append(line)
        results[name] = values

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
) -> Tuple[Dict[str, Set[str]], Dict[str, List[Tuple[List[str], bool]]], Dict[str, Set[str]]]:
    tables: Dict[str, Set[str]] = {}
    indexes: Dict[str, List[Tuple[List[str], bool]]] = {}
    enums: Dict[str, Set[str]] = {}

    if not migrations_dir.is_dir():
        print(f"ERROR: migrations dir not found: {migrations_dir}", file=sys.stderr)
        sys.exit(2)

    migration_files = sorted(migrations_dir.glob("*/migration.sql"))
    if not migration_files:
        print(f"ERROR: no migration.sql files found under {migrations_dir}", file=sys.stderr)
        sys.exit(2)

    create_type_patterns = [
        re.compile(
            r'CREATE\s+TYPE\s+"public"\."([^"]+)"\s+AS\s+ENUM\s*\((.*?)\);',
            re.IGNORECASE | re.DOTALL,
        ),
        re.compile(
            r'CREATE\s+TYPE\s+"([^"]+)"\s+AS\s+ENUM\s*\((.*?)\);',
            re.IGNORECASE | re.DOTALL,
        ),
    ]
    alter_type_add_value_re = re.compile(
        r'ALTER\s+TYPE\s+(?:"public"\.)?"([^"]+)"\s+ADD\s+VALUE(?:\s+IF\s+NOT\s+EXISTS)?\s+\'([^\']+)\'',
        re.IGNORECASE,
    )

    for f in migration_files:
        sql = f.read_text(errors="replace")

        for create_type_re in create_type_patterns:
            for m in create_type_re.finditer(sql):
                enum_name, body = m.groups()
                values = set(re.findall(r"'([^']+)'", body))
                enums.setdefault(enum_name, set()).update(values)

        for enum_name, value in alter_type_add_value_re.findall(sql):
            enums.setdefault(enum_name, set()).add(value)

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

    return tables, indexes, enums


# ─────────────────────────────────────────────────────────────────────────────
# Diff
# ─────────────────────────────────────────────────────────────────────────────


def diff(
    expected: Dict[str, Dict],
    actual_cols: Dict[str, Set[str]],
    actual_indexes: Dict[str, List[Tuple[List[str], bool]]],
    expected_enums: Dict[str, List[str]],
    actual_enums: Dict[str, Set[str]],
) -> Tuple[List[str], List[str], List[str], List[str]]:
    missing_cols: List[str] = []
    missing_idx: List[str] = []
    missing_tables: List[str] = []
    missing_enums: List[str] = []

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

    for enum_name, values in sorted(expected_enums.items()):
        actual_values = actual_enums.get(enum_name, set())
        for value in values:
            if value not in actual_values:
                missing_enums.append(f"{enum_name}.{value}")

    return missing_cols, missing_idx, missing_tables, missing_enums


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────


def find_unexpected_migration_artifacts(migrations_dir: Path) -> List[str]:
    unexpected: List[str] = []

    for path in sorted(migrations_dir.iterdir()):
        if path.is_file():
            if path.name != "migration_lock.toml":
                unexpected.append(str(path.relative_to(REPO_ROOT)))
            continue

        if not path.is_dir():
            unexpected.append(str(path.relative_to(REPO_ROOT)))
            continue

        expected_sql = path / "migration.sql"
        if not expected_sql.is_file():
            unexpected.append(f"{path.relative_to(REPO_ROOT)}/<missing migration.sql>")

        for child in sorted(path.rglob("*")):
            if not child.is_file():
                continue
            if child == expected_sql:
                continue
            unexpected.append(str(child.relative_to(REPO_ROOT)))

    return unexpected


def main() -> int:
    if not SCHEMA_PATH.is_file():
        print(f"ERROR: {SCHEMA_PATH} not found", file=sys.stderr)
        return 2

    if not MIGRATION_LOCK_PATH.is_file():
        print(f"ERROR: {MIGRATION_LOCK_PATH} not found", file=sys.stderr)
        return 2

    unexpected_artifacts = find_unexpected_migration_artifacts(MIGRATIONS_DIR)

    schema_text = SCHEMA_PATH.read_text()
    expected = parse_schema(schema_text)
    expected_enums = parse_schema_enums(schema_text)
    actual_cols, actual_indexes, actual_enums = parse_migrations(MIGRATIONS_DIR)

    missing_cols, missing_idx, missing_tables, missing_enums = diff(
        expected,
        actual_cols,
        actual_indexes,
        expected_enums,
        actual_enums,
    )

    total_expected_cols = sum(len(v["columns"]) for v in expected.values())
    total_expected_idx = sum(len(v["indexes"]) + len(v["uniques"]) for v in expected.values())
    total_expected_enum_values = sum(len(v) for v in expected_enums.values())

    if VERBOSE:
        print(
            f"[schema-drift] schema.prisma: {len(expected)} models, "
            f"{total_expected_cols} scalar/enum columns, "
            f"{total_expected_idx} @@index/@@unique decls, "
            f"{len(expected_enums)} enums / {total_expected_enum_values} enum values"
        )
        print(
            f"[schema-drift] migrations:    {len(actual_cols)} tables, "
            f"{sum(len(v) for v in actual_cols.values())} columns, "
            f"{sum(len(v) for v in actual_indexes.values())} indexes, "
            f"{len(actual_enums)} enums / {sum(len(v) for v in actual_enums.values())} enum values"
        )

    if not missing_cols and not missing_idx and not missing_tables and not missing_enums and not unexpected_artifacts:
        print(
            f"[schema-drift] OK — {len(expected)} models / "
            f"{total_expected_cols} columns and {total_expected_enum_values} enum values "
            f"all have matching migrations"
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

    if missing_enums:
        print(f"MISSING ENUM VALUES ({len(missing_enums)}):")
        for e in missing_enums:
            print(f"  ✗ {e}")
        print()

    if unexpected_artifacts:
        print(f"UNEXPECTED MIGRATION ARTIFACTS ({len(unexpected_artifacts)}):")
        for artifact in unexpected_artifacts:
            print(f"  ✗ {artifact}")
        print()

    print("FIX:")
    print("  1. cd backend")
    print("  2. Create migrations/$(date +%Y%m%d)_<name>/migration.sql")
    print('  3. Add `ALTER TABLE "..." ADD COLUMN IF NOT EXISTS "..." <type>;`')
    print("     for each missing column, and `CREATE INDEX IF NOT EXISTS ...`")
    print("     for each missing index. Use `ALTER TYPE ... ADD VALUE IF NOT EXISTS`")
    print("     for missing enum values.")
    print("     Remove hidden/nested files from migration directories so history stays deterministic.")
    print("  4. Apply to prod via Supabase MCP or `npm run db:migrate:deploy`.")
    print("  5. Commit the migration file so Vercel picks it up.")
    print()
    return 1


if __name__ == "__main__":
    sys.exit(main())
