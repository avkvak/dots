# dots

Arch Linux workstation bootstrap and dotfiles repo centered on Niri + Wayland.

## Bootstrap

For a clean Arch system, run:

```bash
curl -fsSL https://raw.githubusercontent.com/avkvak/dots/main/install/bootstrap.sh | bash
```

The bootstrap script clones the repo to `~/.local/src/dots` by default and then runs the modular setup flow.

If the repo is already cloned locally, run:

```bash
bash install/setup.sh
```
