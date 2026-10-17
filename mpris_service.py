"""
MPRIS2 D-Bus Media Player Service with LRCLIB Synced Lyrics Integration.
Listens to org.mpris.MediaPlayer2.* on the session bus.
Fetches and syncs lyrics from https://lrclib.net/api/get.
"""

import os
import re
import time
import json
import logging
import threading
import urllib.request
import urllib.parse
from typing import Dict, List, Optional, Any
from qt_compat import QObject, Signal, Slot, Property, QTimer

logger = logging.getLogger("zatsu.mpris")

LRC_LINE_REGEX = re.compile(r"^\[(\d+):(\d+(?:\.\d+)?)\](.*)$")


class MprisService(QObject):
    """
    Manages active MPRIS2 player, playback controls, track progress,
    and synchronized lyrics.
    """
    trackChanged = Signal()
    playbackStatusChanged = Signal(str)
    positionChanged = Signal(float)
    lyricsChanged = Signal()
    currentLyricIndexChanged = Signal(int)
    playersListChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._bus = None
        self._active_player_bus_name = ""
        self._available_players: List[str] = []

        # Metadata
        self._title = "Нет активного плеера"
        self._artist = "Zatsu Focus"
        self._album = ""
        self._art_url = ""
        self._playback_status = "Stopped"  # "Playing", "Paused", "Stopped"
        self._duration = 0.0  # seconds
        self._position = 0.0  # seconds
        self._last_position_update = time.time()

        # Lyrics
        self._synced_lyrics: List[Dict[str, Any]] = []
        self._plain_lyrics = ""
        self._lyrics_status = "idle"  # "idle", "loading", "ready", "not_found"
        self._current_lyric_index = -1
        self._lyrics_cache: Dict[str, Any] = {}

        # Position ticker timer
        self._ticker = QTimer(self)
        self._ticker.setInterval(250)
        self._ticker.timeout.connect(self._on_tick)

        # Background poll timer for players
        self._poll_timer = QTimer(self)
        self._poll_timer.setInterval(2000)
        self._poll_timer.timeout.connect(self._poll_players)

        # Try connecting to D-Bus
        self._init_dbus()

        # Start timers
        self._ticker.start()
        self._poll_timer.start()

    def _init_dbus(self):
        try:
            import dbus
            self._bus = dbus.SessionBus()
            logger.info("Connected to D-Bus SessionBus for MPRIS")
            self._poll_players()
        except Exception as e:
            logger.warning("D-Bus SessionBus not available for MPRIS (%s). Demo/mock mode active.", e)
            self._load_demo_track()

    def _load_demo_track(self):
        """Loads a pleasant demo track when no real player is active."""
        self._title = "Weightless"
        self._artist = "Marconi Union"
        self._album = "Ambient Transmissions"
        self._art_url = ""
        self._playback_status = "Paused"
        self._duration = 485.0
        self._position = 42.0
        self.trackChanged.emit()
        self.playbackStatusChanged.emit(self._playback_status)
        self.positionChanged.emit(self._position)
        # Fetch or mock lyrics
        self._fetch_lyrics(self._artist, self._title, self._duration)

    @Slot()
    def _poll_players(self):
        """Discovers available MPRIS2 players."""
        if not self._bus:
            return

        try:
            import dbus
            obj = self._bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
            iface = dbus.Interface(obj, "org.freedesktop.DBus")
            names = iface.ListNames()
            mpris_players = [str(n) for n in names if n.startswith("org.mpris.MediaPlayer2.")]

            if mpris_players != self._available_players:
                self._available_players = mpris_players
                self.playersListChanged.emit()

            if not self._active_player_bus_name and mpris_players:
                self.switch_to_player(mpris_players[0])
            elif self._active_player_bus_name and self._active_player_bus_name not in mpris_players:
                if mpris_players:
                    self.switch_to_player(mpris_players[0])
                else:
                    self._active_player_bus_name = ""
                    self._title = "Медиаплеер не запущен"
                    self._artist = "Ожидание воспроизведения"
                    self._art_url = ""
                    self._playback_status = "Stopped"
                    self._duration = 0.0
                    self._position = 0.0
                    self._synced_lyrics = []
                    self.trackChanged.emit()
                    self.playbackStatusChanged.emit(self._playback_status)
                    self.lyricsChanged.emit()
            elif self._active_player_bus_name:
                self._refresh_player_state()

        except Exception as e:
            logger.debug("Error polling MPRIS players: %s", e)

    def switch_to_player(self, bus_name: str):
        self._active_player_bus_name = bus_name
        logger.info("Switching to MPRIS player: %s", bus_name)
        self._refresh_player_state()

    def _refresh_player_state(self):
        if not self._bus or not self._active_player_bus_name:
            return

        try:
            import dbus
            player_obj = self._bus.get_object(self._active_player_bus_name, "/org/mpris/MediaPlayer2")
            props_iface = dbus.Interface(player_obj, "org.freedesktop.DBus.Properties")

            # 1. Playback status
            status = str(props_iface.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus"))
            if status != self._playback_status:
                self._playback_status = status
                self.playbackStatusChanged.emit(status)

            # 2. Position
            try:
                pos_us = int(props_iface.Get("org.mpris.MediaPlayer2.Player", "Position"))
                self._position = pos_us / 1000000.0
                self._last_position_update = time.time()
                self.positionChanged.emit(self._position)
            except Exception:
                pass

            # 3. Metadata
            meta = props_iface.Get("org.mpris.MediaPlayer2.Player", "Metadata")
            title = str(meta.get("xesam:title", "")) if "xesam:title" in meta else "Неизвестный трек"
            
            artists = meta.get("xesam:artist", "")
            if isinstance(artists, (list, tuple, dbus.Array)):
                artist = ", ".join(str(a) for a in artists)
            else:
                artist = str(artists)
            if not artist:
                artist = "Неизвестный исполнитель"

            album = str(meta.get("xesam:album", "")) if "xesam:album" in meta else ""
            art_url = str(meta.get("mpris:artUrl", "")) if "mpris:artUrl" in meta else ""

            length_us = int(meta.get("mpris:length", 0)) if "mpris:length" in meta else 0
            duration = length_us / 1000000.0

            title_changed = (title != self._title or artist != self._artist)
            self._title = title
            self._artist = artist
            self._album = album
            self._art_url = art_url
            self._duration = duration

            if title_changed:
                self.trackChanged.emit()
                self._fetch_lyrics(self._artist, self._title, self._duration)

        except Exception as e:
            logger.debug("Failed to read player state: %s", e)

    def _on_tick(self):
        """Advances position during playback and recalculates active lyric line."""
        if self._playback_status == "Playing" and self._duration > 0:
            now = time.time()
            elapsed = now - self._last_position_update
            self._last_position_update = now
            self._position = min(self._duration, self._position + elapsed)
            self.positionChanged.emit(self._position)

        # Update lyric index
        self._update_lyric_index()

    def _update_lyric_index(self):
        if not self._synced_lyrics:
            if self._current_lyric_index != -1:
                self._current_lyric_index = -1
                self.currentLyricIndexChanged.emit(-1)
            return

        cur_time = self._position
        target_idx = -1

        for i, item in enumerate(self._synced_lyrics):
            if item["time"] <= cur_time:
                target_idx = i
            else:
                break

        if target_idx != self._current_lyric_index:
            self._current_lyric_index = target_idx
            self.currentLyricIndexChanged.emit(target_idx)

    # --- LRCLIB Synchronized Lyrics Integration ---

    def _fetch_lyrics(self, artist: str, track: str, duration: float):
        """Fetches lyrics from LRCLIB in a background worker thread."""
        cache_key = f"{artist.lower()}__{track.lower()}"
        if cache_key in self._lyrics_cache:
            data = self._lyrics_cache[cache_key]
            self._apply_lyrics(data)
            return

        self._lyrics_status = "loading"
        self._synced_lyrics = []
        self._plain_lyrics = "Загрузка текста песни..."
        self.lyricsChanged.emit()

        threading.Thread(
            target=self._worker_fetch_lyrics,
            args=(artist, track, duration, cache_key),
            daemon=True
        ).start()

    def _worker_fetch_lyrics(self, artist: str, track: str, duration: float, cache_key: str):
        try:
            # Clean artist and track for query
            clean_track = re.sub(r"\(feat\..*?\)", "", track, flags=re.IGNORECASE)
            clean_track = re.sub(r"\[.*?\]", "", clean_track).strip()

            params = {
                "artist_name": artist.strip(),
                "track_name": clean_track.strip()
            }
            if duration > 0:
                params["duration"] = int(duration)

            query_str = urllib.parse.urlencode(params)
            url = f"https://lrclib.net/api/get?{query_str}"

            req = urllib.request.Request(
                url,
                headers={"User-Agent": "ZatsuFocus/1.0 (https://github.com/zatsu/zatsu-focus)"}
            )

            with urllib.request.urlopen(req, timeout=5.0) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read().decode("utf-8"))
                    self._lyrics_cache[cache_key] = data
                    self._apply_lyrics(data)
                    return
        except Exception as e:
            logger.debug("LRCLIB lookup failed for %s - %s: %s", artist, track, e)

        # Fallback if not found
        fallback_data = {
            "syncedLyrics": None,
            "plainLyrics": "Текст песни для этой композиции не найден.",
            "instrumental": False
        }
        self._lyrics_cache[cache_key] = fallback_data
        self._apply_lyrics(fallback_data)

    def _apply_lyrics(self, data: Dict[str, Any]):
        try:
            synced = data.get("syncedLyrics")
            plain = data.get("plainLyrics")
            is_instrumental = data.get("instrumental", False)

            parsed_synced = []
            if is_instrumental:
                plain = "♪ Инструментальная композиция ♪"
                self._lyrics_status = "ready"
            elif synced:
                for line in synced.splitlines():
                    line = line.strip()
                    if not line:
                        continue
                    match = LRC_LINE_REGEX.match(line)
                    if match:
                        mins = int(match.group(1))
                        secs = float(match.group(2))
                        text = match.group(3).strip()
                        total_sec = mins * 60 + secs
                        parsed_synced.append({
                            "time": total_sec,
                            "text": text if text else "..."
                        })
                parsed_synced.sort(key=lambda x: x["time"])
                self._lyrics_status = "ready"
            elif plain:
                self._lyrics_status = "ready"
            else:
                plain = "Текст песни отсутствует."
                self._lyrics_status = "not_found"

            self._synced_lyrics = parsed_synced
            self._plain_lyrics = plain or ""
            self._current_lyric_index = -1
            self.lyricsChanged.emit()
            self._update_lyric_index()
        except RuntimeError:
            pass  # Object was deleted before worker completed

    # --- QML Exposed Properties ---

    @Property(str, notify=trackChanged)
    def title(self) -> str:
        return self._title

    @Property(str, notify=trackChanged)
    def artist(self) -> str:
        return self._artist

    @Property(str, notify=trackChanged)
    def album(self) -> str:
        return self._album

    @Property(str, notify=trackChanged)
    def artUrl(self) -> str:
        return self._art_url

    @Property(str, notify=playbackStatusChanged)
    def playbackStatus(self) -> str:
        return self._playback_status

    @Property(float, notify=trackChanged)
    def duration(self) -> float:
        return self._duration

    @Property(float, notify=positionChanged)
    def position(self) -> float:
        return self._position

    @Property(str, notify=lyricsChanged)
    def lyricsStatus(self) -> str:
        return self._lyrics_status

    @Property(str, notify=lyricsChanged)
    def plainLyrics(self) -> str:
        return self._plain_lyrics

    @Property("QVariantList", notify=lyricsChanged)
    def syncedLyrics(self) -> List[Dict[str, Any]]:
        return self._synced_lyrics

    @Property(int, notify=currentLyricIndexChanged)
    def currentLyricIndex(self) -> int:
        return self._current_lyric_index

    @Property("QVariantList", notify=playersListChanged)
    def availablePlayers(self) -> List[str]:
        return self._available_players

    # --- Playback Controls ---

    @Slot()
    def playPause(self):
        if not self._bus or not self._active_player_bus_name:
            # Toggle demo state
            if self._playback_status == "Playing":
                self._playback_status = "Paused"
            else:
                self._playback_status = "Playing"
                self._last_position_update = time.time()
            self.playbackStatusChanged.emit(self._playback_status)
            return

        try:
            import dbus
            player = self._bus.get_object(self._active_player_bus_name, "/org/mpris/MediaPlayer2")
            iface = dbus.Interface(player, "org.mpris.MediaPlayer2.Player")
            iface.PlayPause()
            self._refresh_player_state()
        except Exception as e:
            logger.error("PlayPause call failed: %s", e)

    @Slot()
    def nextTrack(self):
        if not self._bus or not self._active_player_bus_name:
            self._position = 0.0
            self.positionChanged.emit(0.0)
            return

        try:
            import dbus
            player = self._bus.get_object(self._active_player_bus_name, "/org/mpris/MediaPlayer2")
            iface = dbus.Interface(player, "org.mpris.MediaPlayer2.Player")
            iface.Next()
            self._refresh_player_state()
        except Exception as e:
            logger.error("NextTrack call failed: %s", e)

    @Slot()
    def previousTrack(self):
        if not self._bus or not self._active_player_bus_name:
            self._position = 0.0
            self.positionChanged.emit(0.0)
            return

        try:
            import dbus
            player = self._bus.get_object(self._active_player_bus_name, "/org/mpris/MediaPlayer2")
            iface = dbus.Interface(player, "org.mpris.MediaPlayer2.Player")
            iface.Previous()
            self._refresh_player_state()
        except Exception as e:
            logger.error("PreviousTrack call failed: %s", e)

    @Slot(float)
    def seek(self, target_seconds: float):
        self._position = max(0.0, min(self._duration, target_seconds))
        self._last_position_update = time.time()
        self.positionChanged.emit(self._position)
        self._update_lyric_index()

        if self._bus and self._active_player_bus_name:
            try:
                import dbus
                player = self._bus.get_object(self._active_player_bus_name, "/org/mpris/MediaPlayer2")
                props = dbus.Interface(player, "org.freedesktop.DBus.Properties")
                meta = props.Get("org.mpris.MediaPlayer2.Player", "Metadata")
                track_id = meta.get("mpris:trackid", "/org/mpris/MediaPlayer2/CurrentTrack")
                player_iface = dbus.Interface(player, "org.mpris.MediaPlayer2.Player")
                player_iface.SetPosition(track_id, int(target_seconds * 1000000))
            except Exception as e:
                logger.debug("Seek call failed: %s", e)
