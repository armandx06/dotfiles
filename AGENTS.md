# AGENTS.md

Personal Linux dotfiles for a Hyprland/Wayland desktop. There is no build, test suite, linter, or CI — the files are consumed directly by running applications.

## Layout and install

- Each top-level directory is one app package mirroring `$HOME`: `<app>/.config/<app>/...` (hypr, kitty, noctalia, swaync, waybar, wiremix, wofi).
- The layout is GNU Stow-compatible: `stow -t ~ <app>`.
- On this machine `~/.config/<app>` is already symlinked to `../dotfiles/<app>/.config/<app>`, so **edits take effect without a deploy step**.
- `waybar/.config/waybar/scripts/wofi-network.sh`, `waybar/.config/waybar/scripts/wofi-bluetooth.sh`, `hypr/.config/hypr/scripts/auto-monitors.sh`, `hypr/.config/hypr/scripts/cliphist-menu.sh`, and `hypr/.config/hypr/scripts/window-switcher.sh` are intentionally tracked as executable (`100755`); preserve that mode.

## Hyprland: the active config is Lua

`hypr/.config/hypr/hyprland.lua` is the only Hyprland config and the file Hyprland 0.56 loads (confirmed in `hyprland.log`). There is no `hyprland.conf`; do not reintroduce legacy hyprlang config.

- `hypridle.conf`, `hyprlock.conf`, and `hyprpaper.conf` still use hyprlang and remain valid, but they are no longer autostarted: Noctalia handles idle, lock, and wallpaper. Keep them as fallback and do not convert them to Lua.
- Apply/verify: `hyprctl reload && hyprctl configerrors`; syntax-check with `luac -p hypr/.config/hypr/hyprland.lua` (`hl` is unresolved by design).
- API shapes: `hl.monitor{...}`, `hl.config{...}`, `hl.bind("SUPER + X", hl.dsp....)`. Reference: https://wiki.hypr.land/configuring/core/advanced-configuration/lua-utilities/
- Workspace binds (1–10) are generated in a loop near the bottom of the file; check it before adding per-workspace binds.
- `SUPER + SPACE` opens the Noctalia launcher, `SUPER + S` the control center, `SUPER + comma` its settings, `SUPER + V` the clipboard panel, `SUPER + TAB` its window switcher, and `SUPER + L` locks via Noctalia. The old `scripts/window-switcher.sh` (wofi) and `scripts/cliphist-menu.sh` remain as fallback but are no longer bound.
- Hyprland 0.56 uses the Lua parser for the CLI too: `hyprctl keyword` fails (`keyword can't work with non-legacy parsers`) and classic dispatchers like `hyprctl dispatch focuswindow` no longer work. Use `hyprctl eval 'hl.monitor({...})'` for monitors and `hyprctl dispatch 'hl.dsp.focus({window="address:0x..."})'` for focusing a window.
- `hypr/.config/hypr/scripts/auto-monitors.sh` is called on `hyprland.start`, `monitor.added`, `monitor.removed`, and `config.reloaded`. It disables `eDP-1` while the `DP-1` dock is active and re-enables it when the dock disappears. It uses `hyprctl eval 'hl.monitor({...})'`, not `hyprctl keyword`. Keep monitor switching there; don't duplicate it in binds or other scripts except the `SUPER+SHIFT+D` manual re-apply bind.
- In `auto-monitors.sh`, disable `eDP-1` **before** moving `DP-1` to `0x0`. If `DP-1` moves first, both overlap for a moment and Hyprland shows its "monitor layout ... overlaps" notification. Also, `enable_edp` must pass `disabled=false`; without it `hl.monitor` does not re-enable an output that was turned off.
- `window-switcher.sh` excludes the currently focused window so pressing Enter always changes focus.

The config is intentionally machine-specific: monitors `eDP-1` (1920x1080) and `DP-1` (2560x1440), `latam` keyboard, `/home/armandx06` paths, and the Spanish `Imágenes` wallpaper directory. Do not genericize these unless asked.

## Desktop shell: Noctalia

Noctalia v5 (`noctalia` package, native Wayland, no Qt/GTK) is the active shell: bar, launcher, control center, notifications, clipboard, lock/idle, and wallpaper. Do **not** install `cachyos-hypr-noctalia` (it overwrites config) or `noctalia-shell` (v4, Quickshell-based).

