#!/bin/bash
# Module 40: Development tools
# Installs nvm, bun, Claude Code, and Zed

log_header "40" "Development tools..."

# Install nvm
if [[ ! -d "$HOME/.nvm" ]]; then
    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    log_ok "nvm installed"
else
    log_ok "nvm already installed"
fi

# Install bun
if ! has_cmd bun; then
    log_info "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
    log_ok "bun installed"
else
    log_ok "bun already installed"
fi

# Install Claude Code
if ! has_cmd claude; then
    log_info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    log_ok "Claude Code installed"
else
    log_ok "Claude Code already installed"
fi

# Install Zed
if ! has_cmd zed; then
    log_info "Installing Zed..."
    curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh
    log_ok "Zed installed"
else
    log_ok "Zed already installed"
fi
