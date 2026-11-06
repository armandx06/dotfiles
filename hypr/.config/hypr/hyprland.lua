------------------
---- MONITORS ----
------------------
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = "1",
    disabled = false
})
hl.monitor({
    output = "DP-1",
    mode = "2560x1440@143.97301",
    position = "1920x0",
    scale = "auto"
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "nautilus"
local browser = "firefox"
local ipc = "noctalia msg "

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("HYPRSHOT_DIR", "/home/armandx06/Imágenes/Screenshots")

-------------------
---- AUTOSTART ----
-------------------

local function apply_monitor_layout()
    hl.exec_cmd("~/.config/hypr/scripts/auto-monitors.sh")
end

hl.on("hyprland.start", function()
    -- Noctalia cubre barra, notificaciones, portapapeles, idle, bloqueo y
    -- fondo de pantalla. Waybar, SwayNC, Hypridle, hyprpaper y hyprlock
    -- siguen en el repo como respaldo, pero ya no se inician solos.
    hl.exec_cmd("noctalia --daemon")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(terminal)
    hl.exec_cmd(browser)
    apply_monitor_layout()
end)

-- Al conectar, desconectar o recargar la config, ajustar eDP-1 automáticamente.
hl.on("monitor.added", apply_monitor_layout)
hl.on("monitor.removed", apply_monitor_layout)
hl.on("config.reloaded", apply_monitor_layout)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = "rgb(a2bcd1)",
            inactive_border = "rgb(1a2332)"
        },
        layout = "dwindle"
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.96,
        inactive_opacity = 0.90,
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            new_optimizations = true
        },
        shadow = {
            enabled = true,
            range = 10,
            render_power = 2,
            color = "rgba(1a2332ee)"
        }
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false
    },
    master = {
        new_status = "master"
    },
    input = {
        kb_layout = "latam",
        kb_variant = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true
        }
    }
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + D", hl.dsp.window.float({
    action = "toggle"
}))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())

hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m window"))

hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(ipc .. "window-switcher"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/auto-monitors.sh"))

hl.bind(mainMod .. " + H", hl.dsp.focus({
    direction = "left"
}))
hl.bind(mainMod .. " + K", hl.dsp.focus({
    direction = "right"
}))
hl.bind(mainMod .. " + U", hl.dsp.focus({
    direction = "up"
}))
hl.bind(mainMod .. " + J", hl.dsp.focus({
    direction = "down"
}))

-- Mover ventana (movewindow)
-- TODO: verifica en la wiki (Configuring > Basics > Binds > Dispatchers) que
-- window.move({direction=...}) sea el nombre correcto; la documentación
-- oficial solo confirma window.move({workspace=...}) explícitamente.
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({
    direction = "left"
}))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({
    direction = "right"
}))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({
    direction = "up"
}))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({
    direction = "down"
}))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({
        workspace = i
    }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({
        workspace = i
    }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true
})
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true
})

hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(ipc .. "volume-up"), {
        repeating = true
    })
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd(ipc .. "volume-down"), {
        repeating = true
    })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name = "wiremix-float",
    match = {
        class = "^(wiremix-float)$"
    },
    float = true,
    center = true,
    size = "500 400"
})

-- La ventana de ajustes de Noctalia es una ventana normal: flotante y grande.
hl.window_rule({
    name = "noctalia-settings",
    match = {
        class = "^(dev\\.noctalia\\.Noctalia)$"
    },
    float = true,
    center = true,
    size = "1080 920"
})

-- Las superficies de Noctalia se dibujan solas: sin animaciones de Hyprland
-- y con blur del compositor detrás de sus paneles.
hl.layer_rule({
    name = "noctalia-no-anim",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$"
    },
    no_anim = true
})

hl.layer_rule({
    name = "noctalia-blur",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$"
    },
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true
})
