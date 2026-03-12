#!/bin/bash

set -euo pipefail

emit() {
    local count="$1"
    local dnd="$2"
    local visible="$3"
    local inhibited="$4"
    local text class tooltip

    if [[ "$dnd" == "true" ]]; then
        text="󰂛"
        class="dnd"
        tooltip="Do not disturb enabled"
    elif [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
        text="󰂚 $count"
        class="unread"
        tooltip="$count notifications"
    else
        text="󰂚"
        class="idle"
        tooltip="No unread notifications"
    fi

    if [[ "$visible" == "true" ]]; then
        class="$class open"
    fi

    if [[ "$inhibited" == "true" ]]; then
        tooltip="$tooltip"$'\n'"Notifications inhibited"
    fi

    jq -cn \
        --arg text "$text" \
        --arg class "$class" \
        --arg tooltip "$tooltip" \
        '{text: $text, class: $class, tooltip: $tooltip}'
}

if swaync-client --help 2>&1 | grep -q -- '--subscribe-waybar'; then
    swaync-client --subscribe-waybar | while IFS= read -r line; do
        count=$(jq -r '.count // 0' <<<"$line" 2>/dev/null || echo 0)
        dnd=$(jq -r '.dnd // false' <<<"$line" 2>/dev/null || echo false)
        visible=$(jq -r '.visible // false' <<<"$line" 2>/dev/null || echo false)
        inhibited=$(jq -r '.inhibited // false' <<<"$line" 2>/dev/null || echo false)
        emit "$count" "$dnd" "$visible" "$inhibited"
    done
    exit 0
fi

count=$(swaync-client --count 2>/dev/null || echo 0)
dnd=$(swaync-client --get-dnd 2>/dev/null || echo false)
emit "$count" "$dnd" false false
