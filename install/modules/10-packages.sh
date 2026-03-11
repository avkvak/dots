#!/bin/bash
# Module 10: Package installation
# Installs yay, base packages, apps, and AUR packages

log_header "10" "Installing packages..."

# Ensure build deps for yay
log_info "Ensuring build dependencies for yay..."
sudo pacman -S --needed --noconfirm base-devel git
log_ok "Build dependencies ready"

# Install yay if not present
if ! has_cmd yay; then
    log_info "Installing yay AUR helper..."
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
    (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_dir"
    log_ok "yay installed"
else
    log_ok "yay already installed"
fi

# Install base packages
base_packages=$(parse_packages "$PACKAGES_DIR/base.txt")
if [[ -n "$base_packages" ]]; then
    log_info "Installing base packages..."
    sudo pacman -S --needed --noconfirm $base_packages
    log_ok "Base packages installed"
fi

# Install app packages
app_packages=$(parse_packages "$PACKAGES_DIR/apps.txt")
if [[ -n "$app_packages" ]]; then
    log_info "Installing app packages..."
    sudo pacman -S --needed --noconfirm $app_packages
    log_ok "App packages installed"
fi

# Install AUR packages
aur_packages=$(parse_packages "$PACKAGES_DIR/aur.txt")
if [[ -n "$aur_packages" ]]; then
    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm $aur_packages
    log_ok "AUR packages installed"
fi
