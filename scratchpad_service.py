"""
Quick notes and session scratchpad service for Zatsu Focus.
Stores fast thoughts and temporary tasks in ~/.config/zatsu-focus/scratchpad.md.
"""

import os
import logging
from qt_compat import QObject, Signal, Slot, Property

logger = logging.getLogger("zatsu.scratchpad")

SCRATCHPAD_PATH = os.path.expanduser("~/.config/zatsu-focus/scratchpad.md")


class ScratchpadService(QObject):
    """
    Manages persistent session scratchpad text.
    """
    textChanged = Signal(str)
    scratchpadRequested = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._text = ""
        self.load()

    def load(self):
        if os.path.exists(SCRATCHPAD_PATH):
            try:
                with open(SCRATCHPAD_PATH, "r", encoding="utf-8") as f:
                    self._text = f.read()
                    logger.info("Loaded scratchpad from %s", SCRATCHPAD_PATH)
                    return
            except Exception as e:
                logger.error("Failed to load scratchpad: %s", e)
        self._text = "# Заметки сессии\n\n- [ ] "

    @Property(str, notify=textChanged)
    def text(self) -> str:
        return self._text

    @Slot(str)
    def saveText(self, content: str):
        if self._text != content:
            self._text = content
            self.textChanged.emit(self._text)
            try:
                os.makedirs(os.path.dirname(SCRATCHPAD_PATH), exist_ok=True)
                with open(SCRATCHPAD_PATH, "w", encoding="utf-8") as f:
                    f.write(content)
            except Exception as e:
                logger.error("Failed to save scratchpad: %s", e)

    @Slot()
    def clear(self):
        self.saveText("")
