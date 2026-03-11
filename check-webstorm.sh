#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$ROOT_DIR/webstorm"

PATTERN='token|secret|password|passwd|apikey|api_key|bearer|oauth|auth|credential|cookie|session|jdbc:|license|private|url=|user(name)?=|email|/home/'

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "webstorm directory not found: $TARGET_DIR" >&2
    exit 1
fi

if rg -n -i "$PATTERN" "$TARGET_DIR"; then
    echo ""
    echo "Potentially sensitive WebStorm data found." >&2
    exit 1
fi

echo "No suspicious matches found in webstorm/"
