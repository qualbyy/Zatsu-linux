"""
Configuration manager for Zatsu Focus.
Stores and synchronizes settings in ~/.config/zatsu-focus/config.json.

/*
[Chorus]
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Me)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer

[Verse 1]
Wake up in the morning
I'm feeling no stress
Ain't got no worries
'Cause I know I'm the best
Not even trying
I was born like this
Just feel the aura
Babe, give me a kiss

[Pre-Chorus]
Look so fresh
God in flesh
Everybody at my feet
Sun looks dim
Next to him
Baby, feel the heat (Ah)

[Chorus]
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Me)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Yeah)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer
You might also like
Master of Humanity (Lord Verity)
Horror Skunx
It’s me, It’s Verity
Horror Skunx
Be My Friend (The Verity Band)
Horror Skunx
[Verse 2]
Papa always told me
"Your aura is gone"
But then I realized
I wasn't his son (I'm a horse)
And when I'm down
I revive myself (Uh, uh)
'Cause in danger (Ah, ah, ah)
Nobody can help (Save me)
(Ooh)

[Pre-Chorus]
Look so fresh
God in flesh
Everybody at my feet
Sun looks dim
Next to him
Baby, feel the heat (Ah)

[Chorus]
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Me)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Yeah)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer
[Bridge]
Man
Doesn't it suck to be alone?
To be a loser
I guess I'll never know
Feel the sun (Aura)
Feel the wind (Farmer)
Feel the blood in your veins (Aura)
Feel the aura

[Chorus]
Do, do, do-do-do-do, do, do
(Ah) The Aura Farmer (Me)
Do, do, do-do-do-do, do, do
(Ah) He's such a charmer (Aura)
Do, do, do-do-do-do, do, do (Farmer)
(Ah) The Aura Farmer (Yeah; Aura)
Do, do, do-do-do-do, do, do (Farmer)
(Ah) He's such a charmer (Aura)
Do, do, do-do-do-do, do, do (Farmer)
(Ah) He's such a charmer (Yeah; Aura)
Do, do, do-do-do-do (Me), do, do (Farmer)
(Ah) He's such a charmer (Aura)

[Outro]
See you around, baby girl
*/
"""

import os
import json
import logging
from typing import Any, Dict, List
from qt_compat import QObject, Signal, Slot, Property

logger = logging.getLogger("zatsu.config")

CONFIG_DIR = os.path.expanduser("~/.config/zatsu-focus")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")

# Fallback path if ~/.config is read-only or in sandboxed mode
FALLBACK_CONFIG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".config")
FALLBACK_CONFIG_PATH = os.path.join(FALLBACK_CONFIG_DIR, "config.json")

