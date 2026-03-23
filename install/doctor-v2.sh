#!/bin/bash
# Live runtime doctor for the current workstation session.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/doctor_v2.sh"

SECTION_FILTER=""

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

CORE_COMMANDS=(
    bash
    git
    stow
    curl
    python3
    alacritty
    fuzzel
    jq
    notify-send
    niri
    xwayland-satellite
    waybar
    swaybg
    swayidle
    swaylock
    swaync-client
    swayosd-client
    wl-paste
    wl-copy
    cliphist
    grim
    slurp
    satty
    brightnessctl
    rclone
    fusermount3
)

OPTIONAL_COMMANDS=(
    wlsunset
    playerctl
    pamixer
    impala
    wiremix
    bluetui
    handy
    orca
    uwsm-app
)

REPO_BASH_SCRIPTS=(
    "$DOTS_DIR/install/bootstrap.sh"
    "$DOTS_DIR/install/setup.sh"
    "$DOTS_DIR/install/doctor.sh"
    "$DOTS_DIR/install/doctor-v2.sh"
    "$DOTS_DIR/install/modules/20-dotfiles.sh"
    "$DOTS_DIR/install/modules/50-services.sh"
    "$DOTS_DIR/themes/set-theme"
    "$DOTS_DIR/themes/auto-theme.sh"
    "$DOTS_DIR/themes/set-next-bg.sh"
    "$DOTS_DIR/themes/run-wallpaper.sh"
    "$DOTS_DIR/themes/brightness-control.sh"
    "$DOTS_DIR/themes/theme-picker.sh"
    "$DOTS_DIR/themes/wallpaper-picker.sh"
    "$DOTS_DIR/themes/clipboard-picker.sh"
    "$DOTS_DIR/waybar/.config/waybar/scripts/clock.sh"
    "$DOTS_DIR/waybar/.config/waybar/scripts/toggle-clock-mode.sh"
    "$DOTS_DIR/waybar/.config/waybar/scripts/swaync-status.sh"
    "$DOTS_DIR/waybar/.config/waybar/scripts/open-power-menu.sh"
    "$DOTS_DIR/waybar/.config/waybar/scripts/open-timezone-picker.sh"
    "$DOTS_DIR/niri/.config/niri/idle.sh"
    "$DOTS_DIR/niri/.config/niri/lock.sh"
)

REPO_PYTHON_SCRIPTS=(
    "$DOTS_DIR/waybar/.config/waybar/scripts/evolution-calendar.py"
)

MANAGED_SYMLINKS=(
    "$HOME/.zshrc"
    "$HOME/.config/niri"
    "$HOME/.config/waybar"
    "$HOME/.config/swaync"
    "$HOME/.config/swayosd"
)

run_section() {
    local section_name="$1"

    if [[ -n "$SECTION_FILTER" ]] && [[ "$SECTION_FILTER" != "$section_name" ]]; then
        return 0
    fi

    "$section_name"
}

repo() {
    doctor_v2_section "repo"

    local package
    for package in "${STOW_PACKAGES[@]}"; do
        if [[ -d "$DOTS_DIR/$package" ]]; then
            doctor_v2_pass "Stow package exists: $package"
        else
            doctor_v2_fail "Stow package missing: $package"
        fi
    done

    doctor_v2_check_dir "$DOTS_DIR/claude/.claude" fail "claude/.claude"
    doctor_v2_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-auto-theme.service" fail
    doctor_v2_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-auto-theme.timer" fail
    doctor_v2_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-wallpaper.service" fail
    doctor_v2_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/omarchy-swayosd.service" fail
    doctor_v2_check_file "$DOTS_DIR/systemd-user/.config/systemd/user/rclone-gdrive.service" fail
}

commands() {
    doctor_v2_section "commands"

    local cmd
    for cmd in "${CORE_COMMANDS[@]}"; do
        doctor_v2_check_cmd "$cmd" fail
    done

    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        doctor_v2_check_cmd "$cmd" warn
    done
}

scripts() {
    doctor_v2_section "scripts"

    local path
    for path in "${REPO_BASH_SCRIPTS[@]}"; do
        doctor_v2_check_file "$path" fail
        [[ -f "$path" ]] && doctor_v2_check_bash_syntax "$path" fail "${path#$DOTS_DIR/}"
    done

    for path in "${REPO_PYTHON_SCRIPTS[@]}"; do
        doctor_v2_check_file "$path" fail
        [[ -f "$path" ]] && doctor_v2_check_python_compile "$path" fail "${path#$DOTS_DIR/}"
    done

    if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("EDataServer", "1.2")
gi.require_version("ECal", "2.0")
from gi.repository import ECal, EDataServer
PY
    then
        doctor_v2_pass "Python GI Evolution bindings available"
    else
        doctor_v2_issue warn "Python GI Evolution bindings unavailable"
    fi
}

