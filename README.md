# Hyprland dotfiles

An opinionated Hyprland setup — this is the desktop I genuinely believe is the best development environment on a window manager, and I set it up accordingly. Keyboard-first, low visual noise, terminal-centric, with just enough UI to stay informed without getting in the way.

It is designed and tested on **Artix Linux**, but there is nothing Artix-specific in the configs themselves: they run fine on Arch, Fedora, openSUSE, or anything else with recent enough packages. Only the service management differs (runit vs systemd), and none of these configs depend on it.

## Philosophy

- **Keyboard first.** Everything is reachable without touching the mouse: launcher, notifications, workspaces, window management, screenshots, volume, brightness.
- **Fast and lightweight.** No compositor gimmicks, no heavy widget toolkits, no autostart junk. Blur and animations are subtle and can be killed instantly with `blitz-mode.sh`.
- **Developer oriented.** Kitty + Fish as the daily driver, Foot kept as a minimal alternative, Zed one `Super + B` away, a control center with a built-in Pomodoro timer, and a coding-agent indicator that tells you when Claude, OpenCode, or Codex is working in the background.
- **Flat and dark.** Terracotta/cream accent, JetBrainsMono Nerd Font everywhere, consistent across every component.

## Included configuration

| Component | Configuration |
| --- | --- |
| Hyprland | French layout, i3-style tiling and navigation, master layout, subtle blur, animated transitions, window rules, shaders |
| Quickshell | Default shell: vertical bar, app launcher, control center, and a notification popup component |
| Hypridle | Locks the session after 10 minutes and before sleep |
| Hyprlock | Blurred session screenshot, clock, date, identity, password field |
| Kitty | Default terminal: JetBrainsMono Nerd Font, dark palette, tabs, scrollback |
| Foot | Minimal alternative terminal: Fish shell, dark palette, 10k scrollback, block cursor, no blinking |
| Fish | Minimal config: quiet greeting, `l` alias, Copilot completions |
| SwayNC | Notification daemon started at login: grouping and Do Not Disturb |
| Rofi | Main menu (`Super + Alt + Space`): applications, Wi-Fi, configuration, plus power menu themes |
| Waybar | Alternative status bar — kept in the repo, not started by default |
| Hyprland shaders | CRT, focus, invert-colors, reading-mode, and display-enhancement shaders |

The active Hyprland setup starts PipeWire, WirePlumber, `awww-daemon`, Quickshell, SwayNC, and Hypridle. It uses Kitty as the terminal, Nautilus as the file manager, Quickshell as the application launcher, and Zed as the IDE.

### Quickshell highlights

Quickshell is where most of the custom work lives — it provides the bar, the launcher, and the control center:

- **Vertical bar** — 5 workspaces, rotated active-window title, MPRIS media controls, system tray, Wi-Fi state, volume, brightness, and clock, all clickable or scrollable.
- **App launcher** (`Super + Space`) — bottom panel over an overlay layer, live search over desktop entries, keyboard navigation with Enter to launch, Esc or an outside click to close.
- **Control center** (`Super + N`) — clock, Do Not Disturb toggle, a Pomodoro timer (25/5) with notifications, Wi-Fi SSID, volume and brightness sliders, and lock/logout/reboot/poweroff actions.
- **Coding agent indicator** — the control center watches running processes and shows a banner when Claude, OpenCode, or Codex is actively working, so you know a task is still in flight.
- **Warm brown/terracotta palette** shared by the bar, the launcher, and the control center, with animated open/close on both overlay windows.

The launcher and the control center are driven from Hyprland through `qs ipc call launcher toggle` and `qs ipc call controlcenter toggle`, so Quickshell must be running (it is started at login) for `Super + Space` and `Super + N` to work. `NotificationPopup.qml` ships as a standalone component ready to be wired to a notification server; actual notification popups are currently handled by SwayNC.

