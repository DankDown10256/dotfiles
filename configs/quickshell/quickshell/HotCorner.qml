// HotCorner.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var colors
    required property string corner      // "tl" | "tr" | "bl" | "br"
    property var command: []
    property int dwell: 80              // ms de survol avant déclenchement

    anchors {
        top: corner[0] === "t"
        bottom: corner[0] === "b"
        left: corner[1] === "l"
        right: corner[1] === "r"
    }

    implicitWidth: 4
    implicitHeight: 4
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore  // ne réserve pas d'espace
    WlrLayershell.layer: WlrLayer.Overlay  // reste au-dessus des fullscreen
    WlrLayershell.namespace: "hotcorner"

    Timer {
        id: dwellTimer
        interval: root.dwell
        onTriggered: Quickshell.execDetached(root.command)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: dwellTimer.restart()
        onExited: dwellTimer.stop()
    }
}
