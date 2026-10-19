import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: miniTimerRoot

    width: 176
    height: 46
    x: 80
    y: 80
    visible: config ? config.showMiniTimer : false
    color: "transparent"

    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.Tool

    BreezeTheme {
        id: breezeTheme
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 10
        color: breezeTheme.surfaceElevated
        border.color: (systemService && systemService.pomodoroPhase === "break") ? "#2ecc71" : breezeTheme.accent
        border.width: 1.5

        // Shadow border
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.4)
            border.width: 1
            z: -1
        }

        // Draggable Mouse Area with Wayland startSystemMove support
        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: Qt.SizeAllCursor
            property point clickPos: Qt.point(0, 0)

            onPressed: function(mouse) {
                clickPos = Qt.point(mouse.x, mouse.y)
                if (typeof miniTimerRoot.startSystemMove === "function") {
                    miniTimerRoot.startSystemMove()
                }
            }

            onPositionChanged: function(mouse) {
                if (pressed) {
                    var deltaX = mouse.x - clickPos.x
                    var deltaY = mouse.y - clickPos.y
                    miniTimerRoot.x += deltaX
                    miniTimerRoot.y += deltaY
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            // State Icon
            Image {
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                source: (systemService && systemService.pomodoroPhase === "break")
                        ? "image://icon/emblem-favorite"
                        : "image://icon/preferences-system-time"
                sourceSize.width: 16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
            }

            // Countdown / Pomodoro Time
            Text {
                text: (systemService && systemService.remainingFormatted) ? systemService.remainingFormatted : "25:00"
                font.family: breezeTheme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                color: (systemService && systemService.pomodoroPhase === "break") ? "#2ecc71" : breezeTheme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 4 }

            // Play / Pause Button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: playMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: (systemService && systemService.isTimerRunning)
                            ? "image://icon/media-playback-pause"
                            : "image://icon/media-playback-start"
                    sourceSize.width: 12
                    sourceSize.height: 12
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!systemService) return
                        if (systemService.isTimerRunning) systemService.pause_timer()
                        else systemService.start_timer()
                    }
                }
            }

            // Close (Hide) Button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: closeMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    source: "image://icon/window-close"
                    sourceSize.width: 10
                    sourceSize.height: 10
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (config) config.showMiniTimer = false
                    }
                }
            }
        }
    }
}
