set theme:

`themes/set-theme <theme-name>`

generated theme files are materialized into `~/.config/omarchy/current/theme`.

template files live in `themes/themed/*.tpl` and are rendered from `colors.toml` when a theme does not provide an explicit override file.

Zed now follows the active system theme via a generated local theme file at `~/.config/zed/themes/current-system.json`; `themes/set-theme` regenerates it from the active `colors.toml` or `alacritty.toml` palette and sends Zed `SIGHUP` to reload.
