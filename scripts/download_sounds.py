#!/usr/bin/env python3
"""
Hexbound Sound Downloader — P0 MVP Sounds
==========================================
Скачивает все P0 звуки с Pixabay (royalty-free, no attribution required).

Использование:
    cd "путь/к/PVP RPG"
    python3 scripts/download_sounds.py

Требования: Python 3.7+ (requests и beautifulsoup4 не нужны — используем только stdlib)

Важно: это bootstrap-скрипт для курированного Pixabay seed-набора, а не
канонический source of truth для production-аудио. Актуальные bundle-имена и
вариации живут в `Hexbound/Hexbound/Persistence/SFXCatalog.swift`.
"""

import re
import time
import urllib.request
import urllib.parse
import urllib.error
import ssl
from pathlib import Path
from typing import Optional

# ============================================================
# КОНФИГУРАЦИЯ — Курированные Pixabay страницы для каждого звука
# ============================================================

# Формат: (output_filename, subfolder, pixabay_page_url, description)
# pixabay_page_url — либо прямая ссылка на страницу звука, либо поисковый запрос (search:query)

SOUNDS = [
    # ─── UI (7) ───
    ("ui_tap.mp3",           "sfx/ui",          "https://pixabay.com/sound-effects/musical-video-game-menu-click-sounds-148373/",              "Мягкий UI тап"),
    ("ui_tap_heavy.mp3",     "sfx/ui",          "search:heavy button click game",                                                               "Тяжёлый CTA тап"),
    ("ui_back.mp3",          "sfx/ui",          "search:whoosh swipe back ui",                                                                  "Swoosh назад"),
    ("ui_tab_switch.mp3",    "sfx/ui",          "search:tab switch click interface",                                                            "Переключение табов"),
    ("ui_modal_open.mp3",    "sfx/ui",          "search:popup appear whoosh soft",                                                              "Модалка открывается"),
    ("ui_modal_close.mp3",   "sfx/ui",          "search:close dismiss soft swoosh",                                                             "Модалка закрывается"),
    ("ui_error.mp3",         "sfx/ui",          "search:error wrong buzzer game",                                                               "Ошибка / отказ"),

    # ─── COMBAT (9) ───
    ("combat_hit_physical.mp3",  "sfx/combat",  "https://pixabay.com/sound-effects/film-special-effects-sword-clashhit-393837/",               "Удар мечом — физический"),
    ("combat_hit_magical.mp3",   "sfx/combat",  "https://pixabay.com/sound-effects/film-special-effects-epic-spell-impact-478364/",            "Магический удар"),
    ("combat_hit_rogue.mp3",     "sfx/combat",  "search:knife dagger slash quick",                                                              "Быстрый порез (Rogue)"),
    ("combat_crit.mp3",          "sfx/combat",  "search:critical hit impact heavy",                                                             "Критический удар"),
    ("combat_miss.mp3",          "sfx/combat",  "search:sword whoosh miss swing",                                                               "Промах — свист"),
    ("combat_dodge.mp3",         "sfx/combat",  "search:dodge swoosh fast",                                                                     "Уворот"),
    ("combat_block.mp3",         "sfx/combat",  "https://pixabay.com/sound-effects/film-special-effects-shield-block-shortsword-143940/",      "Блок щитом"),
    ("combat_death.mp3",         "sfx/combat",  "search:body fall death impact",                                                                "Смерть — падение"),
    ("combat_start.mp3",         "sfx/combat",  "search:battle horn war start epic",                                                            "Рог начала боя"),

    # ─── REWARDS (5) ───
    ("result_victory.mp3",    "sfx/rewards",    "https://pixabay.com/sound-effects/film-special-effects-success-fanfare-trumpets-6185/",       "Фанфары победы"),
    ("result_defeat.mp3",     "sfx/rewards",    "https://pixabay.com/sound-effects/musical-game-over-39-199830/",                              "Тема поражения"),
    ("reward_gold.mp3",       "sfx/rewards",    "https://pixabay.com/sound-effects/film-special-effects-gold-coins-437273/",                   "Звон золотых монет"),
    ("reward_xp.mp3",         "sfx/rewards",    "search:level up chime game rpg",                                                               "XP / повышение"),
    ("reward_item_drop.mp3",  "sfx/rewards",    "search:item pickup sparkle loot game",                                                         "Подбор предмета"),

    # ─── PROGRESSION (2) ───
    ("progression_upgrade.mp3",       "sfx/progression",  "search:upgrade forge anvil success",                                                 "Апгрейд предмета"),
    ("progression_upgrade_fail.mp3",  "sfx/progression",  "search:break shatter fail",                                                          "Неудачный апгрейд"),

    # ─── DUNGEON (3) ───
    ("dungeon_enter.mp3",          "sfx/dungeon",  "search:heavy stone door open dungeon",                                                      "Вход в данж — тяжёлая дверь"),
    ("dungeon_floor_complete.mp3", "sfx/dungeon",  "search:short triumph success chime game",                                                   "Этаж пройден"),
    ("dungeon_boss_appear.mp3",    "sfx/dungeon",  "search:boss appear dark ominous",                                                           "Появление босса"),

    # ─── SHOP (2) ───
    ("shop_purchase.mp3",  "sfx/shop",  "search:purchase buy cash register game",                                                               "Покупка — ка-чинг"),
    ("shop_sell.mp3",      "sfx/shop",  "search:sell coins drop payment",                                                                       "Продажа"),
]

