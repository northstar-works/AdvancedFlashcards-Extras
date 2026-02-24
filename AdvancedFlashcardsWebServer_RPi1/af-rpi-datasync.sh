#!/usr/bin/env bash
# ============================================================
# af-rpi-datasync — Sync data between Windows/PC and RPi
# Project: AdvancedFlashcardsWebServer_RPi
# ============================================================
set -euo pipefail

RPi_DATA_DIR="/opt/advanced-flashcards/data"
BACKUP_DIR="/opt/advanced-flashcards/backups"
SERVICE_NAME="advanced-flashcards"
WIN_DATA_RELPATH="KenpoFlashcardsWebServer/data"
WIN_USER="${AF_WIN_USER:-Sidscri}"
WIN_SSH_PORT="${AF_WIN_SSH_PORT:-22}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}[DATASYNC]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}     $*"; }
error() { echo -e "${RED}[ERROR]${NC}    $*"; }

show_help() {
    echo ""
    echo -e "${BOLD}af-rpi-datasync${NC} — Sync data between Windows and RPi"
    echo ""
    echo "Usage:"
    echo "  af-rpi-datasync pull <windows-ip>   Pull data FROM Windows"
    echo "  af-rpi-datasync push <windows-ip>   Push data TO Windows"
    echo "  af-rpi-datasync status              Show current data info"
    echo "  af-rpi-datasync backup              Create a local backup"
    echo ""
    echo "Environment variables:"
    echo "  AF_WIN_USER       Windows SSH username (default: Sidscri)"
    echo "  AF_WIN_SSH_PORT   SSH port on Windows (default: 22)"
    echo "  AF_WIN_DATA       Full Windows path to data/ dir"
    echo ""
    echo "Examples:"
    echo "  af-rpi-datasync pull 192.168.1.100"
    echo "  AF_WIN_USER=admin af-rpi-datasync push 192.168.1.100"
    echo ""
    echo "Alternative (no SSH required on Windows):"
    echo "  On Windows, run: af-rpi-datasync-to-rpi.bat <rpi-ip>"
    echo ""
}

do_backup() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/data_backup_${TIMESTAMP}.tar.gz"
    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_FILE" -C "$(dirname "$RPi_DATA_DIR")" "$(basename "$RPi_DATA_DIR")"
    info "Backup created: ${BACKUP_FILE} ($(du -sh "$BACKUP_FILE" | awk '{print $1}'))"
    ls -1t "${BACKUP_DIR}"/data_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f
}

do_status() {
    echo ""
    echo -e "${CYAN}═══ RPi Data Status ═══${NC}"
    echo ""
    if [[ -d "$RPi_DATA_DIR" ]]; then
        echo -e "  ${BOLD}Data dir:${NC}   ${RPi_DATA_DIR}"
        echo -e "  ${BOLD}Size:${NC}       $(du -sh "$RPi_DATA_DIR" | awk '{print $1}')"
        echo ""
        echo -e "  ${BOLD}Contents:${NC}"
        USER_COUNT=$(find "${RPi_DATA_DIR}/users" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        echo "    Users:        ${USER_COUNT}"
        if [[ -f "${RPi_DATA_DIR}/profiles.json" ]]; then
            PROFILE_COUNT=$(python3 -c "import json; d=json.load(open('${RPi_DATA_DIR}/profiles.json')); print(len(d))" 2>/dev/null || echo "?")
            echo "    Profiles:     ${PROFILE_COUNT}"
        fi
        if [[ -f "${RPi_DATA_DIR}/decks.json" ]]; then
            DECK_COUNT=$(python3 -c "import json; d=json.load(open('${RPi_DATA_DIR}/decks.json')); print(len(d.get('decks',[])))" 2>/dev/null || echo "?")
            echo "    Decks:        ${DECK_COUNT}"
        fi
        if [[ -f "${RPi_DATA_DIR}/breakdowns.json" ]]; then
            BD_COUNT=$(python3 -c "import json; d=json.load(open('${RPi_DATA_DIR}/breakdowns.json')); print(len(d))" 2>/dev/null || echo "?")
            echo "    Breakdowns:   ${BD_COUNT}"
        fi
        echo ""
        echo -e "  ${BOLD}Last modified:${NC}"
        find "$RPi_DATA_DIR" -type f -name "*.json" -printf "    %T+ %p\n" 2>/dev/null | sort -r | head -5
    else
        warn "Data directory not found: ${RPi_DATA_DIR}"
    fi
    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}"/data_backup_*.tar.gz 2>/dev/null | wc -l)
        echo -e "  ${BOLD}Backups:${NC}    ${BACKUP_COUNT} (${BACKUP_DIR})"
    fi
    echo ""
}

do_pull() {
    local WIN_IP="$1"
    local WIN_DATA="${AF_WIN_DATA:-/c/Users/${WIN_USER}/Documents/GitHub/sidscri-apps/${WIN_DATA_RELPATH}}"
    echo -e "${CYAN}═══ Pull: Windows (${WIN_IP}) → RPi ═══${NC}"
    info "Source: ${WIN_USER}@${WIN_IP}:${WIN_DATA}/"
    info "Dest:   ${RPi_DATA_DIR}/"
    echo ""
    warn "Creating backup before pull..."
    do_backup
    info "Stopping service..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    info "Pulling data from Windows..."
    rsync -avz --progress -e "ssh -p ${WIN_SSH_PORT}" \
        "${WIN_USER}@${WIN_IP}:${WIN_DATA}/" "${RPi_DATA_DIR}/" \
        --exclude '__pycache__' --exclude '*.pyc' --exclude 'test*'
    info "Restarting service..."
    sudo systemctl start "$SERVICE_NAME"
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        info "✓ Pull complete — service running"
    else
        error "Service failed after pull!"
        echo "  Restore: tar -xzf ${BACKUP_DIR}/data_backup_*.tar.gz -C /opt/advanced-flashcards/"
    fi
}

do_push() {
    local WIN_IP="$1"
    local WIN_DATA="${AF_WIN_DATA:-/c/Users/${WIN_USER}/Documents/GitHub/sidscri-apps/${WIN_DATA_RELPATH}}"
    echo -e "${CYAN}═══ Push: RPi → Windows (${WIN_IP}) ═══${NC}"
    info "Source: ${RPi_DATA_DIR}/"
    info "Dest:   ${WIN_USER}@${WIN_IP}:${WIN_DATA}/"
    echo ""
    info "Pushing data to Windows..."
    rsync -avz --progress -e "ssh -p ${WIN_SSH_PORT}" \
        "${RPi_DATA_DIR}/" "${WIN_USER}@${WIN_IP}:${WIN_DATA}/" \
        --exclude '__pycache__' --exclude '*.pyc' --exclude 'test*'
    info "✓ Push complete"
}

ACTION="${1:-}"; shift || true
case "$ACTION" in
    pull)  [[ -z "${1:-}" ]] && { error "Missing IP"; exit 1; }; do_pull "$1" ;;
    push)  [[ -z "${1:-}" ]] && { error "Missing IP"; exit 1; }; do_push "$1" ;;
    status) do_status ;;
    backup) do_backup ;;
    *)      show_help; exit 0 ;;
esac
