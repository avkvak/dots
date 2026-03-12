#!/bin/bash
# Audits the local machine against the repository's expectations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/doctor.sh"

STOW_PACKAGES=(
    alacritty
    btop
    claude
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

REQUIRED_COMMANDS=(
    bash
    stow
    git
    curl
    python3
    fuzzel
    alacritty
    wl-paste
    cliphist
    jq
    swaybg
    swaync-client
    swayosd-client
    grim
    slurp
    satty
    notify-send
)

OPTIONAL_COMMANDS=(
    yay
    wlsunset
    playerctl
    pamixer
    wl-copy
    btop
    impala
    wiremix
    bluetui
    handy
    uwsm-app
)

EXTERNAL_OPTIONAL_FILES=(
    "$HOME/.config/waybar/scripts/clock.sh"
    "$HOME/.config/waybar/scripts/toggle-clock-mode.sh"
    "$HOME/.config/waybar/scripts/evolution-calendar.py"
    "$HOME/.config/waybar/scripts/swaync-status.sh"
    "$HOME/.config/waybar/scripts/open-power-menu.sh"
    "$HOME/.config/waybar/scripts/open-timezone-picker.sh"
    "$HOME/.pi/agent/settings.json"
)

repo_integrity_checks() {
    doctor_section "repo"

    local package
    for package in "${STOW_PACKAGES[@]}"; do
        if [[ -d "$DOTS_DIR/$package" ]]; then
            doctor_pass "Stow package exists: $package"
        else
            doctor_fail "Stow package missing from repo: $package"
        fi
    done

    local module
    for module in \
        "00-preflight.sh" \
        "10-packages.sh" \
        "20-dotfiles.sh" \
        "30-git.sh" \
        "40-dev-tools.sh" \
        "50-services.sh" \
        "60-finalize.sh"; do
        doctor_check_file "$MODULES_DIR/$module" fail "install/modules/$module"
    done

    doctor_check_dir "$DOTS_DIR/themes" fail "themes/"
    doctor_check_dir "$DOTS_DIR/themes/themed" fail "themes/themed/"
    doctor_check_file "$DOTS_DIR/themes/set-theme" fail "themes/set-theme"
    doctor_check_file "$DOTS_DIR/themes/set-next-bg.sh" fail "themes/set-next-bg.sh"
    doctor_check_file "$DOTS_DIR/themes/theme-picker.sh" fail "themes/theme-picker.sh"
    doctor_check_file "$DOTS_DIR/themes/clipboard-picker.sh" fail "themes/clipboard-picker.sh"
    doctor_check_file "$DOTS_DIR/themes/wallpaper-picker.sh" fail "themes/wallpaper-picker.sh"
    doctor_check_file "$DOTS_DIR/themes/brightness-control.sh" fail "themes/brightness-control.sh"
    doctor_check_file "$DOTS_DIR/themes/run-wallpaper.sh" fail "themes/run-wallpaper.sh"
    doctor_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-wallpaper.service" fail "systemd-user/.config/systemd/user/omarchy-wallpaper.service"
    doctor_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-swayosd.service" fail "systemd-user/.config/systemd/user/omarchy-swayosd.service"
    doctor_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-auto-theme.service" fail "systemd-user/.config/systemd/user/omarchy-auto-theme.service"
    doctor_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-auto-theme.timer" fail "systemd-user/.config/systemd/user/omarchy-auto-theme.timer"
}

command_checks() {
    doctor_section "commands"

    local cmd
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        doctor_check_cmd "$cmd" fail
    done

    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        doctor_check_cmd "$cmd" warn
    done
}

path_checks() {
    doctor_section "paths"

    doctor_check_file "$HOME/.config/niri/lock.sh" warn "~/.config/niri/lock.sh"
    doctor_check_file "$HOME/.local/share/omarchy/themes/theme-picker.sh" warn "~/.local/share/omarchy/themes/theme-picker.sh"
    doctor_check_file "$HOME/.local/share/omarchy/themes/clipboard-picker.sh" warn "~/.local/share/omarchy/themes/clipboard-picker.sh"
    doctor_check_file "$HOME/.local/share/omarchy/themes/set-next-bg.sh" warn "~/.local/share/omarchy/themes/set-next-bg.sh"
    doctor_check_file "$HOME/.local/share/omarchy/themes/wallpaper-picker.sh" warn "~/.local/share/omarchy/themes/wallpaper-picker.sh"
    doctor_check_file "$HOME/.local/share/omarchy/themes/brightness-control.sh" warn "~/.local/share/omarchy/themes/brightness-control.sh"
    doctor_check_dir "$HOME/.config/omarchy/current" warn "~/.config/omarchy/current"
    doctor_check_file "$HOME/.config/omarchy/current/theme.name" warn "~/.config/omarchy/current/theme.name"
    doctor_check_dir "$HOME/.config/omarchy/current/theme" warn "~/.config/omarchy/current/theme"
    doctor_check_link_target "$HOME/.config/omarchy/current/background" warn "~/.config/omarchy/current/background"

    local path
    for path in "${EXTERNAL_OPTIONAL_FILES[@]}"; do
        doctor_check_file "$path" warn "$path"
    done
}

theme_checks() {
    doctor_section "theme"

    local current_theme=""
    local theme_dir=""

    if [[ -f "$HOME/.config/omarchy/current/theme.name" ]]; then
        current_theme=$(<"$HOME/.config/omarchy/current/theme.name")
    fi

    if [[ -z "$current_theme" ]]; then
        doctor_warn "Current theme name is not set"
        return 0
    fi

    doctor_pass "Current theme name: $current_theme"

    if [[ -d "$DOTS_DIR/themes/$current_theme" ]]; then
        theme_dir="$DOTS_DIR/themes/$current_theme"
    elif [[ -d "$HOME/.config/omarchy/themes/$current_theme" ]]; then
        theme_dir="$HOME/.config/omarchy/themes/$current_theme"
    fi

    if [[ -z "$theme_dir" ]]; then
        doctor_fail "Theme cannot be resolved: $current_theme"
        return 1
    fi

    doctor_pass "Theme resolves to: $theme_dir"

    doctor_check_dir "$theme_dir/backgrounds" warn "$theme_dir/backgrounds"
    doctor_check_file "$HOME/.config/omarchy/current/theme/alacritty.toml" warn "~/.config/omarchy/current/theme/alacritty.toml"
    doctor_check_file "$HOME/.config/omarchy/current/theme/waybar.css" warn "~/.config/omarchy/current/theme/waybar.css"
}

package_manifest_checks() {
    doctor_section "packages"

    local -a package_files=(
        "$PACKAGES_DIR/base.txt"
        "$PACKAGES_DIR/apps.txt"
        "$PACKAGES_DIR/aur.txt"
    )
    local file

    for file in "${package_files[@]}"; do
        doctor_check_file "$file" fail "${file#$DOTS_DIR/}"
    done

    local -a runtime_packages=(
        "python"
        "python-gobject"
        "evolution-data-server"
        "swaybg"
        "playerctl"
        "pamixer"
    )
    local package_name

    for package_name in "${runtime_packages[@]}"; do
        if grep -Rqx "$package_name" "$PACKAGES_DIR"; then
            doctor_pass "Runtime dependency declared in package manifests: $package_name"
        else
            doctor_warn "Runtime dependency used by configs but not declared in package manifests: $package_name"
        fi
    done
}

script_runtime_checks() {
    doctor_section "script-runtime"

    if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("EDataServer", "1.2")
gi.require_version("ECal", "2.0")
from gi.repository import ECal, EDataServer
PY
    then
        doctor_pass "Python GI Evolution bindings available for evolution-calendar.py"
    else
        doctor_warn "Missing Python GI Evolution bindings for evolution-calendar.py"
    fi
}

main() {
    cd "$DOTS_DIR"
    show_banner

    repo_integrity_checks
    package_manifest_checks
    command_checks
    path_checks
    theme_checks
    script_runtime_checks

    doctor_summary

    if (( DOCTOR_FAIL_COUNT > 0 )); then
        exit 1
    fi
}

main "$@"
