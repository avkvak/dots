#!/bin/bash
# Bootstrap script for fresh Arch installation
# Usage: curl -fsSL https://raw.githubusercontent.com/<user>/dots/main/install/bootstrap.sh | bash

set -euo pipefail

# Configuration
REPO_URL="https://github.com/avkvak/dots.git"  # Update with your repo
DEFAULT_DOTS_DIR="$HOME/.local/src/dots"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTS_DIR="${DOTS_DIR:-$DEFAULT_DOTS_DIR}"

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

# Install git if needed
if ! command -v git &>/dev/null; then
    echo -e "  → Installing git..."
    sudo pacman -Sy --noconfirm git
fi

# Run from the current checkout if this script already lives inside the repo.
if [[ -f "$SCRIPT_REPO_DIR/install/setup.sh" ]] && [[ -d "$SCRIPT_REPO_DIR/.git" ]]; then
    DOTS_DIR="$SCRIPT_REPO_DIR"
    echo -e "  → Using existing checkout at $DOTS_DIR"
elif [[ -d "$DOTS_DIR/.git" ]]; then
    echo -e "  → Updating dotfiles..."
    cd "$DOTS_DIR"
    git pull --ff-only
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
