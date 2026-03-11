#!/bin/bash

current_theme_path="$HOME/.config/omarchy/current/theme"
chromium_theme="$current_theme_path/chromium.theme"
chromium_policy_dir="${CHROMIUM_POLICY_DIR:-/etc/chromium/policies/managed}"
brave_policy_dir="${BRAVE_POLICY_DIR:-/etc/brave/policies/managed}"

apply_browser_theme() {
    local browser_cmd="$1"
    local policy_dir="$2"
    local policy_parent

    command -v "$browser_cmd" >/dev/null 2>&1 || return 0

    policy_parent=$(dirname "$policy_dir")

    if [[ ! -d "$policy_dir" ]] || [[ ! -w "$policy_dir" ]]; then
        echo "[set-theme] $browser_cmd policy directory is missing or not writable: $policy_dir"
        if [[ -d "$policy_parent" ]]; then
            echo "[set-theme] run once: sudo mkdir -p '$policy_dir' && sudo chmod a+rw '$policy_dir'"
        fi
        return 0
    fi

    printf '{"BrowserThemeColor": "%s"}\n' "$theme_hex_color" > "$policy_dir/color.json"
    "$browser_cmd" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 || true
}

if [[ -f "$chromium_theme" ]]; then
    theme_rgb_color=$(<"$chromium_theme")
    theme_hex_color=$(printf '#%02x%02x%02x' ${theme_rgb_color//,/ })
else
    theme_rgb_color="28,32,39"
    theme_hex_color="#1c2027"
fi

apply_browser_theme chromium "$chromium_policy_dir"
apply_browser_theme brave "$brave_policy_dir"
