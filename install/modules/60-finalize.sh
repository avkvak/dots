#!/bin/bash
# Module 60: Finalize setup
# Changes shell, applies theme, shows summary

log_header "60" "Finalizing..."

# Change default shell to zsh
if [[ "$SHELL" != *"zsh"* ]]; then
    if has_cmd zsh; then
        chsh -s /usr/bin/zsh
        log_ok "Default shell: zsh"
    else
        log_warn "zsh not installed"
    fi
else
    log_ok "Shell already zsh"
fi

# Apply theme if set-theme exists
if [[ -x "$DOTS_DIR/themes/set-theme" ]]; then
    if [[ -f "$HOME/.config/omarchy/current/theme.name" ]]; then
        current_theme=$(<"$HOME/.config/omarchy/current/theme.name")
    else
        current_theme=$(basename "$(readlink -f "$HOME/.config/omarchy/current/theme" 2>/dev/null)" 2>/dev/null || echo "")
    fi

    if [[ -n "$current_theme" ]]; then
        log_info "Applying theme: $current_theme"
        "$DOTS_DIR/themes/set-theme" "$current_theme" &>/dev/null || true
        log_ok "Theme applied: $current_theme"
    fi
fi

# Summary
echo ""
echo -e "  ${BOLD}Installed:${NC}"
echo "    - Packages (base + apps + AUR)"
echo "    - Dotfiles (stow)"
echo "    - Git + SSH key"
echo "    - nvm, bun, Claude Code, Zed"
echo "    - ly display manager"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo "    1. Reboot the system"
echo "    2. Log in via ly"
echo "    3. niri will start automatically"
echo ""

show_complete
