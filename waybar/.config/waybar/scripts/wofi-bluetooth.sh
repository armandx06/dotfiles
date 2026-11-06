#!/usr/bin/env bash
# Menú de Bluetooth para Waybar, usando Wofi y bluetoothctl.
set -u

WOFI=(wofi --dmenu --cache-file /dev/null --insensitive)

notify() {
    notify-send "Bluetooth" "$1" -a "wofi-bluetooth"
}

powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')

if [ "${powered:-no}" != "yes" ]; then
    choice=$(printf '%s\n' "󰂯  Encender Bluetooth" | "${WOFI[@]}" -p "Bluetooth apagado")
    if [ "$choice" = "󰂯  Encender Bluetooth" ]; then
        bluetoothctl power on >/dev/null 2>&1 && notify "Encendido"
    fi
    exit 0
fi

declare -A macs=()
menu=$'󰂲  Apagar Bluetooth\n⟳  Buscar dispositivos\n'

while IFS= read -r line; do
    [[ $line =~ ^Device\ ([0-9A-F:]{17})\ (.+)$ ]] || continue
    mac=${BASH_REMATCH[1]}
    name=${BASH_REMATCH[2]}

    info=$(bluetoothctl info "$mac" 2>/dev/null)
    icon="󰂯"
    grep -q 'Connected: yes' <<<"$info" && icon="󰂱"

    label="$icon  $name"
    if [ -n "${macs["$label"]:-}" ]; then
        label="$label ($mac)"
    fi
    macs["$label"]="$mac"
    menu+="$label"$'\n'
done < <(bluetoothctl devices 2>/dev/null)

chosen=$(printf '%s' "$menu" | "${WOFI[@]}" -p "Bluetooth")
[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰂲  Apagar Bluetooth")
        bluetoothctl power off >/dev/null 2>&1 && notify "Apagado"
        exit 0
        ;;
    "⟳  Buscar dispositivos")
        notify "Buscando dispositivos..."
        bluetoothctl --timeout 10 scan on >/dev/null 2>&1
        exec "$0"
        ;;
esac

mac=${macs["$chosen"]:-}
[ -z "$mac" ] && exit 0

info=$(bluetoothctl info "$mac" 2>/dev/null)

if grep -q 'Connected: yes' <<<"$info"; then
    bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify "Desconectado: $chosen"
    exit 0
fi

# El emparejamiento es asíncrono: hay que mantener el agente vivo y dar tiempo
# entre `pair`, `trust` y `connect`. Si se envían seguidos, `connect` corre
# antes de que termine el pairing y BlueZ descarta el vínculo al salir.
if ! grep -q 'Paired: yes' <<<"$info"; then
    notify "Emparejando con $chosen..."
    {
        printf 'power on\npairable on\nagent on\ndefault-agent\n'
        printf 'pair %s\n' "$mac"
        sleep 6
        printf 'trust %s\n' "$mac"
        sleep 2
        printf 'connect %s\n' "$mac"
        sleep 8
        printf 'quit\n'
    } | bluetoothctl >/dev/null 2>&1
else
    bluetoothctl connect "$mac" >/dev/null 2>&1
fi

if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
    notify "Conectado: $chosen"
else
    notify "No se pudo conectar: $chosen"
fi
