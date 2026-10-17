import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    Launcher {}
    ControlCenter {}
    Bar {}

    // ---------- hot corners ----------
    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            HotCorner {
                screen: modelData
                corner: "bl"
                command: ["qs", "ipc", "call", "launcher", "toggle"]
            }

            HotCorner {
                screen: modelData
                corner: "tr"
                command: ["qs", "ipc", "call", "controlcenter", "toggle"]
            }
        }
    }
}
