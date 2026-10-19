"""
System Integration Service for KDE Plasma 6.
Handles theme colors, wallpaper detection, Klipper D-Bus, Dolphin launch,
keyboard layout detection, and session countdown timer.
"""

import os
import re
import time
import logging
import subprocess
import configparser
from typing import Dict, Any, Optional
from qt_compat import QObject, Signal, Slot, Property, QTimer

logger = logging.getLogger("zatsu.system")

KDEGLOBALS_PATH = os.path.expanduser("~/.config/kdeglobals")
PLASMA_APPLETS_PATH = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
DEFAULT_WALLPAPER_PATH = "/usr/share/wallpapers/Next/contents/images/5120x2880.png"


def parse_rgb_or_hex(val: str, default: str) -> str:
    """Parses 'R,G,B' or '#RRGGBB' into standard hex format '#RRGGBB'."""
    val = val.strip()
    if not val:
        return default
    if val.startswith("#"):
        return val
    parts = val.split(",")
    if len(parts) >= 3:
        try:
            r = int(parts[0].strip())
            g = int(parts[1].strip())
            b = int(parts[2].strip())
            return f"#{r:02x}{g:02x}{b:02x}"
        except ValueError:
            pass
    return default


def is_dark_color(hex_color: str) -> bool:
    """Estimates luminosity of a hex color."""
    try:
        c = hex_color.lstrip("#")
        r, g, b = int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)
        lum = (0.299 * r + 0.587 * g + 0.114 * b)
        return lum < 128
    except Exception:
        return True


