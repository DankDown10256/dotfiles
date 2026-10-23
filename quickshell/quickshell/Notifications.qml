import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Scope {
    id: root

    required property var colors
    property int barInset: 30
    property bool dnd: false
    property bool open: false
    property bool alive: false
    property var popupIds: []

    readonly property var history: server.trackedNotifications.values
        .filter(notification => !notification.transient).slice().reverse()
    readonly property var historyGroups: {
        const groups = []
        for (const notification of history) {
            const name = notification.appName || "Application"
            let group = groups.find(item => item.name === name)
            if (!group) { group = { name: name, items: [] }; groups.push(group) }
            group.items.push(notification)
        }
        return groups
    }
    readonly property var popups: server.trackedNotifications.values
        .filter(notification => root.popupIds.includes(notification.id))
        .slice().reverse()

    function hidePopup(id) {
        popupIds = popupIds.filter(value => value !== id)
        const notification = server.trackedNotifications.values
            .find(notification => notification.id === id)
        if (notification?.transient)
            notification.expire()
    }

    function clearPopups() {
        const ids = popupIds.slice()
        for (const id of ids)
            hidePopup(id)
    }

    function dismissAll() {
        const notifications = server.trackedNotifications.values.slice()
        popupIds = []
        for (const notification of notifications)
            notification.dismiss()
    }

    onDndChanged: {
        if (dnd) clearPopups()
    }

    onOpenChanged: {
        if (open) {
            clearPopups()
            alive = true
            closeTimer.stop()
        } else {
            closeTimer.restart()
        }
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true
            if (root.dnd || root.open || notification.lastGeneration) {
                if (notification.transient)
                    notification.expire()
                return
            }
            root.popupIds = root.popupIds.filter(id => id !== notification.id)
            if (root.popupIds.length >= 3)
                root.hidePopup(root.popupIds[0])
            root.popupIds = root.popupIds.concat([notification.id])
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
        function silence(): void { root.dnd = !root.dnd }
        function clear(): void { root.dismissAll() }
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.alive = false
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        anchors { top: true; right: true }
        margins { top: root.barInset + 8; right: 12 }
        implicitWidth: Math.min(340, screen.width - 32)
        implicitHeight: Math.min(popupColumn.implicitHeight, screen.height - root.barInset - 20)
        visible: root.popups.length > 0 && !root.alive
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: popupColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: popupColumn
                width: parent.width
                spacing: 8

                Repeater {
                    model: ScriptModel { values: root.popups }

                    delegate: NotificationPopup {
                        required property var modelData
                        Layout.fillWidth: true
                        notification: modelData
                        colors: root.colors
                        onExpired: root.hidePopup(modelData.id)
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: root.barInset + 8
                anchors.rightMargin: 12
                width: Math.min(372, parent.width - 32)
                height: Math.min(
                    parent.height - root.barInset - 20,
                    root.history.length === 0 ? 160
                        : Math.min(560, historyList.contentHeight + 80)
                )
                radius: 6
                color: root.colors.cSurface
                border.width: 1
                border.color: root.colors.cBorder
                property bool shown: false
                opacity: shown ? 1 : 0
                focus: true

                Component.onCompleted: {
                    forceActiveFocus()
                    Qt.callLater(() => shown = root.open)
                }

                Connections {
                    target: root
                    function onOpenChanged() { card.shown = root.open }
                }

                Keys.onEscapePressed: root.open = false

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                transform: Translate {
                    x: card.shown ? 0 : 4

                    Behavior on x {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: "Notifications · " + root.history.length
                            font.family: "sans-serif"
                            font.pixelSize: 13
                            color: root.colors.cText
                            elide: Text.ElideRight
                        }

                        Button {
                            implicitHeight: 28
                            text: root.dnd ? "DND actif" : "DND"
                            onClicked: root.dnd = !root.dnd
                            contentItem: Text { text: parent.text; color: root.dnd ? root.colors.cAccent : root.colors.cText; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { radius: 6; color: root.dnd ? root.colors.cSelection : root.colors.cElevated }
                        }

                        Button {
                            implicitHeight: 28
                            implicitWidth: 80
                            text: "Tout effacer"
                            enabled: root.history.length > 0
                            onClicked: root.dismissAll()

                            contentItem: Text {
                                text: parent.text
                                font.family: "sans-serif"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: parent.enabled
                                    ? root.colors.cText : root.colors.cMuted
                            }

                            background: Rectangle {
                                radius: 6
                                color: parent.hovered || parent.activeFocus
                                    ? root.colors.cSelection : root.colors.cElevated

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.history.length === 0
                        text: "Aucune notification"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "sans-serif"
                        font.pixelSize: 13
                        color: root.colors.cMuted
                    }

                    Flickable {
                        id: historyList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.history.length > 0
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: historyColumn.implicitHeight

                        ColumnLayout {
                            id: historyColumn
                            width: historyList.width
                            spacing: 12
                            Repeater {
                                model: root.historyGroups
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        text: modelData.name + " · " + modelData.items.length
                                        color: root.colors.cMuted
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Repeater {
                                        model: modelData.items
                                        delegate: NotificationPopup {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            notification: modelData
                                            colors: root.colors
                                            popup: false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
