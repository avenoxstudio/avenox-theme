#!/usr/bin/env bash
# ================================================================
#   AvenoxTheme — Installer
#   For Pterodactyl / Reviactyl Panel
#
#   Install command:
#     bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/avenox-theme/main/install.sh)
# ================================================================

set -euo pipefail

PURPLE='\033[0;35m'; CYAN='\033[0;36m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

# ── CHANGE THIS to your GitHub username ──────────────────────────
GITHUB_USER="YOUR_USERNAME"
GITHUB_REPO="avenox-theme"
GITHUB_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# Panel paths
PANEL_DIR="/var/www/pterodactyl"
THEME_DIR="${PANEL_DIR}/public/themes/avenox"
BLADE_FILE="${PANEL_DIR}/resources/views/layouts/master.blade.php"

log()     { echo -e "${PURPLE}[AvenoxTheme]${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
error()   { echo -e "${RED}  ✗ ERROR:${NC} $*"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}── $*${NC}"; }

clear
echo -e "${PURPLE}"
echo "    ___                          _____ _"
echo "   / _ \__   _____  _ __   ___ |_   _| |__   ___ _ __ ___   ___"
echo "  / /_\\ \\ \\ / / _ \\| '_ \\ / _ \\  | | | '_ \\ / _ \\ '_ \` _ \\ / _ \\"
echo " /  _  |\\ V /  __/| | | | (_) | | | | | | |  __/ | | | | |  __/"
echo "/_/ \\_/ \\_/ \\___||_| |_|\\___/  |_| |_| |_|\\___|_| |_| |_|\\___|"
echo -e "${NC}"
echo -e "${BOLD}${PURPLE}  AvenoxTheme — Minecraft End for Pterodactyl / Reviactyl${NC}"
echo -e "${CYAN}  https://github.com/${GITHUB_USER}/${GITHUB_REPO}${NC}"
echo ""

step "Checking requirements"
[[ $EUID -ne 0 ]] && error "Run as root or with sudo."
success "Running as root"
[[ ! -d "${PANEL_DIR}" ]] && error "Panel not found at ${PANEL_DIR}. Install Pterodactyl / Reviactyl first."
success "Panel found at ${PANEL_DIR}"
command -v curl &>/dev/null || error "curl not found: apt install curl -y"
success "curl available"

step "Connecting to GitHub"
log "Testing connection..."
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "${RAW_BASE}/install.sh" || true)
[[ "$HTTP_CODE" != "200" ]] && error "Cannot reach GitHub (HTTP ${HTTP_CODE}). Make sure repo is public."
success "GitHub reachable"

step "Backing up blade template"
if [[ -f "${BLADE_FILE}" ]]; then
  BACKUP="${BLADE_FILE}.avenox-backup.$(date +%Y%m%d_%H%M%S)"
  cp "${BLADE_FILE}" "${BACKUP}"
  success "Backed up → $(basename ${BACKUP})"
else
  warn "master.blade.php not found — continuing."
fi

step "Creating theme directory"
mkdir -p "${THEME_DIR}"
success "Created: ${THEME_DIR}"

step "Downloading AvenoxTheme files"
# Files are in the ROOT of the repo — no subfolders needed

log "Downloading avenox.css..."
curl -fsSL --max-time 30 "${RAW_BASE}/avenox.css" -o "${THEME_DIR}/avenox.css" \
  || error "Failed to download avenox.css — check your repo is public and file exists."
success "avenox.css downloaded"

log "Downloading theme.js..."
curl -fsSL --max-time 30 "${RAW_BASE}/theme.js" -o "${THEME_DIR}/theme.js" \
  || error "Failed to download theme.js — check your repo is public and file exists."
success "theme.js downloaded"

step "Setting permissions"
chown -R www-data:www-data "${THEME_DIR}" 2>/dev/null \
  || chown -R nginx:nginx "${THEME_DIR}" 2>/dev/null \
  || warn "Could not auto-set ownership. Run: chown -R www-data:www-data ${THEME_DIR}"
chmod 755 "${THEME_DIR}"
chmod 644 "${THEME_DIR}/avenox.css" "${THEME_DIR}/theme.js"
success "Permissions set"

step "Injecting AvenoxTheme into panel"
CSS_TAG='    <link rel="stylesheet" href="/themes/avenox/avenox.css">'
JS_TAG='    <script src="/themes/avenox/theme.js" defer></script>'
MARKER="<!-- AVENOX_THEME -->"

if [[ -f "${BLADE_FILE}" ]]; then
  if grep -q "AVENOX_THEME" "${BLADE_FILE}" 2>/dev/null; then
    warn "Already injected — skipping."
  elif grep -q "</head>" "${BLADE_FILE}"; then
    sed -i "s|</head>|${CSS_TAG}\n${JS_TAG}\n    ${MARKER}\n</head>|" "${BLADE_FILE}"
    success "Injected into master.blade.php"
  else
    printf '\n%s\n%s\n%s\n' "${CSS_TAG}" "${JS_TAG}" "${MARKER}" >> "${BLADE_FILE}"
    success "Appended to master.blade.php"
  fi
else
  warn "Blade file not found — add manually before </head>:"
  echo -e "  ${CYAN}${CSS_TAG}${NC}"
  echo -e "  ${CYAN}${JS_TAG}${NC}"
fi

step "Clearing panel cache"
cd "${PANEL_DIR}"
php artisan view:clear   2>/dev/null && success "View cache cleared"   || warn "Skipped"
php artisan config:clear 2>/dev/null && success "Config cache cleared" || warn "Skipped"
php artisan cache:clear  2>/dev/null && success "App cache cleared"    || warn "Skipped"

echo ""
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║       ✓  AvenoxTheme Installed Successfully!         ║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  Hard-refresh:${NC} Ctrl+Shift+R  /  Cmd+Shift+R"
echo ""
echo -e "${YELLOW}  To uninstall:${NC}"
echo -e "  ${CYAN}bash <(curl -sL ${RAW_BASE}/uninstall.sh)${NC}"
echo ""
