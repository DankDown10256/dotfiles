import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    required property var colors
    required property var controlCenter
    property bool barVisible: true

    Variants {
        model: Quickshell.screens
        Scope {
            required property var modelData
            readonly property bool fullscreenWindow: Hyprland.monitors.values.some(m =>
                m.name === modelData.name && m.hasFullscreen)

            HotCorner {
                colors: root.colors
                screen: modelData
                visible: !fullscreenWindow
                corner: "bl"
                command: ["qs", "ipc", "call", "launcher", "toggle"]
            }

            PanelWindow {
                screen: modelData
                visible: !fullscreenWindow
                anchors.top: true
                margins.top: root.barVisible && !fullscreenWindow ? 36 : 0
                implicitWidth: 240
                implicitHeight: 4
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "controlcenter-hotspot"

                Timer {
                    id: controlCenterDwell
                    interval: 120
                    onTriggered: root.controlCenter.showOn(modelData)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: controlCenterDwell.restart()
                    onExited: controlCenterDwell.stop()
                }
            }
        }
    }
}
