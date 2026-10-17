#!/usr/bin/env python3
"""
Zatsu Focus - Autonomous Minimalist Focus Environment for Linux / KDE Plasma 6.
EndeavourOS / Arch Linux (Wayland & X11).
"""

import os
import sys
import argparse
import logging
import subprocess
from typing import Optional

from qt_compat import (
    QApplication, QGuiApplication, QQmlApplicationEngine, QUrl,
    QObject, Slot, Signal, Property, Qt, QFileDialog, QIcon, QtCore
)

from config import ConfigManager
from desktop_scanner import DesktopScanner
from blocker import ProcessBlocker
from mpris_service import MprisService
from system_service import SystemService
from shell_manager import ShellManager
from icon_provider import BreezeIconProvider

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(name)s]: %(message)s"
)
logger = logging.getLogger("zatsu.main")


class GlobalKeyFilter(QObject):
    """
    Application-level event filter to reliably intercept standalone Meta (Super) key taps.
    """
    def __init__(self, system_service, parent=None):
        super().__init__(parent)
        self.system_svc = system_service
        self._meta_pressed = False
        self._other_key_pressed = False

    def eventFilter(self, obj, event):
        t = event.type()
        if t == QtCore.QEvent.Type.KeyPress:
            key = event.key()
            if key in (Qt.Key.Key_Super_L, Qt.Key.Key_Super_R, Qt.Key.Key_Meta):
                self._meta_pressed = True
                self._other_key_pressed = False
            else:
                self._other_key_pressed = True
        elif t == QtCore.QEvent.Type.KeyRelease:
            key = event.key()
            if key in (Qt.Key.Key_Super_L, Qt.Key.Key_Super_R, Qt.Key.Key_Meta):
                if self._meta_pressed and not self._other_key_pressed:
                    self._meta_pressed = False
                    logger.info("[zatsu.keyfilter]: Standalone Meta key tap detected -> emitting metaKeyTriggered")
                    self.system_svc.metaKeyTriggered.emit()
                    return True
                self._meta_pressed = False
        return super().eventFilter(obj, event)


