-- local terminal = alacritty 
-- local fileManager = nautilus 
-- local menu = qs ipc call launcher toggle 
-- local browser = firefox

-- exec-once = pipewire 
-- exec-once = pipewire-pulse
-- exec-once = wireplumber
-- exec-once = quickshell 
-- exec-once = hypridle
-- exec-once = awww-daemon

-- hl.env("XCURSOR_SIZE", "30")
-- hl.env("XCURSOR_THEME", "macOS")

-- source = ~/.config/hypr/colors-hyprland.conf

-- general {
--     gaps_in = 8
--     gaps_out = 8
--     border_size = 2 
--
--     col.active_border = $primary $accent 45deg
--
--     -- col.inactive_border = $surface
--
--     -- layout = dwindle
-- }

-- decoration {
--     rounding = 0
--
--     active_opacity = 0.90
--     inactive_opacity = 0.85 
--
--
--     dim_inactive = false
--
--     shadow {
--         enabled = false 
--     }
--
--     blur {
--         enabled = false 
--         size = 6
--         passes = 3
--         noise = 0.006
--         brightness = 2 
--         contrast = 1
--         vibrancy = 0.25
--         vibrancy_darkness = 0.6
--         new_optimizations = true
--         popups = true
--         special = true
--     }
-- }


-- animations {
--     enabled = yes
--     bezier = easeOutQuint, 0.23, 1, 0.32, 1
--     bezier = easeInOutCubic, 0.65, 0, 0.35, 1
--     bezier = linear, 0, 0, 1, 1
--
--     animation = windows, 1, 4, easeOutQuint
--     animation = windowsIn, 1, 4, easeOutQuint, popin
--     animation = windowsOut, 1, 4, easeInOutCubic, popin 80%
--     animation = windowsMove, 1, 4, easeOutQuint
--
--     #animation = border, 1, 5, easeOutQuint
--     #animation = borderangle, 1, 6, easeOutQuint
--
--     animation = fade, 1, 4, easeOutQuint
--     animation = fadeIn, 1, 4, easeOutQuint
--     animation = fadeOut, 1, 4, easeInOutCubic
--
--     animation = workspaces, 1, 5, easeOutQuint, slide
--     animation = specialWorkspace, 1, 5, easeOutQuint, slidevert
-- }

-- dwindle {
--     pseudotile = true
--     preserve_split = true
--     force_split = 2 # Split vers la droite/bas systématique comme i3
-- }

hl.config({
    general = {
        layout = "dwindle",
    },
    master = {
        new_status = "dwindle",
    },
})

-- misc {
--     force_default_wallpaper = 0
--     disable_hyprland_logo = true
-- }

-- input {
--     kb_layout = fr
--     follow_mouse = 1
--     sensitivity = 0
--     touchpad {
--         natural_scroll = true
--     }
-- }

local mainMod = "SUPER"

