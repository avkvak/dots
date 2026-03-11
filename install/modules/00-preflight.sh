#!/bin/bash
# Module 00: Preflight checks
# Verifies system requirements and updates

log_header "00" "Preflight checks..."

check_arch
check_not_root
check_internet

log_info "Updating system..."
sudo pacman -Syu --noconfirm
log_ok "System updated"
