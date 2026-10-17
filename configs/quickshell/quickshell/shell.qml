import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import "."

Scope {
    id: root

    Colors {
      id: colors
    }

    Notifications {
      id: notificationCenter
      colors: colors
    }

    Launcher {
      colors: colors
      barInset: desktopBar.barVisible ? 32 : 0
    } 
    
    ControlCenter {
      colors: colors
      notifications: notificationCenter
      barInset: desktopBar.barVisible ? 32 : 0
    }
    Bar {
      id: desktopBar
      colors: colors
    }
    ThemeSwitcher {
      colors: colors
    } 
    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            HotCorner {
                colors: colors
                screen: modelData
                corner: "bl"
                command: ["qs", "ipc", "call", "launcher", "toggle"]
            }

            HotCorner {
                colors: colors
                screen: modelData
                corner: "tr"
                command: ["qs", "ipc", "call", "controlcenter", "toggle"]
            }
        }
    }
}
