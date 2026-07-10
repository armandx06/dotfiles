#!/usr/bin/env bash

WOFI_ARGS="--dmenu --cache-file /dev/null --insensitive"

connect_with_password() {
    local ssid="$1"
    local password
    # wofi --dmenu no necesita que le pases un eco vacío por stdin para funcionar como input
    password=$(wofi --dmenu --password -p "Contraseña para $ssid")
    [ -z "$password" ] && exec "$0"

    if nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
        notify-send "Red" "Conectado a $ssid" -a "wofi-network"
        return 0
    else
        notify-send "Red" "Contraseña incorrecta o falló la conexión" -a "wofi-network" -u critical
        return 1
    fi
}

# Refresca el listado de redes visibles antes de mostrar el menú
nmcli device wifi rescan >/dev/null 2>&1

# SSID:SEGURIDAD:SEÑAL:EN-USO (modo terse, delimitado por ':')
mapfile -t networks < <(nmcli -t -f SSID,SECURITY,SIGNAL,IN-USE device wifi list | sed '/^:/d' | sort -t: -k3 -rn)

declare -A seen
declare -A menu_to_ssid   # Relaciona la línea visual de wofi con el SSID real
declare -A ssid_security  # Guarda la seguridad de cada SSID para evitar el segundo nmcli
menu=""

menu+="⟳ Actualizar redes"$'\n'
menu+="✕ Desconectar"$'\n'

for line in "${networks[@]}"; do
    ssid="${line%%:*}"
    rest="${line#*:}"
    security="${rest%%:*}"
    rest="${rest#*:}"
    signal="${rest%%:*}"
    inuse="${rest#*:}"

    [ -z "$ssid" ] && continue
    [ -n "${seen[$ssid]}" ] && continue
    seen[$ssid]=1
    
    # Guardamos la seguridad asociada a este SSID
    ssid_security["$ssid"]="$security"

    # Asignación de iconos de señal (Nerd Fonts)
    if [ "$signal" -ge 70 ]; then
        icon="󰤨"
    elif [ "$signal" -ge 40 ]; then
        icon="󰤥"
    else
        icon="󰤟"
    fi

    # Indicador de red activa actual (mantiene el icono de señal)
    active="  "
    [ "$inuse" = "*" ] && active="● "

    # Indicador de seguridad
    lock=""
    [ -n "$security" ] && [ "$security" != "--" ] && lock=" 󰌾"

    # Construimos la línea tal y como se verá en Wofi
    line_text="${active}${icon}  ${ssid}${lock}"
    menu+="$line_text"$'\n'
    
    # Vinculamos esa línea exacta con su SSID correspondiente
    menu_to_ssid["$line_text"]="$ssid"
done

chosen=$(echo -n "$menu" | wofi $WOFI_ARGS -p "Redes Wi-Fi")
[ -z "$chosen" ] && exit 0

if [ "$chosen" = "⟳ Actualizar redes" ]; then
    exec "$0"
fi

if [ "$chosen" = "✕ Desconectar" ]; then
    iface=$(nmcli -t -f DEVICE,TYPE device | grep ':wifi$' | cut -d: -f1 | head -n1)
    nmcli device disconnect "$iface" >/dev/null 2>&1
    notify-send "Red" "Desconectado" -a "wofi-network"
    exit 0
fi

# Recuperación del SSID 100% segura mediante el mapa asociativo
ssid="${menu_to_ssid[$chosen]}"
[ -z "$ssid" ] && exit 0

# ¿Ya existe un perfil guardado para este SSID?
if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    if nmcli connection up "$ssid" >/dev/null 2>&1; then
        notify-send "Red" "Conectado a $ssid" -a "wofi-network"
        exit 0
    fi

    retry=$(printf "Reintentar con nueva contraseña\nOlvidar red\nCancelar" | wofi $WOFI_ARGS -p "Falló $ssid, ¿qué hacer?")

    case "$retry" in
        "Reintentar con nueva contraseña")
            nmcli connection delete "$ssid" >/dev/null 2>&1
            connect_with_password "$ssid"
            ;;
        "Olvidar red")
            nmcli connection delete "$ssid" >/dev/null 2>&1
            notify-send "Red" "Se olvidó $ssid" -a "wofi-network"
            ;;
        *)
            notify-send "Red" "No se pudo conectar a $ssid" -a "wofi-network" -u critical
            ;;
    esac
    exit 0
fi

security="${ssid_security[$ssid]}"

if [ -z "$security" ] || [ "$security" = "--" ]; then
    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
        notify-send "Red" "Conectado a $ssid" -a "wofi-network"
    else
        notify-send "Red" "No se pudo conectar a $ssid" -a "wofi-network" -u critical
    fi
else
    connect_with_password "$ssid"
fi