#!/usr/bin/env bash
# Selector del historial del portapapeles (cliphist) para Hyprland.
#
# cliphist separa el id y la vista previa con un tabulador, pero wofi en modo
# dmenu interpreta el tabulador como separador de columnas y devuelve solo la
# primera columna (el id). Por eso no basta con reenviar la salida de wofi a
# `cliphist decode`: hay que extraer el id y pasarlo como argumento.
set -u

list=$(cliphist list 2>/dev/null)
[ -z "$list" ] && exit 0

# La entrada más reciente suele ser el portapapeles actual. Seleccionarla no
# produciría ningún cambio visible, así que se omite para que Enter siempre
# copie algo distinto.
first_id=${list%%$'\t'*}
current_hash=$(timeout 1 wl-paste --no-newline 2>/dev/null | sha256sum | cut -d' ' -f1)
first_hash=$(cliphist decode "$first_id" 2>/dev/null | sha256sum | cut -d' ' -f1)
if [ -n "$current_hash" ] && [ "$current_hash" = "$first_hash" ]; then
    list=$(printf '%s\n' "$list" | tail -n +2)
fi
[ -z "$list" ] && exit 0

selection=$(printf '%s\n' "$list" |
    wofi --dmenu --prompt "Portapapeles..." --cache-file /dev/null)
[ -z "$selection" ] && exit 0

# Acepta tanto la línea completa (id<TAB>vista previa) como solo el id.
id=${selection%%$'\t'*}
[[ $id =~ ^[0-9]+$ ]] || exit 0

# Buscar la entrada original para saber si es una imagen y su tipo MIME.
entry=$(printf '%s\n' "$list" | awk -F'\t' -v id="$id" '$1 == id { print; exit }')

if [[ $entry == *"binary data"* ]]; then
    mime=$(grep -oE 'image/[a-z0-9.+-]+' <<<"$entry" | head -1)
    if [ -n "$mime" ]; then
        cliphist decode "$id" | wl-copy --type "$mime"
        exit 0
    fi
fi

cliphist decode "$id" | wl-copy
