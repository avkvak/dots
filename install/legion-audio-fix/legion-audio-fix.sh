#!/bin/bash
# Two-phase installer for the Lenovo Legion 16IAX10H Linux audio fix.
# Phase 1 prepares and installs a patched kernel.
# Phase 2 runs after rebooting into the patched kernel and applies UCM2/ALSA state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

REPO_URL="https://github.com/nadimkobeissi/16iax10h-linux-sound-saga.git"
REPO_DIR="${HOME}/16iax10h-linux-sound-saga"
KERNEL_VERSION="6.19"
KERNEL_TARBALL="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TARBALL}"
KERNEL_SRC_DIR="${HOME}/linux-${KERNEL_VERSION}"
PATCH_FILE="16iax10h-audio-linux-${KERNEL_VERSION}.patch"
CUSTOM_KERNEL_BASENAME="linux-16iax10h-audio"
CUSTOM_KERNEL_IMAGE="/boot/vmlinuz-${CUSTOM_KERNEL_BASENAME}"
CUSTOM_INITRAMFS="/boot/initramfs-${CUSTOM_KERNEL_BASENAME}.img"
PRESET_FILE="/etc/mkinitcpio.d/${CUSTOM_KERNEL_BASENAME}.preset"
GRUB_FILE="/etc/default/grub"
DEFAULT_CAPTURE_LEVEL="${CAPTURE_LEVEL:-80%}"
DEFAULT_DSP_DRIVER="${DSP_DRIVER:-3}"
CPU_COUNT="$(nproc)"

show_help() {
    cat <<EOF
Usage: $0 [OPTION]

Applies the Lenovo Legion 16IAX10H audio fix on Arch Linux.

Options:
  --prepare   Run the pre-reboot kernel patch/build/install phase
  --postboot  Run the post-reboot UCM2/ALSA phase
  -h, --help  Show this help

Without options, the script asks whether to patch the kernel now.
If skipped and the current kernel is already ${KERNEL_VERSION}.0, it runs the postboot phase.
EOF
}

require_arch() {
    check_arch
    check_not_root
    check_internet
}

check_model() {
    local model=""

    if [[ -r /sys/devices/virtual/dmi/id/product_version ]]; then
        model="$(< /sys/devices/virtual/dmi/id/product_version)"
    fi

    if [[ "$model" == *"16IAX10H"* ]] || [[ "$model" == *"Legion Pro 7 16IAX10H"* ]]; then
        log_ok "Detected supported model: $model"
        return
    fi

    log_warn "Detected model: ${model:-unknown}"
    read -rp "  Continue anyway? [y/N]: " reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        log_err "Aborted"
        exit 1
    fi
}

ensure_packages() {
    local packages=(
        alsa-utils
        base-devel
        bc
        cpio
        dkms
        git
        libelf
        linux-headers
        mkinitcpio
        nvidia-open-dkms
        pahole
        perl
    )

    log_info "Installing required packages..."
    sudo pacman -S --needed "${packages[@]}"
    log_ok "Required packages are installed"
}

sync_fix_repo() {
    if [[ -d "$REPO_DIR/.git" ]]; then
        log_info "Updating fix repository..."
        git -C "$REPO_DIR" pull --ff-only
    else
        log_info "Cloning fix repository..."
        git clone "$REPO_URL" "$REPO_DIR"
    fi
    log_ok "Fix repository is ready"
}

install_firmware() {
    log_info "Installing AW88399 firmware..."
    sudo cp -f "$REPO_DIR/fix/firmware/aw88399_acf.bin" /lib/firmware/aw88399_acf.bin
    log_ok "Firmware installed"
}

ensure_kernel_source() {
    if [[ ! -f "${HOME}/${KERNEL_TARBALL}" ]]; then
        log_info "Downloading Linux ${KERNEL_VERSION} sources..."
        curl -L "$KERNEL_TARBALL_URL" -o "${HOME}/${KERNEL_TARBALL}"
    else
        log_info "Kernel tarball already exists, skipping download"
    fi

    if [[ ! -d "$KERNEL_SRC_DIR" ]]; then
        log_info "Extracting Linux ${KERNEL_VERSION} sources..."
        tar -xf "${HOME}/${KERNEL_TARBALL}" -C "$HOME"
    else
        log_info "Kernel source directory already exists, reusing it"
    fi

    log_ok "Kernel sources are ready"
}

copy_patch() {
    cp -f "$REPO_DIR/fix/patches/${PATCH_FILE}" "$KERNEL_SRC_DIR/"
}

