#!/bin/bash

set -euo pipefail

state_file="/tmp/waybar-clock-alt"

if [[ -f "$state_file" ]]; then
    rm -f "$state_file"
else
    : > "$state_file"
fi
