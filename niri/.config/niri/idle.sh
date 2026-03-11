#!/bin/sh

set -eu

lock_cmd='sh "$HOME/.config/niri/lock.sh"'

if pgrep -x swayidle >/dev/null; then
    exit 0
fi

exec swayidle -w \
    timeout 300 "$lock_cmd" \
    timeout 600 'niri msg action power-off-monitors' \
        resume 'niri msg action power-on-monitors' \
    timeout 900 'systemctl suspend' \
    before-sleep "$lock_cmd" \
    after-resume 'niri msg action power-on-monitors' \
    lock "$lock_cmd"
