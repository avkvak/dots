#!/bin/sh

set -eu

config="$HOME/.config/omarchy/current/theme/swaylock.conf"

if pgrep -x swaylock >/dev/null; then
    exit 0
fi

if [ -f "$config" ]; then
    exec swaylock --daemonize --config "$config"
fi

exec swaylock --daemonize
