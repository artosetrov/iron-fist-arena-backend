#!/usr/bin/env python3
"""
Design System Drift Checker
============================
Compares iOS code (DarkFantasyTheme.swift, LayoutConstants.swift) against
admin design-tokens.json and reports any drift.

Usage:
  python3 scripts/ds-drift-check.py        # audit mode
  python3 scripts/ds-drift-check.py --fix   # auto-fix mode (regenerate design-tokens.json)

Exit codes:
  0 = no drift
  1 = drift found
"""

import re
import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple, Any


# ANSI color codes (auto-disabled if not a tty)
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    DIM = '\033[2m'
    RESET = '\033[0m'

    @staticmethod
    def disable():
        """Disable colors if not a tty."""
        if not sys.stdout.isatty():
            for attr in dir(Colors):
                if not attr.startswith('_') and attr != 'disable':
                    setattr(Colors, attr, '')


Colors.disable()


def parse_dark_fantasy_theme(file_path: str) -> Dict[str, Any]:
    """
    Parse DarkFantasyTheme.swift and extract:
    - static let X = Color(hex: 0xHHHHHH)
    - static let X = Color(hex: 0xHHHHHH, opacity: Y)
    - static let X = Color.black.opacity(Y)
    - static let X = Color.white.opacity(Y)
    - static let X = LinearGradient(...)
    - static let X = Font.custom(...)
    - static let X = CGFloat / Double opacity scales
    """
    tokens = {}

    with open(file_path, 'r') as f:
        content = f.read()

    # Pattern 1: static let X = Color(hex: 0xHHHHHH)
    hex_pattern = r'static let (\w+)\s*=\s*Color\(hex:\s*(0x[0-9A-Fa-f]+)\s*(?:,\s*opacity:\s*([\d.]+))?\s*\)'
    for match in re.finditer(hex_pattern, content):
        name = match.group(1)
        hex_val = match.group(2)
        opacity = match.group(3)
        if opacity:
            tokens[name] = {'type': 'color', 'hex': hex_val, 'opacity': float(opacity)}
        else:
            tokens[name] = {'type': 'color', 'hex': hex_val}

    # Pattern 1b: static let X = Color(hex: 0xHHHHHH).opacity(Y)
    hex_opacity_pattern = r'static let (\w+)\s*=\s*Color\(hex:\s*(0x[0-9A-Fa-f]+)\)\.opacity\(([\d.]+)\)'
    for match in re.finditer(hex_opacity_pattern, content):
        name = match.group(1)
        hex_val = match.group(2)
        opacity = float(match.group(3))
        tokens[name] = {'type': 'color', 'hex': hex_val, 'opacity': opacity}

    # Pattern 2: Color.black.opacity(Y) or Color.white.opacity(Y)
    opacity_pattern = r'static let (\w+)\s*=\s*Color\.(black|white)\.opacity\(([\d.]+)\)'
    for match in re.finditer(opacity_pattern, content):
        name = match.group(1)
        base_color = match.group(2)
        opacity = float(match.group(3))
        hex_val = '0x000000' if base_color == 'black' else '0xFFFFFF'
        tokens[name] = {'type': 'color', 'hex': hex_val, 'opacity': opacity}

    # Pattern 2b: Aliases (static let X = Y where Y is another token)
    alias_pattern = r'static let (\w+)\s*=\s*(\w+)(?:\s|$|//)'
    for match in re.finditer(alias_pattern, content):
        name = match.group(1)
        alias_target = match.group(2)
        # Only track if target is already defined (to avoid dupes)
        if alias_target in tokens:
            tokens[name] = {'type': 'alias', 'target': alias_target}

    # Pattern 3: Gradient references (we note them but don't enforce strict value match)
    gradient_pattern = r'static let (\w+)\s*=\s*LinearGradient\('
    for match in re.finditer(gradient_pattern, content):
        name = match.group(1)
        tokens[name] = {'type': 'gradient'}

    # Pattern 4: Font tokens
    font_pattern = r'static let (\w+)\s*=\s*Font\.custom\("([^"]+)",\s*size:\s*([\d.]+)\)'
    for match in re.finditer(font_pattern, content):
        name = match.group(1)
        font_family = match.group(2)
        size = float(match.group(3))
        tokens[name] = {'type': 'font', 'family': font_family, 'size': size}

    # Pattern 5: Static font properties (e.g., static let title = Font.custom(...).bold())
    bold_font_pattern = r'static let (\w+)\s*=\s*Font\.custom\("([^"]+)",\s*size:\s*([\d.]+)\)\.bold\(\)'
    for match in re.finditer(bold_font_pattern, content):
        name = match.group(1)
        font_family = match.group(2)
        size = float(match.group(3))
        tokens[name] = {'type': 'font', 'family': font_family, 'size': size, 'bold': True}

    # Pattern 6: Opacity scale tokens (static let opacity* = ...)
    opacity_scale_pattern = r'static let (opacity\w+)\s*:\s*Double\s*=\s*([\d.]+)'
    for match in re.finditer(opacity_scale_pattern, content):
        name = match.group(1)
        value = float(match.group(2))
        tokens[name] = {'type': 'opacity', 'value': value}

    return tokens


