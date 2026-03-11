#!/bin/bash
# Monitor brightness control with swayosd progress bar
# Usage: brightness-control.sh [up|down]

if [ "$1" == "up" ]; then
    brightnessctl set "10%+"
elif [ "$1" == "down" ]; then
    brightnessctl set "10%-"
else
    echo "Usage: $0 [up|down]"
    exit 1
fi

# Get current brightness value
brightness=$(brightnessctl get)

percentage=$((brightness/655))

# Display progress bar with swayosd
swayosd-client \
    --custom-icon=display-brightness-symbolic \
    --custom-progress=$(echo "scale=2; $brightness / 65535" | bc) \
    --custom-progress-text="$percentage%"
