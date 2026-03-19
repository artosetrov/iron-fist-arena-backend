#!/bin/bash
# ═══════════════════════════════════════════════
# Hexbound → TestFlight (одна команда)
# Запуск: ./scripts/deploy_testflight.sh
# ═══════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# 2. Проверить что Appfile настроен
if grep -q "YOUR_APPLE_ID" fastlane/Appfile; then
    echo ""
    echo "❌ Сначала настрой fastlane/Appfile:"
    echo "   1. Замени YOUR_APPLE_ID@example.com на свой Apple ID"
    echo "   2. Раскомментируй и заполни team_id"
    echo ""
    exit 1
fi

# 3. Проверить что приложение создано в App Store Connect
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

# 4. Запустить Fastlane
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