## Main key bindings

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + Space` | Toggle the Quickshell app launcher |
| `Super + N` | Toggle the Quickshell control center |
| `Super + Alt + Space` | Open the Rofi main menu |
| `Super + E` | Open Nautilus |
| `Super + B` | Open Zed |
| `Super + Q` | Close the active window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating mode |
| `Super + P` | Toggle pseudo-tiling |
| `Super + L` | Lock the session |
| `Super + M` | Exit Hyprland (`hyprshutdown` if installed, `hyprctl dispatch exit` otherwise) |
| `Super + G` | Region screenshot to clipboard (hyprshot) |
| `Super + Shift + W` | Open `foot nmtui` (network setup) |
| `Super + Arrow` | Move focus |
| `Super + Shift + Arrow` | Move the active window |
| `Super + Ctrl + Arrow` | Resize the active window |
| `Super + 1–0` | Switch to workspace 1–10 |
| `Super + Shift + 1–0` | Move the active window to workspace 1–10 |
| `Super + S` | Toggle the special workspace |
| `Super + Drag` | Move / resize a window with the mouse |
| `Super + Mouse wheel` (bar) | Change volume / brightness |
| `Volume` / `Brightness` keys | Change volume / brightness (pactl, brightnessctl) |

## Repository layout

```text
configs/
├── fish/        Fish shell configuration and completions
├── foot/        Foot terminal configuration
├── hypr/        Hyprland, Hypridle, Hyprlock, shaders, and helper scripts
├── kitty/       Kitty configuration and color themes
├── quickshell/  Bar, control center, launcher, and notification popup component
├── rofi/        Main menu, application launcher fallback, and themes
├── swaync/      Notification center configuration and stylesheet
└── waybar/      Status bar configuration and stylesheet
```

The `configs/hypr/shaders/` directory also contains an alternative Hyprland and Hyprlock setup alongside the shader collection.

`update_configs.sh` copies `~/.config/<app>/` into `configs/<app>/`, so a directory refreshed by the script ends up containing a nested copy of itself: `configs/hypr/hypr/`, `configs/rofi/rofi/`, `configs/swaync/swaync/`, `configs/waybar/waybar/`, `configs/foot/foot/`, and `configs/fish/fish/`. The nested copy is the live one — `configs/hypr/hypr/hyprland.conf` is the Hyprland config described in this README — while the files directly under `configs/hypr/` are the older retro setup kept for reference.

## Requirements

Install the applications referenced by the configuration before enabling it. On Artix with pacman:

```bash
sudo pacman -S hyprland hypridle hyprlock quickshell kitty foot fish swaync rofi-wayland \
  nautilus pipewire pipewire-pulse wireplumber brightnessctl libnotify jq curl \
  playerctl imagemagick networkmanager hyprshot
```

On other distros, install the same packages through your own package manager (names may vary slightly: `quickshell`, `rofi-wayland`, and `hyprshot` are the usual suspects on non-Arch distros).

Additional commands referenced by the configuration are `awww-daemon`, `qs` (the Quickshell IPC client, used for the launcher and the control center), `nmcli`, `pactl`, `dunstctl`, `notify-send`, `systemctl`, `imv`, and the Rofi scripts expected under `~/.config/rofi/`.

Optional, only for specific bindings or helpers: `zed` (`Super + B`), `hyprshutdown` (`Super + M`, falls back to `hyprctl dispatch exit`), `waybar`, `udiskie`, and `nmtui` from `networkmanager` (`Super + Shift + W`).

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

Review the monitor definitions, cursor theme, program paths, and autostart commands in `configs/hypr/hypr/hyprland.conf` before starting Hyprland. The current monitor setup mirrors `HDMI-A-2` to `eDP-1`, and the launcher, the bar, and the control center come from `configs/quickshell/`, which must be present at `~/.config/quickshell/` for the default bindings to work.

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
- `rofi/launcher.sh`, `rofi/mainmenu.sh` launch the Rofi main menu and its application launcher fallback.

Some helper scripts contain user-specific paths or values. Review them before use, especially the GitHub username, battery device, wallpaper path, and Hyprlock script paths.