def parse_layout_constants(file_path: str) -> Dict[str, Any]:
    """
    Parse LayoutConstants.swift and extract:
    - static let X: CGFloat = Y
    - static let X = Y (inferred as sizing)
    """
    tokens = {}

    with open(file_path, 'r') as f:
        content = f.read()

    # Pattern: static let X: CGFloat = Y or static let X = Y
    const_pattern = r'static let (\w+)(?:\s*:\s*CGFloat)?\s*=\s*([\d.]+)'
    for match in re.finditer(const_pattern, content):
        name = match.group(1)
        value = float(match.group(2))
        tokens[name] = {'type': 'spacing/sizing', 'value': value}

    return tokens


def hex_to_rgba_string(hex_val: str, opacity: float = 1.0) -> str:
    """Convert 0xHHHHHH to #HHHHH or rgba(...) if opacity < 1."""
    hex_clean = hex_val.replace('0x', '').upper()
    if opacity < 1.0:
        r = int(hex_clean[0:2], 16)
        g = int(hex_clean[2:4], 16)
        b = int(hex_clean[4:6], 16)
        # Format opacity with 2 decimal places for consistency
        return f"rgba({r},{g},{b},{opacity:.2f})"
    else:
        return f"#{hex_clean}"


def normalize_color_value(val: str) -> str:
    """Normalize color value for comparison (handles opacity precision)."""
    # If it's a hex color, uppercase it
    if val.startswith('#'):
        return val.upper()
    # If it's rgba, normalize opacity to 2 decimal places
    if val.startswith('rgba('):
        match = re.match(r'rgba\((\d+),(\d+),(\d+),([\d.]+)\)', val)
        if match:
            r, g, b, opacity = match.groups()
            return f"rgba({r},{g},{b},{float(opacity):.2f})"
    return val


def load_admin_tokens(file_path: str) -> Dict[str, Any]:
    """Load the admin design-tokens.json file."""
    with open(file_path, 'r') as f:
        return json.load(f)


def flatten_admin_tokens(admin_data: Dict) -> Dict[str, str]:
    """
    Flatten nested admin token structure into flat {name: value} dict.
    e.g. admin_data['colors']['background']['bgAbyss'] -> {'bgAbyss': '#08080C'}
    """
    flat = {}

    def flatten_dict(d: Dict, prefix: str = ''):
        for key, value in d.items():
            if isinstance(value, dict):
                flatten_dict(value, prefix)
            else:
                flat[key] = value

    if 'colors' in admin_data:
        flatten_dict(admin_data['colors'])
    if 'typography' in admin_data:
        flat.update(admin_data['typography'])
    if 'spacing' in admin_data:
        flat.update(admin_data['spacing'])
    if 'radius' in admin_data:
        flat.update(admin_data['radius'])
    if 'opacity' in admin_data:
        flat.update(admin_data['opacity'])
    if 'sizing' in admin_data:
        flat.update(admin_data['sizing'])

    return flat


