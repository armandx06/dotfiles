#!/usr/bin/env bash
# Ajusta el monitor del portátil según la presencia del monitor de docking.
# Si DP-1 está activo, desactiva eDP-1; si DP-1 desaparece, reactiva eDP-1.
#
# Hyprland 0.56 usa el parser Lua: `hyprctl keyword` ya no funciona
# ("keyword can't work with non-legacy parsers"). Por eso se usa `hyprctl eval`
# con la API `hl.monitor{...}`.
set -u

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hypr-auto-monitors.lock"
flock -n 9 || exit 0

# Esperar a que Hyprland termine de configurar el hotplug.
sleep 0.4

monitors=$(hyprctl monitors -j 2>/dev/null) || exit 0

docked=$(jq -r 'any(.[]; .name == "DP-1" and (.disabled != true))' <<<"$monitors" 2>/dev/null)
edp_enabled=$(jq -r 'any(.[]; .name == "eDP-1" and (.disabled != true))' <<<"$monitors" 2>/dev/null)

apply_dp1() {
    # El monitor externo manda: colocarlo en el origen.
    hyprctl eval \
        'hl.monitor({output="DP-1", mode="2560x1440@143.97301", position="0x0", scale="auto"})' \
        >/dev/null 2>&1 || true
}

disable_edp() {
    hyprctl eval 'hl.monitor({output="eDP-1", disabled=true})' >/dev/null 2>&1 || true
}

enable_edp() {
    hyprctl eval 'hl.monitor({output="eDP-1", mode="1920x1080@60", position="0x0", scale=1})' \
        >/dev/null 2>&1 || true
}

if [ "$docked" = "true" ]; then
    apply_dp1
    sleep 0.2

    if hyprctl monitors -j 2>/dev/null |
        jq -e 'any(.[]; .name == "DP-1" and (.disabled != true))' >/dev/null 2>&1; then
        if [ "$edp_enabled" = "true" ]; then
            disable_edp
        fi
    elif [ "$edp_enabled" != "true" ]; then
        # El dock no llegó a activarse: no dejar la sesión sin pantallas.
        enable_edp
    fi
else
    # Sin docking: recuperar el panel interno si estaba apagado.
    if [ "$edp_enabled" != "true" ]; then
        enable_edp
    fi
fi
