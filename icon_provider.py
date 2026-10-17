"""
QQuickImageProvider for KDE Plasma 6 Breeze icons.
Serves images via 'image://icon/<icon-name-or-path>'.
Supports both PySide6 and PyQt6 seamlessly.
"""

import os
import glob
from typing import Optional, Union, Tuple
from qt_compat import (
    QQuickImageProvider, QIcon, QPixmap, QImage, QPainter, QColor,
    QFont, Qt, QSize, IS_PYSIDE, IS_PYQT
)

SEARCH_DIRS = [
    "/usr/share/icons/breeze-dark",
    "/usr/share/icons/breeze",
    "/usr/share/icons/hicolor",
    "/usr/share/pixmaps",
    os.path.expanduser("~/.local/share/icons")
]


class BreezeIconProvider(QQuickImageProvider):
    """
    Provides crisp Breeze theme icons to QML components.
    Handles differences between PySide6 and PyQt6 signatures.
    """
    def __init__(self):
        super().__init__(QQuickImageProvider.ImageType.Pixmap)
        self._cache = {}
        existing = QIcon.themeSearchPaths()
        custom_paths = ["/usr/share/icons", "/usr/share/pixmaps", os.path.expanduser("~/.local/share/icons")]
        for p in custom_paths:
            if p not in existing and os.path.exists(p):
                existing.append(p)
        QIcon.setThemeSearchPaths(existing)

    def requestPixmap(self, *args):
        # Determine arguments based on caller
        id_str = args[0] if len(args) > 0 else ""
        req_size = None

        if IS_PYSIDE:
            # PySide6: (id, size, requested_size)
            if len(args) >= 3 and isinstance(args[2], QSize):
                req_size = args[2]
            elif len(args) >= 2 and isinstance(args[1], QSize):
                req_size = args[1]
        else:
            # PyQt6: (id, requested_size)
            if len(args) >= 2 and isinstance(args[1], QSize):
                req_size = args[1]

        target_w = req_size.width() if (req_size and req_size.width() > 0) else 64
        target_h = req_size.height() if (req_size and req_size.height() > 0) else 64

        cache_key = f"{id_str}_{target_w}x{target_h}"
        if cache_key in self._cache:
            px = self._cache[cache_key]
        else:
            px = self._load_icon_pixmap(id_str, target_w, target_h)
            self._cache[cache_key] = px

        if IS_PYQT:
            return (px, px.size())
        return px

    def _load_icon_pixmap(self, icon_identifier: str, width: int, height: int) -> QPixmap:
        # 1. Check if direct file path
        if os.path.isabs(icon_identifier) and os.path.exists(icon_identifier):
            px = QPixmap(icon_identifier)
            if not px.isNull():
                return px.scaled(width, height, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)

        base_name = os.path.splitext(icon_identifier)[0]

        # 2. Try QIcon.fromTheme with multiple variations
        candidates = [
            icon_identifier,
            base_name,
            f"org.kde.{base_name}",
            f"application-x-{base_name}",
            f"preferences-system-{base_name}"
        ]

        for cand in candidates:
            icon = QIcon.fromTheme(cand)
            if not icon.isNull():
                px = icon.pixmap(width, height)
                if not px.isNull():
                    return px

        # 3. Direct disk search in icon theme directories
        for base_dir in SEARCH_DIRS:
            if not os.path.exists(base_dir):
                continue
            patterns = [
                os.path.join(base_dir, "**", f"{base_name}.svg"),
                os.path.join(base_dir, "**", f"{base_name}.png"),
                os.path.join(base_dir, f"{base_name}.png"),
                os.path.join(base_dir, f"{base_name}.svg")
            ]
            for pat in patterns:
                matches = glob.glob(pat, recursive=True)
                if matches:
                    px = QPixmap(matches[0])
                    if not px.isNull():
                        return px.scaled(width, height, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)

        # 4. Fallback placeholder icon in Breeze style
        return self._generate_fallback_pixmap(base_name, width, height)

    def _generate_fallback_pixmap(self, name: str, width: int, height: int) -> QPixmap:
        """Generates a pleasant Breeze-styled rounded badge with the first letter."""
        pixmap = QPixmap(width, height)
        pixmap.fill(Qt.GlobalColor.transparent)

        painter = QPainter(pixmap)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        # Breeze slate-blue background
        bg_color = QColor(61, 107, 148, 230)
        border_color = QColor(255, 255, 255, 50)

        painter.setBrush(bg_color)
        painter.setPen(border_color)
        painter.drawRoundedRect(4, 4, width - 8, height - 8, 12, 12)

        letter = name[:1].upper() if name else "?"
        painter.setPen(QColor(240, 243, 246))
        font = QFont("Noto Sans", int(height * 0.42))
        font.setBold(True)
        painter.setFont(font)
        painter.drawText(pixmap.rect(), Qt.AlignmentFlag.AlignCenter, letter)
        painter.end()

        return pixmap
