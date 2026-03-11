#!/bin/bash

script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
user_theme_dir="$HOME/.config/omarchy/themes"

THEMES=$({
    find "$script_dir" -maxdepth 1 -mindepth 1 -type d ! -name 'themed' -not -path '*/.*' -printf '%f\n'
    if [[ -d "$user_theme_dir" ]]; then
        find "$user_theme_dir" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) -not -path '*/.*' -printf '%f\n'
    fi
} | sort -u)

SELECTED=$(echo "$THEMES" | fuzzel -d -p "󰔉 Theme > " --width 30)

if [[ -n "$SELECTED" ]]; then
    "$script_dir/set-theme" "$SELECTED"
    notify-send "Theme Changed" "Active theme: $SELECTED"
fi
