"""
Strict Blocker Daemon for Zatsu Focus.
Monitors user processes via psutil and enforces whitelist in Strict Mode.
Sends notifications via D-Bus org.freedesktop.Notifications or notify-send.

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
import sys
import time
import signal
import psutil
import logging
import threading
import subprocess
from typing import Set, Dict, List, Optional
from qt_compat import QObject, Signal, Slot, Property

logger = logging.getLogger("zatsu.blocker")

# Critical system and session processes that must NEVER be terminated
PROTECTED_PROCESSES = {
    # Systemd, PAM & Init
    "systemd", "systemd-logind", "systemd-journald", "systemd-udevd", "systemd-resolved",
    "init", "kthreadd", "dbus-broker", "dbus-broker-launch", "dbus-daemon", "busctl", "(sd-pam)",
    # Display server, Compositor & Session
    "plasmashell", "kwin_wayland", "kwin_x11", "kwin", "Xwayland", "wayland", "startplasma-wayland",
    "plasma-session", "startplasma-x11", "xorg", "Xorg", "polkitd", "polkit-kde-authentication-agent-1",
    "plasma-polkit-agent", "kded6", "kactivitymanagerd", "kscreen_backend_launcher", "kglobalaccel", "kaccess",
    "ksmserver", "ksystemstats", "plasma-ksystemstats", "gesture-daemon", "touchegg", "xsettingsd",
    # Power management & Hardware
    "org_kde_powerdevil", "powerdevil", "upowerd", "power-profiles-daemon", "tlp",
    # Integration, Portals & Connectivity
    "kdeconnectd", "kdeconnect-daemon", "kdeconnect-indicator",
    "xdg-desktop-portal", "xdg-desktop-portal-kde", "xdg-desktop-portal-gtk",
    "xdg-document-portal", "xdg-permission-store", "dconf-service", "dconf",
    # Accessibility, Tray & Input
    "at-spi-bus-launcher", "at-spi2-registryd", "gmenudbusmenuproxy", "xembedsniproxy",
    # Audio & Media servers
    "pipewire", "pipewire-pulse", "wireplumber", "pulseaudio",
    # Shells & Python runtime
    "python", "python3", "bash", "sh", "zsh", "fish", "agetty", "sshd", "ssh",
    # Focus tool itself
    "zatsu", "zatsu-focus", "main.py",
    # Agent / IDE environment & Proxies
    "antigravity", "cursor", "code-oss", "vscode", "node", "tgwsproxy_linux_amd64", "ag-dedicated-proxy", "ag-unlocker-proxy"
}


class ProcessBlocker(QObject):
    """
    Background process blocker service.
    """
    blockedProcessDetected = Signal(str, str)  # (proc_name, binary_path)
    activeWindowsChanged = Signal()

    def __init__(self, config_manager, system_service=None, desktop_scanner=None, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self.system_service = system_service
        self.scanner = desktop_scanner
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._current_username = self._get_current_username()
        self._notification_cooldown: Dict[str, float] = {}
        self._tracked_windows: List[Dict[str, str]] = []

        # Connect config signals
        self.config.strictModeChanged.connect(self._on_strict_mode_changed)

    def _get_current_username(self) -> str:
        try:
            import getpass
            return getpass.getuser()
        except Exception:
            return os.environ.get("USER", "")

    def start(self):
        """Starts the process monitoring thread."""
        if self._running:
            return
        self._running = True
        self._thread = threading.Thread(target=self._monitor_loop, daemon=True, name="StrictBlocker")
        self._thread.start()
        logger.info("Process blocker service started.")

    def stop(self):
        """Stops the process monitoring thread."""
        self._running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=1.0)
        logger.info("Process blocker service stopped.")

    def _on_strict_mode_changed(self, enabled: Optional[bool] = None):
        if enabled is None:
            enabled = self.config.strictMode
        logger.info("Strict mode changed to: %s", enabled)

    @Slot(str)
    def closeWindow(self, pid_str: str):
        """Terminates an active window process by PID."""
        try:
            pid = int(pid_str)
            if psutil.pid_exists(pid):
                proc = psutil.Process(pid)
                p_name = proc.name().lower()
                if not self._is_protected(p_name, p_name):
                    proc.terminate()
                    logger.info("Closed window process %s (PID: %d)", p_name, pid)
        except Exception as e:
            logger.error("Failed to close window PID %s: %s", pid_str, e)

    def _monitor_loop(self):
        while self._running:
            strict_enabled = False
            try:
                strict_enabled = self.config.strictMode
                if self.system_service and self.config.timerMode == "pomodoro" and self.system_service.pomodoroPhase == "break":
                    strict_enabled = False
                whitelisted_execs = set(self.config.get_all_whitelisted_executables())

                # Build lookup for desktop shortcuts & all scanned applications
                apps_map = {}
                if self.scanner and hasattr(self.scanner, "_all_apps"):
                    for app in self.scanner._all_apps:
                        e = app.get("exec", "")
                        if e:
                            parts = e.strip().split()
                            if parts:
                                b = os.path.basename(parts[0]).lower()
                                apps_map[b] = app
                                if app.get("id"):
                                    apps_map[app.get("id").lower()] = app

                for s in self.config.desktopShortcuts:
                    e = s.get("exec", "")
                    if e:
                        parts = e.strip().split()
                        if parts:
                            b = os.path.basename(parts[0]).lower()
                            apps_map[b] = s

                # Collect active user window apps for taskbar
                active_apps = []

                # Query active tray / SNI PIDs so background services without tray or window don't clutter the taskbar
                tray_pids = set()
                try:
                    import dbus
                    bus = dbus.SessionBus()
                    snw = bus.get_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
                    props = dbus.Interface(snw, "org.freedesktop.DBus.Properties")
                    registered = props.Get("org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems")
                    dbus_obj = bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
                    dbus_iface = dbus.Interface(dbus_obj, "org.freedesktop.DBus")
                    for item in registered:
                        svc = item.split("/")[0]
                        try:
                            c_pid = int(dbus_iface.GetConnectionUnixProcessID(svc))
                            tray_pids.add(c_pid)
                        except Exception:
                            pass
                except Exception:
                    pass

                for proc in psutil.process_iter(['pid', 'name', 'exe', 'username', 'status', 'cmdline']):
                    try:
                        # Skip if process is dead or zombie
                        if not proc.is_running() or proc.status() == psutil.STATUS_ZOMBIE:
                            continue

                        # Check username to avoid touching root or system services
                        p_user = proc.info.get('username')
                        if p_user and self._current_username and p_user != self._current_username:
                            continue

                        p_name = (proc.info.get('name') or "").lower()
                        p_exe = proc.info.get('exe') or ""
                        p_bin = os.path.basename(p_exe).lower() if p_exe else p_name
                        cmdline = " ".join(proc.info.get('cmdline') or []).lower()

                        # Exclude headless background daemons, CLI runners, and proxies (e.g. xray, xray run, incy background daemons)
                        is_daemon_tool = any(d in p_bin or d in cmdline for d in ["xray", "proxy", "daemon", "service", "helper"])

                        # If it's a protected system process, skip
                        if self._is_protected(p_name, p_bin):
                            continue

                        # Match with desktop apps (only real GUI applications appear on the taskbar)
                        match_item = apps_map.get(p_bin) or apps_map.get(p_name)
                        if match_item:
                            # If it's a pure background daemon without tray or GUI window, do not add as dead taskbar icon
                            if not is_daemon_tool:
                                active_apps.append({
                                    "id": match_item.get("id", p_bin),
                                    "name": match_item.get("name", proc.info.get('name') or p_bin),
                                    "icon": match_item.get("icon", p_bin),
                                    "binary": match_item.get("icon", p_bin),
                                    "exec": match_item.get("exec", p_bin),
                                    "pid": str(proc.pid)
                                })

                        # If Strict Mode is on, enforce blocking!
                        if strict_enabled:
                            if p_bin not in whitelisted_execs and p_name not in whitelisted_execs:
                                self._terminate_unauthorized_process(proc, p_name, p_exe)

                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        continue

                # Update tracked apps
                self._update_tracked_windows(active_apps)

            except Exception as e:
                logger.error("Error in process blocker loop: %s", e)

            # Sleep: 0.4s in strict mode, 1.2s in normal mode to save CPU/battery
            sleep_time = 0.4 if strict_enabled else 1.2
            time.sleep(sleep_time)

    def _is_protected(self, name: str, binary: str) -> bool:
        """Checks if process matches protected system processes."""
        for prot in PROTECTED_PROCESSES:
            if prot in name or prot in binary:
                return True
        return False

    def _terminate_unauthorized_process(self, proc: psutil.Process, name: str, exe_path: str):
        """Safely terminates an unauthorized process and sends desktop notification."""
        try:
            pid = proc.pid
            logger.warning("Terminating unauthorized process: %s (PID: %d)", name, pid)

            # Attempt graceful termination first
            proc.terminate()
            try:
                proc.wait(timeout=0.2)
            except psutil.TimeoutExpired:
                # Force kill if still lingering
                proc.kill()

            # Debounced notification
            now = time.time()
            last_time = self._notification_cooldown.get(name, 0)
            if now - last_time > 3.0:
                self._notification_cooldown[name] = now
                self.blockedProcessDetected.emit(name, exe_path)
                self._send_dbus_notification(
                    "Zatsu Focus — Программа заблокирована",
                    f"Программа «{name}» заблокирована в строгом режиме фокусировки."
                )

        except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
            logger.debug("Process already exited or access denied: %s", e)
        except Exception as e:
            logger.error("Failed to terminate process %s: %s", name, e)

    def _send_dbus_notification(self, title: str, message: str):
        """Sends notification via D-Bus org.freedesktop.Notifications or notify-send."""
        # 1. Try notify-send command
        try:
            subprocess.Popen(
                ["notify-send", "-a", "Zatsu Focus", "-u", "critical", "-i", "security-medium", title, message],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return
        except Exception:
            pass

        # 2. Try python-dbus
        try:
            import dbus
            bus = dbus.SessionBus()
            notif = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
            notify_interface = dbus.Interface(notif, "org.freedesktop.Notifications")
            notify_interface.Notify("Zatsu Focus", 0, "dialog-warning", title, message, [], {}, 4000)
        except Exception as e:
            logger.debug("DBus notification failed: %s", e)

    def _update_tracked_windows(self, active_apps: List[Dict[str, str]]):
        # Deduplicate by app exec/name
        seen = set()
        deduped = []
        for a in active_apps:
            key = a.get("exec") or a.get("name") or a.get("binary")
            if key not in seen:
                seen.add(key)
                deduped.append(a)

        if deduped != self._tracked_windows:
            self._tracked_windows = deduped
            self.activeWindowsChanged.emit()

    @Property("QVariantList", notify=activeWindowsChanged)
    def activeWindows(self) -> List[Dict[str, str]]:
        return self._tracked_windows
