#!/usr/bin/env bash
# Selector de ventanas abiertas para Hyprland, usando wofi.
#
# wofi interpreta el tabulador como separador de columnas y devuelve la línea
# completa; el primer campo es la dirección, justo lo que necesita el
# dispatcher de foco.
#
# Se excluye la ventana activa para que Enter siempre cambie de ventana.
set -u

active=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')
clients=$(hyprctl clients -j 2>/dev/null)
[ -z "$clients" ] && exit 0

selection=$(jq -r --arg active "$active" '
    .[]
    | select(.mapped != false)
    | select(.address != $active)
    | "\(.address)\t\(.workspace.name)\t\((.title // "") | gsub("[\\n\\t]"; " "))  —  \(.class // "")"
' <<<"$clients" | wofi --dmenu --prompt "Ventanas..." --cache-file /dev/null)

[ -z "$selection" ] && exit 0

address=${selection%%$'\t'*}
[[ $address =~ ^0x[0-9a-fA-F]+$ ]] || exit 0

# Hyprland 0.56 con parser Lua: `hyprctl dispatch focuswindow` ya no existe.
hyprctl dispatch "hl.dsp.focus({window=\"address:$address\"})"
