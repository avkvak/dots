#!/bin/bash
# Module 20: Dotfiles deployment
# Uses GNU Stow to symlink configurations

log_header "20" "Deploying dotfiles..."

deploy_claude_home() {
    local claude_source_dir="$DOTS_DIR/claude/.claude"
    local claude_home_dir="$HOME/.claude"
    local temp_dir=""

    if [[ ! -d "$claude_source_dir" ]]; then
        log_warn "Claude config source not found: $claude_source_dir"
        return 0
    fi

    if [[ -L "$claude_home_dir" ]]; then
        temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/claude-home.XXXXXX")"
        cp -a "$claude_home_dir/." "$temp_dir/"
        rm "$claude_home_dir"
        mkdir -p "$claude_home_dir"
        cp -a "$temp_dir/." "$claude_home_dir/"
        rm -rf "$temp_dir"
        log_ok "Replaced Claude symlink with a real ~/.claude directory"
    else
        mkdir -p "$claude_home_dir"
    fi

    cp -an "$claude_source_dir/." "$claude_home_dir/"
    log_ok "Claude config copied into ~/.claude"
}

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log_ok "Oh My Zsh installed"
else
    log_ok "Oh My Zsh already installed"
fi

# Install zsh-autosuggestions
zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    mkdir -p "$zsh_custom/plugins"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
    log_ok "zsh-autosuggestions installed"
else
    log_ok "zsh-autosuggestions already installed"
fi

# Stow packages to deploy
STOW_PACKAGES=(
    alacritty
    btop
    electron-and-browsers-flags
    fontconfig
    fuzzel
    hypr
    niri
    nvim
    swaync
    swayosd
    systemd-user
    waybar
    webstorm
    zed
    zsh
)

# Check stow is installed
if ! has_cmd stow; then
    log_err "stow is not installed"
    exit 1
fi

# Stow each package
cd "$DOTS_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$DOTS_DIR/$pkg" ]]; then
        if ! stow --restow --target="$HOME" "$pkg"; then
            log_err "Failed to stow package: $pkg"
            exit 1
        fi
        log_ok "Stowed $pkg"
    else
        log_warn "Package not found: $pkg"
    fi
done

deploy_claude_home

# Setup theme system
log_info "Setting up theme system..."
mkdir -p "$HOME/.local/share/omarchy"
mkdir -p "$HOME/.config/omarchy/current"
mkdir -p "$HOME/.config/omarchy/themes"
mkdir -p "$HOME/.config/omarchy/themed"

# Link themes directory
if [[ ! -L "$HOME/.local/share/omarchy/themes" ]]; then
    ln -snf "$DOTS_DIR/themes" "$HOME/.local/share/omarchy/themes"
fi

# Add managed policy directory for Google Chrome theme changes
sudo mkdir -p /etc/opt/chrome/policies/managed
sudo chmod a+rw /etc/opt/chrome/policies/managed

# Track current theme name for the generated theme workflow
if [[ -f "$HOME/.config/omarchy/current/theme.name" ]]; then
    current_theme=$(<"$HOME/.config/omarchy/current/theme.name")
    log_ok "Theme already set: $current_theme"
elif [[ -L "$HOME/.config/omarchy/current/theme" ]]; then
    current_theme=$(basename "$(readlink -f "$HOME/.config/omarchy/current/theme")")
    printf '%s\n' "$current_theme" > "$HOME/.config/omarchy/current/theme.name"
    log_ok "Migrated theme: $current_theme"
elif [[ -d "$DOTS_DIR/themes/flexoki-light" ]]; then
    printf 'flexoki-light\n' > "$HOME/.config/omarchy/current/theme.name"
    log_ok "Default theme: flexoki-light"
elif [[ -d "$DOTS_DIR/themes/tokyo-night" ]]; then
    printf 'tokyo-night\n' > "$HOME/.config/omarchy/current/theme.name"
    log_ok "Default theme: tokyo-night"
else
    log_warn "No default theme found"
fi

log_ok "Dotfiles deployed"