class MainController(QObject):
    """
    Glue controller exposing dialogs and system operations to QML.
    """
    wallpaperChanged = Signal(str)

    def __init__(self, config_manager, desktop_scanner, system_service, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self.scanner = desktop_scanner
        self.system_svc = system_service

    @Slot()
    def pick_custom_wallpaper_dialog(self):
        """Opens native file picker to select custom wallpaper image."""
        home = os.path.expanduser("~")
        filePath, _ = QFileDialog.getOpenFileName(
            None,
            "Выберите обои рабочего стола",
            home,
            "Изображения (*.png *.jpg *.jpeg *.webp *.svg)"
        )
        if filePath and os.path.exists(filePath):
            logger.info("Custom wallpaper selected: %s", filePath)
            self.config.set("wallpaper_mode", "custom")
            self.config.set("custom_wallpaper_path", filePath)
            self.system_svc.wallpaperChanged.emit()
            self.wallpaperChanged.emit(filePath)

    @Slot(str)
    def pick_custom_file_dialog(self, target_mode: str = "desktop"):
        """Opens native file picker to select an arbitrary executable or script."""
        home = os.path.expanduser("~")
        filePath, _ = QFileDialog.getOpenFileName(
            None,
            "Выберите исполняемый файл или скрипт",
            home,
            "Все файлы (*)"
        )
        if filePath and os.path.exists(filePath):
            app_data = self.scanner.parse_custom_binary(filePath)
            if app_data:
                if target_mode == "desktop":
                    self.config.addShortcut(
                        app_data["id"],
                        app_data["name"],
                        app_data["exec"],
                        app_data["icon"],
                        app_data["category"],
                        48, 48
                    )
                else:
                    self.config.addBackgroundApp(app_data["binary"])


def main():
    parser = argparse.ArgumentParser(description="Zatsu Focus Environment for Linux / KDE Plasma 6")
    parser.add_argument("--strict", action="store_true", help="Start immediately in Strict Mode")
    parser.add_argument("--no-plasma-stop", action="store_true", help="Do not stop plasma-plasmashell.service (run as overlay)")
    parser.add_argument("--no-blackout", action="store_true", help="Disable secondary display blackout")
    parser.add_argument("--duration", type=int, default=None, help="Session duration in minutes")
    parser.add_argument("--windowed", action="store_true", help="Run windowed (e.g. for testing) instead of fullscreen")
    args = parser.parse_args()

    # Create Qt Application (QApplication is required for QFileDialog)
    app = QApplication(sys.argv)
    app.setApplicationName("Zatsu Focus")
    app.setOrganizationName("Zatsu")
    app.setDesktopFileName("zatsu-focus")

    # Prevent KDE session manager from re-launching Zatsu across reboot!
    if hasattr(app, "setFallbackSessionManagementEnabled"):
        app.setFallbackSessionManagementEnabled(False)

    if any("-session" in arg for arg in sys.argv) or (hasattr(app, "isSessionRestored") and app.isSessionRestored()):
        logger.warning("Session was restored by KDE session manager after reboot. Restoring Plasma and exiting.")
        subprocess.run(["systemctl", "--user", "start", "plasma-plasmashell.service"])
        sys.exit(0)

    # Tell ksmserver never to save Zatsu in session
    try:
        subprocess.run(["kwriteconfig6", "--file", "ksmserverrc", "--group", "General", "--key", "excludeApps", "zatsu-focus,main.py,python3"], stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # Set icon theme to breeze-dark (crisp white monochrome icons for dark surfaces)
    if os.path.exists("/usr/share/icons/breeze-dark"):
        QIcon.setThemeName("breeze-dark")
    else:
        QIcon.setThemeName("breeze")

    # Initialize Core Services
    config_mgr = ConfigManager()

    if args.strict:
        config_mgr.strictMode = True
    if args.no_blackout:
        config_mgr.oledSecondaryBlackout = False
    if args.duration:
        config_mgr.set("session_duration_minutes", args.duration)

    scanner = DesktopScanner()
    mpris = MprisService()
    system_svc = SystemService(config_mgr)
    blocker = ProcessBlocker(config_mgr, system_svc, desktop_scanner=scanner)
    main_ctrl = MainController(config_mgr, scanner, system_svc)

    # QML Engine Setup
    engine = QQmlApplicationEngine()

    # Register Icon Image Provider
    engine.addImageProvider("icon", BreezeIconProvider())

    # Shell Manager
    shell_mgr = ShellManager(config_mgr, engine)

    # Expose Objects to QML Context
    root_context = engine.rootContext()
    root_context.setContextProperty("config", config_mgr)
    root_context.setContextProperty("desktopScanner", scanner)
    root_context.setContextProperty("blocker", blocker)
    root_context.setContextProperty("mpris", mpris)
    root_context.setContextProperty("systemService", system_svc)
    root_context.setContextProperty("shellManager", shell_mgr)
    root_context.setContextProperty("mainController", main_ctrl)

    # Install Global Key Filter for Meta (Super) key
    key_filter = GlobalKeyFilter(system_svc)
    app.installEventFilter(key_filter)

    # Load Main QML Window
    base_dir = os.path.dirname(os.path.abspath(__file__))
    qml_file = os.path.join(base_dir, "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        logger.error("Failed to load QML interface.")
        sys.exit(1)

    main_win = engine.rootObjects()[0]

    # Configure Screen Geometry
    primary_screen = app.primaryScreen()
    if primary_screen:
        geom = primary_screen.geometry()
        if args.windowed:
            main_win.setWidth(1280)
            main_win.setHeight(800)
            main_win.setX(geom.x() + 50)
            main_win.setY(geom.y() + 50)
            main_win.show()
        else:
            main_win.setScreen(primary_screen)
            main_win.setGeometry(geom)
            main_win.showFullScreen()
    else:
        main_win.showFullScreen()

    # Start Background Blocker Daemon
    blocker.start()

    # Activate Focus Mode Shell (stops plasma-plasmashell if requested)
    if not args.no_plasma_stop:
        shell_mgr.activate_focus_mode()

    logger.info("Zatsu Focus started successfully.")

    # Execute Qt event loop
    ret = app.exec()

    # Clean up
    blocker.stop()
    shell_mgr.restore_plasma()
    sys.exit(ret)


if __name__ == "__main__":
    main()