-- bind = $mainMod, return, exec, $terminal
-- bind = $mainMod, Q, killactive,
-- bind = $mainMod, M, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit
-- bind = $mainMod, E, exec, $fileManager
-- bind = $mainMod, V, togglefloating,
-- bind = $mainMod, T, exec, noctalia msg panel-toggle wallpaper
-- bind = $mainMod, F, fullscreen,
-- bind = $mainMod, P, pseudo,
-- #bind = $mainMod, J, togglesplit,
-- bind = $mainMod, space, exec, $menu
-- bind = $mainMod, TAB, exec, qs ipc call launcher windows
-- bind = $mainMod SHIFT, P, exec, qs ipc call launcher toggle
-- bind = $mainMod, N, exec, qs ipc call controlcenter toggle
-- bind = $mainMod SHIFT, C, exec, qs ipc call clipboard toggle
-- bind = $mainMod SHIFT, N, exec, qs ipc call notifications toggle
-- bind = $mainMod, D, exec, qs ipc call bar toggle
-- bind = $mainMod, G, exec, hyprshot -m region --clipboard-only
-- bind = $mainMod, I, exec, noctalia msg settings-toggle
-- bind = $mainMod, B, exec, $browser 
-- bind = $mainMod, L, exec, hyprlock 
-- bind = $mainMod ALT, space, exec, ~/.config/rofi/mainmenu.sh
-- bind = $mainMod SHIFT, W, exec, foot nmtui
--
-- bind = $mainMod, left, movefocus, l
-- bind = $mainMod, right, movefocus, r
-- bind = $mainMod, up, movefocus, u
-- bind = $mainMod, down, movefocus, d
--
-- bind = $mainMod, code:10, workspace, 1
-- bind = $mainMod, code:11, workspace, 2
-- bind = $mainMod, code:12, workspace, 3
-- bind = $mainMod, code:13, workspace, 4
-- bind = $mainMod, code:14, workspace, 5
-- bind = $mainMod, code:15, workspace, 6
-- bind = $mainMod, code:16, workspace, 7
-- bind = $mainMod, code:17, workspace, 8
-- bind = $mainMod, code:18, workspace, 9
-- bind = $mainMod, code:19, workspace, 10
--
-- bind = $mainMod SHIFT, code:10, movetoworkspace, 1
-- bind = $mainMod SHIFT, code:11, movetoworkspace, 2
-- bind = $mainMod SHIFT, code:12, movetoworkspace, 3
-- bind = $mainMod SHIFT, code:13, movetoworkspace, 4
-- bind = $mainMod SHIFT, code:14, movetoworkspace, 5
-- bind = $mainMod SHIFT, code:15, movetoworkspace, 6
-- bind = $mainMod SHIFT, code:16, movetoworkspace, 7
-- bind = $mainMod SHIFT, code:17, movetoworkspace, 8
-- bind = $mainMod SHIFT, code:18, movetoworkspace, 9
-- bind = $mainMod SHIFT, code:19, movetoworkspace, 10
--
-- bind = SUPER SHIFT, left, movewindow, l
-- bind = SUPER SHIFT, right, movewindow, r
-- bind = SUPER SHIFT, up, movewindow, u
-- bind = SUPER SHIFT, down, movewindow, d
--
-- bind = $mainMod, S, togglespecialworkspace, magic
-- bind = SUPER SHIFT, S, movetoworkspacesilent, special:magic
-- bind = SUPER SHIFT, R, movetoworkspace, e+0
-- bindm = $mainMod, mouse:272, movewindow
-- bindm = $mainMod, mouse:273, resizewindow
-- binde = $mainMod CONTROL, right, resizeactive, 30 0
-- binde = $mainMod CONTROL, left, resizeactive, -30 0
-- binde = $mainMod CONTROL, up, resizeactive, 0 -30
-- binde = $mainMod CONTROL, down, resizeactive, 0 30
--
-- bindel = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5% && qs ipc call osd volume
-- bindel = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5% && qs ipc call osd volume
-- bindl = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle && qs ipc call osd volume
-- bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+ && qs ipc call osd brightness
-- bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%- && qs ipc call osd brightness
--
-- windowrule = match:class org.gnome.Nautilus, float true, size 1000 650 
-- windowrule = match:class imv, float true, size 1000 650
-- windowrule = match:class firefox, opacity 1.0 override 1.0 override
--
-- xwayland {
--   force_zero_scaling = true
-- }

local terminal = "alacritty"
local fileManager = "nautilus"
local menu = "qs ipc call launcher toggle"
local browser = "firefox"

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60.00",
    position = "0x0",
    scale = 1,
    -- transform = 2,
})
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.on("hyprland.start", function()
    hl.exec_cmd("pipewire")
    hl.exec_cmd("pipewire-pulse")
    hl.exec_cmd("wireplumber")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
end)

hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgb(91cef5)", "rgb(cbc1e9)" },
                angle = 45,
            },
            inactive_border = "rgb(0f1417)",
        },
    },
    decoration = {
        rounding = 0,
        active_opacity = 0.90,
        inactive_opacity = 0.85,
        dim_inactive = false,
        shadow = { enabled = false },
        blur = {
            enabled = false,
            size = 6,
            passes = 3,
            noise = 0.006,
            brightness = 2,
            contrast = 1,
            vibrancy = 0.25,
            vibrancy_darkness = 0.6,
            new_optimizations = true,
            popups = true,
            special = true,
        },
    },
    animations = { enabled = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
    input = {
        kb_layout = "fr",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = true },
    },
    xwayland = { force_zero_scaling = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "easeInOutCubic", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "easeInOutCubic" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slidevert" })

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs ipc call launcher windows"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call bar toggle"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd("~/.config/rofi/mainmenu.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("foot nmtui"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end

for workspace = 1, 10 do
    local key = "code:" .. (workspace + 9)
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.window.move({ workspace = "e+0", follow = true }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + CONTROL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CONTROL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5% && qs ipc call osd volume"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5% && qs ipc call osd volume"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle && qs ipc call osd volume"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+ && qs ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%- && qs ipc call osd brightness"), { locked = true, repeating = true })

hl.window_rule({ match = { class = "org.gnome.Nautilus" }, float = true, size = "1000 650" })
hl.window_rule({ match = { class = "imv" }, float = true, size = "1000 650" })
hl.window_rule({ match = { class = "firefox" }, opacity = "1.0 override 1.0 override" })