symlinks() {
    doctor_v2_section "symlinks"

    local path
    for path in "${MANAGED_SYMLINKS[@]}"; do
        if [[ "$path" == "$HOME/.config/niri" ]]; then
            doctor_v2_check_managed_dir "$path" warn "$path"
        else
            doctor_v2_check_symlink "$path" warn "$path"
        fi
    done

    doctor_v2_check_symlink "$HOME/.local/share/omarchy/themes" warn "~/.local/share/omarchy/themes"
    doctor_v2_check_symlink "$HOME/.config/omarchy/current/background" warn "~/.config/omarchy/current/background"
    doctor_v2_check_file "$HOME/.config/systemd/user/rclone-gdrive.service" warn "~/.config/systemd/user/rclone-gdrive.service"
    doctor_v2_check_dir "$HOME/mnt/gdrive" warn "~/mnt/gdrive"

    if [[ -d "$HOME/.claude" ]] && [[ ! -L "$HOME/.claude" ]]; then
        doctor_v2_pass "Claude config is a real directory: ~/.claude"
    elif [[ -L "$HOME/.claude" ]]; then
        doctor_v2_issue warn "Claude config is still symlinked: ~/.claude"
    else
        doctor_v2_issue warn "Claude config missing: ~/.claude"
    fi
}

google_drive() {
    doctor_v2_section "google-drive"

    if has_cmd rclone; then
        if rclone listremotes 2>/dev/null | grep -qx 'gdrive:'; then
            doctor_v2_pass "rclone remote configured: gdrive"
        else
            doctor_v2_issue warn "rclone remote is not configured: gdrive"
        fi
    else
        doctor_v2_issue warn "Skipping rclone remote check because rclone is unavailable"
    fi

    if has_cmd mountpoint; then
        if mountpoint -q "$HOME/mnt/gdrive" >/dev/null 2>&1; then
            doctor_v2_pass "Mount is active: ~/mnt/gdrive"
        else
            doctor_v2_issue warn "Mount is not active: ~/mnt/gdrive"
        fi
    fi
}

