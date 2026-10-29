-- Minimal Hyprland configuration

local terminal = "kitty"

-- Window styling

hl.config({
    general = {
	allow_tearing = true,
        border_size = 2,
        col = {
            active_border = "rgb(ff003c)",
            inactive_border = "rgb(ff003c)",
        },
    },
    misc = {
        vrr = 1,    -- Adaptive Sync / FreeSync / G-Sync (1 = always on)
        disable_hyprland_logo = true,
    },
    decoration = {
        rounding = 25,
        rounding_power = 1.0,
    },
    windowrulev2 = {
        "immediate, class:^(Cyberpunk 2077)$",
        "immediate, class:^(steam_app_1091500)$",
        "fullscreen, class:^(Cyberpunk 2077)$",
        "idleinhibit always, class:^(Cyberpunk 2077)$",
    }
})

hl.window_rule({
    name = "game-fullscreen-fix",
    match = {
        content = "game",
    },
    suppress_event = "fullscreen",
})

hl.window_rule({
    name = "aniimo-windowed",
    match = {
        class = "^steam_app_4126040$",
    },
    float = true,
})






-- Kitty: no border
hl.window_rule({
    name = "kitty-no-border",
    match = {
        class = "^kitty$",
    },
    border_size = 0,
})

-- Discord
hl.window_rule({
    match = {
        class = "discord",
    },
    opacity = "0.85 override 0.80 override",
})

-- Monitor
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})


-- Basic keybindings

hl.bind("SUPER + Return",
    hl.dsp.exec_cmd(terminal))

hl.bind("SUPER + Space",
    hl.dsp.exec_cmd("~/.config/wofi/menu.sh"))

hl.bind("SUPER + Q",
    hl.dsp.window.close())

hl.bind("SUPER + L",
    hl.dsp.exit())

hl.bind("SUPER + E",
    hl.dsp.exec_cmd("kitty -e yazi"))

hl.bind("SUPER + T",
    hl.dsp.exec_cmd("env GTK_THEME=NightCity thunar"))

hl.bind("SUPER + F",
    hl.dsp.window.fullscreen())

-- Move focus between windows

hl.bind("SUPER + left",
    hl.dsp.focus({ direction = "left" }))

hl.bind("SUPER + right",
    hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER + up",
    hl.dsp.focus({ direction = "up" }))

hl.bind("SUPER + down",
    hl.dsp.focus({ direction = "down" }))


-- Shift window whithin same workspace

hl.bind("SUPER + SHIFT + left",
    hl.dsp.window.move({ direction = "left"}))

hl.bind("SUPER + SHIFT + right",
    hl.dsp.window.move({ direction = "right" }))

hl.bind("SUPER + SHIFT + up",
    hl.dsp.window.move({ direction = "up" }))

hl.bind("SUPER + SHIFT + down",
    hl.dsp.window.move({ direction = "down" }))


-- Audio

hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
    { repeating = true })

hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { repeating = true })

hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))


-- Brightness

hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { repeating = true })

hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { repeating = true })


-- Screenshots

hl.bind("Print",
    hl.dsp.exec_cmd(
        "sh -c 'mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png'"
    ))

hl.bind("SUPER + Print",
    hl.dsp.exec_cmd(
        "sh -c 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png'"
    ))

hl.bind("SUPER + SHIFT + S",
    hl.dsp.exec_cmd(
        "sh -c 'grim -g \"$(slurp)\" - | wl-copy'"
    ))


-- Switch workspaces

for i = 1, 9 do
    hl.bind(
        "SUPER + " .. i,
        hl.dsp.focus({ workspace = tostring(i) })
    )
end

hl.bind(
    "SUPER + TAB",
    hl.dsp.focus({ workspace = "previous" })
)


-- Move focused window to workspace

for i = 1, 4 do
    hl.bind(
        "SUPER + SHIFT + " .. i,
        hl.dsp.window.move({ workspace = tostring(i) })
    )
end


-- Startup applications

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("quickshell -p ~/.config/quickshell/shell.qml")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)
