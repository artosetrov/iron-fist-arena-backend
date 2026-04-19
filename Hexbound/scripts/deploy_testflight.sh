#!/bin/bash
# ═══════════════════════════════════════════════
# Hexbound → TestFlight (одна команда)
# Запуск: ./scripts/deploy_testflight.sh
# ═══════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOCAL_APPFILE="$PROJECT_DIR/fastlane/Appfile.local"

cd "$PROJECT_DIR"

echo "🎮 Hexbound → TestFlight Deploy"
echo "═══════════════════════════════════════"

# 1. Проверить что Fastlane установлен
if ! command -v fastlane &> /dev/null; then
    echo "⚠️  Fastlane не найден. Устанавливаю..."

    if [ -f "Gemfile" ]; then
        bundle install
    else
        gem install fastlane
    fi
fi

# 2. Проверить iOS runtime config
echo ""
echo "🔎 Проверяю iOS release config..."
python3 scripts/check_release_config.py

# 3. Проверить что Fastlane identity настроен
has_fastlane_apple_id=false
if [ -n "${FASTLANE_APPLE_ID:-}" ]; then
    has_fastlane_apple_id=true
elif [ -f "$LOCAL_APPFILE" ] && grep -Eq '^[[:space:]]*apple_id\(' "$LOCAL_APPFILE"; then
    has_fastlane_apple_id=true
fi

has_fastlane_team=false
if [ -n "${FASTLANE_TEAM_ID:-}" ] || [ -n "${FASTLANE_ITC_TEAM_ID:-}" ]; then
    has_fastlane_team=true
elif [ -f "$LOCAL_APPFILE" ] && grep -Eq '^[[:space:]]*(team_id|itc_team_id)\(' "$LOCAL_APPFILE"; then
    has_fastlane_team=true
fi

if [ "$has_fastlane_apple_id" != "true" ] || [ "$has_fastlane_team" != "true" ]; then
    echo ""
    echo "❌ Сначала настрой Fastlane identity:"
    echo "   Нужен Apple ID и Team ID / App Store Connect Team ID"
    echo ""
    echo "   Вариант A: создать fastlane/Appfile.local"
    echo "   1. Скопируй fastlane/Appfile.local.example → fastlane/Appfile.local"
    echo "   2. Заполни apple_id / team_id / itc_team_id"
    echo ""
    echo "   Вариант B: передать env vars"
    echo "   FASTLANE_APPLE_ID=..."
    echo "   FASTLANE_TEAM_ID=..."
    echo "   FASTLANE_ITC_TEAM_ID=...   # если нужен отдельный ASC team"
    echo ""
    exit 1
fi

# 4. Проверить что приложение создано в App Store Connect
echo ""
echo "📋 Чеклист перед загрузкой:"
echo "   ✓ Apple Developer Program оплачен?"
echo "   ✓ Приложение создано в App Store Connect?"
echo "   ✓ Bundle ID: com.hexbound.app зарегистрирован?"
echo ""
read -p "Всё готово? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Ок, сначала настрой всё по TESTFLIGHT_GUIDE.md"
    exit 0
fi

# 5. Запустить Fastlane
echo ""
echo "🚀 Запускаю сборку и загрузку..."
echo ""

if [ -f "Gemfile" ]; then
    bundle exec fastlane beta
else
    fastlane beta
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ Готово! Проверь TestFlight в App Store Connect"
echo "   https://appstoreconnect.apple.com"
echo "═══════════════════════════════════════"
