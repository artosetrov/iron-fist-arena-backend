#!/usr/bin/env python3
"""
check_a11y.py — VoiceOver label gate for the iOS client.

The rules already exist in the project. docs/rules/rules-ui-design.md and
docs/07_ui_ux/DESIGN_SYSTEM.md section 13 both say every interactive element
carries an accessibilityLabel, and the mirror / guardian agent skills check it
by hand. Nothing checked it mechanically, so the result drifted: on
2026-10-14 there were 173 labels across 68 files, and fourteen routed screens
with none at all.

What this gate enforces
-----------------------
One rule, the one with no judgement in it: a Button whose label draws an
Image and no Text is unreadable to VoiceOver as anything but "Button", so it
must carry .accessibilityLabel. A button with visible text already announces
that text, and a composed row that sets .accessibilityElement(children:
.combine) on a parent is handled there, so neither is flagged here.

Violations that predate the gate live in scripts/a11y_baseline.txt. The
baseline may only shrink: a new violation fails the build, and a fixed one
has to be removed from the file or the gate complains that the baseline is
stale. That way the gate can go in today without a fourteen-screen rewrite
blocking it.

The heuristic
-------------
Swift is not parsed. For each `Button` the script takes the lines that belong
to it — up to the first line indented no deeper than the Button itself that
does not continue the expression with a leading `.` — and looks inside that
window. The window keeps going past the Button's own closing brace, because that is
where SwiftUI modifiers live. It is deliberately conservative: when in doubt
the window grows (at worst picking up a parent's label and staying quiet)
rather than reporting, because a gate that cries wolf gets switched off.

Usage
-----
    python3 scripts/check_a11y.py            # fail on new violations
    python3 scripts/check_a11y.py --report   # print every violation, exit 0
    python3 scripts/check_a11y.py --write-baseline
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VIEWS = ROOT / "Hexbound" / "Hexbound" / "Views"
BASELINE = Path(__file__).resolve().parent / "a11y_baseline.txt"

# Dev-only catalogs are not shipped to players.
SKIP_DIRS = {"Dev"}

BUTTON_RE = re.compile(r"(?<![A-Za-z0-9_])Button\s*[({]")
LABEL_RE = re.compile(r"\.accessibility(?:Label|Hidden|Element)\b")
IMAGE_RE = re.compile(r"(?<![A-Za-z0-9_])Image\s*\(")
TEXT_RE = re.compile(r"(?<![A-Za-z0-9_])(?:Text|Label)\s*\(")


def strip_noise(src: str) -> str:
    """Blank out string literals and comments, keeping line structure."""
    out, i, n = [], 0, len(src)
    in_str = esc = False
    while i < n:
        c = src[i]
        if in_str:
            out.append("\n" if c == "\n" else " ")
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(" ")
            i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i)
            j = n if j < 0 else j + 2
            out.append("".join("\n" if ch == "\n" else " " for ch in src[i:j]))
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def indent_of(line: str) -> int:
    return len(line) - len(line.lstrip())


def button_windows(lines: list[str]) -> list[tuple[int, list[str]]]:
    """(0-based start line, lines belonging to that Button expression)."""
    found = []
    for idx, line in enumerate(lines):
        if not BUTTON_RE.search(line):
            continue
        base = indent_of(line)
        window = [line]
        for nxt in lines[idx + 1:]:
            if not nxt.strip():
                window.append(nxt)
                continue
            ind = indent_of(nxt)
            stripped = nxt.lstrip()
            if ind < base:
                break  # left the Button's nesting level entirely
            if ind == base and not stripped.startswith((".", "}", ")", "]")):
                break  # a sibling statement, not a closer or a modifier
            # A closer or a trailing modifier at the same indent still belongs
            # to the Button expression: `}` ends its label block and
            # `.accessibilityLabel` may follow it.
            window.append(nxt)
            if len(window) > 80:  # runaway — give up rather than guess
                break
        found.append((idx, window))
    return found


def scan() -> tuple[list[str], int, int]:
    violations: list[str] = []
    buttons = labels = 0
    for path in sorted(VIEWS.rglob("*.swift")):
        if any(part in SKIP_DIRS for part in path.relative_to(VIEWS).parts):
            continue
        raw = path.read_text(encoding="utf-8", errors="replace")
        clean = strip_noise(raw)
        lines = clean.split("\n")
        raw_lines = raw.split("\n")
        labels += len(LABEL_RE.findall(clean))
        for start, window in button_windows(lines):
            buttons += 1
            body = "\n".join(window)
            if not IMAGE_RE.search(body) or TEXT_RE.search(body):
                continue  # has visible text, or draws no image — not icon-only
            if LABEL_RE.search(body):
                continue
            rel = path.relative_to(ROOT).as_posix()
            snippet = raw_lines[start].strip()[:60]
            violations.append(f"{rel}:{start + 1}: icon-only Button without accessibilityLabel — {snippet}")
    return violations, buttons, labels


def load_baseline() -> set[str]:
    if not BASELINE.exists():
        return set()
    return {
        ln.strip()
        for ln in BASELINE.read_text(encoding="utf-8").splitlines()
        if ln.strip() and not ln.startswith("#")
    }


def key(violation: str) -> str:
    """Baseline on file + snippet, not line number — edits shift lines."""
    path, _, rest = violation.partition(":")
    return f"{path}::{rest.split('— ', 1)[-1]}"


def main() -> int:
    args = set(sys.argv[1:])
    violations, buttons, labels = scan()

    if "--write-baseline" in args:
        BASELINE.write_text(
            "# Icon-only buttons without an accessibilityLabel, known at the time\n"
            "# the gate was added. This list may only shrink. Regenerating it to\n"
            "# silence a new violation defeats the gate.\n"
            + "\n".join(sorted(key(v) for v in violations))
            + "\n",
            encoding="utf-8",
        )
        print(f"[a11y] baseline written: {len(violations)} known violations")
        return 0

    if "--report" in args:
        for v in violations:
            print(v)
        print(f"\n[a11y] {len(violations)} icon-only buttons without labels, "
              f"{buttons} buttons and {labels} accessibility modifiers scanned")
        return 0

    baseline = load_baseline()
    current = {key(v): v for v in violations}
    new = [v for k, v in current.items() if k not in baseline]
    fixed = [k for k in baseline if k not in current]

    for v in new:
        print(f"[a11y] NEW {v}")
    if fixed:
        print(f"[a11y] {len(fixed)} baselined violations are fixed — "
              f"run `python3 scripts/check_a11y.py --write-baseline` to shrink the baseline")

    if new:
        print(f"\n[a11y] FAILED — {len(new)} icon-only button(s) without an accessibilityLabel.")
        print("Give the button a label describing the ACTION ('Close item detail'), "
              "or .accessibilityHidden(true) if it is decorative.")
        return 1

    print(f"[a11y] OK — {len(current)} known violations, none new "
          f"({buttons} buttons, {labels} accessibility modifiers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
