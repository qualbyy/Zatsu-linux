#!/usr/bin/env bash
# ==============================================================================
# Zatsu Focus - KDE Plasma 6 Uninstallation Script
# ==============================================================================
set -e

APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
ICON_128_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/128x128/apps"

echo "=== Удаление интеграции Zatsu Focus из KDE Plasma 6 ==="

rm -f "$APPS_DIR/zatsu-focus.desktop"
rm -f "$ICONS_DIR/zatsu-focus.svg"
rm -f "$ICON_128_DIR/zatsu-focus.svg"

echo "[+] Обновление кэшей KDE Plasma..."
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental 2>/dev/null || true
fi

echo "Интеграция Zatsu Focus успешно удалена."
