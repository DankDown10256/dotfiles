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
    }

    Launcher {
      colors: colors
      barInset: desktopBar.barVisible ? 40 : 0
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
    }

    SessionLock { colors: colors }

    Utilities { colors: colors }

    ShortcutBindings {}
    
    ControlCenter {
      id: controlCenter
      colors: colors
      notifications: notificationCenter
      barInset: desktopBar.barVisible ? 32 : 0
    }
    Bar {
      id: desktopBar
      colors: colors
      panels: systemPanels
      notifications: notificationCenter
      capture: captureMenu
      controlCenter: controlCenter
    }
    ThemeSwitcher {
      colors: colors
    } 
    ScreenHotspots {
      colors: colors
      controlCenter: controlCenter
      barVisible: desktopBar.barVisible
    }
}
