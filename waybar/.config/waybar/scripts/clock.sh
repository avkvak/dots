#!/bin/bash

set -euo pipefail

state_file="/tmp/waybar-clock-alt"

if [[ -f "$state_file" ]]; then
    text=$(printf 'BAT %s LON %s SPB %s' \
        "$(TZ=Asia/Tbilisi date '+%H:%M')" \
        "$(TZ=Europe/London date '+%H:%M')" \
        "$(TZ=Europe/Moscow date '+%H:%M')")
else
    text=$(date '+%A, %d %b %Y | %H:%M')
fi

jq -cn --arg text "$text" '{text: $text}'
