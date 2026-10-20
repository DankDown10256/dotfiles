
import QtQuick

QtObject {
    id: colors

    // Scheme actif :
    // quattro, github-dark, catppuccin, warm, e-ink, claude-light
    property string scheme: "quattro"

    readonly property var availableSchemes: [
        { id: "quattro", name: "Quattro" },
        { id: "github-dark", name: "GitHub Dark" },
        { id: "catppuccin", name: "Catppuccin Mocha" },
        { id: "warm", name: "Warm Dark" },
        { id: "e-ink", name: "E-Ink" },
        { id: "claude-light", name: "Claude Light" }
    ]

    readonly property color qtBg: "#111315"
    readonly property color qtSurface: "#191c1e"
    readonly property color qtElevated: "#23272a"
    readonly property color qtSelection: "#30363a"
    readonly property color qtAccent: "#d9a46c"
    readonly property color qtText: "#ebe9e4"
    readonly property color qtMuted: "#9a9b99"
    readonly property color qtBorder: "#353a3d"
    readonly property color qtDanger: "#e07570"
    readonly property color qtSuccess: "#9fc49b"
    readonly property color qtWarning: "#deb76d"

    function setScheme(name) {
        for (const item of availableSchemes) {
            if (item.id === name) {
                scheme = name
                return true
            }
        }
        return false
    }

    // ============================================================
    // GitHub Dark
    // ============================================================

    readonly property color ghBg:       "#0d1117"
    readonly property color ghSurface:  "#161b22"
    readonly property color ghElevated: "#21262d"
    readonly property color ghSelection:"#30363d"
    readonly property color ghAccent:   "#58a6ff"
    readonly property color ghText:     "#e6edf3"
    readonly property color ghMuted:    "#8b949e"
    readonly property color ghBorder:   "#30363d"
    readonly property color ghDanger:   "#f85149"
    readonly property color ghSuccess:  "#3fb950"
    readonly property color ghWarning:  "#d29922"

    // ============================================================
    // Catppuccin Mocha
    // ============================================================

    readonly property color ccBg:       "#1e1e2e"
    readonly property color ccSurface:  "#181825"
    readonly property color ccElevated: "#313244"
    readonly property color ccSelection:"#45475a"
    readonly property color ccAccent:   "#cba6f7"
    readonly property color ccText:     "#cdd6f4"
    readonly property color ccMuted:    "#a6adc8"
    readonly property color ccBorder:   "#45475a"
    readonly property color ccDanger:   "#f38ba8"
    readonly property color ccSuccess:  "#a6e3a1"
    readonly property color ccWarning:  "#f9e2af"

    // ============================================================
    // Warm Dark
    // ============================================================

    readonly property color wdBg:       "#1f1a17"
    readonly property color wdSurface:  "#2d241f"
    readonly property color wdElevated: "#392d26"
    readonly property color wdSelection:"#49372d"
    readonly property color wdAccent:   "#d97757"
    readonly property color wdText:     "#f0e6d8"
    readonly property color wdMuted:    "#a08b7a"
    readonly property color wdBorder:   "#49372d"
    readonly property color wdDanger:   "#e5534b"
    readonly property color wdSuccess:  "#a3b86c"
    readonly property color wdWarning:  "#e6b566"

    // ============================================================
    // E-Ink
    // ============================================================

    readonly property color eiBg:       "#f2f0e9"
    readonly property color eiSurface:  "#e7e5de"
    readonly property color eiElevated: "#d8d6cf"
    readonly property color eiSelection:"#c8c6bf"
    readonly property color eiAccent:   "#292929"
    readonly property color eiText:     "#171717"
    readonly property color eiMuted:    "#64645f"
    readonly property color eiBorder:   "#aaa9a2"
    readonly property color eiDanger:   "#5b2929"
    readonly property color eiSuccess:  "#354735"
    readonly property color eiWarning:  "#655126"

    // ============================================================
    // Claude Light
    // ============================================================

    readonly property color clBg:       "#faf9f5"
    readonly property color clSurface:  "#ffffff"
    readonly property color clElevated: "#f1eee8"
    readonly property color clSelection:"#e8e2d9"
    readonly property color clAccent:   "#c15f3c"
    readonly property color clText:     "#292724"
    readonly property color clMuted:    "#858078"
    readonly property color clBorder:   "#e5e0d7"
    readonly property color clDanger:   "#c44638"
    readonly property color clSuccess:  "#527653"
    readonly property color clWarning:  "#a87524"

    // ============================================================
    // Active palette
    // ============================================================

    readonly property color cBg:
        scheme === "quattro" ? qtBg :
        scheme === "catppuccin" ? ccBg :
        scheme === "warm" ? wdBg :
        scheme === "e-ink" ? eiBg :
        scheme === "claude-light" ? clBg : ghBg

    readonly property color cSurface:
        scheme === "quattro" ? qtSurface :
        scheme === "catppuccin" ? ccSurface :
        scheme === "warm" ? wdSurface :
        scheme === "e-ink" ? eiSurface :
        scheme === "claude-light" ? clSurface : ghSurface

    readonly property color cElevated:
        scheme === "quattro" ? qtElevated :
        scheme === "catppuccin" ? ccElevated :
        scheme === "warm" ? wdElevated :
        scheme === "e-ink" ? eiElevated :
        scheme === "claude-light" ? clElevated : ghElevated

    readonly property color cSelection:
        scheme === "quattro" ? qtSelection :
        scheme === "catppuccin" ? ccSelection :
        scheme === "warm" ? wdSelection :
        scheme === "e-ink" ? eiSelection :
        scheme === "claude-light" ? clSelection : ghSelection

    readonly property color cAccent:
        scheme === "quattro" ? qtAccent :
        scheme === "catppuccin" ? ccAccent :
        scheme === "warm" ? wdAccent :
        scheme === "e-ink" ? eiAccent :
        scheme === "claude-light" ? clAccent : ghAccent

    readonly property color cText:
        scheme === "quattro" ? qtText :
        scheme === "catppuccin" ? ccText :
        scheme === "warm" ? wdText :
        scheme === "e-ink" ? eiText :
        scheme === "claude-light" ? clText : ghText

    readonly property color cMuted:
        scheme === "quattro" ? qtMuted :
        scheme === "catppuccin" ? ccMuted :
        scheme === "warm" ? wdMuted :
        scheme === "e-ink" ? eiMuted :
        scheme === "claude-light" ? clMuted : ghMuted

    readonly property color cBorder:
        scheme === "quattro" ? qtBorder :
        scheme === "catppuccin" ? ccBorder :
        scheme === "warm" ? wdBorder :
        scheme === "e-ink" ? eiBorder :
        scheme === "claude-light" ? clBorder : ghBorder

    readonly property color cDanger:
        scheme === "quattro" ? qtDanger :
        scheme === "catppuccin" ? ccDanger :
        scheme === "warm" ? wdDanger :
        scheme === "e-ink" ? eiDanger :
        scheme === "claude-light" ? clDanger : ghDanger

    readonly property color cSuccess:
        scheme === "quattro" ? qtSuccess :
        scheme === "catppuccin" ? ccSuccess :
        scheme === "warm" ? wdSuccess :
        scheme === "e-ink" ? eiSuccess :
        scheme === "claude-light" ? clSuccess : ghSuccess

    readonly property color cWarning:
        scheme === "quattro" ? qtWarning :
        scheme === "catppuccin" ? ccWarning :
        scheme === "warm" ? wdWarning :
        scheme === "e-ink" ? eiWarning :
        scheme === "claude-light" ? clWarning : ghWarning
}
