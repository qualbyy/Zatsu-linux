import QtQuick

QtObject {
    id: theme

    // Base colors from KDE system service
    readonly property color background: systemService ? systemService.backgroundColor : "#211d18"
    readonly property color foreground: systemService ? systemService.foregroundColor : "#e9e2d7"
    readonly property color accent: systemService ? systemService.accentColor : "#3daee9"
    readonly property bool isDark: systemService ? systemService.isDarkMode : true

    // Surface & Card colors with Plasma 6 subtle translucent glass
    readonly property color surface: isDark ? Qt.rgba(0.18, 0.17, 0.15, 0.88) : Qt.rgba(0.96, 0.96, 0.96, 0.92)
    readonly property color surfaceElevated: isDark ? Qt.rgba(0.24, 0.22, 0.20, 0.94) : Qt.rgba(1.0, 1.0, 1.0, 0.96)
    readonly property color surfaceCard: isDark ? Qt.rgba(0.14, 0.13, 0.11, 0.75) : Qt.rgba(0.92, 0.92, 0.92, 0.8)

    // Button colors
    readonly property color buttonBg: isDark ? Qt.rgba(0.22, 0.20, 0.18, 0.85) : Qt.rgba(0.90, 0.90, 0.90, 0.85)
    readonly property color buttonHover: isDark ? Qt.rgba(0.32, 0.30, 0.26, 0.95) : Qt.rgba(0.82, 0.82, 0.82, 0.95)
    readonly property color buttonPressed: accent

    // Borders & Dividers
    readonly property color borderSubtle: isDark ? Qt.rgba(1.0, 1.0, 1.0, 0.12) : Qt.rgba(0.0, 0.0, 0.0, 0.12)
    readonly property color borderFocus: accent

    // Text colors
    readonly property color textPrimary: foreground
    readonly property color textSecondary: isDark ? Qt.rgba(0.85, 0.82, 0.78, 0.75) : Qt.rgba(0.2, 0.2, 0.2, 0.75)
    readonly property color textDim: isDark ? Qt.rgba(0.7, 0.68, 0.64, 0.5) : Qt.rgba(0.4, 0.4, 0.4, 0.5)
    readonly property color textOnAccent: "#ffffff"

    // Semantic colors
    readonly property color success: "#8CDA6A"
    readonly property color warning: "#FFB870"
    readonly property color danger: "#FF5555"

    // Sizing & Radii
    readonly property int radiusCard: 10
    readonly property int radiusButton: 6
    readonly property int radiusPopup: 12
    readonly property int radiusPill: 20

    // Fonts
    readonly property string fontFamily: "Noto Sans, Segoe UI, sans-serif"
}
