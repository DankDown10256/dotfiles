import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Rectangle {
    id: root

    required property Notification notification
    required property var colors
    property bool popup: true
    property bool shown: !popup
    signal expired()

    width: 320
    implicitHeight: mainLayout.implicitHeight + 28
    color: root.colors.cSurface
    radius: 9
    border.color: Qt.alpha(root.colors.cBorder, 0.65)
    border.width: 1
    opacity: shown ? 1 : 0

    Component.onCompleted: Qt.callLater(() => shown = true)

    Behavior on opacity {
        NumberAnimation {
            duration: root.shown ? 200 : 160
            easing.type: Easing.OutCubic
        }
    }

    transform: Translate {
        x: root.shown ? 0 : 8

        Behavior on x {
            NumberAnimation {
                duration: root.shown ? 200 : 160
                easing.type: Easing.OutCubic
            }
        }
    }

    HoverHandler { id: popupHover }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            IconImage {
                implicitSize: 17
                source: Quickshell.iconPath(root.notification.appIcon || root.notification.desktopEntry || "application-x-executable")
            }
            Text {
                Layout.fillWidth: true
                text: root.notification.appName
                textFormat: Text.PlainText
                visible: text.length > 0
                font.family: "sans-serif"
                font.pixelSize: 11
                color: root.colors.cMuted
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.notification.summary
                textFormat: Text.PlainText
                font.family: "sans-serif"
                font.pixelSize: 13
                font.bold: true
                color: root.colors.cText
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "\uF00D"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: closeMouse.containsMouse
                    ? root.colors.cText : root.colors.cMuted

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    onClicked: root.notification.dismiss()
                }
            }
        }

        Text {
            text: root.notification.body
            textFormat: Text.PlainText
            font.family: "sans-serif"
            font.pixelSize: 12
            color: root.colors.cMuted
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            maximumLineCount: root.popup ? 4 : 12
            elide: Text.ElideRight
            visible: text.length > 0
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: root.notification.actions.length > 0

            Repeater {
                model: root.notification.actions

                delegate: Rectangle {
                    required property var modelData
                    width: Math.min(actionText.implicitWidth + 24, mainLayout.width)
                    height: 32
                    radius: 8
                    color: actionMouse.containsMouse
                        ? root.colors.cSelection : root.colors.cElevated

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        width: parent.width - 24
                        text: modelData.text
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "sans-serif"
                        font.pixelSize: 12
                        color: root.colors.cText
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }

    Timer {
        interval: root.notification.expireTimeout > 0
            ? root.notification.expireTimeout : 5000
        running: root.popup && root.shown && !popupHover.hovered
            && root.notification.expireTimeout !== 0
            && root.notification.urgency !== NotificationUrgency.Critical
        onTriggered: root.shown = false
    }

    Timer {
        interval: 160
        running: root.popup && !root.shown
        onTriggered: root.expired()
    }
}