class SystemService(QObject):
    """
    Exposes KDE Plasma 6 system features to QML.
    """
    themeChanged = Signal()
    wallpaperChanged = Signal()
    layoutChanged = Signal(str)
    timerTick = Signal()
    sessionFinished = Signal()
    metaKeyTriggered = Signal()
    menuRequested = Signal()
    quickRunnerRequested = Signal()
    layoutSwitchRequested = Signal()
    lockScreenRequested = Signal()
    strictModeToggleRequested = Signal()
    resetTimerRequested = Signal()
    clipboardRequested = Signal()
    recordingActionChanged = Signal(str)
    calendarRequested = Signal()
    volumeChanged = Signal()
    pomodoroPhaseChanged = Signal(str)
    pomodoroCycleChanged = Signal(int)
    doNotDisturbChanged = Signal()
    scratchpadRequested = Signal()
    miniTimerRequested = Signal()
    clipboardHistoryChanged = Signal()

    def __init__(self, config_manager, parent=None):
        super().__init__(parent)
        self.config = config_manager

        # Connect to config updates so wallpaper and work area update immediately
        self.config.wallpaperChanged.connect(self._on_config_wallpaper_changed)
        self.config.panelScaleChanged.connect(self.enforceWindowWorkArea)

        # Audio Volume state
        self._volume = 65
        self._is_muted = False

        # Pomodoro State
        self._pomodoro_phase = "work"  # "work" or "break"
        self._pomodoro_cycles = 0

        # Hotkey Recording state
        self._recording_action = ""

        # KDE Do Not Disturb (Notification inhibition)
        self._dnd_cookie = 0
        self._do_not_disturb = bool(self.config.get("do_not_disturb", True))

        # Theme Colors
        self._bg_color = "#211d18"
        self._fg_color = "#e9e2d7"
        self._accent_color = "#3daee9"  # Breeze blue fallback
        self._button_bg = "#2b2a23"
        self._is_dark = True
        self._system_wallpaper = DEFAULT_WALLPAPER_PATH

        # Keyboard layout
        self._current_layout = "EN"

        # Session Timer
        self._session_total_seconds = self.config.get("session_duration_minutes", 25) * 60
        self._session_remaining_seconds = self._session_total_seconds
        self._timer_active = False

        self._second_timer = QTimer(self)
        self._second_timer.setInterval(1000)
        self._second_timer.timeout.connect(self._on_second_tick)

        # Layout poll timer (poll every 2 seconds)
        self._layout_timer = QTimer(self)
        self._layout_timer.setInterval(1500)
        self._layout_timer.timeout.connect(self._check_keyboard_layout)

        # Volume poll timer (poll every 2.5 seconds)
        self._volume_timer = QTimer(self)
        self._volume_timer.setInterval(2500)
        self._volume_timer.timeout.connect(self._check_system_volume)

        # Load initial system states
        self.reload_theme()
        self.detect_system_wallpaper()
        self._check_keyboard_layout()
        self._check_system_volume()

        # Start timer by default
        self.start_timer()
        self._second_timer.start()
        self._layout_timer.start()
        self._volume_timer.start()

        # Clean up any lingering or orphaned KWin scripts from past runs/crashes
        self._cleanup_kwin_scripts()
        import atexit
        atexit.register(self._cleanup_kwin_scripts)

        # Activate Do Not Disturb if configured
        atexit.register(self.restore_do_not_disturb)
        if self._do_not_disturb:
            self.enable_do_not_disturb()

    def _on_config_wallpaper_changed(self):
        logger.info("Wallpaper config changed! Emitting wallpaperChanged signal...")
        self.wallpaperChanged.emit()

    # --- KDE Theme Inspection ---

    @Slot()
    def reload_theme(self):
        """Reads KDE colors from ~/.config/kdeglobals."""
        if not os.path.exists(KDEGLOBALS_PATH):
            return

        try:
            parser = configparser.ConfigParser(interpolation=None)
            parser.read(KDEGLOBALS_PATH, encoding="utf-8")

            # Background color
            if parser.has_section("Colors:Window"):
                raw_bg = parser.get("Colors:Window", "BackgroundNormal", fallback="#211d18")
                raw_fg = parser.get("Colors:Window", "ForegroundNormal", fallback="#e9e2d7")
                self._bg_color = parse_rgb_or_hex(raw_bg, "#211d18")
                self._fg_color = parse_rgb_or_hex(raw_fg, "#e9e2d7")

            # Accent color
            if parser.has_section("Colors:Selection"):
                raw_accent = parser.get("Colors:Selection", "BackgroundNormal", fallback="")
                if raw_accent:
                    self._accent_color = parse_rgb_or_hex(raw_accent, "#3daee9")
            elif parser.has_section("Colors:Button"):
                raw_accent = parser.get("Colors:Button", "DecorationFocus", fallback="")
                if raw_accent:
                    self._accent_color = parse_rgb_or_hex(raw_accent, "#3daee9")

            # Button background
            if parser.has_section("Colors:Button"):
                raw_btn = parser.get("Colors:Button", "BackgroundNormal", fallback="#2b2a23")
                self._button_bg = parse_rgb_or_hex(raw_btn, "#2b2a23")

            self._is_dark = is_dark_color(self._bg_color)
            self.themeChanged.emit()
            logger.info("Loaded KDE Plasma 6 theme. Dark: %s, Accent: %s", self._is_dark, self._accent_color)
        except Exception as e:
            logger.error("Failed to parse kdeglobals: %s", e)

    @Slot()
    def detect_system_wallpaper(self):
        """Finds current KDE Plasma 6 wallpaper."""
        if os.path.exists(PLASMA_APPLETS_PATH):
            try:
                with open(PLASMA_APPLETS_PATH, "r", encoding="utf-8", errors="replace") as f:
                    for line in f:
                        if line.startswith("Image="):
                            val = line.strip().split("=", 1)[1]
                            val = val.replace("file://", "")
                            if os.path.exists(val):
                                self._system_wallpaper = val
                                self.wallpaperChanged.emit()
                                return
            except Exception as e:
                logger.debug("Could not read plasma applets config: %s", e)

        # Fallbacks to known KDE / EndeavourOS wallpapers
        candidates = [
            "/usr/share/wallpapers/Next/contents/images/5120x2880.png",
            "/usr/share/wallpapers/EndeavourOS/contents/images/3840x2160.png",
            "/usr/share/wallpapers/Flow/contents/images/5120x2880.png",
            "/usr/share/wallpapers/Altai/contents/images/5120x2880.png"
        ]
        for c in candidates:
            if os.path.exists(c):
                self._system_wallpaper = c
                break
        self.wallpaperChanged.emit()

    @Slot()
    def ensureDesktopWindowBottom(self):
        """Ensures the Zatsu main desktop window stays on the bottom layer behind all apps."""
        try:
            import tempfile, dbus
            js_code = """
            var windows = workspace.windowList();
            for (var i = 0; i < windows.length; i++) {
                var w = windows[i];
                if (w.caption && (w.caption.indexOf('Zatsu') !== -1 || (w.resourceClass && w.resourceClass.indexOf('zatsu') !== -1))) {
                    w.keepBelow = true;
                }
            }
            """
            with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as f:
                f.write(js_code)
                tmp_path = f.name
            try:
                bus = dbus.SessionBus()
                kwin_scripting = bus.get_object("org.kde.KWin", "/Scripting")
                script_iface = dbus.Interface(kwin_scripting, "org.kde.kwin.Scripting")
                script_id = script_iface.loadScript(tmp_path)
                script_obj = bus.get_object("org.kde.KWin", f"/Scripting/Script{script_id}")
                script_run = dbus.Interface(script_obj, "org.kde.kwin.Script")
                script_run.run()
                try:
                    script_iface.unloadScript(f"Script{script_id}")
                except Exception:
                    pass
            finally:
                if os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except Exception:
                        pass
        except Exception as e:
            logger.debug("Failed to set desktop window keepBelow: %s", e)

        # Also trigger persistent work area enforcement
        self.enforceWindowWorkArea()

    def _cleanup_kwin_scripts(self):
        """Safely stops and unloads any orphaned KWin scripts to ensure window maximizing is never impaired."""
        try:
            import dbus
            import xml.etree.ElementTree as ET
            bus = dbus.SessionBus()
            obj = bus.get_object("org.kde.KWin", "/Scripting")
            intro_iface = dbus.Interface(obj, "org.freedesktop.DBus.Introspectable")
            xml_data = intro_iface.Introspect(timeout=1.5)
            root = ET.fromstring(xml_data)
            children = [child.attrib.get("name") for child in root if child.tag == "node" and child.attrib.get("name")]
            for child in children:
                try:
                    script_obj = bus.get_object("org.kde.KWin", f"/Scripting/{child}")
                    script_run = dbus.Interface(script_obj, "org.kde.kwin.Script")
                    script_run.stop(timeout=1.0)
                except Exception:
                    pass
        except Exception:
            pass

    @Slot()
    def enforceWindowWorkArea(self):
        """
        Cleans up any stray KWin compositor scripts so window maximizing is never hijacked.
        On Wayland, panel work area is natively enforced by panelStrutWindow (LayerShellQt exclusionZone).
        """
        self._cleanup_kwin_scripts()

    # --- Keyboard Layout ---

    def _check_keyboard_layout(self):
        layout = self._query_keyboard_layout()
        if layout and layout != self._current_layout:
            self._current_layout = layout
            self.layoutChanged.emit(self._current_layout)

    def _query_keyboard_layout(self) -> str:
        # 1. Try D-Bus KDE keyboard layout
        try:
            import dbus
            bus = dbus.SessionBus()
            obj = bus.get_object("org.kde.keyboard", "/Layouts")
            iface = dbus.Interface(obj, "org.kde.KeyboardLayouts")
            cur = str(iface.getCurrentLayout())
            if cur:
                return cur[:2].upper()
        except Exception:
            pass

        # 2. Try setxkbmap
        try:
            res = subprocess.check_output(["setxkbmap", "-query"], stderr=subprocess.DEVNULL, timeout=1.0).decode("utf-8")
            for line in res.splitlines():
                if "layout:" in line:
                    parts = line.split(":", 1)[1].strip().split(",")
                    if parts:
                        return parts[0][:2].upper()
        except Exception:
            pass

        return self._current_layout

    @Slot()
    def nextKeyboardLayout(self):
        """Switches to the next keyboard layout using D-Bus and system calls."""
        # 1. Try python-dbus directly
        try:
            import dbus
            bus = dbus.SessionBus()
            try:
                obj = bus.get_object("org.kde.keyboard", "/Layouts")
                iface = dbus.Interface(obj, "org.kde.KeyboardLayouts")
                iface.switchToNextLayout()
            except Exception:
                try:
                    accel = bus.get_object("org.kde.kglobalaccel", "/component/kwin")
                    accel_iface = dbus.Interface(accel, "org.kde.kglobalaccel.Component")
                    accel_iface.invokeShortcut("Switch to Next Keyboard Layout")
                except Exception:
                    pass
        except Exception:
            pass

        # 2. Try CLI commands (qdbus6 / busctl)
        commands = [
            ["qdbus6", "org.kde.keyboard", "/Layouts", "org.kde.KeyboardLayouts.switchToNextLayout"],
            ["qdbus6", "org.kde.keyboard", "/Layouts", "switchToNextLayout"],
            ["qdbus6", "org.kde.keyboard", "/Layouts", "nextLayout"],
            ["qdbus6", "org.kde.kglobalaccel", "/component/kwin", "invokeShortcut", "Switch to Next Keyboard Layout"],
            ["qdbus6", "org.kde.KWin", "/KWin", "nextLayout"],
            ["busctl", "--user", "call", "org.kde.keyboard", "/Layouts", "org.kde.KeyboardLayouts", "switchToNextLayout"],
            ["busctl", "--user", "call", "org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component", "invokeShortcut", "s", "Switch to Next Keyboard Layout"],
        ]
        for cmd in commands:
            try:
                res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.3)
                if res.returncode == 0:
                    break
            except Exception:
                pass

        # Also toggle local state immediately so user sees instant feedback
        cur = self._current_layout.upper()
        target = "RU" if cur == "EN" else "EN"
        self._current_layout = target
        self.layoutChanged.emit(self._current_layout)

        try:
            subprocess.run(["setxkbmap", target.lower()], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.2)
        except Exception:
            pass

        QTimer.singleShot(250, self._check_keyboard_layout)

    # --- Actions: Dolphin & Klipper ---

    @Slot()
    def launchDolphin(self):
        """Launches Dolphin at home folder."""
        try:
            subprocess.Popen(["dolphin", os.path.expanduser("~")])
        except Exception:
            try:
                subprocess.Popen(["xdg-open", os.path.expanduser("~")])
            except Exception as e:
                logger.error("Failed to launch Dolphin: %s", e)

    @Property("QVariantList", notify=clipboardHistoryChanged)
    def clipboardHistory(self) -> List[str]:
        """Returns clipboard history items from Klipper or clipboard."""
        try:
            import dbus
            bus = dbus.SessionBus()
            klipper = bus.get_object("org.kde.klipper", "/klipper")
            iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            items = iface.getClipboardHistoryMenu()
            return [str(it) for it in items if str(it).strip()]
        except Exception:
            return []

    @Slot(str)
    def selectClipboardItem(self, text: str):
        """Sets clipboard item as current active clipboard content."""
        try:
            import dbus
            bus = dbus.SessionBus()
            klipper = bus.get_object("org.kde.klipper", "/klipper")
            iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            iface.setClipboardContents(text)
        except Exception:
            pass
        self.copyToClipboard(text)

    @Slot()
    def openKlipper(self):
        """Invokes Klipper clipboard history context menu via D-Bus."""
        # 1. Direct python dbus call (org.kde.klipper.klipper.showKlipperPopupMenu)
        try:
            import dbus
            bus = dbus.SessionBus()
            klipper = bus.get_object("org.kde.klipper", "/klipper")
            iface = dbus.Interface(klipper, "org.kde.klipper.klipper")
            iface.showKlipperPopupMenu()
        except Exception as e:
            logger.debug("Failed to call Klipper D-Bus: %s", e)

        # 2. Try busctl fallback
        try:
            subprocess.Popen([
                "busctl", "--user", "call", "org.kde.klipper", "/klipper",
                "org.kde.klipper.klipper", "showKlipperPopupMenu"
            ])
        except Exception:
            pass

        self.clipboardHistoryChanged.emit()

    @Slot(str)
    def launchApp(self, exec_cmd: str):
        """Launches an application command."""
        try:
            subprocess.Popen(exec_cmd, shell=True)
        except Exception as e:
            logger.error("Failed to launch app %s: %s", exec_cmd, e)

    @Slot(str, str)
    def activateWindow(self, pid_str: str, exec_cmd: str):
        """Activates and raises an existing window to the foreground without launching duplicates."""
        logger.info("Activating window PID %s (exec: %s)", pid_str, exec_cmd)
        try:
            pid = int(pid_str)
        except (ValueError, TypeError):
            pid = 0

        # 1. First, check if this is a tray application (StatusNotifierItem like incy, firewall-applet, etc.)
        try:
            import dbus
            bus = dbus.SessionBus()
            snw = bus.get_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
            props = dbus.Interface(snw, "org.freedesktop.DBus.Properties")
            registered = props.Get("org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems")
            dbus_obj = bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
            dbus_iface = dbus.Interface(dbus_obj, "org.freedesktop.DBus")

            clean_cmd = os.path.basename(exec_cmd.split()[0]).lower() if exec_cmd else ""

            for item in registered:
                svc = item.split("/")[0]
                path = "/" + item.split("/", 1)[1] if "/" in item else "/StatusNotifierItem"
                try:
                    c_pid = int(dbus_iface.GetConnectionUnixProcessID(svc))
                except Exception:
                    c_pid = 0

                item_match = False
                if pid > 0 and c_pid == pid:
                    item_match = True
                elif clean_cmd and clean_cmd in item.lower():
                    item_match = True

                if item_match:
                    try:
                        tray_obj = bus.get_object(svc, path)
                        for if_name in ["org.kde.StatusNotifierItem", "org.freedesktop.StatusNotifierItem"]:
                            try:
                                item_iface = dbus.Interface(tray_obj, if_name)
                                item_iface.Activate(0, 0)
                                logger.info("Activated tray StatusNotifierItem: %s", item)
                                return
                            except Exception:
                                pass
                    except Exception as e:
                        logger.debug("Failed to activate tray item %s: %s", item, e)
        except Exception as e:
            logger.debug("Tray check error: %s", e)

        # 2. Try KWin Scripting via D-Bus (native KDE Plasma 6 Wayland/X11)
        kwin_found = False
        try:
            import tempfile, dbus
            clean_cmd = os.path.basename(exec_cmd.split()[0]).lower() if exec_cmd else ""
            kwin_code = f"""
            var windows = workspace.windowList();
            var targetPid = {pid};
            var targetName = "{clean_cmd}";
            for (var i = 0; i < windows.length; i++) {{
                var w = windows[i];
                var match = false;
                if (targetPid > 0 && w.pid == targetPid) {{
                    match = true;
                }} else if (targetName && ((w.resourceClass && w.resourceClass.toLowerCase().indexOf(targetName) !== -1) ||
                                           (w.resourceName && w.resourceName.toLowerCase().indexOf(targetName) !== -1) ||
                                           (w.caption && w.caption.toLowerCase().indexOf(targetName) !== -1))) {{
                    match = true;
                }}
                if (match) {{
                    if (w.minimized) {{
                        w.minimized = false;
                    }}
                    workspace.activeWindow = w;
                    workspace.raiseWindow(w);
                    break;
                }}
            }}
            """
            with tempfile.NamedTemporaryFile("w", suffix=".js", delete=False) as f:
                f.write(kwin_code)
                tmp_path = f.name

            try:
                bus = dbus.SessionBus()
                kwin_scripting = bus.get_object("org.kde.KWin", "/Scripting")
                script_iface = dbus.Interface(kwin_scripting, "org.kde.kwin.Scripting")
                script_id = script_iface.loadScript(tmp_path)
                script_obj = bus.get_object("org.kde.KWin", f"/Scripting/Script{script_id}")
                script_run = dbus.Interface(script_obj, "org.kde.kwin.Script")
                script_run.run()
                try:
                    script_iface.unloadScript(f"Script{script_id}")
                except Exception:
                    pass
                kwin_found = True
            finally:
                if os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except Exception:
                        pass
        except Exception as e:
            logger.debug("KWin script activation failed: %s", e)

        # 3. Only launch if not a running process/window
        if not kwin_found and exec_cmd and pid == 0:
            self.launchApp(exec_cmd)

    @Slot(str)
    def copyToClipboard(self, text: str):
        """Copies text to system clipboard using QGuiApplication clipboard and wl-copy/xclip."""
        from qt_compat import QGuiApplication
        cb = QGuiApplication.clipboard()
        if cb:
            cb.setText(text)

        # Also pipe to wl-copy / xclip
        try:
            p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
            p.communicate(input=text.encode("utf-8"), timeout=0.5)
        except Exception:
            try:
                p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
                p.communicate(input=text.encode("utf-8"), timeout=0.5)
            except Exception:
                pass

        self._play_notification("Буфер обмена", f"Скопировано: {text}")

    @Slot(str)
    def runInTerminal(self, command: str):
        """Runs a command in a terminal emulator."""
        clean = command.strip().lstrip(">").lstrip("!").strip()
        if not clean:
            return
        logger.info("Running command in terminal: %s", clean)
        terminals = [
            ["konsole", "-e", "bash", "-c", f"{clean}; echo; read -p 'Нажмите Enter для выхода...'"],
            ["alacritty", "-e", "bash", "-c", f"{clean}; echo; read -p 'Нажмите Enter для выхода...'"],
            ["kitty", "bash", "-c", f"{clean}; echo; read -p 'Нажмите Enter для выхода...'"],
            ["xterm", "-e", f"{clean}"]
        ]
        for term_cmd in terminals:
            try:
                subprocess.Popen(term_cmd)
                return
            except FileNotFoundError:
                continue
        # Fallback to direct launch
        self.launchApp(clean)

    # --- Audio Volume Controls (wpctl / PipeWire / PulseAudio) ---

    def _check_system_volume(self):
        """Polls current system master volume and mute status via wpctl/pactl."""
        try:
            res = subprocess.check_output(
                ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=0.6
            )
            # Example: "Volume: 0.65" or "Volume: 0.65 [MUTED]"
            parts = res.strip().split()
            if len(parts) >= 2:
                vol_val = float(parts[1])
                new_vol = int(round(vol_val * 100))
                new_muted = "[MUTED]" in res
                if new_vol != self._volume or new_muted != self._is_muted:
                    self._volume = new_vol
                    self._is_muted = new_muted
                    self.volumeChanged.emit()
                return
        except Exception:
            pass

        # Fallback to pactl
        try:
            res = subprocess.check_output(
                ["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=0.6
            )
            import re
            m = re.search(r"(\d+)%", res)
            if m:
                new_vol = int(m.group(1))
                if new_vol != self._volume:
                    self._volume = new_vol
                    self.volumeChanged.emit()
        except Exception:
            pass

    @Slot(int)
    def setVolume(self, percent: int):
        """Sets master volume percentage (0-100)."""
        pct = max(0, min(100, int(percent)))
        self._volume = pct
        self._is_muted = False
        self.volumeChanged.emit()

        # Try wpctl
        try:
            val_str = f"{pct / 100.0:.2f}"
            subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", val_str], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
            subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
            return
        except Exception:
            pass

        # Try pactl
        try:
            subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{pct}%"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
            subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
        except Exception:
            pass

    @Slot()
    def toggleMute(self):
        """Toggles audio mute state."""
        self._is_muted = not self._is_muted
        self.volumeChanged.emit()

        try:
            subprocess.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
            return
        except Exception:
            pass

        try:
            subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.5)
        except Exception:
            pass

    @Slot()
    def increaseVolume(self):
        self.setVolume(min(100, self._volume + 5))

    @Slot()
    def decreaseVolume(self):
        self.setVolume(max(0, self._volume - 5))

    # --- Screen Lock ---

    @Slot()
    def lockScreen(self):
        """Locks the user session using loginctl or D-Bus ScreenSaver."""
        logger.info("Locking screen session...")
        try:
            subprocess.Popen(["loginctl", "lock-session"])
            return
        except Exception:
            pass

        try:
            subprocess.Popen(["qdbus6", "org.freedesktop.ScreenSaver", "/ScreenSaver", "Lock"])
        except Exception as e:
            logger.error("Failed to lock screen: %s", e)

    # --- Session Countdown & Pomodoro Timer ---

    def _on_second_tick(self):
        if self._timer_active and self._session_remaining_seconds > 0:
            self._session_remaining_seconds -= 1
            self.timerTick.emit()

            if self._session_remaining_seconds <= 0:
                is_pomodoro = (self.config.timerMode == "pomodoro")
                if is_pomodoro:
                    if self._pomodoro_phase == "work":
                        # Transition to Break
                        self._pomodoro_phase = "break"
                        self._pomodoro_cycles += 1
                        break_mins = self.config.pomodoroBreakMinutes
                        self._session_total_seconds = break_mins * 60
                        self._session_remaining_seconds = self._session_total_seconds
                        self._timer_active = True
                        self.pomodoroPhaseChanged.emit("break")
                        self.pomodoroCycleChanged.emit(self._pomodoro_cycles)
                        self._play_notification("Время отдыха!", f"Отличный раунд! Перерыв на {break_mins} минут.")
                    else:
                        # Break finished -> Transition to Work
                        self._pomodoro_phase = "work"
                        work_mins = self.config.pomodoroWorkMinutes
                        self._session_total_seconds = work_mins * 60
                        self._session_remaining_seconds = self._session_total_seconds
                        self._timer_active = True
                        self.pomodoroPhaseChanged.emit("work")
                        self._play_notification("Перерыв окончен!", "Готовы к следующему раунду глубокой концентрации?")
                else:
                    self._timer_active = False
                    self.sessionFinished.emit()
                    self._play_notification("Сессия завершена!", "Время фокусировки подошло к концу. Отличная работа!")

    def _play_notification(self, title: str, message: str):
        """Sends desktop notification for timer events."""
        try:
            subprocess.Popen([
                "notify-send", "-a", "Zatsu Focus", "-u", "normal",
                "-i", "alarm-clock", title, message
            ])
        except Exception:
            pass

    @Slot()
    def start_timer(self):
        self._timer_active = True

    @Slot()
    def pause_timer(self):
        self._timer_active = False

    @Slot()
    def reset_timer(self):
        mins = self.config.sessionDurationMinutes
        self._session_total_seconds = mins * 60
        self._session_remaining_seconds = self._session_total_seconds
        self._pomodoro_phase = "work"
        self._timer_active = True
        self.timerTick.emit()
        self.pomodoroPhaseChanged.emit("work")

    @Slot(int)
    def setSessionMinutes(self, minutes: int):
        mins = max(1, min(720, minutes))
        self.config.sessionDurationMinutes = mins
        self._session_total_seconds = mins * 60
        self._session_remaining_seconds = self._session_total_seconds
        self._pomodoro_phase = "work"
        self._timer_active = True
        self.timerTick.emit()
        self.pomodoroPhaseChanged.emit("work")

    # --- Properties exposed to QML ---

    @Property(str, notify=themeChanged)
    def backgroundColor(self) -> str:
        return self._bg_color

    @Property(str, notify=themeChanged)
    def foregroundColor(self) -> str:
        return self._fg_color

    @Property(str, notify=themeChanged)
    def accentColor(self) -> str:
        return self._accent_color

    @Property(str, notify=themeChanged)
    def buttonBackground(self) -> str:
        return self._button_bg

    @Property(bool, notify=themeChanged)
    def isDarkMode(self) -> bool:
        return self._is_dark

    @Property(str, notify=wallpaperChanged)
    def activeWallpaper(self) -> str:
        mode = self.config.wallpaperMode
        if mode == "custom" and self.config.customWallpaperPath and os.path.exists(self.config.customWallpaperPath):
            return self.config.customWallpaperPath
        return self._system_wallpaper

    @Property(str, notify=layoutChanged)
    def currentLayout(self) -> str:
        return self._current_layout

    @Property(int, notify=timerTick)
    def remainingSeconds(self) -> int:
        return self._session_remaining_seconds

    @Property(str, notify=timerTick)
    def remainingFormatted(self) -> str:
        s = self._session_remaining_seconds
        h = s // 3600
        m = (s % 3600) // 60
        sec = s % 60
        if h > 0:
            return f"{h:02d}:{m:02d}:{sec:02d}"
        return f"{m:02d}:{sec:02d}"

    @Property(float, notify=timerTick)
    def timerProgress(self) -> float:
        if self._session_total_seconds <= 0:
            return 1.0
        return 1.0 - (self._session_remaining_seconds / self._session_total_seconds)

    @Property(bool, notify=timerTick)
    def isTimerRunning(self) -> bool:
        return self._timer_active

    @Property(int, notify=volumeChanged)
    def volume(self) -> int:
        return self._volume

    @Property(bool, notify=volumeChanged)
    def isMuted(self) -> bool:
        return self._is_muted

    @Property(str, notify=pomodoroPhaseChanged)
    def pomodoroPhase(self) -> str:
        return self._pomodoro_phase

    @Property(int, notify=pomodoroCycleChanged)
    def pomodoroCycles(self) -> int:
        return self._pomodoro_cycles

    # --- Hotkey Interactive Recording ---

    @Property(str, notify=recordingActionChanged)
    def recordingAction(self) -> str:
        return self._recording_action

    @Slot(str)
    def startRecordingHotkey(self, action_id: str):
        logger.info("Started hotkey recording for action: %s", action_id)
        self._recording_action = action_id
        self.recordingActionChanged.emit(self._recording_action)

    @Slot()
    def stopRecordingHotkey(self):
        logger.info("Stopped hotkey recording")
        self._recording_action = ""
        self.recordingActionChanged.emit("")

    # --- KDE Do Not Disturb (DND) Operations ---

    @Property(bool, notify=doNotDisturbChanged)
    def doNotDisturb(self) -> bool:
        return self._do_not_disturb

    @doNotDisturb.setter
    def doNotDisturb(self, val: bool):
        val = bool(val)
        if self._do_not_disturb == val:
            return
        self._do_not_disturb = val
        self.config.set("do_not_disturb", self._do_not_disturb)
        if self._do_not_disturb:
            self.enable_do_not_disturb()
        else:
            self.restore_do_not_disturb()
        self.doNotDisturbChanged.emit()

    @Slot()
    def toggleDoNotDisturb(self):
        self.doNotDisturb = not self._do_not_disturb

    def enable_do_not_disturb(self):
        """Inhibits KDE Plasma desktop notifications safely without reviving stopped plasmashell."""
        if self._dnd_cookie > 0:
            return
        logger.info("Enabling KDE Plasma Do Not Disturb mode...")
        try:
            import dbus
            bus = dbus.SessionBus()
            # Do NOT call Inhibit if no notification server is running!
            # Otherwise DBus auto-activates plasma_waitforname and restarts plasmashell!
            if not bus.name_has_owner("org.freedesktop.Notifications"):
                logger.info("org.freedesktop.Notifications has no owner (plasmashell is stopped). Notifications are already silent.")
                return
            notif = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
            iface = dbus.Interface(notif, "org.freedesktop.Notifications")
            self._dnd_cookie = int(iface.Inhibit("zatsu-focus", "Сессия глубокой концентрации Zatsu Focus", {}, timeout=2.0))
            logger.info("D-Bus notification inhibition active (cookie: %s)", self._dnd_cookie)
        except Exception as e:
            logger.debug("Could not inhibit notifications via D-Bus: %s", e)

    def restore_do_not_disturb(self):
        """Restores notifications upon focus session exit or DND disable."""
        cookie = self._dnd_cookie
        self._dnd_cookie = 0
        if cookie > 0:
            logger.info("Restoring KDE Plasma notifications...")
            try:
                import dbus
                bus = dbus.SessionBus()
                if not bus.name_has_owner("org.freedesktop.Notifications"):
                    return
                notif = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
                iface = dbus.Interface(notif, "org.freedesktop.Notifications")
                iface.UnInhibit(cookie, timeout=2.0)
                logger.info("D-Bus notification uninhibited successfully (cookie: %s)", cookie)
            except Exception as e:
                logger.debug("Failed to UnInhibit notification: %s", e)

