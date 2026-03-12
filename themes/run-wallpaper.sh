#!/bin/bash
set -euo pipefail

background_link="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/background"

if [[ -L "$background_link" ]] && [[ -f "$(readlink -f "$background_link")" ]]; then
    exec swaybg -i "$background_link" -m fill
fi

exec swaybg --color '#000000'
