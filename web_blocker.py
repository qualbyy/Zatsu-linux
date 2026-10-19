"""
Website distraction blocker for Zatsu Focus.
Blocks access to distracting domains (YouTube, Reddit, VK, Twitch, etc.) during active sessions.
Uses non-destructive window-title intervention + optional /etc/hosts redirect.
Guarantees clean restoration upon session completion or exit.
"""

import os
import atexit
import logging
import subprocess
from typing import List, Set
from qt_compat import QObject, Signal, Slot, Property, QTimer

logger = logging.getLogger("zatsu.web_blocker")

HOSTS_PATH = "/etc/hosts"
BLOCK_MARKER_START = "# --- BEGIN ZATSU FOCUS BLOCK ---"
BLOCK_MARKER_END = "# --- END ZATSU FOCUS BLOCK ---"

DEFAULT_BLOCKED_DOMAINS = [
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
]

BROWSER_PROCESSES = {
    "firefox", "chrome", "google-chrome", "chromium", "brave",
    "brave-browser", "opera", "vivaldi", "epiphany", "falkon",
    "edge", "microsoft-edge"
}


class WebBlocker(QObject):
    """
    Monitors and suppresses distracting websites during focus sessions.
    """
    statusChanged = Signal(bool)
    domainsChanged = Signal()
    interceptionOccurred = Signal(str)

    def __init__(self, config_manager, system_service, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self.system_svc = system_service
        self._enabled = bool(self.config.get("web_blocker_enabled", False))
        self._blocked_domains: List[str] = list(self.config.get("blocked_websites", DEFAULT_BLOCKED_DOMAINS))
        self._intercept_count = 0

        # Safety cleanup on process exit
        atexit.register(self.restore)

        # Window inspection timer (every 1.2 seconds when active)
        self._monitor_timer = QTimer(self)
        self._monitor_timer.setInterval(1200)
        self._monitor_timer.timeout.connect(self._inspect_active_windows)

        if self._enabled:
            self.activate()

    @Property(bool, notify=statusChanged)
    def enabled(self) -> bool:
        return self._enabled

    @enabled.setter
    def enabled(self, val: bool):
        if self._enabled != bool(val):
            self._enabled = bool(val)
            self.config.set("web_blocker_enabled", self._enabled)
            self.statusChanged.emit(self._enabled)
            if self._enabled:
                self.activate()
            else:
                self.restore()

    @Property("QVariantList", notify=domainsChanged)
    def blockedDomains(self) -> List[str]:
        return list(self._blocked_domains)

    @Slot(str)
    def addBlockedDomain(self, domain: str):
        clean = domain.strip().lower().replace("https://", "").replace("http://", "").split("/")[0]
        if clean and clean not in self._blocked_domains:
            self._blocked_domains.append(clean)
            self.config.set("blocked_websites", self._blocked_domains)
            self.domainsChanged.emit()
            if self._enabled:
                self._apply_hosts_block()

    @Slot(str)
    def removeBlockedDomain(self, domain: str):
        clean = domain.strip().lower()
        if clean in self._blocked_domains:
            self._blocked_domains.remove(clean)
            self.config.set("blocked_websites", self._blocked_domains)
            self.domainsChanged.emit()
            if self._enabled:
                self._apply_hosts_block()

    @Slot()
    def toggle(self):
        self.enabled = not self._enabled

    def activate(self):
        """Activates website protection."""
        logger.info("Activating Distraction-Free Web Blocker...")
        self._apply_hosts_block()
        self._monitor_timer.start()

    def restore(self):
        """Restores /etc/hosts and stops inspection."""
        try:
            if hasattr(self, "_monitor_timer") and self._monitor_timer is not None:
                self._monitor_timer.stop()
        except Exception:
            pass
        self._remove_hosts_block()
        logger.info("Web Blocker deactivated and restored.")

    def _apply_hosts_block(self):
        """Attempts to add local redirect to /etc/hosts if write access is permitted."""
        if not os.access(HOSTS_PATH, os.W_OK):
            logger.debug("/etc/hosts is not directly writable. Relying on active window title suppressor.")
            return

        try:
            with open(HOSTS_PATH, "r", encoding="utf-8") as f:
                content = f.read()

            if BLOCK_MARKER_START in content:
                # Remove existing block first
                content = self._strip_marker_block(content)

            lines = [BLOCK_MARKER_START]
            for domain in self._blocked_domains:
                lines.append(f"127.0.0.1 {domain}")
                lines.append(f"::1 {domain}")
            lines.append(BLOCK_MARKER_END)
            block_text = "\n".join(lines) + "\n"

            with open(HOSTS_PATH, "w", encoding="utf-8") as f:
                f.write(content.rstrip() + "\n\n" + block_text)
            logger.info("Successfully updated /etc/hosts with blocked domains.")
        except Exception as e:
            logger.warning("Could not modify /etc/hosts: %s", e)

    def _remove_hosts_block(self):
        """Removes Zatsu block from /etc/hosts."""
        if not os.path.exists(HOSTS_PATH) or not os.access(HOSTS_PATH, os.W_OK):
            return
        try:
            with open(HOSTS_PATH, "r", encoding="utf-8") as f:
                content = f.read()
            if BLOCK_MARKER_START in content:
                new_content = self._strip_marker_block(content)
                with open(HOSTS_PATH, "w", encoding="utf-8") as f:
                    f.write(new_content)
                logger.info("Removed Zatsu block from /etc/hosts.")
        except Exception as e:
            logger.error("Failed to restore /etc/hosts: %s", e)

    def _strip_marker_block(self, text: str) -> str:
        res = []
        in_block = False
        for line in text.splitlines():
            if BLOCK_MARKER_START in line:
                in_block = True
                continue
            if BLOCK_MARKER_END in line:
                in_block = False
                continue
            if not in_block:
                res.append(line)
        return "\n".join(res) + "\n"

    def _inspect_active_windows(self):
        """Checks active window title to intercept distracting websites in browsers."""
        if not self._enabled:
            return

        # 1. Try KWin Scripting via D-Bus
        try:
            import dbus
            bus = dbus.SessionBus()
            kwin = bus.get_object("org.kde.KWin", "/KWin")
            # Query active window title
            title = ""
            try:
                active_win = kwin.Get("org.kde.KWin", "activeWindow", dbus_interface="org.freedesktop.DBus.Properties")
            except Exception:
                pass
        except Exception:
            pass

        # 2. Inspect active windows via xdotool or wmctrl if present
        title = ""
        try:
            title = subprocess.check_output(
                ["xdotool", "getactivewindow", "getwindowname"],
                stderr=subprocess.DEVNULL, timeout=0.3
            ).decode("utf-8", errors="ignore").strip()
        except Exception:
            pass

        if not title:
            return

        title_lower = title.lower()
        for domain in self._blocked_domains:
            keyword = domain.replace(".com", "").replace(".org", "").replace(".tv", "").replace("www.", "")
            if len(keyword) >= 3 and keyword in title_lower:
                self._handle_distraction(keyword, title)
                break

    def _handle_distraction(self, keyword: str, window_title: str):
        """Sends notification and minimizes/closes the distracting window."""
        logger.info("Distraction intercepted: %s in window '%s'", keyword, window_title)
        self._intercept_count += 1
        self.interceptionOccurred.emit(keyword)

        try:
            subprocess.Popen([
                "notify-send", "-a", "Zatsu Focus", "-u", "critical",
                "-i", "security-high",
                "Сайт заблокирован режимом фокусировки!",
                f"Ресурс '{keyword}' недоступен во время сеанса концентрации."
            ])
        except Exception:
            pass

        # Minimize or close the active distracting window
        try:
            subprocess.run(["xdotool", "getactivewindow", "windowminimize"], stderr=subprocess.DEVNULL, timeout=0.3)
        except Exception:
            pass