def compare_tokens(ios_theme: Dict, ios_layout: Dict, admin_tokens: Dict) -> Tuple[Dict, bool]:
    """
    Compare iOS tokens (source of truth) against admin tokens.
    Returns (report, has_drift) where report contains detailed findings.
    """
    admin_flat = flatten_admin_tokens(admin_tokens)
    report = {
        'colors': {'missing': [], 'mismatch': [], 'extra': []},
        'spacing': {'missing': [], 'mismatch': [], 'extra': []},
        'radius': {'missing': [], 'mismatch': [], 'extra': []},
        'opacity': {'missing': [], 'mismatch': [], 'extra': []},
        'typography': {'missing': [], 'mismatch': [], 'extra': []},
        'sizing': {'missing': [], 'mismatch': [], 'extra': []}
    }

    has_drift = False

    # Check iOS theme colors (skip aliases, they're just references)
    for name, token in ios_theme.items():
        if token.get('type') == 'alias':
            # Aliases don't need to be in admin (they're internal references)
            continue
        if token.get('type') == 'color':
            hex_val = token['hex']
            opacity = token.get('opacity', 1.0)
            expected = hex_to_rgba_string(hex_val, opacity)
            expected_norm = normalize_color_value(expected)

            if name not in admin_flat:
                report['colors']['missing'].append({'name': name, 'expected': expected})
                has_drift = True
            else:
                admin_val = str(admin_flat[name])
                admin_norm = normalize_color_value(admin_val)
                # Normalize for comparison
                if admin_norm != expected_norm:
                    report['colors']['mismatch'].append({
                        'name': name,
                        'expected': expected,
                        'admin': admin_val
                    })
                    has_drift = True

    # Check iOS layout constants (spacing, radius, sizing, opacity)
    for name, token in ios_layout.items():
        if token.get('type') == 'spacing/sizing':
            value = token['value']

            # Categorize
            if name.startswith('space'):
                category = 'spacing'
            elif name.startswith('radius'):
                category = 'radius'
            elif name.startswith('opacity'):
                category = 'opacity'
            else:
                category = 'sizing'

            if name not in admin_flat:
                report[category]['missing'].append({'name': name, 'expected': value})
                has_drift = True
            else:
                admin_val = admin_flat[name]
                if admin_val != value:
                    report[category]['mismatch'].append({
                        'name': name,
                        'expected': value,
                        'admin': admin_val
                    })
                    has_drift = True

    # Check iOS opacity tokens from DarkFantasyTheme
    for name, token in ios_theme.items():
        if token.get('type') == 'opacity':
            value = token['value']

            if name not in admin_flat:
                report['opacity']['missing'].append({'name': name, 'expected': value})
                has_drift = True
            else:
                admin_val = admin_flat[name]
                if admin_val != value:
                    report['opacity']['mismatch'].append({
                        'name': name,
                        'expected': value,
                        'admin': admin_val
                    })
                    has_drift = True

    # Check for extra tokens in admin that aren't in iOS (excluding aliases & legacy)
    ios_names = set(ios_theme.keys()) | set(ios_layout.keys())

    # Known legacy/alias names that are OK to be in admin even if not in iOS
    legacy_ok = {
        'bgDark', 'bgCard', 'goldLight', 'textMuted', 'borderGold', 'borderDefault',
        'toastAchievement', 'toastQuest', 'toastReward', 'toastError', 'hpRed',
        'difficultyEasy', 'difficultyMedium', 'pillHealText', 'pillUrgentText',
        'pillEnergyText', 'pillStatText', 'pillWarnText', 'pillOfflineText', 'gems',
        'npcAvatarOffset', 'merchantAvatarSize', 'merchantMiniSize', 'merchantBarHeight',
        'merchantBubbleRadius', 'heroBottomSlots'
    }

    for admin_name in admin_flat.keys():
        if admin_name not in ios_names and admin_name not in legacy_ok:
            # Categorize
            if admin_name.startswith('bg') or admin_name.startswith('text') or \
               admin_name.startswith('border') or admin_name.startswith('glow') or \
               admin_name.startswith('rarity') or admin_name.startswith('stat') or \
               admin_name.startswith('class') or admin_name.startswith('rank') or \
               admin_name.startswith('btn') or admin_name.startswith('color') or \
               admin_name.startswith('pill') or admin_name.startswith('toast') or \
               admin_name.startswith('zone') or admin_name.startswith('daily') or \
               admin_name.startswith('fog') or admin_name.startswith('moon') or \
               admin_name.startswith('sky') or admin_name.startswith('gems') or \
               admin_name.startswith('upgrade') or admin_name.startswith('heal') or \
               admin_name.startswith('durability') or admin_name.startswith('difficulty') or \
               admin_name.startswith('arena') or admin_name.startswith('xp') or \
               admin_name.startswith('hp') or admin_name.startswith('stamina') or \
               admin_name.startswith('premium') or admin_name.startswith('vfx') or \
               admin_name.startswith('loot') or admin_name.startswith('locked') or \
               admin_name.startswith('defeated') or admin_name.startswith('boss'):
                report['colors']['extra'].append({'name': admin_name})
            elif admin_name.startswith('space'):
                report['spacing']['extra'].append({'name': admin_name})
            elif admin_name.startswith('radius'):
                report['radius']['extra'].append({'name': admin_name})
            elif admin_name.startswith('opacity'):
                report['opacity']['extra'].append({'name': admin_name})
            elif isinstance(admin_flat[admin_name], dict):  # typography
                report['typography']['extra'].append({'name': admin_name})
            else:
                report['sizing']['extra'].append({'name': admin_name})

    return report, has_drift


