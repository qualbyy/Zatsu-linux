"""
Shell and Multi-Monitor Manager for Zatsu Focus.
Manages stopping/starting plasma-plasmashell.service via systemctl,
coordinates primary desktop screen and secondary OLED blackout displays.
"""

import os
import atexit
import signal
import logging
import subprocess
import time
import psutil
from typing import List, Optional
from qt_compat import (
    QObject, Signal, Slot, Property, QGuiApplication, QScreen,
    QQmlComponent, QQuickView, QUrl, Qt, QRect
)

logger = logging.getLogger("zatsu.shell")


class ShellManager(QObject):
    """
    Coordinates the desktop environment lifecycle:
    - Stops/restores plasma-plasmashell.service
    - Creates blackout overlay windows on secondary monitors
    - Handles screen connect/disconnect events
    """
    screensChanged = Signal()
    plasmaRestored = Signal()

    def __init__(self, config_manager, qml_engine, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self.engine = qml_engine
        self._plasma_was_active = False
        self._blackout_windows: List[Any] = []
        self._is_active = False

        # Register exit handler to ensure Plasma is ALWAYS restored
        atexit.register(self.restore_plasma)
        signal.signal(signal.SIGINT, self._handle_signal)
        signal.signal(signal.SIGTERM, self._handle_signal)
        if hasattr(signal, "SIGHUP"):
            signal.signal(signal.SIGHUP, self._handle_signal)

        # Monitor screen changes and app termination
        app = QGuiApplication.instance()
        if app:
            app.aboutToQuit.connect(self.restore_plasma)
            app.screenAdded.connect(self._on_screens_changed)
            app.screenRemoved.connect(self._on_screens_changed)
            app.primaryScreenChanged.connect(self._on_screens_changed)

        # Connect config changes
        self.config.oledBlackoutChanged.connect(self._update_blackout_windows)

    def _handle_signal(self, signum, frame):
        logger.info("Signal %d received, restoring Plasma and exiting...", signum)
        self.restore_plasma()
        app = QGuiApplication.instance()
        if app:
            app.quit()

    @Slot()
    def activate_focus_mode(self):
        """Stops plasma-plasmashell.service and initializes secondary monitor blackout."""
        self._is_active = True
        self._stop_plasma()
        self._update_blackout_windows()

    @Slot()
    def exit_focus_mode(self):
        """Restores Plasma desktop and closes Zatsu."""
        self._is_active = False
        self._destroy_blackout_windows()
        self.restore_plasma()
        app = QGuiApplication.instance()
        if app:
            app.quit()

    def _is_plasma_active(self) -> bool:
        """Checks if plasma-plasmashell is running either via systemd or as a process."""
        # 1. Check systemctl
        try:
            res = subprocess.run(
                ["systemctl", "--user", "is-active", "plasma-plasmashell.service"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=1.5
            )
            if res.stdout.strip() == "active":
                return True
        except Exception:
            pass

        # 2. Check running processes via psutil
        try:
            for proc in psutil.process_iter(['name', 'exe']):
                try:
                    name = (proc.info.get('name') or "").lower()
                    exe = (proc.info.get('exe') or "").lower()
                    if "plasmashell" in name or "plasmashell" in exe:
                        return True
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except Exception:
            pass

        return False

    def _stop_plasma(self):
        """Stops KDE Plasma shell via systemctl, D-Bus, and process signals."""
        was_active = self._is_plasma_active()
        if not was_active:
            logger.info("plasmashell is not running.")
            return

        self._plasma_was_active = True
        logger.info("Stopping KDE plasmashell desktop environment...")

        # 1. Mask and Stop systemd service to prevent auto-restart
        try:
            subprocess.run(["systemctl", "--user", "mask", "plasma-plasmashell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1.5)
            subprocess.run(["systemctl", "--user", "stop", "plasma-plasmashell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2.0)
            subprocess.run(["systemctl", "--user", "stop", "plasma-plasmashell"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2.0)
        except Exception:
            pass

        # 2. Ask plasmashell to quit cleanly via D-Bus / kquitapp6
        try:
            subprocess.run(["kquitapp6", "plasmashell"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1.0)
        except Exception:
            pass
        try:
            subprocess.run(["qdbus6", "org.kde.plasmashell", "/MainApplication", "quit"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1.0)
        except Exception:
            pass

        # 3. Check if processes are still alive and terminate them
        time.sleep(0.3)
        plasma_procs = []
        try:
            for proc in psutil.process_iter(['pid', 'name', 'exe']):
                try:
                    name = (proc.info.get('name') or "").lower()
                    exe = (proc.info.get('exe') or "").lower()
                    if "plasmashell" in name or "plasmashell" in exe:
                        plasma_procs.append(proc)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except Exception:
            pass

        if plasma_procs:
            logger.info("Terminating %d lingering plasmashell processes...", len(plasma_procs))
            for p in plasma_procs:
                try:
                    p.terminate()
                except Exception:
                    pass

            gone, alive = psutil.wait_procs(plasma_procs, timeout=1.0)
            for p in alive:
                try:
                    logger.warning("Force killing plasmashell PID %d...", p.pid)
                    p.kill()
                except Exception:
                    pass

        logger.info("KDE plasmashell stopped successfully.")

    @Slot()
    def restore_plasma(self):
        """Restores the KDE Plasma desktop shell."""
        if not self._is_active and not self._plasma_was_active:
            return

        logger.info("Restoring KDE Plasma shell...")
        self._is_active = False
        self._plasma_was_active = False

        # 1. Try systemctl user service first
        try:
            subprocess.run(["systemctl", "--user", "unmask", "plasma-plasmashell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1.0)
            subprocess.run(["systemctl", "--user", "start", "plasma-plasmashell.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3.0)
        except Exception:
            pass

        # 2. Verify if plasmashell started
        time.sleep(0.8)
        running = False
        try:
            for proc in psutil.process_iter(['name', 'exe']):
                try:
                    name = (proc.info.get('name') or "").lower()
                    exe = (proc.info.get('exe') or "").lower()
                    if "plasmashell" in name or "plasmashell" in exe:
                        running = True
                        break
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
        except Exception:
            pass

        # 3. If still not running, spawn directly via kstart6 or binary
        if not running:
            logger.info("Spawning plasmashell binary directly...")
            try:
                subprocess.Popen(["kstart6", "plasmashell"], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                try:
                    subprocess.Popen(["plasmashell"], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception as e:
                    logger.error("Failed to directly launch plasmashell: %s", e)

        logger.info("KDE Plasma shell restoration initiated.")
        self.plasmaRestored.emit()

    # --- Multi-Monitor and OLED Blackout Management ---

    def _on_screens_changed(self, *args):
        logger.info("Displays configuration changed. Total screens: %d", len(QGuiApplication.screens()))
        self.screensChanged.emit()
        if self._is_active:
            self._update_blackout_windows()

    @Slot()
    def _update_blackout_windows(self):
        """Updates blackout windows on all non-primary screens."""
        self._destroy_blackout_windows()

        if not self.config.oledSecondaryBlackout:
            logger.info("OLED secondary blackout is disabled in settings.")
            return

        screens = QGuiApplication.screens()
        if len(screens) <= 1:
            logger.info("Single monitor detected, no secondary blackout needed.")
            return

        primary = QGuiApplication.primaryScreen()
        logger.info("Setting up OLED blackout on %d secondary screen(s)...", len(screens) - 1)

        base_dir = os.path.dirname(os.path.abspath(__file__))
        qml_blackout_file = os.path.join(base_dir, "qml", "BlackoutScreen.qml")
        qml_url = QUrl.fromLocalFile(qml_blackout_file)

        for s in screens:
            if s == primary:
                continue

            try:
                view = QQuickView(self.engine, None)
                view.setSource(qml_url)
                view.setScreen(s)
                view.setGeometry(s.geometry())
                view.setFlags(
                    Qt.WindowType.FramelessWindowHint |
                    Qt.WindowType.WindowStaysOnTopHint |
                    Qt.WindowType.BypassWindowManagerHint
                )
                view.showFullScreen()
                self._blackout_windows.append(view)
                logger.info("Blackout window created for screen: %s (%dx%d)", s.name(), s.geometry().width(), s.geometry().height())
            except Exception as e:
                logger.error("Failed to create blackout window for screen %s: %s", s.name(), e)

    def _destroy_blackout_windows(self):
        for win in self._blackout_windows:
            try:
                win.close()
                win.deleteLater()
            except Exception:
                pass
        self._blackout_windows.clear()