apply_patch_if_needed() {
    local patch_path="${KERNEL_SRC_DIR}/${PATCH_FILE}"

    copy_patch

    if patch -d "$KERNEL_SRC_DIR" -R -p1 --dry-run < "$patch_path" >/dev/null 2>&1; then
        log_info "Kernel patch already applied, skipping"
        return
    fi

    if patch -d "$KERNEL_SRC_DIR" -p1 --dry-run < "$patch_path" >/dev/null 2>&1; then
        log_info "Applying kernel patch..."
        patch -d "$KERNEL_SRC_DIR" -p1 < "$patch_path"
        log_ok "Kernel patch applied"
        return
    fi

    log_err "Kernel patch cannot be applied cleanly"
    exit 1
}

ensure_module_license() {
    local driver_file="${KERNEL_SRC_DIR}/sound/hda/codecs/side-codecs/aw88399_hda.c"

    if grep -q 'MODULE_LICENSE("GPL")' "$driver_file"; then
        log_info "MODULE_LICENSE already present"
        return
    fi

    log_info "Adding missing MODULE_LICENSE() to AW88399 driver"
    printf '\nMODULE_LICENSE("GPL");\n' >> "$driver_file"
    log_ok "MODULE_LICENSE() added"
}

set_kernel_config() {
    local key="$1"
    local value="$2"
    local config_file="${KERNEL_SRC_DIR}/.config"

    if grep -q "^${key}=" "$config_file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$config_file"
        return
    fi

    if grep -q "^# ${key} is not set" "$config_file"; then
        sed -i "s|^# ${key} is not set|${key}=${value}|" "$config_file"
        return
    fi

    printf '%s=%s\n' "$key" "$value" >> "$config_file"
}

configure_kernel() {
    log_info "Seeding kernel config from the running kernel..."
    zcat /proc/config.gz > "${KERNEL_SRC_DIR}/.config"

    set_kernel_config "CONFIG_SND_HDA_SCODEC_AW88399" "m"
    set_kernel_config "CONFIG_SND_HDA_SCODEC_AW88399_I2C" "m"
    set_kernel_config "CONFIG_SND_SOC_AW88399" "m"
    set_kernel_config "CONFIG_SND_SOC_SOF_INTEL_TOPLEVEL" "y"
    set_kernel_config "CONFIG_SND_SOC_SOF_INTEL_COMMON" "m"
    set_kernel_config "CONFIG_SND_SOC_SOF_INTEL_MTL" "m"
    set_kernel_config "CONFIG_SND_SOC_SOF_INTEL_LNL" "m"

    log_info "Resolving config defaults..."
    yes "" | make -C "$KERNEL_SRC_DIR" olddefconfig >/dev/null
    log_ok "Kernel config prepared"
}

build_kernel() {
    log_info "Building kernel with -j${CPU_COUNT}..."
    make -C "$KERNEL_SRC_DIR" -j"${CPU_COUNT}"

    log_info "Building modules with -j${CPU_COUNT}..."
    make -C "$KERNEL_SRC_DIR" -j"${CPU_COUNT}" modules

    log_info "Installing kernel modules..."
    sudo make -C "$KERNEL_SRC_DIR" -j"${CPU_COUNT}" modules_install

    log_info "Installing kernel image..."
    sudo cp -f "${KERNEL_SRC_DIR}/arch/x86/boot/bzImage" "$CUSTOM_KERNEL_IMAGE"
    log_ok "Kernel image installed"
}

install_nvidia_dkms() {
    local dkms_version kernel_release

    kernel_release="$(< "${KERNEL_SRC_DIR}/include/config/kernel.release")"
    dkms_version="$(pacman -Q nvidia-open-dkms | awk '{print $2}' | cut -d- -f1)"

    if dkms status -m nvidia -v "$dkms_version" -k "$kernel_release" | grep -q ': installed'; then
        log_info "NVIDIA DKMS modules already installed for kernel ${kernel_release}"
        return
    fi

    log_info "Installing NVIDIA DKMS ${dkms_version} for kernel ${kernel_release}..."
    sudo dkms install "nvidia/${dkms_version}" -k "$kernel_release"
    log_ok "NVIDIA DKMS modules installed"
}

write_mkinitcpio_preset() {
    log_info "Writing mkinitcpio preset..."
    sudo tee "$PRESET_FILE" >/dev/null <<EOF
# mkinitcpio preset file for the '${CUSTOM_KERNEL_BASENAME}' package

ALL_kver="${CUSTOM_KERNEL_IMAGE}"
PRESETS=('default')
default_image="${CUSTOM_INITRAMFS}"
EOF
    log_ok "mkinitcpio preset written"
}

