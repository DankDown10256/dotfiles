import Quickshell
import "quickshell" as Desktop

Scope {
    id: root

    Desktop.Colors {
      id: colors
    }

    Desktop.Notifications {
      id: notificationCenter
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    }

    Desktop.Launcher {
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    } 

    Desktop.WorkspaceOverview {
      colors: colors
    }

    Desktop.DevTools {
      colors: colors
    }

    Desktop.ClipboardHistory {
      colors: colors
    }

    Desktop.CaptureMenu {
      id: captureMenu
      colors: colors
    }

    Desktop.SystemPanels {
      id: systemPanels
      colors: colors
      barInset: desktopBar.barVisible ? 30 : 0
    }

    Desktop.SessionLock { colors: colors }

    Desktop.Utilities { colors: colors }

    
    Desktop.ControlCenter {
      id: controlCenter
      colors: colors
      notifications: notificationCenter
      barInset: desktopBar.barVisible ? 30 : 0
    }
    Desktop.Bar {
      id: desktopBar
      colors: colors
      panels: systemPanels
      notifications: notificationCenter
      capture: captureMenu
      controlCenter: controlCenter
    }
    Desktop.ScreenHotspots {
      colors: colors
      controlCenter: controlCenter
      barVisible: desktopBar.barVisible
    }
}
