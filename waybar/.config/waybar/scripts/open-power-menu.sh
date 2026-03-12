#!/bin/bash

set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
    notify-send "Power menu" "fuzzel is not installed."
    exit 1
fi

choice="$(
    printf '%s\n' \
        "Lock" \
        "Suspend" \
        "Reboot" \
        "Power off" \
        | fuzzel --dmenu --prompt "power> "
)"

[[ -n "$choice" ]] || exit 0

case "$choice" in
    "Lock")
        if [[ -x "$HOME/.config/niri/lock.sh" ]]; then
            exec sh "$HOME/.config/niri/lock.sh"
        fi

        notify-send "Power menu" "Lock script was not found."
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Power off")
        systemctl poweroff
        ;;
esac
