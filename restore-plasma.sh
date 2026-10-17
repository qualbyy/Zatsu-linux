#!/usr/bin/env bash
# Zatsu Focus - Standalone Emergency Plasma Restorer
echo "Восстановление оболочки KDE Plasma 6..."
systemctl --user unmask plasma-plasmashell.service 2>/dev/null || true
systemctl --user start plasma-plasmashell.service 2>/dev/null || true
sleep 1
if ! pgrep -x "plasmashell" >/dev/null 2>&1; then
    echo "Запуск plasmashell напрямую..."
    kstart6 plasmashell 2>/dev/null || kstart plasmashell 2>/dev/null || (nohup plasmashell >/dev/null 2>&1 &)
fi
echo "Готово! Plasma восстановлена."
