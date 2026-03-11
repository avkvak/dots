#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')

# Get git branch if in a git repository
GIT_BRANCH=""
if [ -d "$CURRENT_DIR/.git" ] || git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git -C "$CURRENT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$GIT_BRANCH" ]; then
        GIT_BRANCH=" on  $GIT_BRANCH"
    fi
fi

echo "${CURRENT_DIR##*/}$GIT_BRANCH | $MODEL_DISPLAY"