def build_admin_tokens_from_ios(ios_theme: Dict, ios_layout: Dict, existing_admin: Dict) -> Dict:
    """
    Regenerate admin design-tokens.json from iOS source code (--fix mode).
    Preserves existing typography and other sections.
    """
    new_admin = {
        'colors': {},
        'typography': {},
        'spacing': {},
        'radius': {},
        'opacity': {},
        'sizing': {}
    }

    # Process iOS theme colors
    for name, token in sorted(ios_theme.items()):
        if token.get('type') == 'alias':
            continue  # Skip aliases
        if token.get('type') == 'color':
            hex_val = token['hex']
            opacity = token.get('opacity', 1.0)
            color_val = hex_to_rgba_string(hex_val, opacity)

            if 'colors' not in new_admin:
                new_admin['colors'] = {}
            new_admin['colors'][name] = color_val

    # Reorganize colors into subcategories (matching original structure)
    if new_admin['colors']:
        categorized = {}
        for name, val in sorted(new_admin['colors'].items()):
            if name.startswith('bg'):
                cat = 'background'
            elif name.startswith('text'):
                cat = 'text'
            elif name.startswith('gold'):
                cat = 'gold'
            elif name.startswith('danger') or name.startswith('success') or \
                 name.startswith('info') or name.startswith('cyan') or name.startswith('purple'):
                cat = 'feedback'
            elif name.startswith('border'):
                cat = 'border'
            elif name.startswith('rarity'):
                cat = 'rarity'
            elif name.startswith('stat'):
                cat = 'stats'
            elif name.startswith('class'):
                cat = 'classes'
            elif name.startswith('rank'):
                cat = 'ranks'
            elif name.startswith('btn'):
                cat = 'button'
            elif name.startswith('toast'):
                cat = 'toast'
            elif name.startswith('zone'):
                cat = 'stance'
            elif name.startswith('daily'):
                cat = 'daily'
            elif name.startswith('fog') or name.startswith('moon') or name.startswith('sky'):
                cat = 'atmosphere'
            elif name.startswith('glow'):
                cat = 'glow'
            elif name.startswith('vfx'):
                cat = 'vfx'
            elif name.startswith('pill'):
                cat = 'pill'
            elif name.startswith('dungeon') or name.startswith('boss') or name.startswith('loot') or \
                 name.startswith('locked') or name.startswith('defeated'):
                cat = 'dungeon'
            elif name.startswith('arena') or name.startswith('shimmer'):
                cat = 'arena'
            elif name.startswith('premium') or name.startswith('borderPremium'):
                cat = 'premium'
            elif name.startswith('hp') or name.startswith('heal'):
                cat = 'hp'
            elif name.startswith('stamina'):
                cat = 'stamina'
            elif name.startswith('durability'):
                cat = 'durability'
            elif name.startswith('difficulty'):
                cat = 'difficulty'
            elif name.startswith('xp'):
                cat = 'xp'
            elif name.startswith('gems') or name.startswith('upgrade'):
                cat = 'special'
            else:
                cat = 'other'

            if cat not in categorized:
                categorized[cat] = {}
            categorized[cat][name] = val

        new_admin['colors'] = categorized

    # Process iOS theme opacity tokens (in DarkFantasyTheme)
    for name, token in sorted(ios_theme.items()):
        if token.get('type') == 'opacity':
            value = token['value']
            new_admin['opacity'][name] = value

    # Process iOS layout constants
    for name, token in sorted(ios_layout.items()):
        if token.get('type') == 'spacing/sizing':
            value = token['value']

            if name.startswith('space'):
                new_admin['spacing'][name] = int(value) if value == int(value) else value
            elif name.startswith('radius'):
                new_admin['radius'][name] = int(value) if value == int(value) else value
            elif name.startswith('opacity'):
                new_admin['opacity'][name] = value
            else:
                new_admin['sizing'][name] = int(value) if value == int(value) else value

    # Preserve existing typography and other top-level keys
    for key in existing_admin:
        if key not in new_admin and key not in ['colors', 'spacing', 'radius', 'opacity', 'sizing']:
            new_admin[key] = existing_admin[key]

    # Add typography from existing (preserve it)
    if 'typography' in existing_admin:
        new_admin['typography'] = existing_admin['typography']

    return new_admin


