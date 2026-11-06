# AGENTS.md

Personal Linux dotfiles for a Hyprland/Wayland desktop. There is no build, test suite, linter, or CI — the files are consumed directly by running applications.

## Layout and install

- Each top-level directory is one app package mirroring `$HOME`: `<app>/.config/<app>/...` (hypr, kitty, swaync, waybar, wiremix, wofi).
- The layout is GNU Stow-compatible: `stow -t ~ <app>`.
- On this machine `~/.config/<app>` is already symlinked to `../dotfiles/<app>/.config/<app>`, so **edits take effect without a deploy step**.
- `waybar/.config/waybar/scripts/wofi-network.sh` is intentionally tracked as executable (`100755`); preserve that mode.

## Hyprland: the active config is Lua

`hypr/.config/hypr/hyprland.lua` is the file Hyprland 0.56 loads (confirmed in `hyprland.log`). The sibling `hyprland.conf` is a stale legacy hyprlang copy and is **not loaded** — editing it has no effect. Keep new Hyprland changes in the `.lua` file.

- The other Hypr apps still use hyprlang: `hypridle.conf`, `hyprlock.conf`, and `hyprpaper.conf` are active. Do not convert them.
- Apply/verify: `hyprctl reload && hyprctl configerrors`; syntax-check with `luac -p hypr/.config/hypr/hyprland.lua` (`hl` is unresolved by design).
- API shapes: `hl.monitor{...}`, `hl.config{...}`, `hl.bind("SUPER + X", hl.dsp....)`. Reference: https://wiki.hypr.land/configuring/core/advanced-configuration/lua-utilities/
- Workspace binds (1–10) are generated in a loop near the bottom of the file; check it before adding per-workspace binds.

The config is intentionally machine-specific: monitors `eDP-1` (1920x1080) and `DP-1` (2560x1440), `latam` keyboard, `/home/armandx06` paths, and the Spanish `Imágenes` wallpaper directory. Do not genericize these unless asked.

## Reloading other components

| App | Command |
| --- | --- |
| Waybar | `pkill -SIGUSR2 waybar` (or restart the bar) |
| SwayNC | `swaync-client -R` (config), `swaync-client -rs` (CSS) |
| Kitty | `kill -SIGUSR1 $(pidof kitty)` |
| Wiremix | restart only |

## Coupled files to keep in sync

- Wiremix is launched as `kitty --class wiremix-float -e wiremix` from Waybar's `pulseaudio` module; the `wiremix-float` window rule in `hyprland.lua` matches that class name.
- Waybar's power menus are GTK builder XML (`power_menu.xml`, `power_profile_menu.xml`); their object IDs must match the `menu-actions` keys in `config.jsonc`.
- `config.jsonc` is JSONC with trailing commas. Standard `jq`/`json.tool` validation will fail; do not "fix" it into strict JSON.
- There is no shared theme file. The accent `#a2bcd1` / dark `#1a2332` palette is duplicated in `hyprland.lua`, `waybar/style.css`, and `wiremix.toml`; SwayNC uses `#7fb3d5`. Update each file where the color is used.
- `wofi-network.sh` is Bash-only (uses `mapfile` and associative arrays) and hardcodes `~/.config/waybar/scripts/wofi-network.sh` as its callback path; validate with `bash -n`, not `sh -n`.

## Conventions

- User-facing strings and comments are Spanish (es-MX); keep new UI text in Spanish.
- No formatting or lint config exists. Match the existing style of each file (2-space JSON/CSS, 4-space Lua, aligned key/value blocks in Kitty/conf files).
