#!/bin/bash
# Shared helpers for doctor-v2 checks

set -euo pipefail

DOCTOR_V2_PASS_COUNT=0
DOCTOR_V2_WARN_COUNT=0
DOCTOR_V2_FAIL_COUNT=0
DOCTOR_V2_CURRENT_SECTION=""
DOCTOR_V2_STRICT=0

doctor_v2_section() {
    DOCTOR_V2_CURRENT_SECTION="$1"
    echo ""
    echo -e "${CYAN}${BOLD}[doctor-v2:${DOCTOR_V2_CURRENT_SECTION}]${NC}"
}

doctor_v2_pass() {
    local message="$1"
    DOCTOR_V2_PASS_COUNT=$((DOCTOR_V2_PASS_COUNT + 1))
    log_ok "$message"
}

doctor_v2_warn() {
    local message="$1"
    DOCTOR_V2_WARN_COUNT=$((DOCTOR_V2_WARN_COUNT + 1))
    log_warn "$message"
}

doctor_v2_fail() {
    local message="$1"
    DOCTOR_V2_FAIL_COUNT=$((DOCTOR_V2_FAIL_COUNT + 1))
    log_err "$message"
}

doctor_v2_issue() {
    local severity="$1"
    local message="$2"

    case "$severity" in
        pass)
            doctor_v2_pass "$message"
            ;;
        warn)
            if (( DOCTOR_V2_STRICT == 1 )); then
                doctor_v2_fail "$message"
            else
                doctor_v2_warn "$message"
            fi
            ;;
        fail)
            doctor_v2_fail "$message"
            ;;
    esac
}

doctor_v2_check_cmd() {
    local cmd="$1"
    local severity="${2:-fail}"
    local label="${3:-$cmd}"

    if has_cmd "$cmd"; then
        doctor_v2_pass "Command available: $label"
    else
        doctor_v2_issue "$severity" "Missing command: $label"
    fi
}

doctor_v2_check_file() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -f "$path" ]]; then
        doctor_v2_pass "File exists: $label"
    else
        doctor_v2_issue "$severity" "Missing file: $label"
    fi
}

doctor_v2_check_dir() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -d "$path" ]]; then
        doctor_v2_pass "Directory exists: $label"
    else
        doctor_v2_issue "$severity" "Missing directory: $label"
    fi
}

doctor_v2_check_symlink() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if [[ -L "$path" ]] && [[ -e "$path" ]]; then
        doctor_v2_pass "Symlink target exists: $label"
        return 0
    fi

    if [[ -L "$path" ]]; then
        doctor_v2_issue "$severity" "Broken symlink: $label"
        return 0
    fi

    doctor_v2_issue "$severity" "Symlink not found: $label"
}

doctor_v2_check_managed_dir() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"
    local symlink_count=0

    if [[ -L "$path" ]] && [[ -e "$path" ]]; then
        doctor_v2_pass "Managed path linked: $label"
        return 0
    fi

    if [[ ! -d "$path" ]]; then
        doctor_v2_issue "$severity" "Managed path missing: $label"
        return 0
    fi

    symlink_count=$(find "$path" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$symlink_count" -gt 0 ]]; then
        doctor_v2_pass "Managed directory contains linked files: $label"
        return 0
    fi

    doctor_v2_issue "$severity" "Managed directory has no linked files: $label"
}

doctor_v2_check_bash_syntax() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if bash -n "$path" >/dev/null 2>&1; then
        doctor_v2_pass "Bash syntax OK: $label"
    else
        doctor_v2_issue "$severity" "Bash syntax invalid: $label"
    fi
}

doctor_v2_check_python_compile() {
    local path="$1"
    local severity="${2:-fail}"
    local label="${3:-$path}"

    if python3 -m py_compile "$path" >/dev/null 2>&1; then
        doctor_v2_pass "Python syntax OK: $label"
    else
        doctor_v2_issue "$severity" "Python syntax invalid: $label"
    fi
}

doctor_v2_check_systemctl_user() {
    systemctl --user "$@" >/dev/null 2>&1
}

doctor_v2_summary() {
    echo ""
    echo -e "${BOLD}Doctor v2 summary${NC}"
    echo "  PASS: $DOCTOR_V2_PASS_COUNT"
    echo "  WARN: $DOCTOR_V2_WARN_COUNT"
    echo "  FAIL: $DOCTOR_V2_FAIL_COUNT"
}
