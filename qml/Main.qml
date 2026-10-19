import QtQuick
import QtQuick.Window
import QtQuick.Controls
import org.kde.layershell as LayerShell

Window {
    id: mainWindow

    visible: true
    title: "Zatsu Focus"
    color: "#000000"

    // Set frameless window on Wayland & X11
    flags: Qt.Window | Qt.FramelessWindowHint

    // Prevent minimizing or hiding so Zatsu acts as true desktop environment
    onVisibilityChanged: function() {
        if (mainWindow.visibility === Window.Minimized || mainWindow.visibility === Window.Hidden) {
            mainWindow.showFullScreen()
            if (systemService) {
                systemService.ensureDesktopWindowBottom()
            }
        }
    }

    Component.onCompleted: {
        if (systemService) {
            systemService.ensureDesktopWindowBottom()
        }
    }

    // Breeze Theme instance
    BreezeTheme {
        id: breezeTheme
    }

    // --- Popup Toggle Helpers ---

    function toggleMenu() {
        if (zatsuMenu.visible) {
            zatsuMenu.close()
        } else {
            closeAllPopups()
            zatsuMenu.x = 8
            zatsuMenu.y = Math.max(8, focusPanel.y - zatsuMenu.height - 8)
            zatsuMenu.open()
        }
    }

    function toggleQuickRunner() {
        if (quickRunner.visible) {
            quickRunner.close()
        } else {
            closeAllPopups()
            quickRunner.x = Math.max(8, (mainWindow.width - quickRunner.width) / 2)
            quickRunner.y = Math.max(8, (mainWindow.height - quickRunner.height) / 3)
            quickRunner.open()
        }
    }

    function toggleVolume() {
        if (volumePopup.visible) {
            volumePopup.close()
        } else {
            closeAllPopups()
            volumePopup.x = Math.max(16, focusPanel.width - 290)
            volumePopup.y = Math.max(8, focusPanel.y - volumePopup.height - 8)
            volumePopup.open()
        }
    }

    function toggleCalendar() {
        if (calendarPopup.visible) {
            calendarPopup.close()
        } else {
            closeAllPopups()
            calendarPopup.x = Math.max(16, focusPanel.width - calendarPopup.width - 12)
            calendarPopup.y = Math.max(8, focusPanel.y - calendarPopup.height - 8)
            calendarPopup.open()
        }
    }

    function toggleMiniPlayer() {
        if (miniPlayerPopup.visible) {
            miniPlayerPopup.close()
        } else {
            closeAllPopups()
            miniPlayerPopup.x = Math.max(16, focusPanel.width - 400)
            miniPlayerPopup.y = Math.max(8, focusPanel.y - miniPlayerPopup.height - 8)
            miniPlayerPopup.open()
        }
    }

    function toggleScratchpad() {
        if (scratchpadPopup.visible) {
            scratchpadPopup.close()
        } else {
            closeAllPopups()
            scratchpadPopup.x = Math.max(16, (mainWindow.width - scratchpadPopup.width) / 2)
            scratchpadPopup.y = Math.max(16, (mainWindow.height - scratchpadPopup.height) / 2)
            scratchpadPopup.open()
        }
    }

    function toggleClipboard() {
        if (clipboardPopup.visible) {
            clipboardPopup.close()
        } else {
            closeAllPopups()
            clipboardPopup.x = Math.max(16, focusPanel.width - clipboardPopup.width - 90)
            clipboardPopup.y = Math.max(8, focusPanel.y - clipboardPopup.height - 8)
            clipboardPopup.open()
        }
    }

    function closeAllPopups() {
        zatsuMenu.close()
        quickRunner.close()
        volumePopup.close()
        calendarPopup.close()
        miniPlayerPopup.close()
        scratchpadPopup.close()
        clipboardPopup.close()
        addAppDialog.close()
    }

    // --- Dynamic Configurable Keyboard Shortcuts ---

    // 1. Zatsu Application Launcher Menu
    Shortcut {
        sequences: [
            (config && config.hotkeyMenu) ? config.hotkeyMenu : "Alt+F1",
            "Alt+F1"
        ]
        onActivated: mainWindow.toggleMenu()
    }

    // 2. Quick Runner (Command Palette & Calculator)
    Shortcut {
        sequences: [
            (config && config.hotkeyQuickRunner) ? config.hotkeyQuickRunner : "Meta+F",
            "Ctrl+Space"
        ]
        onActivated: mainWindow.toggleQuickRunner()
    }

    // 3. Switch Keyboard Layout (Language)
    Shortcut {
        sequences: [
            (config && config.hotkeyLayoutSwitch) ? config.hotkeyLayoutSwitch : "Alt+Shift",
            "Shift+Alt",
            "Ctrl+Shift",
            "Meta+Space"
        ]
        onActivated: {
            if (systemService) systemService.nextKeyboardLayout()
        }
    }

    // 4. Lock Screen
    Shortcut {
        sequences: [
            (config && config.hotkeyLockScreen) ? config.hotkeyLockScreen : "Meta+L",
            "Ctrl+Alt+L"
        ]
        onActivated: {
            if (systemService) systemService.lockScreen()
        }
    }

    // 5. Strict Mode Toggle
    Shortcut {
        sequences: [
            (config && config.hotkeyStrictMode) ? config.hotkeyStrictMode : "Meta+S"
        ]
        onActivated: {
            if (config) {
                config.strictMode = !config.strictMode
            }
        }
    }

    // 6. Reset Session Timer
    Shortcut {
        sequences: [
            (config && config.hotkeyResetTimer) ? config.hotkeyResetTimer : "Meta+R"
        ]
        onActivated: {
            if (systemService) systemService.reset_timer()
        }
    }

    // 7. Clipboard History (Klipper)
    Shortcut {
        sequences: [
            (config && config.hotkeyClipboard) ? config.hotkeyClipboard : "Meta+V",
            "Ctrl+Alt+V"
        ]
        onActivated: {
            if (systemService) systemService.openKlipper()
        }
    }

    // 8. Session Scratchpad Quick Notes
    Shortcut {
        sequences: [
            (config && config.hotkeyScratchpad) ? config.hotkeyScratchpad : "Meta+N",
            "Ctrl+Alt+N"
        ]
        onActivated: mainWindow.toggleScratchpad()
    }

    // 9. Floating Mini-Timer Widget
    Shortcut {
        sequences: [
            (config && config.hotkeyMiniTimer) ? config.hotkeyMiniTimer : "Meta+T",
            "Ctrl+Alt+T"
        ]
        onActivated: {
            if (config) config.showMiniTimer = !config.showMiniTimer
        }
    }

    // 10. Escape (Close active popups)
    Shortcut {
        sequence: "Escape"
        onActivated: mainWindow.closeAllPopups()
    }

    // Connect to layout-independent hotkey signals from GlobalKeyFilter in systemService
    Connections {
        target: systemService ? systemService : null
        function onMetaKeyTriggered() {
            mainWindow.toggleMenu()
        }
        function onMenuRequested() {
            mainWindow.toggleMenu()
        }
        function onQuickRunnerRequested() {
            mainWindow.toggleQuickRunner()
        }
        function onLayoutSwitchRequested() {
            if (systemService) systemService.nextKeyboardLayout()
        }
        function onLockScreenRequested() {
            if (systemService) systemService.lockScreen()
        }
        function onStrictModeToggleRequested() {
            if (config) config.strictMode = !config.strictMode
        }
        function onResetTimerRequested() {
            if (systemService) systemService.reset_timer()
        }
        function onClipboardRequested() {
            if (systemService) systemService.openKlipper()
        }
        function onScratchpadRequested() {
            mainWindow.toggleScratchpad()
        }
        function onMiniTimerRequested() {
            if (config) config.showMiniTimer = !config.showMiniTimer
        }
    }

    // =========================================================================
    // 1. FOCUS DESKTOP SURFACE (Wallpaper, Desktop Shortcuts & KDE 6 Widgets)
    // =========================================================================
    FocusDesktop {
        id: focusDesktop
        anchors.fill: parent
        anchors.bottomMargin: focusPanel.scaledHeight

        onOpenSettingsRequested: {
            mainWindow.toggleMenu()
        }

        onAddAppRequested: {
            addAppDialog.targetMode = "desktop"
            addAppDialog.open()
        }

        onChangeWallpaperRequested: {
            if (mainController) {
                mainController.pick_custom_wallpaper_dialog()
            }
        }
    }

    // =========================================================================
    // 2. FOCUS TASK PANEL (Solidly anchored to bottom of display)
    // =========================================================================
    FocusPanel {
        id: focusPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 10

        onToggleZatsuMenu: mainWindow.toggleMenu()
        onToggleMiniPlayer: mainWindow.toggleMiniPlayer()
        onOpenTimerSettings: mainWindow.toggleMenu()
        onToggleCalendar: mainWindow.toggleCalendar()
        onToggleVolume: mainWindow.toggleVolume()
        onToggleScratchpad: mainWindow.toggleScratchpad()
        onToggleClipboard: mainWindow.toggleClipboard()
        onToggleMiniTimer: {
            if (config) config.showMiniTimer = !config.showMiniTimer
        }
    }

    // =========================================================================
    // 3. POPUPS & OVERLAYS (Anchored relative to FocusPanel & Screen)
    // =========================================================================

    // 1. Zatsu Launcher Menu Popup
    ZatsuMenu {
        id: zatsuMenu
        parent: mainWindow.contentItem
        z: 50

        onRequestAddApp: function(mode) {
            addAppDialog.targetMode = mode
            addAppDialog.open()
        }

        onRequestChangeWallpaper: {
            if (mainController) {
                mainController.pick_custom_wallpaper_dialog()
            }
        }
    }

    // 2. MPRIS Mini Player with Lyrics Popup
    MiniPlayerPopup {
        id: miniPlayerPopup
        parent: mainWindow.contentItem
        z: 50
    }

    // 3. Breeze Calendar Popup
    CalendarPopup {
        id: calendarPopup
        parent: mainWindow.contentItem
        z: 50
    }

    // 4. Volume Control Popup
    VolumePopup {
        id: volumePopup
        parent: mainWindow.contentItem
        z: 50
    }

    // 5. Add App Dialog
    AddAppDialog {
        id: addAppDialog
        parent: mainWindow.contentItem
        z: 60
    }

    // 6. Quick Runner (KRunner / Spotlight style) Modal Popup
    QuickRunner {
        id: quickRunner
        parent: mainWindow.contentItem
        z: 100
    }

    // 7. Session Scratchpad Quick Notes Popup
    ScratchpadPopup {
        id: scratchpadPopup
        parent: mainWindow.contentItem
        z: 70
    }

    // 8. Klipper Clipboard History Popup
    ClipboardPopup {
        id: clipboardPopup
        parent: mainWindow.contentItem
        z: 70
    }

    // 9. Always-on-top Mini-Timer Floating Overlay
    MiniTimerOverlay {
        id: miniTimerOverlay
    }

    // 10. Native Wayland LayerShell Panel Strut Window (Reserves bottom taskbar exclusion zone)
    Window {
        id: panelStrutWindow
        visible: Qt.platform.pluginName.indexOf("wayland") !== -1
        width: Screen.width
        height: Math.max(1, Math.round(focusPanel.scaledHeight))
        color: "transparent"
        flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput

        LayerShell.Window.layer: LayerShell.Window.LayerBottom
        LayerShell.Window.anchors: LayerShell.Window.AnchorBottom | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: Math.round(focusPanel.scaledHeight)
    }
}
