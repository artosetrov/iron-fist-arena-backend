#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
import argparse
from pathlib import Path

PLACEHOLDER_PREFIXES = (
    "__MISSING_",
    "YOUR_",
    "REPLACE_",
)


def strip_inline_comment(value: str) -> str:
    for index in range(len(value) - 1):
        if value[index:index + 2] != "//":
            continue
        if index == 0 or value[index - 1].isspace():
            return value[:index].rstrip()
    return value.strip()


def parse_xcconfig(path: Path, seen: set[Path] | None = None) -> dict[str, str]:
    seen = seen or set()
    resolved_path = path.resolve()
    if resolved_path in seen:
        return {}
    seen.add(resolved_path)

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("//"):
            continue
        if line.startswith("#include"):
            match = re.match(r'#include\??\s+"([^"]+)"', line)
            if not match:
                continue
            include_path = path.parent / match.group(1)
            optional = line.startswith("#include?")
            if include_path.exists():
                values.update(parse_xcconfig(include_path, seen))
            elif not optional:
                raise FileNotFoundError(f"Missing required xcconfig include: {include_path}")
            continue
        if "=" not in line:
            continue
        key, raw_value = line.split("=", 1)
        values[key.strip()] = strip_inline_comment(raw_value)
    return values


def resolve_value(key: str, values: dict[str, str], stack: tuple[str, ...] = ()) -> str:
    if key in stack:
        raise ValueError(f"Circular xcconfig reference: {' -> '.join(stack + (key,))}")
    raw_value = values.get(key, "")

    def replace(match: re.Match[str]) -> str:
        nested_key = match.group(1)
        return resolve_value(nested_key, values, stack + (key,))

    return re.sub(r"\$\(([^)]+)\)", replace, raw_value)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def warn(message: str) -> None:
    print(f"WARNING: {message}", file=sys.stderr)


def validate_required_key(name: str, values: dict[str, str], *, allow_placeholders: bool) -> str:
    value = resolve_value(name, values)
    if not value:
        fail(f"{name} is empty")
    if not allow_placeholders and value.startswith(PLACEHOLDER_PREFIXES):
        fail(f"{name} still uses a placeholder value")
    if not allow_placeholders and "your-" in value.lower():
        fail(f"{name} still uses example text")
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Hexbound iOS release config.")
    parser.add_argument(
        "--allow-missing-local-values",
        action="store_true",
        help="Validate config structure without requiring real local secrets/URLs.",
    )
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    config_dir = project_root / "Config"

    debug_values = parse_xcconfig(config_dir / "Debug.xcconfig")
    release_values = parse_xcconfig(config_dir / "Release.xcconfig")

    allow_placeholders = args.allow_missing_local_values

    debug_env = validate_required_key("HEXBOUND_APP_ENV", debug_values, allow_placeholders=allow_placeholders)
    release_env = validate_required_key("HEXBOUND_APP_ENV", release_values, allow_placeholders=allow_placeholders)
    if debug_env != "staging":
        fail(f"Debug.xcconfig must set HEXBOUND_APP_ENV=staging, got {debug_env!r}")
    if release_env != "production":
        fail(f"Release.xcconfig must set HEXBOUND_APP_ENV=production, got {release_env!r}")

    debug_api = validate_required_key("HEXBOUND_API_BASE_URL", debug_values, allow_placeholders=allow_placeholders)
    release_api = validate_required_key("HEXBOUND_API_BASE_URL", release_values, allow_placeholders=allow_placeholders)
    validate_required_key("HEXBOUND_SUPABASE_PROJECT_URL", release_values, allow_placeholders=allow_placeholders)
    validate_required_key("HEXBOUND_SUPABASE_ANON_KEY", release_values, allow_placeholders=allow_placeholders)
    validate_required_key("HEXBOUND_GOOGLE_CLIENT_ID", release_values, allow_placeholders=allow_placeholders)
    validate_required_key("HEXBOUND_GOOGLE_REVERSED_CLIENT_ID", release_values, allow_placeholders=allow_placeholders)

    if not allow_placeholders and not debug_api.startswith("https://"):
        fail("HEXBOUND_API_BASE_URL for Debug must use https://")
    if not allow_placeholders and not release_api.startswith("https://"):
        fail("HEXBOUND_API_BASE_URL for Release must use https://")
    if debug_api == release_api:
        warn(
            "Debug and Release API hosts are the same. This keeps local builds working, "
            "but a dedicated staging backend should replace it before team-scale QA."
        )

    print("iOS release config preflight passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
