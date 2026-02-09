#!/usr/bin/env bash
# ============================================================
# Advanced Flashcards WebServer — RPi Uninstall
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}[ERROR]${NC} Must be run with sudo: sudo ./uninstall_rpi.sh"; exit 1; }

echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Advanced Flashcards WebServer — Uninstall${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}This will remove the Advanced Flashcards server from this Pi.${NC}"
echo ""
echo "  What will be removed:"
echo "    - systemd service (advanced-flashcards)"
echo "    - Application files (/opt/advanced-flashcards)"
echo "    - Log files (/var/log/advanced-flashcards)"
echo "    - CLI tools (af-rpi-sync, af-rpi-update, af-rpi-datasync)"
echo ""
echo -e "${RED}  WARNING: This will DELETE all user data (accounts, progress, decks)!${NC}"
echo -e "${RED}  Back up first: af-rpi-datasync backup${NC}"
echo ""

read -rp "  Are you sure? Type 'yes' to confirm: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && { echo "  Cancelled."; exit 0; }

echo ""
echo "[1/5] Stopping service..."
systemctl stop advanced-flashcards 2>/dev/null || true
systemctl disable advanced-flashcards 2>/dev/null || true
rm -f /etc/systemd/system/advanced-flashcards.service
systemctl daemon-reload

echo "[2/5] Removing CLI tools..."
rm -f /usr/local/bin/af-rpi-sync /usr/local/bin/af-rpi-update /usr/local/bin/af-rpi-datasync

echo "[3/5] Removing application files..."
rm -rf /opt/advanced-flashcards

echo "[4/5] Removing log files..."
rm -rf /var/log/advanced-flashcards

echo "[5/5] Cleaning up firewall..."
command -v ufw &>/dev/null && ufw status | grep -q "Status: active" && ufw delete allow 8009/tcp 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ Uninstall complete.${NC}"
echo "  System packages (python3, git) were NOT removed."
