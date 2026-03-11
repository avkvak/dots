#!/bin/bash
set -euo pipefail

# Monitor brightness control with swayosd progress bar.
# Uses brightnessctl for internal backlight and falls back to ddcutil for DDC/CI monitors.

STEP=10
BRIGHTNESS_DEVICE=""

usage() {
    echo "Usage: $0 [up|down]" >&2
    exit 1
}

parse_ddc_brightness() {
    sed -n 's/.*current value = \([0-9]\+\), max value = \([0-9]\+\).*/\1 \2/p'
}

show_osd() {
    local current="$1"
    local max="$2"
    local percentage progress

    if [[ "$max" -le 0 ]]; then
        exit 1
    fi

    percentage=$(( current * 100 / max ))
    progress=$(echo "scale=4; $current / $max" | bc)

    swayosd-client \
        --custom-icon=display-brightness-symbolic \
        --custom-progress="$progress" \
        --custom-progress-text="${percentage}%"
}

adjust_backlight() {
    local direction="$1"
    local current max

    brightnessctl -d "$BRIGHTNESS_DEVICE" set "${STEP}%${direction}" >/dev/null
    current=$(brightnessctl -d "$BRIGHTNESS_DEVICE" get)
    max=$(brightnessctl -d "$BRIGHTNESS_DEVICE" max)
    show_osd "$current" "$max"
}

select_backlight_device() {
    local devices preferred

    devices=$(brightnessctl -m -l -c backlight 2>/dev/null | cut -d',' -f1)
    [[ -z "$devices" ]] && return 1

    for preferred in intel_backlight amdgpu_bl0 amdgpu_bl1; do
        if grep -qx "$preferred" <<< "$devices"; then
            BRIGHTNESS_DEVICE="$preferred"
            return 0
        fi
    done

    BRIGHTNESS_DEVICE=$(grep -vx 'nvidia_0' <<< "$devices" | head -n1)
    if [[ -n "$BRIGHTNESS_DEVICE" ]]; then
        return 0
    fi

    BRIGHTNESS_DEVICE=$(head -n1 <<< "$devices")
    [[ -n "$BRIGHTNESS_DEVICE" ]]
}

get_ddc_displays() {
    ddcutil detect --brief 2>/dev/null | sed -n 's/^Display \([0-9]\+\).*/\1/p'
}

adjust_ddc() {
    local op="$1"
    local displays first_display current max parsed

    displays=$(get_ddc_displays)
    if [[ -z "$displays" ]]; then
        return 1
    fi

    while read -r display; do
        [[ -z "$display" ]] && continue
        ddcutil --display "$display" setvcp 10 "$op" "$STEP" >/dev/null
        if [[ -z "${first_display:-}" ]]; then
            first_display="$display"
        fi
    done <<< "$displays"

    parsed=$(ddcutil --display "$first_display" getvcp 10 --brief 2>/dev/null | parse_ddc_brightness)
    if [[ -z "$parsed" ]]; then
        return 1
    fi

    read -r current max <<< "$parsed"
    show_osd "$current" "$max"
}

main() {
    local action="${1:-}"
    local direction ddc_op

    case "$action" in
        up)
            direction="+"
            ddc_op="+"
            ;;
        down)
            direction="-"
            ddc_op="-"
            ;;
        *)
            usage
            ;;
    esac

    if select_backlight_device; then
        adjust_backlight "$direction"
        exit 0
    fi

    if command -v ddcutil >/dev/null 2>&1 && adjust_ddc "$ddc_op"; then
        exit 0
    fi

    notify-send "Brightness control" "No supported backlight or DDC/CI monitor was detected."
    exit 1
}

main "$@"
