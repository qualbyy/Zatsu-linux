"""
Ambient sound service for Zatsu Focus.
Provides offline, royalty-free focus soundscapes (Rain, Forest, Fireplace, Pink Noise, Binaural Alpha).
Supports infinite looping, independent volume control, and mute.
"""

import os
import logging
from typing import Dict, Any, Optional
from qt_compat import QObject, Signal, Slot, Property, QUrl

logger = logging.getLogger("zatsu.ambient")

SOUND_PRESETS = [
    {
        "id": "rain",
        "name": "Шум дождя",
        "desc": "Успокаивающий звук капель за окном",
        "icon": "weather-showers",
        "file": "rain.ogg"
    },
    {
        "id": "forest",
        "name": "Шелест леса",
        "desc": "Мягкий ветер и кроны деревьев",
        "icon": "weather-many-clouds",
        "file": "forest.ogg"
    },
    {
        "id": "fireplace",
        "name": "Уютный костёр",
        "desc": "Потрескивание дров и тепло пламени",
        "icon": "weather-clear",
        "file": "fireplace.ogg"
    },
    {
        "id": "pink_noise",
        "name": "Розовый шум",
        "desc": "Глубокая изоляция от внешних раздражителей",
        "icon": "audio-speakers",
        "file": "pink_noise.ogg"
    },
    {
        "id": "binaural_alpha",
        "name": "Альфа-волны (10 Гц)",
        "desc": "Бинауральный тон для максимальной концентрации",
        "icon": "view-media-equalizer",
        "file": "binaural_alpha.ogg"
    }
]


class AmbientSoundService(QObject):
    """
    Manages background ambient sound playback using Qt Multimedia (QMediaPlayer / QAudioOutput).
    """
    soundChanged = Signal(str)
    playingChanged = Signal(bool)
    volumeChanged = Signal(int)

    def __init__(self, config_manager, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self._active_sound_id = self.config.get("ambient_sound", "")
        self._volume = int(self.config.get("ambient_volume", 45))
        self._is_playing = False
        self._base_dir = os.path.dirname(os.path.abspath(__file__))
        self._assets_dir = os.path.join(self._base_dir, "assets", "ambient")

        self._player = None
        self._audio_output = None
        self._init_player()

    def _init_player(self):
        try:
            from qt_compat import IS_PYQT
            if IS_PYQT:
                from PyQt6.QtMultimedia import QMediaPlayer, QAudioOutput
            else:
                from PySide6.QtMultimedia import QMediaPlayer, QAudioOutput

            self._player = QMediaPlayer(self)
            self._audio_output = QAudioOutput(self)
            self._player.setAudioOutput(self._audio_output)
            self._player.setLoops(QMediaPlayer.Loops.Infinite)
            self._audio_output.setVolume(self._volume / 100.0)
            logger.info("AmbientSoundService initialized successfully.")
        except Exception as e:
            logger.error("Failed to initialize QMediaPlayer: %s. Audio will be disabled.", e)

    @Property("QVariantList", constant=True)
    def presets(self):
        return SOUND_PRESETS

    @Property(str, notify=soundChanged)
    def activeSound(self) -> str:
        return self._active_sound_id

    @Property(bool, notify=playingChanged)
    def isPlaying(self) -> bool:
        return self._is_playing

    @Property(int, notify=volumeChanged)
    def volume(self) -> int:
        return self._volume

    @Slot(str)
    def playSound(self, sound_id: str):
        """Starts or switches to an ambient sound preset."""
        if not sound_id:
            self.stop()
            return

        if self._active_sound_id == sound_id and self._is_playing:
            # Toggle off if clicking active sound again
            self.stop()
            return

        self._active_sound_id = sound_id
        self.config.set("ambient_sound", sound_id)
        self.soundChanged.emit(self._active_sound_id)

        matched = next((p for p in SOUND_PRESETS if p["id"] == sound_id), None)
        if not matched:
            return

        file_path = os.path.join(self._assets_dir, matched["file"])
        if not os.path.exists(file_path):
            logger.warning("Ambient file not found: %s", file_path)
            return

        if self._player and self._audio_output:
            try:
                self._player.stop()
                self._player.setSource(QUrl.fromLocalFile(file_path))
                self._audio_output.setVolume(self._volume / 100.0)
                self._player.play()
                self._is_playing = True
                self.playingChanged.emit(True)
                logger.info("Playing ambient sound: %s", matched["name"])
            except Exception as e:
                logger.error("Failed to play ambient sound: %s", e)

    @Slot()
    def togglePlay(self):
        """Toggles between playing and paused state."""
        if self._is_playing:
            self.stop()
        else:
            sound_to_play = self._active_sound_id or "rain"
            self.playSound(sound_to_play)

    @Slot()
    def stop(self):
        """Stops ambient audio playback."""
        if self._player:
            try:
                self._player.stop()
            except Exception:
                pass
        self._is_playing = False
        self.playingChanged.emit(False)
        logger.info("Ambient sound stopped.")

    @Slot(int)
    def setVolume(self, percent: int):
        """Sets ambient volume (0-100)."""
        vol = max(0, min(100, int(percent)))
        self._volume = vol
        self.config.set("ambient_volume", vol)
        if self._audio_output:
            self._audio_output.setVolume(vol / 100.0)
        self.volumeChanged.emit(vol)
