import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root
    required property var colors
    property string status: ""
    property string pendingPassword: ""
    property bool suspendPending: false

    function lockSession() {
        status = ""
        sessionLock.locked = true
    }
    function suspendSession() {
        suspendPending = true
        lockSession()
        if (sessionLock.secure) {
            suspendPending = false
            Quickshell.execDetached(["systemctl", "suspend"])
        }
    }
    function authenticate(password) {
        if (!password) return
        if (pam.active) {
            if (pam.responseRequired) pam.respond(password)
            else pendingPassword = password
            return
        }
        pendingPassword = password
        status = "Authentification…"
        if (!pam.start()) {
            pendingPassword = ""
            status = "PAM indisponible"
        }
    }

    IpcHandler {
        target: "session"
        function lock(): void { root.lockSession() }
        function suspend(): void { root.suspendSession() }
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: {
            if (responseRequired && root.pendingPassword !== "") {
                respond(root.pendingPassword)
                root.pendingPassword = ""
            } else if (message) root.status = message
        }
        onCompleted: result => {
            root.pendingPassword = ""
            if (result === PamResult.Success) {
                root.status = ""
                sessionLock.unlock()
            } else root.status = result === PamResult.Failed
                ? "Mot de passe incorrect" : "Erreur d’authentification"
        }
        onError: root.status = "Erreur d’authentification"
    }

    WlSessionLock {
        id: sessionLock
        onSecureStateChanged: {
            if (secure && root.suspendPending) {
                root.suspendPending = false
                Quickshell.execDetached(["systemctl", "suspend"])
            }
        }

        WlSessionLockSurface {
            color: root.colors.cBg

            Rectangle {
                anchors.fill: parent
                color: root.colors.cBg

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(360, parent.width - 24)
                    height: 216
                    radius: 6
                    color: root.colors.cSurface
                    border.width: 1
                    border.color: root.colors.cBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: ""
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: root.colors.cAccent
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Quickshell.env("USER") || "Session"
                            color: root.colors.cText
                            font.pixelSize: 14
                            font.bold: true
                        }
                        TextField {
                            id: password
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            font.pixelSize: 13
                            placeholderText: "Mot de passe"
                            placeholderTextColor: root.colors.cMuted
                            echoMode: TextInput.Password
                            color: root.colors.cText
                            onAccepted: {
                                root.authenticate(text)
                                clear()
                            }
                            background: Rectangle {
                                radius: 6
                                color: root.colors.cElevated
                                border.width: 1
                                border.color: password.activeFocus ? root.colors.cAccent : root.colors.cBorder
                            }
                            Component.onCompleted: forceActiveFocus()
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.status || Qt.formatDateTime(new Date(), "dddd d MMMM · HH:mm")
                            color: root.status ? root.colors.cWarning : root.colors.cMuted
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
