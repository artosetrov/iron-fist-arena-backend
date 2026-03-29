#!/bin/bash
# Local preview server for Hexbound Landing Page
# Usage: cd hexbound-landing && bash serve.sh
# Then open http://localhost:8080 in browser

PORT=${1:-8080}

echo "🏰 Hexbound Landing — Local Preview"
echo "════════════════════════════════════"
echo "  URL:  http://localhost:$PORT"
echo "  Stop: Ctrl+C"
echo ""

# Use Python's built-in HTTP server (available on macOS)
if command -v python3 &> /dev/null; then
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer "$PORT"
else
    echo "❌ Python not found. Install Python or use: npx serve -p $PORT"
    exit 1
fi
