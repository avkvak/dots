# Repository Guidelines

## Project Structure & Module Organization
This repository is a dotfiles and workstation bootstrap setup for Arch Linux, centered on Niri + Wayland. Top-level directories such as `alacritty/`, `hypr/`, `niri/`, `nvim/`, `waybar/`, `zed/`, and `zsh/` are GNU Stow packages that map into `$HOME`. Installer logic lives under `install/`: `bootstrap.sh` handles first-time clone/setup, `setup.sh` orchestrates modules, `modules/` contains numbered steps, and `packages/*.txt` defines package sets. Theme assets and helper scripts live in `themes/`.

## Build, Test, and Development Commands
Use the installer entrypoints rather than ad hoc setup.

- `bash install/setup.sh --list` shows available setup modules.
- `bash install/setup.sh --module 20` runs a single module, such as dotfile deployment.
- `bash install/setup.sh --from 40` resumes from a later module.
- `bash install/bootstrap.sh` performs the full bootstrap flow on a fresh Arch machine.
- `bash themes/set-theme flexoki-light` applies a theme and regenerates derived theme files.
- `bash -n install/setup.sh` or `bash -n install/modules/20-dotfiles.sh` performs a shell syntax check before commit.

## Coding Style & Naming Conventions
Shell scripts use `bash`, `set -euo pipefail`, and four-space indentation. Keep module filenames numeric and ordered, for example `30-git.sh`. Prefer lowercase, hyphenated names for scripts and theme directories. Reuse shared helpers from `install/lib/common.sh` instead of duplicating logging or path logic. When editing Stow packages, preserve the target application’s expected config path under `.config/` or dotfile root.

## Testing Guidelines
There is no formal automated test suite yet. Validate shell changes with `bash -n` and, when safe, run the narrowest installer scope that covers the change, such as `bash install/setup.sh --module 30`. For theme changes, run `bash themes/set-theme <theme-name>` and confirm generated files land under `~/.config/omarchy/current/`.

## Commit & Pull Request Guidelines
Current history uses short, imperative, sentence-case commit subjects such as `Restore original bootstrap script` and `Use SSH GitHub remote`. Keep subjects concise and descriptive. Pull requests should state the user-facing effect, note any Arch/Linux prerequisites, list manual verification steps, and include screenshots only for visible theme or UI changes.

## Security & Configuration Tips
Installer modules may call `sudo` and modify system paths like `/etc/opt/chrome/policies/managed`; review those changes before running on a non-disposable machine. Avoid committing machine-specific secrets, hostnames, or tokens inside dotfiles.