DEFAULT_CONFIG: Dict[str, Any] = {
    "strict_mode": False,
    "session_duration_minutes": 25,
    "session_end_timestamp": 0.0,
    "timer_mode": "countdown",  # "countdown", "pomodoro"
    "pomodoro_work_minutes": 25,
    "pomodoro_break_minutes": 5,
    "show_desktop_clock": True,
    "show_todo_widget": True,
    "inhibit_sleep": True,
    "focus_tasks": [
        {"id": "task_1", "text": "Сфокусироваться на главной задаче", "done": False}
    ],
    "oled_secondary_blackout": True,
    "panel_height_scale": 1.0,
    "panel_opacity": 0.88,
    "panel_color": "#211d18",
    "theme_mode": "auto",  # "auto", "dark", "light"
    "wallpaper_mode": "system",  # "system", "custom"
    "custom_wallpaper_path": "",
    "sound_on_timer_end": True,
    "grid_snap": True,
    "grid_size": 96,
    "ambient_sound": "",
    "ambient_volume": 45,
    "web_blocker_enabled": False,
    "blocked_websites": [
        "youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be",
        "reddit.com", "www.reddit.com", "old.reddit.com",
        "vk.com", "m.vk.com",
        "twitter.com", "x.com",
        "twitch.tv", "www.twitch.tv",
        "instagram.com", "www.instagram.com",
        "tiktok.com", "www.tiktok.com",
        "facebook.com", "www.facebook.com",
        "web.telegram.org",
        "netflix.com", "www.netflix.com"
    ],
    "do_not_disturb": True,
    "show_mini_timer": False,
    "desktop_shortcuts": [
        {
            "id": "dolphin",
            "name": "Dolphin",
            "exec": "dolphin",
            "icon": "system-file-manager",
            "category": "System",
            "x": 48,
            "y": 48
        },
        {
            "id": "kate",
            "name": "Kate",
            "exec": "kate",
            "icon": "kate",
            "category": "Utility",
            "x": 48,
            "y": 164
        },
        {
            "id": "browser",
            "name": "Web Browser",
            "exec": "xdg-open https://",
            "icon": "internet-web-browser",
            "category": "Network",
            "x": 48,
            "y": 280
        },
        {
            "id": "terminal",
            "name": "Terminal",
            "exec": "konsole",
            "icon": "utilities-terminal",
            "category": "System",
            "x": 48,
            "y": 396
        }
    ],
    "allowed_background_apps": [
        "plasmashell",
        "kwin_wayland",
        "kwin_x11",
        "powerdevil",
        "org_kde_powerdevil",
        "kdeconnectd",
        "kdeconnect-indicator",
        "xdg-desktop-portal",
        "xdg-desktop-portal-kde",
        "dolphin",
        "kate",
        "kcalc",
        "ark",
        "spectacle",
        "alacritty",
        "konsole",
        "kitty",
        "plasma-systemmonitor",
        "gwenview",
        "okular",
        "code",
        "spotify",
        "vlc"
    ],
    "hotkeys": {
        "menu": "Alt+F1",
        "quick_runner": "Meta+F",
        "layout_switch": "Alt+Shift",
        "lock_screen": "Meta+L",
        "strict_mode": "Meta+S",
        "reset_timer": "Meta+R",
        "clipboard": "Meta+V",
        "scratchpad": "Meta+N",
        "mini_timer": "Meta+T"
    }
}