- Config: `noctalia/.config/noctalia/config.toml`, symlinked to `~/.config/noctalia/config.toml`. Noctalia also writes `~/.local/state/noctalia/settings.toml`; any key present there **overrides** `config.toml` (the Settings UI and `noctalia msg config-set` write there). Keep portable settings in `config.toml` and avoid duplicating them in `settings.toml`.
- Autostart: `noctalia --daemon` from `hyprland.lua`. Waybar, SwayNC, Hypridle, hyprpaper, and hyprlock are no longer autostarted; their packages stay in the repo as fallback.
- Bar geometry is tied to Hyprland: `thickness = 28`, `margin_ends = 12`, `margin_edge = 12`, `radius = 10`. These mirror `gaps_out = 12` and `rounding = 10`; update both files together. The bar is inset 12 px and its left/right edges line up with window borders.
- Idle replaces `hypridle.conf` timers: lock at 600 s, screen off at 900 s, lock-and-suspend at 1200 s. `systemctl suspend` only; no hibernation.
- Control/reload: `noctalia msg config-reload` after editing `config.toml`; validate with `noctalia config validate <file>`. Useful IPC: `panel-toggle launcher`, `panel-toggle control-center`, `panel-toggle clipboard`, `window-switcher`, `session lock`, `volume-up`, `brightness-up`.
- Theme: the palette is generated from the wallpaper (`source = "wallpaper"`, `wallpaper_scheme = "muted"`). The built-in `kitty` template keeps `kitty/themes/noctalia.conf` and the `include themes/noctalia.conf` line in `kitty.conf` in sync; remove `builtin_ids = ["kitty"]` to stop Noctalia from touching Kitty.
- Never run Waybar/SwayNC and Noctalia together: both register `org.freedesktop.Notifications` and the tray watcher.
- To fall back to Waybar: `pkill -x noctalia`, start `hyprpaper`, `waybar`, `swaync`, and `hypridle`, and restore their lines in the `hyprland.start` autostart block. The binds to the old scripts are listed above.

## Reloading other components

| App | Command |
| --- | --- |
| Noctalia | `noctalia msg config-reload` (after editing `config.toml`) |
| Waybar | `pkill -SIGUSR2 waybar` (or restart the bar) |
| SwayNC | `swaync-client -R` (config), `swaync-client -rs` (CSS) |
| Hypridle | `pkill -x hypridle; hypridle &` (restart required) |
| Kitty | `kill -SIGUSR1 $(pidof kitty)` |
| Wiremix | restart only |

## Coupled files to keep in sync

- Wiremix is launched as `kitty --class wiremix-float -e wiremix` from Waybar's `pulseaudio` module; the `wiremix-float` window rule in `hyprland.lua` matches that class name.
- Waybar's power menus are GTK builder XML (`power_menu.xml`, `power_profile_menu.xml`); their object IDs must match the `menu-actions` keys in `config.jsonc`.
- `config.jsonc` is JSONC with trailing commas. Standard `jq`/`json.tool` validation will fail; do not "fix" it into strict JSON.
- There is no shared theme file. The accent `#a2bcd1` / dark `#1a2332` palette is duplicated in `hyprland.lua`, `waybar/style.css`, and `wiremix.toml`; SwayNC uses `#7fb3d5`. Update each file where the color is used. Noctalia's palette is independent (`[theme]` in its `config.toml`, default `builtin = "Noctalia"`); it does not read the Waybar/SwayNC colors.
- `wofi-network.sh` and `wofi-bluetooth.sh` are Bash-only (they use `mapfile`/associative arrays) and are referenced by absolute `~/.config/waybar/...` paths; validate with `bash -n`, not `sh -n`.
- Fonts now target `CaskaydiaCove Nerd Font` / `CaskaydiaCove NF`, which are installed. Don't reintroduce the missing JetBrains families in CSS/conf files.
- Clipboard history is now Noctalia's clipboard panel (`SUPER+V`); Noctalia binds `ext_data_control_manager_v1` itself, so the old `wl-paste --watch cliphist store` autostart was removed. `cliphist-menu.sh` stays as fallback for Waybar. Do not pipe `cliphist list` straight into `wofi` and back into `cliphist decode`: wofi treats the tab in `id<TAB>preview` as a column separator and returns only the id, and `cliphist decode` rejects an id without its tab; the script extracts the id and passes it as an argument instead.
- SwayNC now has both `config.json` (layout, widgets, Spanish labels) and `style.css` (colors). Its accent `#a2bcd1`, dark `#1a2332`, and critical `#e06c75` match the rest of the theme.
- Waybar deliberately includes `tray` and `idle_inhibitor`; CPU/memory modules remain intentionally omitted.

## Conventions

- User-facing strings and comments are Spanish (es-MX); keep new UI text in Spanish.
- No formatting or lint config exists. Match the existing style of each file (2-space JSON/CSS, 4-space Lua, aligned key/value blocks in Kitty/conf files).
