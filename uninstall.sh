#!/usr/bin/env bash
# ================================================================
#   AvenoxTheme — Uninstaller
#   bash <(curl -sL https://raw.githubusercontent.com/avenoxstudio/avenox-theme/main/uninstall.sh)
# ================================================================

set -euo pipefail

PURPLE='\033[0;35m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

PANEL_DIR="/var/www/pterodactyl"
THEME_DIR="${PANEL_DIR}/public/themes/avenox"
BLADE_FILE="${PANEL_DIR}/resources/views/layouts/master.blade.php"

log()     { echo -e "${PURPLE}[AvenoxTheme]${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*"; exit 1; }

echo ""
echo -e "${BOLD}${PURPLE}  AvenoxTheme — Uninstaller${NC}"
echo ""

[[ $EUID -ne 0 ]] && error "Run as root or with sudo."

if [[ -d "${THEME_DIR}" ]]; then
  rm -rf "${THEME_DIR}"
  success "Removed ${THEME_DIR}"
else
  warn "Theme directory not found — already removed?"
fi

if [[ -f "${BLADE_FILE}" ]]; then
  if grep -q "AVENOX_THEME" "${BLADE_FILE}"; then
    sed -i '/themes\/avenox\/avenox\.css/d' "${BLADE_FILE}"
    sed -i '/themes\/avenox\/theme\.js/d'   "${BLADE_FILE}"
    sed -i '/AVENOX_THEME/d'                "${BLADE_FILE}"
    success "Removed AvenoxTheme from master.blade.php"
  else
    warn "No injection found — already clean."
  fi

  LATEST_BACKUP=$(ls -t "${BLADE_FILE}.avenox-backup."* 2>/dev/null | head -1 || true)
  if [[ -n "${LATEST_BACKUP}" ]]; then
    echo ""
    log "Found backup: $(basename ${LATEST_BACKUP})"
    read -rp "  Restore blade from backup? [y/N] " yn
    if [[ "${yn}" =~ ^[yY]$ ]]; then
      cp "${LATEST_BACKUP}" "${BLADE_FILE}"
      success "Restored from backup"
    fi
  fi
fi

cd "${PANEL_DIR}"
php artisan view:clear  2>/dev/null && success "View cache cleared" || warn "Skipped"
php artisan cache:clear 2>/dev/null && success "App cache cleared"  || warn "Skipped"

echo ""
echo -e "${GREEN}${BOLD}  AvenoxTheme removed. The void is closed.${NC}"
echo ""
