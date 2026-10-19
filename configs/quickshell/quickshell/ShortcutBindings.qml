import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    readonly property var bindings: [
        { key: "C", name: "clipboard" },
        { key: "E", name: "emoji" },
        { key: "F", name: "files" },
        { key: "G", name: "capture" },
        { key: "R", name: "record" },
        { key: "L", modifiers: "SUPER", name: "lock" },
        { key: "M", name: "power" },
        { key: "A", name: "audio" }
    ]

    function install() {
        const commands = []
        for (const binding of bindings) {
            const modifiers = binding.modifiers || "SUPER SHIFT"
            commands.push("keyword unbind " + modifiers + ", " + binding.key)
            commands.push("keyword bind " + modifiers + ", " + binding.key
                + ", global, quickshell-dev:" + binding.name)
        }
        Quickshell.execDetached(["hyprctl", "--batch", commands.join(" ; ")])
    }
    function call(target, method) {
        Quickshell.execDetached(["qs", "ipc", "call", target, method])
    }

    Timer { id: installTimer; interval: 400; onTriggered: root.install() }
    Component.onCompleted: installTimer.start()
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") installTimer.restart()
        }
    }

    GlobalShortcut { appid: "quickshell-dev"; name: "clipboard"; description: "Historique du presse-papiers"; onPressed: root.call("clipboard", "toggle") }
    GlobalShortcut { appid: "quickshell-dev"; name: "emoji"; description: "Sélecteur d’émojis"; onPressed: root.call("utilities", "emoji") }
    GlobalShortcut { appid: "quickshell-dev"; name: "files"; description: "Sélecteur de fichiers"; onPressed: root.call("utilities", "files") }
    GlobalShortcut { appid: "quickshell-dev"; name: "capture"; description: "Capture d’écran"; onPressed: root.call("capture", "toggle") }
    GlobalShortcut { appid: "quickshell-dev"; name: "record"; description: "Enregistrement d’écran"; onPressed: root.call("capture", "record") }
    GlobalShortcut { appid: "quickshell-dev"; name: "lock"; description: "Verrouiller la session"; onPressed: root.call("session", "lock") }
    GlobalShortcut { appid: "quickshell-dev"; name: "power"; description: "Menu d’alimentation"; onPressed: root.call("utilities", "power") }
    GlobalShortcut { appid: "quickshell-dev"; name: "audio"; description: "Panneau audio"; onPressed: root.call("systempanels", "audio") }
}
