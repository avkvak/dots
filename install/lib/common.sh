#!/bin/bash
# Shared functions for the install system

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Paths
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTS_DIR="$(dirname "$INSTALL_DIR")"
PACKAGES_DIR="$INSTALL_DIR/packages"
MODULES_DIR="$INSTALL_DIR/modules"

# Logging
log_info() { echo -e "  ${DIM}→${NC} $1"; }
log_ok() { echo -e "  ${GREEN}✓${NC} $1"; }
log_err() { echo -e "  ${RED}✗${NC} $1"; }
log_warn() { echo -e "  ${YELLOW}!${NC} $1"; }

log_header() {
    echo -e "\n${CYAN}${BOLD}[$1]${NC} $2"
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║         Arch Setup System             ║"
    echo "║         Niri + Wayland                ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Show completion message
show_complete() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Setup complete! Please reboot.${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
}

# Checks
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_err "This script only works on Arch Linux"
        exit 1
    fi
    log_ok "Running on Arch Linux"
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_err "Do not run this script as root"
        exit 1
    fi
    log_ok "Not running as root"
}

check_internet() {
    if ! ping -c 1 archlinux.org &>/dev/null; then
        log_err "No internet connection"
        exit 1
    fi
    log_ok "Internet connection available"
}

# Parse package file (skip comments and empty lines)
parse_packages() {
    local file="$1"
    if [[ -f "$file" ]]; then
        grep -v '^#' "$file" | grep -v '^$' | tr '\n' ' '
    fi
}

# Run a module
run_module() {
    local module="$1"
    local script="$MODULES_DIR/$module"

    if [[ ! -f "$script" ]]; then
        log_err "Module not found: $module"
        return 1
    fi

    source "$script"
}

# Check if command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Prompt for input (used in git module)
prompt() {
    local var_name="$1"
    local prompt_text="$2"
    local default="${3:-}"

    if [[ -n "$default" ]]; then
        read -rp "  → $prompt_text [$default]: " value
        value="${value:-$default}"
    else
        read -rp "  → $prompt_text: " value
    fi

    eval "$var_name=\"$value\""
}

# Wait for user to press enter
wait_enter() {
    local msg="${1:-Press Enter to continue...}"
    read -rp "  $msg"
}
