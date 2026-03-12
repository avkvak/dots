# Legion 16IAX10H Audio Fix

This wraps the manual process from `nadimkobeissi/16iax10h-linux-sound-saga` into a two-phase Arch Linux script:

- phase 1: build and install the patched `6.19` kernel
- phase 2: after reboot, apply UCM2 and ALSA state

Script path:

```bash
~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh
```

## Interactive bootstrap

Run without arguments:

```bash
bash ~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh
```

It will ask:

```text
Patch and build the custom audio kernel now? [y/N]:
```

- `y`: runs the full pre-reboot kernel patch/build/install phase
- `n`: skips kernel patching; if already booted into `6.19.0`, it runs the postboot audio setup

## Explicit commands

Pre-reboot phase:

```bash
bash ~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh --prepare
```

After rebooting into the patched kernel:

```bash
bash ~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh --postboot
```

## What the script does

`--prepare`:

- installs required packages
- clones or updates the upstream audio-fix repo
- installs `aw88399_acf.bin`
- downloads and extracts `linux-6.19`
- applies `16iax10h-audio-linux-6.19.patch`
- adds the missing `MODULE_LICENSE("GPL")`
- seeds `.config` from `/proc/config.gz`
- enables the required audio kernel config options
- builds and installs the custom kernel
- installs `nvidia-open-dkms` for the custom kernel
- writes `mkinitcpio` preset
- regenerates initramfs and GRUB config
- adds `snd_intel_dspcfg.dsp_driver=3` to GRUB if missing

`--postboot`:

- installs patched UCM2 files
- detects the ALSA card id via `alsaucm listcards`
- runs `alsaucm reset` and `reload`
- restarts `pipewire`, `pipewire-pulse`, and `wireplumber`
- sets:
  - `Master 100%`
  - `Headphone 100%`
  - `Speaker 100%`
  - `Capture 80%`
  - `Mic Boost 0`
  - `Internal Mic Boost 0`
- saves ALSA state with `sudo alsactl store`

## Verification

Check the patched kernel:

```bash
uname -a
```

Check devices:

```bash
wpctl status
```

Test microphone:

```bash
arecord -D default -f cd -d 5 ~/mic-test.wav
aplay ~/mic-test.wav
```

## Notes

- The script expects Arch Linux, GRUB, and the same general machine layout we used during manual setup.
- Default mic capture is `80%`. Override it for one run like this:

```bash
CAPTURE_LEVEL=70% bash ~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh --postboot
```

- Override DSP driver similarly if needed:

```bash
DSP_DRIVER=1 bash ~/.local/src/dots/install/legion-audio-fix/legion-audio-fix.sh --prepare
```
