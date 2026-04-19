#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

ALLOWED_ENV_SUFFIXES = (
    ".env.example",
    ".env.sample",
    ".env.template",
)

BANNED_PATH_SUFFIXES = (
    ".p8",
    ".mobileprovision",
)

TEXT_FILE_SUFFIXES = {
    ".cjs",
    ".conf",
    ".css",
    ".env",
    ".example",
    ".gitignore",
    ".html",
    ".js",
    ".json",
    ".jsx",
    ".md",
    ".mjs",
    ".plist",
    ".py",
    ".rb",
    ".sh",
    ".swift",
    ".toml",
    ".ts",
    ".tsx",
    ".txt",
    ".xcconfig",
    ".xml",
    ".yaml",
    ".yml",
}

CONTENT_PATTERNS = (
    (re.compile(rb"-----BEGIN (?:EC |RSA )?PRIVATE KEY-----"), "contains a private key block"),
    (re.compile(rb"\bghp_[A-Za-z0-9]{20,}\b"), "contains a GitHub token-like value"),
    (re.compile(rb"\bvcp_[A-Za-z0-9]{20,}\b"), "contains a Vercel token-like value"),
)


def git_ls_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    raw_paths = [chunk for chunk in result.stdout.split(b"\0") if chunk]
    return [ROOT / Path(chunk.decode("utf-8")) for chunk in raw_paths]


def is_banned_env_file(path: Path) -> bool:
    name = path.name
    if not name.startswith(".env"):
        return False
    return not any(name.endswith(suffix) for suffix in ALLOWED_ENV_SUFFIXES)


def should_scan_contents(path: Path) -> bool:
    if path.suffix in TEXT_FILE_SUFFIXES:
        return True
    if path.name.startswith(".env"):
        return True
    return False


def scan_file_contents(path: Path) -> list[str]:
    try:
        data = path.read_bytes()
    except OSError as error:
        return [f"could not be read: {error}"]

    if b"\0" in data:
        return []

    findings: list[str] = []
    for pattern, reason in CONTENT_PATTERNS:
        if pattern.search(data):
            findings.append(reason)
    return findings


def main() -> int:
    findings: list[tuple[str, str]] = []

    for path in git_ls_files():
        if not path.exists():
            continue

        rel = path.relative_to(ROOT).as_posix()

        if is_banned_env_file(path):
            findings.append((rel, "tracked .env files are not allowed"))

        if path.suffix in BANNED_PATH_SUFFIXES:
            findings.append((rel, f"tracked {path.suffix} files are not allowed"))
            continue

        if not should_scan_contents(path):
            continue

        for reason in scan_file_contents(path):
            findings.append((rel, reason))

    if findings:
        print("Tracked secret scan failed:", file=sys.stderr)
        for rel, reason in findings:
            print(f" - {rel}: {reason}", file=sys.stderr)
        return 1

    print("Tracked secret scan passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
