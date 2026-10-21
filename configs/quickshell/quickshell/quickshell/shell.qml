import Quickshell
import "."

Scope {
    id: root

    Colors {
      id: colors
    }

    Notifications {
      id: notificationCenter
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    }

    Launcher {
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    } 

    WorkspaceOverview {
      colors: colors
    }

    DevTools {
      colors: colors
    }

    ClipboardHistory {
      colors: colors
    }

    CaptureMenu {
      id: captureMenu
      colors: colors
    }

    SystemPanels {
      id: systemPanels
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    }

    SessionLock { colors: colors }

    Utilities { colors: colors }

    ShortcutBindings {}
    
    ControlCenter {
      id: controlCenter
      colors: colors
      notifications: notificationCenter
      barInset: desktopBar.barVisible ? 30 : 0
    }
    Bar {
      id: desktopBar
      colors: colors
      panels: systemPanels
      notifications: notificationCenter
      capture: captureMenu
      controlCenter: controlCenter
    }
    ScreenHotspots {
      colors: colors
      controlCenter: controlCenter
      barVisible: desktopBar.barVisible
    }
}