def print_report(report: Dict, has_drift: bool):
    """Print a formatted drift report."""
    print(f"\n{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════════════╗{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}║       Design System Drift Check Report{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}╚══════════════════════════════════════════════════════════════╝{Colors.RESET}\n")

    total_issues = 0

    for category in ['colors', 'typography', 'spacing', 'radius', 'opacity', 'sizing']:
        category_issues = len(report[category]['missing']) + \
                         len(report[category]['mismatch']) + \
                         len(report[category]['extra'])

        if category_issues == 0:
            print(f"{Colors.GREEN}✓{Colors.RESET} {Colors.BOLD}{category.capitalize()}{Colors.RESET}: OK")
            continue

        total_issues += category_issues
        print(f"{Colors.RED}✗{Colors.RESET} {Colors.BOLD}{category.capitalize()}{Colors.RESET}: {category_issues} issue(s)\n")

        # Missing
        if report[category]['missing']:
            print(f"  {Colors.YELLOW}Missing in admin:{Colors.RESET}")
            for item in report[category]['missing']:
                print(f"    - {Colors.BOLD}{item['name']}{Colors.RESET}: {item['expected']}")

        # Mismatch
        if report[category]['mismatch']:
            print(f"  {Colors.YELLOW}Value mismatch:{Colors.RESET}")
            for item in report[category]['mismatch']:
                print(f"    - {Colors.BOLD}{item['name']}{Colors.RESET}")
                print(f"      Expected: {item['expected']}")
                print(f"      Admin:    {item['admin']}")

        # Extra
        if report[category]['extra']:
            print(f"  {Colors.YELLOW}Extra in admin (not in iOS):{Colors.RESET}")
            for item in report[category]['extra']:
                print(f"    - {Colors.BOLD}{item['name']}{Colors.RESET}")

        print()

    print(f"{Colors.BOLD}{Colors.CYAN}─────────────────────────────────────────────────────────────{Colors.RESET}\n")

    if has_drift:
        print(f"{Colors.RED}{Colors.BOLD}DRIFT DETECTED: {total_issues} issue(s) found{Colors.RESET}\n")
        return 1
    else:
        print(f"{Colors.GREEN}{Colors.BOLD}CDO: CLEAN ✓ No design system drift detected{Colors.RESET}\n")
        return 0


def main():
    """Main entry point."""
    # Determine paths
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent

    theme_path = root_dir / 'Hexbound' / 'Hexbound' / 'Theme' / 'DarkFantasyTheme.swift'
    layout_path = root_dir / 'Hexbound' / 'Hexbound' / 'Theme' / 'LayoutConstants.swift'
    admin_path = root_dir / 'admin' / 'src' / 'lib' / 'design-tokens.json'

    # Validate files exist
    for path in [theme_path, layout_path, admin_path]:
        if not path.exists():
            print(f"{Colors.RED}Error: {path} not found{Colors.RESET}", file=sys.stderr)
            sys.exit(1)

    # Check for --fix flag
    fix_mode = '--fix' in sys.argv

    # Parse iOS source code
    ios_theme = parse_dark_fantasy_theme(str(theme_path))
    ios_layout = parse_layout_constants(str(layout_path))

    # Load admin tokens
    admin_tokens = load_admin_tokens(str(admin_path))

    if fix_mode:
        # Regenerate design-tokens.json from iOS source
        print(f"{Colors.CYAN}Regenerating design-tokens.json from iOS source...{Colors.RESET}")
        new_admin = build_admin_tokens_from_ios(ios_theme, ios_layout, admin_tokens)

        with open(admin_path, 'w') as f:
            json.dump(new_admin, f, indent=2)

        print(f"{Colors.GREEN}✓ design-tokens.json updated{Colors.RESET}\n")

        # Re-check and report
        admin_tokens = new_admin

    # Compare tokens
    report, has_drift = compare_tokens(ios_theme, ios_layout, admin_tokens)

    # Print report
    exit_code = print_report(report, has_drift)

    sys.exit(exit_code)


if __name__ == '__main__':
    main()
