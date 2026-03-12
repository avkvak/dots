#!/bin/bash

set -euo pipefail

london_time=$(TZ=Europe/London date '+%H:%M')
spb_time=$(TZ=Europe/Moscow date '+%H:%M')
text=$(printf 'LON %s  SPB %s' "$london_time" "$spb_time")

jq -cn \
    --arg text "$text" \
    '{text: $text}'
