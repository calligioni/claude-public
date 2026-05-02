#!/usr/bin/env bash
# browser-use skill installer (Linux / macOS)
# Installs Python deps + Chromium for Playwright.
# Idempotent: safe to re-run.

set -euo pipefail

echo "==> Checking Python..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 not found on PATH. Install Python >= 3.11." >&2
    exit 1
fi

PY_VER="$(python3 -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')"
PY_MAJOR="${PY_VER%%.*}"
PY_MINOR="${PY_VER##*.}"
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 11 ]; }; then
    echo "ERROR: Python $PY_VER detected. browser-use requires >= 3.11." >&2
    exit 1
fi
echo "    Python $PY_VER OK"

echo "==> Installing browser-use + playwright..."
python3 -m pip install --upgrade browser-use playwright

echo "==> Installing Chromium for Playwright (~170 MB)..."
python3 -m playwright install chromium

echo "==> Smoke test..."
python3 -c "import browser_use, playwright; print('imports OK')"

echo ""
echo "Done. browser-use skill is ready."
echo "Start the server when invoking the skill:"
echo "    cd ~/.claude/skills/browser-use"
echo "    python3 server.py start"
