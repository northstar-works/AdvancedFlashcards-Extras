#!/usr/bin/env bash
# ============================================================
# START_AdvancedFlashcardsWebServer_RPi.sh — Manual start
# For dev/testing. Production: sudo systemctl start advanced-flashcards
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -f ".env.rpi" ]]; then set -a; source .env.rpi; set +a; fi
KENPO_WEB_PORT="${KENPO_WEB_PORT:-8009}"

[[ ! -f "app.py" ]] && { echo "[ERROR] app.py not found in: $(pwd)"; exit 1; }

if [[ ! -f ".venv/bin/python" ]]; then
    echo "[INFO] Creating virtual environment..."
    python3 -m venv .venv
fi

echo "[INFO] Activating venv..."
source .venv/bin/activate
echo "[INFO] Installing/updating requirements..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

LAN_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
echo ""
echo "[INFO] Starting Advanced Flashcards WebServer on port ${KENPO_WEB_PORT}..."
echo "       Local:   http://localhost:${KENPO_WEB_PORT}"
echo "       LAN:     http://${LAN_IP}:${KENPO_WEB_PORT}"
echo ""
echo "[TIP]  Press Ctrl+C to stop the server."
echo ""
python app.py
echo ""
echo "[INFO] Server stopped."
