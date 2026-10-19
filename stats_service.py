"""
Productivity analytics and session statistics service for Zatsu Focus.
Tracks daily and weekly focus time, completed Pomodoro cycles, tasks, and streaks.
Persists data to ~/.config/zatsu-focus/stats.json.
"""

import os
import json
import time
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List
from qt_compat import QObject, Signal, Slot, Property

logger = logging.getLogger("zatsu.stats")

STATS_PATH = os.path.expanduser("~/.config/zatsu-focus/stats.json")


def get_today_key() -> str:
    return datetime.now().strftime("%Y-%m-%d")


def format_minutes(total_mins: int) -> str:
    if total_mins <= 0:
        return "0 мин"
    h = total_mins // 60
    m = total_mins % 60
    if h > 0 and m > 0:
        return f"{h} ч {m} мин"
    elif h > 0:
        return f"{h} ч"
    return f"{m} мин"


class StatsService(QObject):
    """
    Exposes focus analytics and weekly history to QML.
    """
    statsUpdated = Signal()

    def __init__(self, config_manager, parent=None):
        super().__init__(parent)
        self.config = config_manager
        self._data: Dict[str, Any] = {
            "total_focus_minutes": 0,
            "total_sessions": 0,
            "pomodoro_cycles_completed": 0,
            "tasks_completed": 0,
            "daily_history": {}
        }
        self.load()

    def load(self):
        if os.path.exists(STATS_PATH):
            try:
                with open(STATS_PATH, "r", encoding="utf-8") as f:
                    self._data.update(json.load(f))
                    logger.info("Loaded focus statistics from %s", STATS_PATH)
                    return
            except Exception as e:
                logger.error("Failed to load stats: %s", e)
        self.save()

    def save(self):
        try:
            os.makedirs(os.path.dirname(STATS_PATH), exist_ok=True)
            temp = STATS_PATH + ".tmp"
            with open(temp, "w", encoding="utf-8") as f:
                json.dump(self._data, f, indent=2, ensure_ascii=False)
            os.replace(temp, STATS_PATH)
        except Exception as e:
            logger.error("Failed to save stats: %s", e)

    @Slot(int)
    def addFocusMinutes(self, minutes: int):
        """Adds elapsed focus minutes to today's count."""
        if minutes <= 0:
            return
        today = get_today_key()
        self._data["total_focus_minutes"] = self._data.get("total_focus_minutes", 0) + minutes

        history = self._data.setdefault("daily_history", {})
        day_entry = history.setdefault(today, {"minutes": 0, "pomodoro_cycles": 0, "sessions": 0})
        day_entry["minutes"] = day_entry.get("minutes", 0) + minutes

        self.save()
        self.statsUpdated.emit()

    @Slot()
    def recordPomodoroCycle(self):
        """Records a successfully completed Pomodoro work cycle."""
        today = get_today_key()
        self._data["pomodoro_cycles_completed"] = self._data.get("pomodoro_cycles_completed", 0) + 1

        history = self._data.setdefault("daily_history", {})
        day_entry = history.setdefault(today, {"minutes": 0, "pomodoro_cycles": 0, "sessions": 0})
        day_entry["pomodoro_cycles"] = day_entry.get("pomodoro_cycles", 0) + 1

        work_mins = int(self.config.get("pomodoro_work_minutes", 25))
        self.addFocusMinutes(work_mins)

    @Slot()
    def recordSessionCompleted(self):
        """Records a completed countdown session."""
        today = get_today_key()
        self._data["total_sessions"] = self._data.get("total_sessions", 0) + 1

        history = self._data.setdefault("daily_history", {})
        day_entry = history.setdefault(today, {"minutes": 0, "pomodoro_cycles": 0, "sessions": 0})
        day_entry["sessions"] = day_entry.get("sessions", 0) + 1

        mins = int(self.config.get("session_duration_minutes", 25))
        self.addFocusMinutes(mins)

    @Slot()
    def recordTaskDone(self):
        self._data["tasks_completed"] = self._data.get("tasks_completed", 0) + 1
        self.save()
        self.statsUpdated.emit()

    # --- Properties for QML ---

    @Property(str, notify=statsUpdated)
    def todayMinutesFormatted(self) -> str:
        today = get_today_key()
        history = self._data.get("daily_history", {})
        today_mins = history.get(today, {}).get("minutes", 0)
        return format_minutes(today_mins)

    @Property(str, notify=statsUpdated)
    def totalFocusFormatted(self) -> str:
        total = self._data.get("total_focus_minutes", 0)
        return format_minutes(total)

    @Property(int, notify=statsUpdated)
    def totalSessions(self) -> int:
        return int(self._data.get("total_sessions", 0))

    @Property(int, notify=statsUpdated)
    def pomodoroCycles(self) -> int:
        return int(self._data.get("pomodoro_cycles_completed", 0))

    @Property(int, notify=statsUpdated)
    def streakDays(self) -> int:
        """Calculates current consecutive day streak."""
        history = self._data.get("daily_history", {})
        if not history:
            return 0
        streak = 0
        cur = datetime.now()
        # If today has minutes, count from today, otherwise check yesterday
        today_key = cur.strftime("%Y-%m-%d")
        if history.get(today_key, {}).get("minutes", 0) > 0:
            streak += 1
            cur -= timedelta(days=1)
        else:
            yesterday_key = (cur - timedelta(days=1)).strftime("%Y-%m-%d")
            if history.get(yesterday_key, {}).get("minutes", 0) > 0:
                cur -= timedelta(days=1)
            else:
                return 0

        while True:
            k = cur.strftime("%Y-%m-%d")
            if history.get(k, {}).get("minutes", 0) > 0:
                streak += 1
                cur -= timedelta(days=1)
            else:
                break
        return streak

    @Property("QVariantList", notify=statsUpdated)
    def weeklyData(self) -> List[Dict[str, Any]]:
        """Returns 7 days of focus time for the weekly bar chart."""
        days_ru = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        history = self._data.get("daily_history", {})

        result = []
        today = datetime.now()
        max_mins = 60  # baseline maximum scale

        # Gather last 7 days ending with today
        raw_items = []
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            key = d.strftime("%Y-%m-%d")
            weekday = days_ru[d.weekday()]
            mins = history.get(key, {}).get("minutes", 0)
            if mins > max_mins:
                max_mins = mins
            raw_items.append((weekday, mins, key == get_today_key()))

        for wday, mins, is_today in raw_items:
            pct = mins / float(max_mins) if max_mins > 0 else 0.0
            result.append({
                "day": wday,
                "minutes": mins,
                "formatted": format_minutes(mins),
                "heightPct": max(0.08, pct),
                "isToday": is_today
            })
        return result