theme() {
    doctor_v2_section "theme"

    local current_theme=""
    local light_theme=""
    local dark_theme=""
    local light_start=""
    local dark_start=""
    local schedule_file="$HOME/.config/omarchy/theme-schedule.conf"

    doctor_v2_check_file "$HOME/.config/omarchy/current/theme.name" fail "~/.config/omarchy/current/theme.name"
    doctor_v2_check_dir "$HOME/.config/omarchy/current/theme" fail "~/.config/omarchy/current/theme"
    doctor_v2_check_symlink "$HOME/.config/omarchy/current/background" warn "~/.config/omarchy/current/background"
    doctor_v2_check_file "$HOME/.config/omarchy/current/theme/alacritty.toml" warn
    doctor_v2_check_file "$HOME/.config/omarchy/current/theme/waybar.css" warn
    doctor_v2_check_file "$schedule_file" warn "$schedule_file"

    if [[ -f "$HOME/.config/omarchy/current/theme.name" ]]; then
        current_theme=$(<"$HOME/.config/omarchy/current/theme.name")
        doctor_v2_pass "Current theme: $current_theme"
    fi

    if [[ -f "$schedule_file" ]]; then
        light_theme="$(sed -n 's/^light_theme=//p' "$schedule_file" | tail -n1)"
        dark_theme="$(sed -n 's/^dark_theme=//p' "$schedule_file" | tail -n1)"
        light_start="$(sed -n 's/^light_start=//p' "$schedule_file" | tail -n1)"
        dark_start="$(sed -n 's/^dark_start=//p' "$schedule_file" | tail -n1)"

        [[ -n "$light_theme" ]] && doctor_v2_pass "Scheduled light theme: $light_theme" || doctor_v2_issue warn "light_theme missing from theme schedule"
        [[ -n "$dark_theme" ]] && doctor_v2_pass "Scheduled dark theme: $dark_theme" || doctor_v2_issue warn "dark_theme missing from theme schedule"
        [[ "$light_start" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] && doctor_v2_pass "light_start valid: $light_start" || doctor_v2_issue warn "Invalid light_start in theme schedule"
        [[ "$dark_start" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]] && doctor_v2_pass "dark_start valid: $dark_start" || doctor_v2_issue warn "Invalid dark_start in theme schedule"

        if [[ -n "$light_theme" ]] && [[ ! -d "$DOTS_DIR/themes/$light_theme" ]] && [[ ! -d "$HOME/.config/omarchy/themes/$light_theme" ]]; then
            doctor_v2_issue warn "Scheduled light theme cannot be resolved: $light_theme"
        fi

        if [[ -n "$dark_theme" ]] && [[ ! -d "$DOTS_DIR/themes/$dark_theme" ]] && [[ ! -d "$HOME/.config/omarchy/themes/$dark_theme" ]]; then
            doctor_v2_issue warn "Scheduled dark theme cannot be resolved: $dark_theme"
        fi
    fi
}

services() {
    doctor_v2_section "services"

    if ! doctor_v2_check_systemctl_user list-unit-files; then
        doctor_v2_issue warn "systemctl --user is unavailable in the current environment"
        return 0
    fi

    local unit
    for unit in \
        omarchy-auto-theme.timer \
        omarchy-wallpaper.service \
        omarchy-swayosd.service \
        rclone-gdrive.service; do
        if doctor_v2_check_systemctl_user is-enabled "$unit"; then
            doctor_v2_pass "User unit enabled: $unit"
        else
            doctor_v2_issue warn "User unit not enabled: $unit"
        fi

        if doctor_v2_check_systemctl_user is-active "$unit"; then
            doctor_v2_pass "User unit active: $unit"
        else
            doctor_v2_issue warn "User unit not active: $unit"
        fi
    done

    if has_cmd systemctl; then
        local next_trigger
        next_trigger="$(systemctl --user list-timers omarchy-auto-theme.timer --no-pager --no-legend 2>/dev/null | awk '{print $1" "$2" "$3}')"
        [[ -n "$next_trigger" ]] && doctor_v2_pass "Auto theme next trigger: $next_trigger" || doctor_v2_issue warn "Could not resolve next auto-theme trigger"
    fi
}

session() {
    doctor_v2_section "session"

    [[ -n "${WAYLAND_DISPLAY:-}" ]] && doctor_v2_pass "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" || doctor_v2_issue warn "WAYLAND_DISPLAY is not set"
    [[ -n "${DISPLAY:-}" ]] && doctor_v2_pass "DISPLAY=$DISPLAY" || doctor_v2_issue warn "DISPLAY is not set; X11 apps like Zoom will not start"
    [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && doctor_v2_pass "DBUS session bus is set" || doctor_v2_issue warn "DBUS_SESSION_BUS_ADDRESS is not set"
    [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] && doctor_v2_pass "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP" || doctor_v2_issue warn "XDG_CURRENT_DESKTOP is not set"

    if has_cmd gdbus; then
        if gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop >/dev/null 2>&1; then
            doctor_v2_pass "XDG desktop portal available"
        else
            doctor_v2_issue warn "XDG desktop portal is unavailable"
        fi

        if gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Settings.ReadOne org.freedesktop.appearance color-scheme >/dev/null 2>&1; then
            doctor_v2_pass "Portal appearance color-scheme available"
        else
            doctor_v2_issue warn "Portal appearance color-scheme unavailable"
        fi
    else
        doctor_v2_issue warn "gdbus is not available"
    fi

    if has_cmd gsettings; then
        if gsettings get org.gnome.desktop.interface color-scheme >/dev/null 2>&1; then
            doctor_v2_pass "gsettings session access works"
        else
            doctor_v2_issue warn "gsettings is installed but session access failed"
        fi
    fi
}

desktop() {
    doctor_v2_section "desktop"

    if pgrep -x swaybg >/dev/null 2>&1; then
        doctor_v2_pass "swaybg is running"
    else
        doctor_v2_issue warn "swaybg is not running"
    fi

    if pgrep -x swaync >/dev/null 2>&1; then
        doctor_v2_pass "swaync is running"
    else
        doctor_v2_issue warn "swaync is not running"
    fi

    if pgrep -x swayosd-server >/dev/null 2>&1; then
        doctor_v2_pass "swayosd-server is running"
    else
        doctor_v2_issue warn "swayosd-server is not running"
    fi

    if has_cmd swaync-client; then
        if timeout 2 swaync-client -R >/dev/null 2>&1; then
            doctor_v2_pass "swaync-client can reach swaync"
        else
            doctor_v2_issue warn "swaync-client could not reach swaync"
        fi
    fi

    if has_cmd swayosd-client; then
        if timeout 2 swayosd-client --custom-message "doctor-v2" >/dev/null 2>&1; then
            doctor_v2_pass "swayosd-client can reach swayosd-server"
        else
            doctor_v2_issue warn "swayosd-client could not reach swayosd-server"
        fi
    fi

    doctor_v2_check_file "$HOME/.config/niri/lock.sh" warn "~/.config/niri/lock.sh"
    doctor_v2_check_file "$HOME/.config/niri/idle.sh" warn "~/.config/niri/idle.sh"
}

optional() {
    doctor_v2_section "optional"

    doctor_v2_check_file "$HOME/.pi/agent/settings.json" warn "~/.pi/agent/settings.json"

    if has_cmd handy; then
        doctor_v2_pass "handy is available"
    else
        doctor_v2_issue warn "handy is unavailable (optional transcription integration)"
    fi

    if has_cmd orca; then
        doctor_v2_pass "orca is available"
    else
        doctor_v2_issue warn "orca is unavailable (optional accessibility integration)"
    fi
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --strict           Treat warnings as failures
  --section <name>   Run only one section
  -h, --help         Show this help

Sections:
  repo commands scripts symlinks theme google-drive services session desktop optional
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --strict)
                DOCTOR_V2_STRICT=1
                shift
                ;;
            --section)
                SECTION_FILTER="${2:-}"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_err "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

main() {
    cd "$DOTS_DIR"
    parse_args "$@"
    show_banner

    run_section repo
    run_section commands
    run_section scripts
    run_section symlinks
    run_section theme
    run_section google_drive
    run_section services
    run_section session
    run_section desktop
    run_section optional

    doctor_v2_summary

    if (( DOCTOR_V2_FAIL_COUNT > 0 )); then
        exit 1
    fi
}

main "$@"
