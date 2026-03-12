#!/bin/bash
# Shared helpers for doctor checks

set -euo pipefail

DOCTOR_PASS_COUNT=0
DOCTOR_WARN_COUNT=0
DOCTOR_FAIL_COUNT=0
DOCTOR_CURRENT_SECTION=""

doctor_section() {
    DOCTOR_CURRENT_SECTION="$1"
    echo ""
    echo -e "${CYAN}${BOLD}[doctor:${DOCTOR_CURRENT_SECTION}]${NC}"
}

doctor_pass() {
    local message="$1"
    DOCTOR_PASS_COUNT=$((DOCTOR_PASS_COUNT + 1))
    log_ok "$message"
}

doctor_warn() {
    local message="$1"
    DOCTOR_WARN_COUNT=$((DOCTOR_WARN_COUNT + 1))
    log_warn "$message"
}

doctor_fail() {
    local message="$1"
    DOCTOR_FAIL_COUNT=$((DOCTOR_FAIL_COUNT + 1))
    log_err "$message"
}

doctor_check_cmd() {
    local cmd="$1"
    local severity="${2:-fail}"
    local message="${3:-Command available: $cmd}"

    if has_cmd "$cmd"; then
        doctor_pass "$message"
        return 0
    fi

    if [[ "$severity" == "warn" ]]; then
        doctor_warn "Missing command: $cmd"
        return 0
    fi

    doctor_fail "Missing command: $cmd"
    return 1
}

doctor_check_file() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -f "$path" ]]; then
        doctor_pass "File exists: $label"
        return 0
    fi

    if [[ "$severity" == "warn" ]]; then
        doctor_warn "Missing file: $label"
        return 0
    fi

    doctor_fail "Missing file: $label"
    return 1
}

doctor_check_dir() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -d "$path" ]]; then
        doctor_pass "Directory exists: $label"
        return 0
    fi

    if [[ "$severity" == "warn" ]]; then
        doctor_warn "Missing directory: $label"
        return 0
    fi

    doctor_fail "Missing directory: $label"
    return 1
}

doctor_check_link_target() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -L "$path" ]] && [[ -e "$path" ]]; then
        doctor_pass "Symlink target exists: $label"
        return 0
    fi

    if [[ -L "$path" ]]; then
        if [[ "$severity" == "warn" ]]; then
            doctor_warn "Broken symlink: $label"
            return 0
        fi

        doctor_fail "Broken symlink: $label"
        return 1
    fi

    if [[ "$severity" == "warn" ]]; then
        doctor_warn "Symlink not found: $label"
        return 0
    fi

    doctor_fail "Symlink not found: $label"
    return 1
}

doctor_summary() {
    echo ""
    echo -e "${BOLD}Doctor summary${NC}"
    echo "  PASS: $DOCTOR_PASS_COUNT"
    echo "  WARN: $DOCTOR_WARN_COUNT"
    echo "  FAIL: $DOCTOR_FAIL_COUNT"
}
