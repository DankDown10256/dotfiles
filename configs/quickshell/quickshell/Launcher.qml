import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: launcher

    readonly property color cBg:      "#0d1117"
    readonly property color cSurface: "#161b22"
    readonly property color cSel:     "#1f6feb80"
    readonly property color cAccent:  "#58a6ff"
    readonly property color cText:    "#e6edf3"
    readonly property color cDim:     "#7d8590"

    // doit correspondre à implicitHeight de la barre
    readonly property int barHeight: 35
    readonly property int gap: 16

    property bool open: false
    property bool alive: false   // garde la fenêtre vivante pendant l'animation de sortie

    onOpenChanged: {
        if (open) { alive = true; closeTimer.stop() }
        else closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 420            // doit rester > durée de l'animation (380 ms)
        onTriggered: launcher.alive = false
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.open = !launcher.open }
    }

    LazyLoader {
        active: launcher.alive

        PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }

            // clic en dehors = fermeture
            MouseArea {
                anchors.fill: parent
                onClicked: launcher.open = false
            }

            // --- panel latéral ---
            Rectangle {
                id: panel
                width: 400
                anchors.top: parent.top
                anchors.topMargin: launcher.gap
                anchors.bottom: parent.bottom
                anchors.bottomMargin: launcher.barHeight + launcher.gap   // ne chevauche pas la barre
                anchors.left: parent.left
                anchors.leftMargin: shown ? launcher.gap : -(width + 20)  // hors écran par la gauche

                color: launcher.cBg
                radius: 28
                border.color: launcher.cSel
                border.width: 1

                property bool shown: false
                opacity: shown ? 1 : 0

                // callLater : l'état initial (hors écran) est rendu avant de passer à true
                Component.onCompleted: Qt.callLater(() => shown = launcher.open)
                Connections {
                    target: launcher
                    function onOpenChanged() { panel.shown = launcher.open }
                }

                Behavior on anchors.leftMargin {
                    NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                // ne pas fermer en cliquant dans la boîte
                MouseArea { anchors.fill: parent }

                readonly property var results: {
                    const q = search.text.toLowerCase();
                    return DesktopEntries.applications.values
                        .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
                        .sort((a, b) => a.name.localeCompare(b.name));
                }

                function launch(entry) {
                    if (!entry) return;
                    entry.execute();
                    launcher.open = false;
                }
                
                function webSearch(q) {
                    Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]);
                    launcher.open = false;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    TextField {
                        id: search
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        placeholderText: "Recherche ..."
                        placeholderTextColor: launcher.cDim
                        color: launcher.cText
                        selectionColor: launcher.cAccent
                        selectedTextColor: launcher.cBg
                        font.pixelSize: 16
                        leftPadding: 14
                        background: Rectangle { radius: 14; color: launcher.cSurface }
                        Component.onCompleted: forceActiveFocus()

                        onTextChanged: list.currentIndex = 0
                        
                        onAccepted: {
                          if (list.currentItem) panel.launch(list.currentItem.entry)
                          else if (text.trim() !== "") panel.webSearch(text.trim())
                        }

                        Keys.onEscapePressed: launcher.open = false
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        currentIndex: 0
                        model: ScriptModel { values: panel.results }

                        delegate: Rectangle {
                            id: item
                            required property var modelData
                            required property int index
                            readonly property var entry: modelData

                            width: ListView.view.width
                            height: 46
                            radius: 12
                            color: ListView.isCurrentItem ? launcher.cSel : "transparent"

                            // barre d'accent sur l'élément sélectionné
                            Rectangle {
                                visible: item.ListView.isCurrentItem
                                width: 3
                                height: parent.height - 18
                                radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                color: launcher.cAccent
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 12

                                IconImage {
                                    implicitSize: 26
                                    source: Quickshell.iconPath(item.entry.icon, "application-x-executable")
                                }
                                Text {
                                    text: item.entry.name
                                    color: item.ListView.isCurrentItem ?  launcher.cText : launcher.cDim
                                    font.pixelSize: 14
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: panel.launch(item.entry)
                            }
                        }
                    }
                }
            }
        }
    }
}
