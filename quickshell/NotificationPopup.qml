import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property Notification notification

    width: 360
    implicitHeight: mainLayout.height + 24
    color: "#2d241f"
    radius: 12
    border.color: "#433025"
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.notification.summary
                font.pixelSize: 13
                font.bold: true
                color: "#f0e6d8"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "\uF00D" // Icône croix (Nerd Font)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: "#a08b7a"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.notification.dismiss()
                }
            }
        }

        Text {
            text: root.notification.body
            font.pixelSize: 12
            color: "#a08b7a"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.notification.dismiss()
    }
}