# Музыка — поисковые запросы для Pixabay Music
MUSIC = [
    ("music_main_theme.mp3",  "music",  "search:dark fantasy epic theme orchestral",            "Главная тема"),
    ("music_hub.mp3",         "music",  "search:medieval town calm dark ambient rpg",            "Тема хаба / города"),
    ("music_battle.mp3",      "music",  "search:epic battle combat orchestral fast rpg",         "Боевая тема"),
    ("music_victory.mp3",     "music",  "search:victory fanfare short orchestral triumph",       "Победный стинг (короткий)"),
    ("music_defeat.mp3",      "music",  "search:defeat sad game over dark",                      "Поражение (короткий)"),
]

# ============================================================
# ЗАГРУЗЧИК
# ============================================================

# SSL context (some systems need this)
SSL_CTX = ssl.create_default_context()

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

def fetch_url(url: str) -> str:
    """Fetch URL and return text content."""
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, context=SSL_CTX, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def search_pixabay_sfx(query: str) -> Optional[str]:
    """Search Pixabay SFX and return first result page URL."""
    encoded = urllib.parse.quote(query)
    search_url = f"https://pixabay.com/sound-effects/search/{encoded}/"
    try:
        html = fetch_url(search_url)
        # Find first sound effect link
        match = re.search(r'href="(/sound-effects/[a-z][^"]*-\d+/)"', html)
        if match:
            return f"https://pixabay.com{match.group(1)}"
    except Exception as e:
        print(f"  ⚠ Поиск не удался: {e}")
    return None


def search_pixabay_music(query: str) -> Optional[str]:
    """Search Pixabay Music and return first result page URL."""
    encoded = urllib.parse.quote(query)
    search_url = f"https://pixabay.com/music/search/{encoded}/"
    try:
        html = fetch_url(search_url)
        match = re.search(r'href="(/music/[a-z][^"]*-\d+/)"', html)
        if match:
            return f"https://pixabay.com{match.group(1)}"
    except Exception as e:
        print(f"  ⚠ Поиск музыки не удался: {e}")
    return None


def extract_cdn_url(page_url: str) -> Optional[str]:
    """Extract CDN download URL from a Pixabay sound/music page."""
    try:
        html = fetch_url(page_url)
        match = re.search(
            r'https://cdn\.pixabay\.com/download/audio/[^"\'<>\s]+\.mp3[^"\'<>\s]*',
            html
        )
        if match:
            return match.group(0).split('"')[0].split("'")[0]
    except Exception as e:
        print(f"  ⚠ Не удалось извлечь CDN URL: {e}")
    return None


def download_file(url: str, output_path: Path) -> bool:
    """Download file from URL to local path."""
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, context=SSL_CTX, timeout=60) as resp:
            data = resp.read()
            output_path.write_bytes(data)
            size_kb = len(data) / 1024
            print(f"  ✅ Скачано: {output_path.name} ({size_kb:.0f} KB)")
            return True
    except Exception as e:
        print(f"  ❌ Ошибка загрузки: {e}")
        return False


