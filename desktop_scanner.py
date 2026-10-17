"""
XDG Desktop Application Scanner for Linux / KDE Plasma 6.
Scans /usr/share/applications, ~/.local/share/applications, and custom paths.
Parses .desktop files, resolves names, Breeze icons, categories, and executable paths.
"""

import os
import re
import shlex
import logging
from typing import Dict, List, Optional, Any
from qt_compat import QObject, Signal, Slot, Property

logger = logging.getLogger("zatsu.scanner")

DEFAULT_SEARCH_PATHS = [
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

# Field regexes
RE_GROUP = re.compile(r"^\[(.*)\]$")
RE_KEY_VALUE = re.compile(r"^([^#=]+)=(.*)$")


def clean_exec_field(exec_val: str) -> str:
    """Removes XDG format specifiers like %u, %U, %f, %F, %i, %c, %k, etc."""
    cleaned = re.sub(r"%[a-zA-Z]", "", exec_val).strip()
    return cleaned


class DesktopScanner(QObject):
    """
    Scans, filters, and searches desktop applications.
    Exposes application list and search to QML.
    """
    appsLoaded = Signal()
    searchResultsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._all_apps: List[Dict[str, Any]] = []
        self._search_results: List[Dict[str, Any]] = []
        self._categories: List[str] = ["Все", "Система", "Утилиты", "Интернет", "Разработка", "Мультимедиа", "Графика", "Офис", "Игры"]
        self._last_query = ""
        self._last_category = "Все"
        # Pre-scan on init in background or fast scan
        self.scan_applications()

    @Property("QVariantList", notify=appsLoaded)
    def allApps(self) -> List[Dict[str, Any]]:
        return self._all_apps

    @Property("QVariantList", notify=appsLoaded)
    def apps(self) -> List[Dict[str, Any]]:
        return self._all_apps

    @Property("QVariantList", notify=searchResultsChanged)
    def searchResults(self) -> List[Dict[str, Any]]:
        return self._search_results

    @Property("QVariantList", constant=True)
    def categories(self) -> List[str]:
        return self._categories

    @Slot()
    def scan_applications(self):
        """Scans directories for .desktop files."""
        apps: Dict[str, Dict[str, Any]] = {}

        for folder in DEFAULT_SEARCH_PATHS:
            if not os.path.exists(folder):
                continue

            try:
                for root, _, files in os.walk(folder):
                    for file in files:
                        if file.endswith(".desktop"):
                            path = os.path.join(root, file)
                            app_data = self._parse_desktop_file(path)
                            if app_data and app_data.get("id"):
                                app_id = app_data["id"]
                                # User local apps override system apps
                                if app_id not in apps or "~/.local" in path:
                                    apps[app_id] = app_data
            except Exception as e:
                logger.error("Error reading directory %s: %s", folder, e)

        # Sort alphabetically by display name
        self._all_apps = sorted(apps.values(), key=lambda a: a.get("name", "").lower())
        logger.info("Scanned %d desktop applications", len(self._all_apps))
        self.appsLoaded.emit()
        self.filter_apps(self._last_query, self._last_category)

    def _parse_desktop_file(self, file_path: str) -> Optional[Dict[str, Any]]:
        """Parses a single .desktop file according to FreeDesktop specification."""
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
        except Exception:
            return None

        in_desktop_entry = False
        data: Dict[str, str] = {}
        localized_names: Dict[str, str] = {}

        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            group_match = RE_GROUP.match(line)
            if group_match:
                group_name = group_match.group(1).strip()
                in_desktop_entry = (group_name == "Desktop Entry")
                continue

            if not in_desktop_entry:
                continue

            kv_match = RE_KEY_VALUE.match(line)
            if kv_match:
                k = kv_match.group(1).strip()
                v = kv_match.group(2).strip()

                if k.startswith("Name[ru]"):
                    localized_names["ru"] = v
                elif k == "Name":
                    data["Name"] = v
                elif k not in data:
                    data[k] = v

        # Validate entry
        if data.get("Type") != "Application":
            return None
        if data.get("NoDisplay", "false").lower() == "true":
            return None
        if "Exec" not in data:
            return None

        # Prioritize Russian localized name if available, else standard Name
        name = localized_names.get("ru") or data.get("Name", "")
        if not name:
            return None

        raw_exec = data.get("Exec", "")
        cleaned_exec = clean_exec_field(raw_exec)
        icon_name = data.get("Icon", "application-x-executable")
        comment = data.get("Comment", "")
        categories_str = data.get("Categories", "")
        terminal = data.get("Terminal", "false").lower() == "true"

        # Determine binary name
        binary = ""
        try:
            tokens = shlex.split(cleaned_exec)
            if tokens:
                binary = os.path.basename(tokens[0])
        except Exception:
            binary = cleaned_exec.split()[0] if cleaned_exec else ""

        # Map categories to our simple set
        mapped_cat = self._map_category(categories_str)

        file_basename = os.path.splitext(os.path.basename(file_path))[0]

        return {
            "id": file_basename,
            "name": name,
            "exec": cleaned_exec,
            "binary": binary,
            "icon": icon_name,
            "comment": comment,
            "category": mapped_cat,
            "raw_categories": categories_str,
            "terminal": terminal,
            "desktop_file": file_path
        }

    def _map_category(self, categories_str: str) -> str:
        cat_lower = categories_str.lower()
        if any(c in cat_lower for c in ["system", "settings"]):
            return "Система"
        if any(c in cat_lower for c in ["network", "webbrowser", "chat"]):
            return "Интернет"
        if any(c in cat_lower for c in ["development", "ide", "debugger"]):
            return "Разработка"
        if any(c in cat_lower for c in ["audiovideo", "audio", "video", "player"]):
            return "Мультимедиа"
        if any(c in cat_lower for c in ["graphics", "2dgraphics", "rastergraphics"]):
            return "Графика"
        if any(c in cat_lower for c in ["office", "wordprocessor", "spreadsheet"]):
            return "Офис"
        if any(c in cat_lower for c in ["game"]):
            return "Игры"
        if any(c in cat_lower for c in ["utility", "accessories", "calculator", "archiving"]):
            return "Утилиты"
        return "Утилиты"

    @Slot(str, str)
    def filter_apps(self, query: str = "", category: str = "Все"):
        """Filters the scanned apps by query and category."""
        self._last_query = query.strip().lower()
        self._last_category = category

        filtered = []
        for app in self._all_apps:
            # Check category match
            if self._last_category != "Все" and app.get("category") != self._last_category:
                continue

            # Check query match
            if self._last_query:
                name_match = self._last_query in app.get("name", "").lower()
                exec_match = self._last_query in app.get("exec", "").lower()
                comment_match = self._last_query in app.get("comment", "").lower()
                binary_match = self._last_query in app.get("binary", "").lower()
                if not (name_match or exec_match or comment_match or binary_match):
                    continue

            filtered.append(app)

        self._search_results = filtered
        self.searchResultsChanged.emit()

    @Slot(str, result="QVariant")
    def parse_custom_binary(self, binary_path: str) -> Optional[Dict[str, Any]]:
        """Creates an app descriptor for a custom executable selected via file dialog."""
        if not binary_path or not os.path.exists(binary_path):
            return None

        filename = os.path.basename(binary_path)
        name = os.path.splitext(filename)[0].capitalize()
        return {
            "id": f"custom_{filename}",
            "name": name,
            "exec": binary_path,
            "binary": filename,
            "icon": "application-x-executable",
            "comment": f"Пользовательский бинарник: {binary_path}",
            "category": "Утилиты",
            "raw_categories": "Utility;",
            "terminal": False,
            "desktop_file": ""
        }
