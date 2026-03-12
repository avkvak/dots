#!/bin/bash
set -euo pipefail

script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
schedule_file="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/theme-schedule.conf"
current_theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/theme.name"

pick_first_existing_theme() {
    local theme_name=""

    for theme_name in "$@"; do
        if [[ -d "$script_dir/$theme_name" ]] || [[ -d "$HOME/.config/omarchy/themes/$theme_name" ]]; then
            printf '%s\n' "$theme_name"
            return 0
        fi
    done

    return 1
}

ensure_schedule_file() {
    local default_light=""
    local default_dark=""
    local current_theme=""
    local current_theme_dir=""

    [[ -f "$schedule_file" ]] && return 0

    mkdir -p "$(dirname "$schedule_file")"

    if [[ -f "$current_theme_file" ]]; then
        current_theme="$(<"$current_theme_file")"
        if validate_theme_exists "$current_theme"; then
            if [[ -d "$script_dir/$current_theme" ]]; then
                current_theme_dir="$script_dir/$current_theme"
            else
                current_theme_dir="$HOME/.config/omarchy/themes/$current_theme"
            fi
        fi
    fi

    if [[ -n "$current_theme_dir" ]] && [[ -f "$current_theme_dir/light.mode" ]]; then
        default_light="$current_theme"
    else
        default_light="$(pick_first_existing_theme catppuccin-latte flexoki-light rose-pine flowers-one-light white)"
    fi

    if [[ -n "$current_theme_dir" ]] && [[ ! -f "$current_theme_dir/light.mode" ]]; then
        default_dark="$current_theme"
    else
        default_dark="$(pick_first_existing_theme catppuccin rose-pine-dark tokyo-night one-dark miasma)"
    fi

    cat > "$schedule_file" <<EOF
# Auto theme schedule for omarchy.
# Format: HH:MM in 24-hour time.

light_theme=${default_light}
dark_theme=${default_dark}
light_start=08:00
dark_start=19:00
EOF
}

load_schedule() {
    local line=""
    local key=""
    local value=""

    ensure_schedule_file

    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -n "$line" ]] || continue
        [[ "$line" == \#* ]] && continue
        [[ "$line" == *"="* ]] || continue

        key="${line%%=*}"
        value="${line#*=}"
        key="${key//[[:space:]]/}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        case "$key" in
            light_theme|dark_theme|light_start|dark_start)
                printf -v "$key" '%s' "$value"
                ;;
        esac
    done < "$schedule_file"
}

validate_theme_exists() {
    local theme_name="$1"

    [[ -d "$script_dir/$theme_name" ]] || [[ -d "$HOME/.config/omarchy/themes/$theme_name" ]]
}

validate_time() {
    local value="$1"
    [[ "$value" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

time_to_minutes() {
    local value="$1"
    local hours="${value%%:*}"
    local minutes="${value##*:}"

    printf '%d\n' "$((10#$hours * 60 + 10#$minutes))"
}

resolve_target_theme() {
    local now_minutes="$1"
    local light_minutes="$2"
    local dark_minutes="$3"

    if (( light_minutes == dark_minutes )); then
        printf '%s\n' "$dark_theme"
        return 0
    fi

    if (( light_minutes < dark_minutes )); then
        if (( now_minutes >= light_minutes && now_minutes < dark_minutes )); then
            printf '%s\n' "$light_theme"
        else
            printf '%s\n' "$dark_theme"
        fi
        return 0
    fi

    if (( now_minutes >= dark_minutes && now_minutes < light_minutes )); then
        printf '%s\n' "$dark_theme"
    else
        printf '%s\n' "$light_theme"
    fi
}

main() {
    local light_theme=""
    local dark_theme=""
    local light_start=""
    local dark_start=""
    local now=""
    local now_minutes=""
    local light_minutes=""
    local dark_minutes=""
    local target_theme=""
    local current_theme=""

    load_schedule

    : "${light_theme:?light_theme is not set in $schedule_file}"
    : "${dark_theme:?dark_theme is not set in $schedule_file}"
    : "${light_start:?light_start is not set in $schedule_file}"
    : "${dark_start:?dark_start is not set in $schedule_file}"

    if ! validate_theme_exists "$light_theme"; then
        echo "[auto-theme] light_theme does not exist: $light_theme" >&2
        exit 1
    fi

    if ! validate_theme_exists "$dark_theme"; then
        echo "[auto-theme] dark_theme does not exist: $dark_theme" >&2
        exit 1
    fi

    if ! validate_time "$light_start"; then
        echo "[auto-theme] invalid light_start: $light_start" >&2
        exit 1
    fi

    if ! validate_time "$dark_start"; then
        echo "[auto-theme] invalid dark_start: $dark_start" >&2
        exit 1
    fi

    now="$(date +%H:%M)"
    now_minutes="$(time_to_minutes "$now")"
    light_minutes="$(time_to_minutes "$light_start")"
    dark_minutes="$(time_to_minutes "$dark_start")"
    target_theme="$(resolve_target_theme "$now_minutes" "$light_minutes" "$dark_minutes")"

    if [[ -f "$current_theme_file" ]]; then
        current_theme="$(<"$current_theme_file")"
        if [[ "$current_theme" == "$target_theme" ]]; then
            exit 0
        fi
    fi

    exec env OMARCHY_THEME_SOURCE=auto "$script_dir/set-theme" "$target_theme"
}

main "$@"
