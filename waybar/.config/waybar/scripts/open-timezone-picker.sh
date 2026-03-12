#!/bin/bash

set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
    notify-send "Timezone picker" "fuzzel is not installed."
    exit 1
fi

if ! command -v timedatectl >/dev/null 2>&1; then
    notify-send "Timezone picker" "timedatectl is not available."
    exit 1
fi

selection="$(
    timedatectl list-timezones | fuzzel --dmenu --prompt "tz> "
)"

[[ -n "$selection" ]] || exit 0

current_time="$(TZ="$selection" date '+%a %d %b %H:%M')"

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s\t%s\n' "$selection" "$current_time" | wl-copy
fi

notify-send "Timezone" "$selection: $current_time"
