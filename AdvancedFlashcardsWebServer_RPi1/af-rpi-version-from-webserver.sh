#!/usr/bin/env bash
# ============================================================
# af-rpi-version-from-webserver.sh
# Updates the RPi project version.json based_on fields from
# the current KenpoFlashcardsWebServer/version.json.
#
# Run from: sidscri-apps/  (the monorepo root)
# Usage:
#   ./AdvancedFlashcardsWebServer_RPi/af-rpi-version-from-webserver.sh
#   ./AdvancedFlashcardsWebServer_RPi/af-rpi-version-from-webserver.sh --bump-build
#   ./AdvancedFlashcardsWebServer_RPi/af-rpi-version-from-webserver.sh --set-version 1.1.0
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Detect monorepo root (parent of this script's folder)
MONO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WS_VERSION="${MONO_ROOT}/KenpoFlashcardsWebServer/version.json"
RPI_VERSION="${SCRIPT_DIR}/version.json"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[VERSION]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC}   $*"; }

# ── Parse args ───────────────────────────────────────────────
BUMP_BUILD=false
SET_VERSION=""

for arg in "$@"; do
    case "$arg" in
        --bump-build) BUMP_BUILD=true ;;
        --set-version=*) SET_VERSION="${arg#*=}" ;;
        --set-version) SET_VERSION="__NEXT__" ;;
        --help|-h)
            echo "Usage: af-rpi-version-from-webserver.sh [OPTIONS]"
            echo ""
            echo "Updates AdvancedFlashcardsWebServer_RPi/version.json"
            echo "with the current webserver version info."
            echo ""
            echo "Options:"
            echo "  --bump-build            Increment RPi build number"
            echo "  --set-version=X.Y.Z     Set RPi version to X.Y.Z"
            echo "  -h, --help              Show this help"
            echo ""
            echo "Without flags: only updates based_on_webserver fields."
            exit 0
            ;;
        *)
            # Handle --set-version X.Y.Z (space-separated)
            if [[ "$SET_VERSION" == "__NEXT__" ]]; then
                SET_VERSION="$arg"
            else
                error "Unknown option: $arg"
                exit 1
            fi
            ;;
    esac
done

# ── Validate ─────────────────────────────────────────────────
if [[ ! -f "$WS_VERSION" ]]; then
    error "WebServer version.json not found: ${WS_VERSION}"
    exit 1
fi

if [[ ! -f "$RPI_VERSION" ]]; then
    error "RPi version.json not found: ${RPI_VERSION}"
    exit 1
fi

# ── Read webserver version ───────────────────────────────────
WS_VER=$(python3 -c "import json; print(json.load(open('${WS_VERSION}'))['version'])")
WS_BUILD=$(python3 -c "import json; print(json.load(open('${WS_VERSION}'))['build'])")

info "WebServer: v${WS_VER} (build ${WS_BUILD})"

# ── Read current RPi version ────────────────────────────────
RPI_VER=$(python3 -c "import json; print(json.load(open('${RPI_VERSION}'))['version'])")
RPI_BUILD=$(python3 -c "import json; print(json.load(open('${RPI_VERSION}'))['build'])")
RPI_BASED_WS=$(python3 -c "import json; print(json.load(open('${RPI_VERSION}')).get('based_on_webserver','?'))")

info "RPi current: v${RPI_VER} (build ${RPI_BUILD}), based on WS v${RPI_BASED_WS}"

# ── Apply changes ────────────────────────────────────────────
NEW_VER="$RPI_VER"
NEW_BUILD="$RPI_BUILD"

if [[ -n "$SET_VERSION" && "$SET_VERSION" != "__NEXT__" ]]; then
    NEW_VER="$SET_VERSION"
    info "Setting RPi version → ${NEW_VER}"
fi

if $BUMP_BUILD; then
    NEW_BUILD=$((RPI_BUILD + 1))
    info "Bumping build → ${NEW_BUILD}"
fi

# ── Write updated version.json ───────────────────────────────
python3 << PYEOF
import json
from datetime import date

with open('${RPI_VERSION}', 'r') as f:
    data = json.load(f)

data['version'] = '${NEW_VER}'
data['build'] = ${NEW_BUILD}
data['released'] = str(date.today())
data['based_on_webserver'] = '${WS_VER}'
data['based_on_webserver_build'] = ${WS_BUILD}

with open('${RPI_VERSION}', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')

print(f"Written: v{data['version']} (build {data['build']})")
print(f"  based_on_webserver: v{data['based_on_webserver']} (build {data['based_on_webserver_build']})")
PYEOF

info "✓ ${RPI_VERSION} updated"
echo ""
echo "Next steps:"
echo "  1. Update CHANGELOG.md with changes"
echo "  2. git add -A && git commit -m \"RPi v${NEW_VER} build ${NEW_BUILD}\""
echo "  3. git push"
