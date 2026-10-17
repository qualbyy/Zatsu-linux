#!/usr/bin/env bash
# ==============================================================================
# Zatsu Focus - KDE Plasma 6 Installation Script
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
ICON_128_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/128x128/apps"

echo "=== Установка Zatsu Focus для KDE Plasma 6 ==="

# 1. Ensure directories exist
mkdir -p "$APPS_DIR"
mkdir -p "$ICONS_DIR"
mkdir -p "$ICON_128_DIR"

# 2. Make scripts executable
chmod +x "$SCRIPT_DIR/main.py"
chmod +x "$SCRIPT_DIR/restore-plasma.sh"

# 3. Install SVG Icon
echo "[+] Установка иконки приложения в $ICONS_DIR..."
cp "$SCRIPT_DIR/assets/zatsu-focus.svg" "$ICONS_DIR/zatsu-focus.svg"
cp "$SCRIPT_DIR/assets/zatsu-focus.svg" "$ICON_128_DIR/zatsu-focus.svg"

# 4. Generate & Install .desktop file with absolute paths
echo "[+] Установка ярлыка запуска в $APPS_DIR..."
cat > "$APPS_DIR/zatsu-focus.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Zatsu Focus
Name[ru]=Режим концентрации Zatsu
GenericName=Focus Desktop Environment
GenericName[ru]=Автономная среда фокусировки
Comment=Minimalist distraction-free focus shell for KDE Plasma 6
Comment[ru]=Минималистичная среда для глубокой концентрации и работы под KDE Plasma 6
Exec=python3 $SCRIPT_DIR/main.py
Path=$SCRIPT_DIR
Icon=zatsu-focus
Terminal=false
Categories=Utility;System;KDE;Qt;
Keywords=focus;plasma;kde;pomodoro;timer;productivity;strict;
StartupNotify=true
X-KDE-SubstituteUID=false
EOF

chmod +x "$APPS_DIR/zatsu-focus.desktop"

# 5. Update system desktop & icon caches
echo "[+] Обновление системных кэшей KDE Plasma..."
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental 2>/dev/null || true
fi

echo ""
echo "=================================================================="
echo "  Установка успешно завершена!"
echo "  Теперь 'Zatsu Focus' доступен в меню приложений KDE Plasma 6."
echo ""
echo "  Быстрые клавиши:"
echo "    • Meta (Super) / Alt+F1 : Главное меню Zatsu"
echo "    • Meta+F / Ctrl+Space   : Быстрый запуск (Quick Runner / калькулятор)"
echo "    • Alt+Shift             : Смена раскладки клавиатуры"
echo "    • Esc                   : Закрыть активные панели и поиск"
echo "=================================================================="
