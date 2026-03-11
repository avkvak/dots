#!/bin/bash
# Bootstrap script for fresh Arch installation
# Usage: curl -fsSL https://raw.githubusercontent.com/<user>/dots/main/install/bootstrap.sh | bash

set -euo pipefail

# Configuration
REPO_URL="${DOTS_REPO_URL:-git@github.com:avkvak/dots.git}"
DOTS_DIR="$HOME/dev/system/dots"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════╗"
echo "║         Arch Bootstrap                ║"
echo "║         Niri + Wayland                ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Check we're on Arch
if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}Error: This script only works on Arch Linux${NC}"
    exit 1
fi

# Check not root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Do not run as root${NC}"
    exit 1
fi

if [[ -z "$REPO_URL" ]]; then
    echo -e "${RED}Error: set DOTS_REPO_URL to your dots repository URL${NC}"
    exit 1
fi

# Install git if needed
if ! command -v git &>/dev/null; then
    echo -e "  → Installing git..."
    sudo pacman -Sy --noconfirm git
fi

# Clone or update dotfiles
if [[ -d "$DOTS_DIR" ]]; then
    echo -e "  → Updating dotfiles..."
    cd "$DOTS_DIR"
    git pull
else
    echo -e "  → Cloning dotfiles..."
    mkdir -p "$(dirname "$DOTS_DIR")"
    git clone "$REPO_URL" "$DOTS_DIR"
fi

# Run setup
echo -e "  → Starting setup..."
cd "$DOTS_DIR/install"
chmod +x setup.sh
./setup.sh
