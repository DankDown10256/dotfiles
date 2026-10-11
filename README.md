# Hyprland dotfiles

An opinionated Hyprland setup — this is the desktop I genuinely believe is the best development environment on a window manager, and I set it up accordingly. Keyboard-first, low visual noise, terminal-centric, with just enough UI to stay informed without getting in the way.

It is designed and tested on **Artix Linux**, but there is nothing Artix-specific in the configs themselves: they run fine on Arch, Fedora, openSUSE, or anything else with recent enough packages. Only the service management differs (runit vs systemd), and none of these configs depend on it.

## Philosophy

- **Keyboard first.** Everything is reachable without touching the mouse: launcher, notifications, workspaces, window management, screenshots, volume, brightness.
- **Fast and lightweight.** No compositor gimmicks, no heavy widget toolkits, no autostart junk. Blur and animations are subtle and can be killed instantly with `blitz-mode.sh`.
- **Developer oriented.** Foot + Fish as the daily driver, Kitty kept as a full-featured alternative, a control center with a built-in Pomodoro timer, and a coding-agent indicator that tells you when Claude, OpenCode, or Codex is working in the background.
- **Flat and dark.** Terracotta/cream accent, JetBrainsMono Nerd Font everywhere, consistent across every component.

## Included configuration

| Component | Configuration |
| --- | --- |
| Hyprland | French layout, i3-style tiling and navigation, master layout, subtle blur, animated transitions, window rules, shaders |
| Hypridle | Locks the session after 10 minutes and before sleep |
| Hyprlock | Blurred session screenshot, clock, date, identity, password field |
| Foot | Default terminal: Fish shell, dark palette, 10k scrollback, block cursor, no blinking |
| Fish | Minimal config: quiet greeting, `l` alias, Copilot completions |
| Kitty | Alternative terminal: JetBrainsMono Nerd Font, dark palette, tabs, scrollback |
| Quickshell | Vertical bar, control center, app launcher, and notification popups |
| Waybar | Workspaces, clock, network, volume, memory, and battery |
| Rofi | App launcher, main menu, power menu, wallpaper and theme selectors, gruvbox themes |
| SwayNC | Top-centered notification center with grouping and Do Not Disturb |
| Hyprland shaders | CRT, focus, invert-colors, reading-mode, and display-enhancement shaders |

The active Hyprland setup starts PipeWire, WirePlumber, `awww-daemon`, Hypridle, SwayNC, Udiskie, and Waybar. It uses Foot as the terminal, Nautilus as the file manager, and Rofi as the application launcher.

### Quickshell highlights

Quickshell is where most of the custom work lives:

- **Vertical bar** — workspaces, MPRIS media controls, system tray, Wi-Fi state, volume, brightness, and clock, all clickable or scrollable.
- **Control center** — Wi-Fi details, volume and brightness sliders, Do Not Disturb, a Pomodoro timer (25/5) with notifications, and lock/logout/reboot/poweroff actions.
- **Coding agent indicator** — the control center watches running processes and shows a banner when Claude, OpenCode, or Codex is actively working, so you know a task is still in flight.
- **App launcher and notification popups** — a warm brown/terracotta palette, overlay-layer windows with animated open/close.

## Main key bindings

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open Foot |
| `Super + Space` | Open Rofi (drun) |
| `Super + Alt + Space` | Open the Rofi main menu |
| `Super + E` | Open Nautilus |
| `Super + Q` | Close the active window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating mode |
| `Super + P` | Toggle pseudo-tiling |
| `Super + L` | Lock the session |
| `Super + M` | Exit Hyprland |
| `Super + N` | Toggle SwayNC |
| `Super + G` | Region screenshot to clipboard (hyprshot) |
| `Super + Shift + W` | Wallpaper selector |
| `Super + Shift + T` | Theme selector |
| `Super + Shift + N` | Open FeatherPad |
| `Super + Arrow` | Move focus |
| `Super + Shift + Arrow` | Move the active window |
| `Super + Ctrl + Arrow` | Resize the active window |
| `Super + 1–0` | Switch to workspace 1–10 |
| `Super + Shift + 1–0` | Move the active window to workspace 1–10 |
| `Super + S` | Toggle the special workspace |
| `Super + Drag` | Move / resize a window with the mouse |
| `Super + Mouse wheel` (bar) | Change volume / brightness |

## Repository layout

```text
configs/
├── fish/        Fish shell configuration and completions
├── foot/        Foot terminal configuration
├── hypr/        Hyprland, Hypridle, Hyprlock, shaders, and helper scripts
├── kitty/       Kitty configuration and color themes
├── quickshell/  Bar, control center, launcher, and notification popups
├── rofi/        Launcher, menus, selectors, and themes
├── swaync/      Notification center configuration and stylesheet
└── waybar/      Status bar configuration and stylesheet
```

The `configs/hypr/shaders/` directory also contains an alternative Hyprland and Hyprlock setup alongside the shader collection.

## Requirements

Install the applications referenced by the configuration before enabling it. On Artix with pacman:

```bash
sudo pacman -S hyprland hypridle hyprlock quickshell foot fish kitty waybar swaync rofi-wayland \
  nautilus pipewire pipewire-pulse wireplumber udiskie brightnessctl libnotify jq curl \
  playerctl imagemagick networkmanager hyprshot featherpad
```

On other distros, install the same packages through your own package manager (names may vary slightly: `rofi-wayland`, `quickshell`, and `hyprshot` are the usual suspects on non-Arch distros).

Additional commands referenced by the configuration are `awww-daemon`, `hyprquickframe`, `imv`, `nmcli`, `pactl`, and the Rofi scripts expected under `~/.config/rofi/`.

A Nerd Font is required for the icons. The Kitty, Foot, and Hyprlock configurations expect JetBrainsMono Nerd Font.

## Installation

Back up any existing configuration, then copy or symlink only the components you want to use:

```bash
mkdir -p ~/.config/{hypr,kitty,swaync,waybar,rofi,foot,fish,quickshell}

cp -r configs/hypr/. ~/.config/hypr/
cp -r configs/kitty/. ~/.config/kitty/
cp -r configs/swaync/. ~/.config/swaync/
cp -r configs/waybar/. ~/.config/waybar/
cp -r configs/rofi/. ~/.config/rofi/
cp -r configs/foot/. ~/.config/foot/
cp -r configs/fish/. ~/.config/fish/
cp -r configs/quickshell/. ~/.config/quickshell/
```

Review the monitor definitions, cursor theme, program paths, and autostart commands in `configs/hypr/hyprland.conf` before starting Hyprland. The current monitor setup mirrors `HDMI-A-2` to `eDP-1`.

Make the helper scripts executable after copying them:

```bash
chmod +x ~/.config/hypr/scripts/*.sh
chmod +x ~/.config/rofi/*.sh
```

### Keeping the repo in sync

`update_configs.sh` copies the live configuration from `~/.config/` back into `configs/`, so the repo always matches what actually runs on the machine. Run it from the repository root after changing something you want to keep.

## Helper scripts

- `blitz-mode.sh` toggles Hyprland animations and visual effects.
- `github_graph.sh` downloads a GitHub contribution graph for Hyprlock.
- `hyprlock-layout.sh` reports the active keyboard layout.
- `hyprlock-music.sh` exposes MPRIS track metadata and prepares album artwork.
- `hyprlock_weather.sh` displays weather and battery information.
- `rofi/launcher.sh`, `rofi/mainmenu.sh` launch the Rofi menus and selectors.

Some helper scripts contain user-specific paths or values. Review them before use, especially the GitHub username, battery device, wallpaper path, and Hyprlock script paths.