ensure_grub_cmdline() {
    local option="snd_intel_dspcfg.dsp_driver=${DEFAULT_DSP_DRIVER}"

    if grep -q "$option" "$GRUB_FILE"; then
        log_info "GRUB kernel option already present"
        return
    fi

    log_info "Adding DSP driver option to GRUB..."
    sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\\(.*\\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\\1 ${option}\"/" "$GRUB_FILE"
    log_ok "GRUB kernel option added"
}

generate_initramfs_and_grub() {
    log_info "Generating initramfs..."
    sudo mkinitcpio -p "$CUSTOM_KERNEL_BASENAME"

    ensure_grub_cmdline

    log_info "Regenerating GRUB config..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    log_ok "GRUB config updated"
}

detect_card_id() {
    local output card

    output="$(alsaucm listcards 2>/dev/null || true)"
    card="$(awk '/^[[:space:]]*[0-9]+: hw:[0-9]+$/ {sub(/^[[:space:]]*[0-9]+: hw:/, "", $0); print $0; exit}' <<< "$output")"

    if [[ -z "$card" ]]; then
        log_err "Could not detect ALSA UCM card ID"
        log_info "alsaucm output:"
        printf '%s\n' "$output"
        exit 1
    fi

    printf '%s\n' "$card"
}

apply_ucm2() {
    log_info "Installing patched UCM2 profiles..."
    sudo cp -f "$REPO_DIR/fix/ucm2/HiFi-analog.conf" /usr/share/alsa/ucm2/HDA/HiFi-analog.conf
    sudo cp -f "$REPO_DIR/fix/ucm2/HiFi-mic.conf" /usr/share/alsa/ucm2/HDA/HiFi-mic.conf
    log_ok "UCM2 profiles installed"
}

apply_audio_state() {
    local card_id

    card_id="$(detect_card_id)"
    log_info "Detected audio card hw:${card_id}"

    alsaucm -c "hw:${card_id}" reset
    alsaucm -c "hw:${card_id}" reload
    systemctl --user restart pipewire pipewire-pulse wireplumber

    amixer sset -c "${card_id}" Master 100% >/dev/null
    amixer sset -c "${card_id}" Headphone 100% >/dev/null
    amixer sset -c "${card_id}" Speaker 100% >/dev/null
    amixer sset -c "${card_id}" Capture "${DEFAULT_CAPTURE_LEVEL}" >/dev/null
    amixer sset -c "${card_id}" 'Mic Boost' 0 >/dev/null || true
    amixer sset -c "${card_id}" 'Internal Mic Boost' 0 >/dev/null || true
    sudo alsactl store

    log_ok "Audio state applied and saved"
}

run_prepare_phase() {
    log_header "Audio" "Preparing patched kernel..."
    require_arch
    check_model
    ensure_packages
    sync_fix_repo
    install_firmware
    ensure_kernel_source
    apply_patch_if_needed
    ensure_module_license
    configure_kernel
    build_kernel
    install_nvidia_dkms
    write_mkinitcpio_preset
    generate_initramfs_and_grub

    echo ""
    log_ok "Pre-reboot phase complete"
    echo "  Reboot, select the ${CUSTOM_KERNEL_BASENAME} entry in GRUB, then run:"
    echo "  $0 --postboot"
}

run_postboot_phase() {
    log_header "Audio" "Applying post-boot audio configuration..."
    require_arch
    sync_fix_repo
    ensure_packages
    apply_ucm2
    apply_audio_state

    echo ""
    log_ok "Post-boot phase complete"
    echo "  Verify with: wpctl status"
    echo "  Test mic with: arecord -D default -f cd -d 5 ~/mic-test.wav && aplay ~/mic-test.wav"
}

main() {
    case "${1:-}" in
        --prepare)
            show_banner
            run_prepare_phase
            ;;
        --postboot)
            show_banner
            run_postboot_phase
            ;;
        -h|--help)
            show_help
            ;;
        "")
            show_banner
            read -rp "  Patch and build the custom audio kernel now? [y/N]: " reply
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                run_prepare_phase
                exit 0
            fi

            log_info "Skipping kernel patch/build phase"
            if [[ "$(uname -r)" == "6.19.0" ]]; then
                run_postboot_phase
            else
                log_warn "Not running on the patched 6.19.0 kernel, so postboot steps were skipped"
                echo "  Run $0 --prepare when you want to build the patched kernel."
            fi
            ;;
        *)
            log_err "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
