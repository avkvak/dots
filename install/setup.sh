#!/bin/bash
# Main setup orchestrator
# Runs all modules in sequence or specific modules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/lib/common.sh"

# Available modules in order
MODULES=(
    "00-preflight.sh"
    "10-packages.sh"
    "20-dotfiles.sh"
    "30-git.sh"
    "40-dev-tools.sh"
    "50-services.sh"
    "60-finalize.sh"
)

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Arch Linux setup script for Niri + Wayland"
    echo ""
    echo "Options:"
    echo "  --module <num>   Run specific module (e.g., --module 30)"
    echo "  --from <num>     Start from module (e.g., --from 20)"
    echo "  --list           List available modules"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0               Run all modules"
    echo "  $0 --module 30   Run only git configuration"
    echo "  $0 --from 40     Run from dev-tools onwards"
}

list_modules() {
    echo "Available modules:"
    for module in "${MODULES[@]}"; do
        num="${module%%-*}"
        name="${module#*-}"
        name="${name%.sh}"
        echo "  $num  $name"
    done
}

run_all() {
    show_banner

    for module in "${MODULES[@]}"; do
        run_module "$module"
    done
}

run_single() {
    local target="$1"

    for module in "${MODULES[@]}"; do
        if [[ "$module" == "$target"* ]]; then
            show_banner
            run_module "$module"
            return 0
        fi
    done

    log_err "Module not found: $target"
    exit 1
}

run_from() {
    local start="$1"
    local started=false

    show_banner

    for module in "${MODULES[@]}"; do
        if [[ "$module" == "$start"* ]]; then
            started=true
        fi

        if $started; then
            run_module "$module"
        fi
    done

    if ! $started; then
        log_err "Module not found: $start"
        exit 1
    fi
}

main() {
    cd "$SCRIPT_DIR"

    if [[ $# -eq 0 ]]; then
        run_all
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --module)
                run_single "$2"
                shift 2
                ;;
            --from)
                run_from "$2"
                shift 2
                ;;
            --list)
                list_modules
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_err "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

main "$@"