class ConfigManager(QObject):
    """
    Manages persistent configuration, emits Qt signals on updates,
    and exposes methods to QML.
    """
    configChanged = Signal()
    shortcutsChanged = Signal()
    allowedAppsChanged = Signal()
    strictModeChanged = Signal()
    oledBlackoutChanged = Signal()
    panelScaleChanged = Signal()
    wallpaperChanged = Signal()
    sessionDurationChanged = Signal()
    timerModeChanged = Signal()
    pomodoroChanged = Signal()
    focusTasksChanged = Signal()
    widgetsChanged = Signal()
    hotkeysChanged = Signal()
    miniTimerChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._config_path = self._determine_config_path()
        self._data: Dict[str, Any] = {}
        self.load()

    def _determine_config_path(self) -> str:
        override = os.environ.get("ZATSU_CONFIG_PATH")
        if override:
            return override
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            # Test write access
            test_file = os.path.join(CONFIG_DIR, ".write_test")
            with open(test_file, "w") as f:
                f.write("test")
            os.remove(test_file)
            return CONFIG_PATH
        except (OSError, PermissionError):
            try:
                os.makedirs(FALLBACK_CONFIG_DIR, exist_ok=True)
                return FALLBACK_CONFIG_PATH
            except Exception:
                return "/tmp/zatsu_config.json"

    def load(self):
        """Loads configuration from JSON file or generates defaults."""
        if os.path.exists(self._config_path):
            try:
                with open(self._config_path, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                    self._data = dict(DEFAULT_CONFIG)
                    self._data.update(loaded)
                    logger.info("Loaded config from %s", self._config_path)
                    return
            except Exception as e:
                logger.error("Failed to load config file: %s. Using defaults.", e)

        self._data = dict(DEFAULT_CONFIG)
        self.save()

    def save(self):
        """Saves current configuration to JSON file."""
        try:
            target_dir = os.path.dirname(self._config_path)
            os.makedirs(target_dir, exist_ok=True)
            temp_path = self._config_path + ".tmp"
            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2, ensure_ascii=False)
            os.replace(temp_path, self._config_path)
            logger.info("Saved config to %s", self._config_path)
        except Exception as e:
            logger.error("Failed to save config: %s", e)

    # --- QML Exposed Getters and Setters ---

    @Slot(str, result="QVariant")
    @Slot(str, "QVariant", result="QVariant")
    def get(self, key: str, default: Any = None) -> Any:
        return self._data.get(key, default)

    @Slot(str, "QVariant")
    def set(self, key: str, value: Any):
        if self._data.get(key) != value:
            self._data[key] = value
            self.save()
            self.configChanged.emit()

            if key == "strict_mode":
                self.strictModeChanged.emit()
            elif key == "session_duration_minutes":
                self.sessionDurationChanged.emit()
            elif key == "timer_mode":
                self.timerModeChanged.emit()
            elif key in ("pomodoro_work_minutes", "pomodoro_break_minutes"):
                self.pomodoroChanged.emit()
            elif key in ("show_desktop_clock", "show_todo_widget"):
                self.widgetsChanged.emit()
            elif key == "focus_tasks":
                self.focusTasksChanged.emit()
            elif key == "oled_secondary_blackout":
                self.oledBlackoutChanged.emit()
            elif key == "panel_height_scale":
                self.panelScaleChanged.emit()
            elif key == "show_mini_timer":
                self.miniTimerChanged.emit()
            elif key in ("wallpaper_mode", "custom_wallpaper_path"):
                self.wallpaperChanged.emit()
            elif key == "hotkeys":
                self.hotkeysChanged.emit()

    # --- Hotkeys Properties & Slots ---

    @Property('QVariantMap', notify=hotkeysChanged)
    def hotkeys(self) -> Dict[str, str]:
        hk = self._data.get("hotkeys", {})
        res = dict(DEFAULT_CONFIG["hotkeys"])
        if isinstance(hk, dict):
            res.update(hk)
        return res

    @Slot(str, str)
    def setHotkey(self, action: str, sequence: str):
        hk = dict(self.hotkeys)
        hk[action] = sequence.strip()
        self.set("hotkeys", hk)

    @Slot()
    def resetHotkeys(self):
        self.set("hotkeys", dict(DEFAULT_CONFIG["hotkeys"]))

    @Property(str, notify=hotkeysChanged)
    def hotkeyMenu(self) -> str:
        return self.hotkeys.get("menu", "Alt+F1")

    @Property(str, notify=hotkeysChanged)
    def hotkeyQuickRunner(self) -> str:
        return self.hotkeys.get("quick_runner", "Meta+F")

    @Property(str, notify=hotkeysChanged)
    def hotkeyLayoutSwitch(self) -> str:
        return self.hotkeys.get("layout_switch", "Alt+Shift")

    @Property(str, notify=hotkeysChanged)
    def hotkeyLockScreen(self) -> str:
        return self.hotkeys.get("lock_screen", "Meta+L")

    @Property(str, notify=hotkeysChanged)
    def hotkeyStrictMode(self) -> str:
        return self.hotkeys.get("strict_mode", "Meta+S")

    @Property(str, notify=hotkeysChanged)
    def hotkeyResetTimer(self) -> str:
        return self.hotkeys.get("reset_timer", "Meta+R")

    @Property(str, notify=hotkeysChanged)
    def hotkeyClipboard(self) -> str:
        return self.hotkeys.get("clipboard", "Meta+V")

    @Property(str, notify=hotkeysChanged)
    def hotkeyScratchpad(self) -> str:
        return self.hotkeys.get("scratchpad", "Meta+N")

    @Property(str, notify=hotkeysChanged)
    def hotkeyMiniTimer(self) -> str:
        return self.hotkeys.get("mini_timer", "Meta+T")

    # --- Mini Floating Timer Window ---

    @Property(bool, notify=miniTimerChanged)
    def showMiniTimer(self) -> bool:
        return bool(self._data.get("show_mini_timer", False))

    @showMiniTimer.setter
    def showMiniTimer(self, val: bool):
        self.set("show_mini_timer", bool(val))
        self.miniTimerChanged.emit()

    # --- Session Duration Property ---

    @Property(int, notify=sessionDurationChanged)
    def sessionDurationMinutes(self) -> int:
        return int(self._data.get("session_duration_minutes", 25))

    @sessionDurationMinutes.setter
    def sessionDurationMinutes(self, val: int):
        self.set("session_duration_minutes", int(val))

    # --- Timer & Pomodoro Properties ---

    @Property(str, notify=timerModeChanged)
    def timerMode(self) -> str:
        return str(self._data.get("timer_mode", "countdown"))

    @timerMode.setter
    def timerMode(self, val: str):
        self.set("timer_mode", str(val))

    @Property(int, notify=pomodoroChanged)
    def pomodoroWorkMinutes(self) -> int:
        return int(self._data.get("pomodoro_work_minutes", 25))

    @Property(int, notify=pomodoroChanged)
    def pomodoroBreakMinutes(self) -> int:
        return int(self._data.get("pomodoro_break_minutes", 5))

    # --- Desktop Widgets Properties ---

    @Property(bool, notify=widgetsChanged)
    def showDesktopClock(self) -> bool:
        return bool(self._data.get("show_desktop_clock", True))

    @showDesktopClock.setter
    def showDesktopClock(self, val: bool):
        self.set("show_desktop_clock", bool(val))

    @Property(bool, notify=widgetsChanged)
    def showTodoWidget(self) -> bool:
        return bool(self._data.get("show_todo_widget", True))

    @showTodoWidget.setter
    def showTodoWidget(self, val: bool):
        self.set("show_todo_widget", bool(val))

    @Property(bool, notify=configChanged)
    def inhibitSleep(self) -> bool:
        return bool(self._data.get("inhibit_sleep", True))

    @inhibitSleep.setter
    def inhibitSleep(self, val: bool):
        self.set("inhibit_sleep", bool(val))

    # --- Focus Tasks Operations ---

    @Property("QVariantList", notify=focusTasksChanged)
    def focusTasks(self) -> List[Dict[str, Any]]:
        return list(self._data.get("focus_tasks", []))

    @Slot(str)
    def addFocusTask(self, text: str):
        clean_text = text.strip()
        if not clean_text:
            return
        tasks = list(self._data.get("focus_tasks", []))
        import time
        new_task = {
            "id": f"task_{int(time.time() * 1000)}",
            "text": clean_text,
            "done": False
        }
        tasks.append(new_task)
        self._data["focus_tasks"] = tasks
        self.save()
        self.focusTasksChanged.emit()

    @Slot(str)
    def toggleFocusTask(self, task_id: str):
        tasks = list(self._data.get("focus_tasks", []))
        for t in tasks:
            if t.get("id") == task_id:
                t["done"] = not t.get("done", False)
                break
        self._data["focus_tasks"] = tasks
        self.save()
        self.focusTasksChanged.emit()

    @Slot(str)
    def removeFocusTask(self, task_id: str):
        tasks = [t for t in self._data.get("focus_tasks", []) if t.get("id") != task_id]
        self._data["focus_tasks"] = tasks
        self.save()
        self.focusTasksChanged.emit()

    # --- Strict Mode Property ---

    @Property(bool, notify=strictModeChanged)
    def strictMode(self) -> bool:
        return bool(self._data.get("strict_mode", False))

    @strictMode.setter
    def strictMode(self, val: bool):
        self.set("strict_mode", bool(val))

    # --- OLED Blackout Property ---

    @Property(bool, notify=oledBlackoutChanged)
    def oledSecondaryBlackout(self) -> bool:
        return bool(self._data.get("oled_secondary_blackout", True))

    @oledSecondaryBlackout.setter
    def oledSecondaryBlackout(self, val: bool):
        self.set("oled_secondary_blackout", bool(val))

    # --- Panel Scale Property ---

    @Property(float, notify=panelScaleChanged)
    def panelHeightScale(self) -> float:
        return float(self._data.get("panel_height_scale", 1.0))

    @panelHeightScale.setter
    def panelHeightScale(self, val: float):
        self.set("panel_height_scale", float(val))

    # --- Wallpaper Properties ---

    @Property(str, notify=wallpaperChanged)
    def wallpaperMode(self) -> str:
        return str(self._data.get("wallpaper_mode", "system"))

    @wallpaperMode.setter
    def wallpaperMode(self, val: str):
        self.set("wallpaper_mode", str(val))

    @Property(str, notify=wallpaperChanged)
    def customWallpaperPath(self) -> str:
        return str(self._data.get("custom_wallpaper_path", ""))

    @customWallpaperPath.setter
    def customWallpaperPath(self, val: str):
        self.set("custom_wallpaper_path", str(val))

    # --- Desktop Shortcuts Operations ---

    @Property("QVariantList", notify=shortcutsChanged)
    def desktopShortcuts(self) -> List[Dict[str, Any]]:
        return list(self._data.get("desktop_shortcuts", []))

    @Slot(str, str, str, str, str, int, int)
    def addShortcut(self, app_id: str, name: str, exec_cmd: str, icon: str, category: str, x: int = 40, y: int = 40):
        shortcuts = list(self._data.get("desktop_shortcuts", []))
        # Prevent exact duplicates
        for s in shortcuts:
            if s.get("id") == app_id or (s.get("exec") == exec_cmd and s.get("name") == name):
                return
        shortcuts.append({
            "id": app_id,
            "name": name,
            "exec": exec_cmd,
            "icon": icon,
            "category": category,
            "x": x,
            "y": y
        })
        self._data["desktop_shortcuts"] = shortcuts
        self.save()
        self.shortcutsChanged.emit()

    @Slot(int)
    def removeShortcut(self, index: int):
        shortcuts = list(self._data.get("desktop_shortcuts", []))
        if 0 <= index < len(shortcuts):
            shortcuts.pop(index)
            self._data["desktop_shortcuts"] = shortcuts
            self.save()
            self.shortcutsChanged.emit()

    @Slot(str, int, int)
    @Slot(str, float, float)
    def updateShortcutPosition(self, app_id: str, x: Any, y: Any):
        shortcuts = list(self._data.get("desktop_shortcuts", []))
        updated = False
        for s in shortcuts:
            if s.get("id") == app_id:
                s["x"] = int(round(x))
                s["y"] = int(round(y))
                updated = True
                break
        if updated:
            self._data["desktop_shortcuts"] = shortcuts
            self.save()
            self.shortcutsChanged.emit()

    @Slot()
    def alignShortcutsToGrid(self):
        """Aligns all desktop shortcuts in a clean grid layout."""
        shortcuts = list(self._data.get("desktop_shortcuts", []))
        start_x = 48
        start_y = 48
        spacing_y = 116
        spacing_x = 116
        max_rows = 6

        for i, s in enumerate(shortcuts):
            col = i // max_rows
            row = i % max_rows
            s["x"] = start_x + col * spacing_x
            s["y"] = start_y + row * spacing_y

        self._data["desktop_shortcuts"] = shortcuts
        self.save()
        self.shortcutsChanged.emit()

    # --- Background Whitelisted Apps Operations ---

    @Property("QVariantList", notify=allowedAppsChanged)
    def allowedBackgroundApps(self) -> List[str]:
        return list(self._data.get("allowed_background_apps", []))

    @Slot(str)
    def addBackgroundApp(self, app_name: str):
        clean_name = os.path.basename(app_name).strip()
        if not clean_name:
            return
        allowed = list(self._data.get("allowed_background_apps", []))
        if clean_name not in allowed:
            allowed.append(clean_name)
            self._data["allowed_background_apps"] = allowed
            self.save()
            self.allowedAppsChanged.emit()

    @Slot(str)
    def removeBackgroundApp(self, app_name: str):
        clean_name = os.path.basename(app_name).strip()
        allowed = list(self._data.get("allowed_background_apps", []))
        if clean_name in allowed:
            allowed.remove(clean_name)
            self._data["allowed_background_apps"] = allowed
            self.save()
            self.allowedAppsChanged.emit()

    def get_desktop_executables(self) -> List[str]:
        """Returns binary basenames only for desktop shortcuts (for the taskbar)."""
        result = set()
        for s in self._data.get("desktop_shortcuts", []):
            exec_str = s.get("exec", "")
            if exec_str:
                parts = exec_str.strip().split()
                if parts:
                    binary = os.path.basename(parts[0])
                    result.add(binary.lower())
        return list(result)

    def get_all_whitelisted_executables(self) -> List[str]:
        """Returns binary basenames for both desktop shortcuts and background apps."""
        result = set(self.get_desktop_executables())

        for b in self._data.get("allowed_background_apps", []):
            if b:
                result.add(os.path.basename(b.strip()).lower())

        return list(result)
