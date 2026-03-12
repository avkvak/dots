#!/bin/bash

set -euo pipefail

pick_player() {
    local player

    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        if [[ "$(playerctl -p "$player" status 2>/dev/null || true)" == "Playing" ]]; then
            printf '%s\n' "$player"
            return 0
        fi
    done < <(playerctl -l 2>/dev/null || true)

    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        if [[ "$(playerctl -p "$player" status 2>/dev/null || true)" == "Paused" ]]; then
            printf '%s\n' "$player"
            return 0
        fi
    done < <(playerctl -l 2>/dev/null || true)

    return 1
}

focus_window_by_id() {
    local window_id="$1"
    niri msg action focus-window --id "$window_id"
}

main() {
    local player=""
    local windows_json=""
    local window_id=""
    local pid=""
    local app_name=""

    player="$(pick_player || true)"
    if [[ -z "$player" ]]; then
        notify-send "Media" "No active player found"
        exit 1
    fi

    windows_json="$(niri msg --json windows)"

    if [[ "$player" =~ \.instance([0-9]+)$ ]]; then
        pid="${BASH_REMATCH[1]}"
        window_id="$(
            jq -r --argjson pid "$pid" '
                map(select(.pid == $pid))
                | sort_by(.focus_timestamp.secs, .focus_timestamp.nanos)
                | last
                | .id // empty
            ' <<<"$windows_json"
        )"
    fi

    if [[ -z "$window_id" ]]; then
        app_name="${player%%.*}"
        case "$app_name" in
            spotify)
                window_id="$(jq -r 'map(select(.app_id | ascii_downcase | contains("spotify"))) | .[0].id // empty' <<<"$windows_json")"
                ;;
            firefox)
                window_id="$(jq -r 'map(select(.app_id | ascii_downcase | contains("firefox"))) | .[0].id // empty' <<<"$windows_json")"
                ;;
            vlc)
                window_id="$(jq -r 'map(select(.app_id | ascii_downcase | contains("vlc"))) | .[0].id // empty' <<<"$windows_json")"
                ;;
            chrome|chromium)
                window_id="$(jq -r 'map(select(.app_id | ascii_downcase | test("chrome|chromium"))) | .[0].id // empty' <<<"$windows_json")"
                ;;
        esac
    fi

    if [[ -z "$window_id" ]]; then
        notify-send "Media" "Could not find a window for $player"
        exit 1
    fi

    focus_window_by_id "$window_id"
}

main "$@"