def process_sound(filename: str, subfolder: str, source: str, description: str,
                  base_dir: Path, is_music: bool = False) -> str:
    """Process one sound: resolve URL → extract CDN → download."""
    output_dir = base_dir / "sounds" / subfolder
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / filename

    if output_path.exists():
        if output_path.stat().st_size > 100:
            print(f"  ⏭ Уже есть: {filename}")
            return "skipped"
        print(f"  ⚠ Поврежденный файл, перекачиваю: {filename}")
        output_path.unlink()

    print(f"\n{'🎵' if is_music else '🔊'} {filename} — {description}")

    # Step 1: Resolve page URL
    if source.startswith("search:"):
        query = source[7:]
        print(f"  🔍 Ищу: \"{query}\"...")
        if is_music:
            page_url = search_pixabay_music(query)
        else:
            page_url = search_pixabay_sfx(query)
        if not page_url:
            print(f"  ❌ Ничего не найдено для \"{query}\"")
            return "failed"
        print(f"  📄 Найдено: {page_url.split('/')[-2]}")
    else:
        page_url = source
        print(f"  📄 Страница: {page_url.split('/')[-2]}")

    # Step 2: Extract CDN URL
    cdn_url = extract_cdn_url(page_url)
    if not cdn_url:
        print(f"  ❌ CDN URL не найден на странице")
        return "failed"

    # Step 3: Download
    time.sleep(0.5)  # Вежливая задержка между запросами
    return "downloaded" if download_file(cdn_url, output_path) else "failed"


# ============================================================
# MAIN
# ============================================================

def main():
    # Определяем корневую папку проекта
    script_dir = Path(__file__).resolve().parent
    base_dir = script_dir.parent  # PVP RPG/

    print("=" * 60)
    print("🏰 HEXBOUND SOUND DOWNLOADER — P0 MVP")
    print("=" * 60)
    print(f"📁 Проект: {base_dir}")
    print(f"📦 Звуки: {base_dir / 'sounds'}")
    print(f"🎯 Цель: {len(SOUNDS)} SFX + {len(MUSIC)} музыка = {len(SOUNDS) + len(MUSIC)} файлов")
    print("=" * 60)

    success = 0
    failed = 0
    skipped = 0
    failed_list = []

    # SFX
    print("\n" + "─" * 40)
    print("📢 ЗВУКОВЫЕ ЭФФЕКТЫ (SFX)")
    print("─" * 40)

    for filename, subfolder, source, desc in SOUNDS:
        result = process_sound(filename, subfolder, source, desc, base_dir)
        if result == "downloaded":
            success += 1
        elif result == "skipped":
            skipped += 1
        else:
            failed += 1
            failed_list.append(filename)

    # Music
    print("\n" + "─" * 40)
    print("🎵 МУЗЫКА")
    print("─" * 40)

    for filename, subfolder, source, desc in MUSIC:
        result = process_sound(filename, subfolder, source, desc, base_dir, is_music=True)
        if result == "downloaded":
            success += 1
        elif result == "skipped":
            skipped += 1
        else:
            failed += 1
            failed_list.append(filename)

    # Summary
    total = len(SOUNDS) + len(MUSIC)
    print("\n" + "=" * 60)
    print("📊 ИТОГО")
    print("=" * 60)
    print(f"  ✅ Скачано: {success}/{total}")
    print(f"  ⏭ Пропущено (уже есть): {skipped}")
    if failed_list:
        print(f"  ❌ Не удалось ({failed}):")
        for f in failed_list:
            print(f"     - {f}")
        print(f"\n💡 Для неудавшихся — скачай вручную с pixabay.com/sound-effects/")
    else:
        print("  🎉 Все звуки скачаны!")

    # List all downloaded files
    sounds_dir = base_dir / "sounds"
    if sounds_dir.exists():
        print(f"\n📂 Структура {sounds_dir}:")
        for p in sorted(sounds_dir.rglob("*.mp3")):
            rel = p.relative_to(sounds_dir)
            size = p.stat().st_size / 1024
            print(f"  {rel} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
