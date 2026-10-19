import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    BreezeTheme { id: breezeTheme }

    property real baseHeight: 48
    readonly property real scaledHeight: baseHeight * (config ? config.panelHeightScale : 1.0)

    signal toggleZatsuMenu()
    signal toggleMiniPlayer()
    signal openTimerSettings()
    signal toggleCalendar()
    signal toggleVolume()
    signal toggleScratchpad()
    signal toggleClipboard()
    signal toggleMiniTimer()

    function getVolumeIcon() {
        if (!systemService) return "audio-volume-medium"
        if (systemService.isMuted) return "audio-volume-muted"
        var vol = systemService.volume
        if (vol === 0) return "audio-volume-muted"
        if (vol < 34) return "audio-volume-low"
        if (vol < 67) return "audio-volume-medium"
        return "audio-volume-high"
    }

    width: parent.width
    height: scaledHeight
    anchors.bottom: parent.bottom

    color: (config && config.panelColor) ? config.panelColor : "#211d18"
    border.color: Qt.rgba(0.24, 0.20, 0.16, 0.8)
    border.width: 1

    // Top border highlight in dark golden-brown style
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // =================================================================
        // 1. KDE APPLICATION LAUNCHER BUTTON (start-here-kde)
        // =================================================================
        Rectangle {
            id: launcherBtn
            Layout.preferredWidth: Math.max(34, root.scaledHeight - 10)
            Layout.preferredHeight: Math.max(34, root.scaledHeight - 10)
            radius: breezeTheme.radiusButton
            color: launcherMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

            Image {
                anchors.centerIn: parent
                width: parent.width * 0.75
                height: width
                source: "image://icon/start-here-kde"
                sourceSize.width: 32
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }

            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.toggleZatsuMenu()
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: root.scaledHeight - 20
            color: breezeTheme.borderSubtle
        }

        // =================================================================
        // 2. ACTIVE WINDOWS TASKBAR (Only desktop apps, no background daemons)
        // =================================================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: taskbarList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 4
                clip: true
                model: (blocker && blocker.activeWindows) ? blocker.activeWindows : []

                delegate: Rectangle {
                    id: taskDelegate
                    width: Math.min(180, Math.max(120, winTitleText.implicitWidth + 44))
                    height: root.scaledHeight - 12
                    anchors.verticalCenter: parent.verticalCenter
                    radius: breezeTheme.radiusButton
                    color: taskMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Image {
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            source: "image://icon/" + (modelData.binary || "application-x-executable")
                            sourceSize.width: 20
                            sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Text {
                            id: winTitleText
                            text: modelData.name || modelData.binary || ""
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: breezeTheme.textPrimary
                            elide: Text.ElideRight
                            width: parent.width - 36
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: taskMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.LeftButton) {
                                if (systemService) {
                                    systemService.activateWindow(modelData.pid || "", modelData.exec || modelData.binary || "")
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                taskContextMenu.targetApp = modelData
                                taskContextMenu.popup()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: root.scaledHeight - 20
            color: breezeTheme.borderSubtle
        }

        // =================================================================
        // 3. INTEGRATED MPRIS MEDIA PLAYER
        // =================================================================
        Rectangle {
            id: mprisWidget
            Layout.preferredWidth: 230
            Layout.preferredHeight: root.scaledHeight - 10
            radius: breezeTheme.radiusButton
            color: mprisMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.surfaceCard
            border.color: breezeTheme.borderSubtle
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: Math.max(26, root.scaledHeight - 20)
                    Layout.preferredHeight: width
                    radius: 4
                    color: breezeTheme.buttonBg
                    clip: true

                    Image {
                        id: thumbImg
                        anchors.fill: parent
                        source: (mpris && mpris.artUrl) ? mpris.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Image {
                        anchors.centerIn: parent
                        width: parent.width * 0.7
                        height: width
                        source: "image://icon/audio-x-generic"
                        sourceSize.width: 24
                        sourceSize.height: 24
                        fillMode: Image.PreserveAspectFit
                        visible: !thumbImg.visible
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: (mpris && mpris.title) ? mpris.title : "Плеер не активен"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: breezeTheme.textPrimary
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: (mpris && mpris.artist) ? mpris.artist : "Zatsu"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        color: breezeTheme.textDim
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Play/Pause button with Breeze icon
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: playBtnMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: (mpris && mpris.playbackStatus === "Playing")
                                ? "image://icon/media-playback-pause"
                                : "image://icon/media-playback-start"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: playBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (mpris) mpris.playPause()
                        }
                    }
                }

                // Next track button with Breeze icon
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: nextBtnMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "image://icon/media-skip-forward"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: nextBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (mpris) mpris.nextTrack()
                        }
                    }
                }
            }

            MouseArea {
                id: mprisMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: root.toggleMiniPlayer()
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: root.scaledHeight - 20
            color: breezeTheme.borderSubtle
        }

        // =================================================================
        // 4. SYSTEM TRAY: TIMER, DOLPHIN, KLIPPER, LAYOUT, CLOCK & CALENDAR
        // =================================================================
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            // Session Countdown / Pomodoro Timer Pill
            Rectangle {
                readonly property bool isPomodoro: (config && config.timerMode === "pomodoro")
                readonly property bool isBreak: (systemService && systemService.pomodoroPhase === "break")
                readonly property bool isStrict: (config && config.strictMode) ? true : false

                width: Math.max(82, timerPillRow.implicitWidth + 18)
                height: root.scaledHeight - 16
                radius: breezeTheme.radiusPill
                color: timerPillMouse.containsMouse ? breezeTheme.buttonHover : 
                       (isBreak ? Qt.rgba(0.18, 0.65, 0.35, 0.25) : 
                       (isStrict ? Qt.rgba(0.9, 0.2, 0.2, 0.2) : breezeTheme.buttonBg))
                border.color: isBreak ? "#2ecc71" : (isStrict ? breezeTheme.danger : breezeTheme.borderSubtle)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: timerPillRow
                    anchors.centerIn: parent
                    spacing: 5

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        source: parent.parent.isBreak ? "image://icon/emblem-favorite" : "image://icon/preferences-system-time"
                        sourceSize.width: 13
                        sourceSize.height: 13
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: (parent.parent.isPomodoro && parent.parent.isBreak ? "Отдых " : "") + 
                              ((systemService && systemService.remainingFormatted) ? systemService.remainingFormatted : "25:00")
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: parent.parent.isBreak ? "#2ecc71" : (parent.parent.isStrict ? breezeTheme.danger : breezeTheme.textPrimary)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: timerPillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.openTimerSettings()
                }
            }

            // Dolphin Quick Launch
            Rectangle {
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: dolphinMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/system-file-manager"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: dolphinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (systemService) systemService.launchDolphin()
                    }
                }
            }

            // Klipper Clipboard Manager
            Rectangle {
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: klipperMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/klipper"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: klipperMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.toggleClipboard()
                    }
                }
            }

            // Scratchpad Quick Notes Button
            Rectangle {
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: scratchMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/accessories-text-editor"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: scratchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleScratchpad()
                }
            }

            // Floating Mini-Timer (PiP) Toggle Button
            Rectangle {
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: (config && config.showMiniTimer) ? breezeTheme.accent : (miniTmrMouse.containsMouse ? breezeTheme.buttonHover : "transparent")
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/view-restore"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: miniTmrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleMiniTimer()
                }
            }

            // Volume Control (Wheel for +/- 5%, click to open popup, middle click to mute)
            Rectangle {
                id: volBtn
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: volMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/" + root.getVolumeIcon()
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: volMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            if (systemService) systemService.toggleMute()
                        } else {
                            root.toggleVolume()
                        }
                    }
                    onWheel: function(wheel) {
                        if (!systemService) return
                        if (wheel.angleDelta.y > 0) {
                            systemService.increaseVolume()
                        } else if (wheel.angleDelta.y < 0) {
                            systemService.decreaseVolume()
                        }
                    }
                }
            }

            // Dedicated Lock Screen Button
            Rectangle {
                id: lockBtn
                width: root.scaledHeight - 18
                height: width
                radius: breezeTheme.radiusButton
                color: lockMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.75
                    height: width
                    source: "image://icon/system-lock-screen"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) systemService.lockScreen()
                    }
                }
            }

            // Keyboard Layout Pill (CLICKABLE to switch language!)
            Rectangle {
                id: layoutPill
                width: 34
                height: root.scaledHeight - 20
                radius: 4
                color: layoutMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.surfaceCard
                border.color: layoutMouse.containsMouse ? breezeTheme.accent : breezeTheme.borderSubtle
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: (systemService && systemService.currentLayout) ? systemService.currentLayout : "EN"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: breezeTheme.textPrimary
                }

                MouseArea {
                    id: layoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) {
                            systemService.nextKeyboardLayout()
                        }
                    }
                }
            }

            // Digital Clock & Date (CLICKABLE to open Calendar!)
            Rectangle {
                id: clockArea
                width: Math.max(54, clockCol.implicitWidth + 14)
                height: root.scaledHeight - 16
                radius: breezeTheme.radiusButton
                color: clockMouse.containsMouse ? breezeTheme.buttonHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Column {
                    id: clockCol
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        id: timeText
                        text: Qt.formatTime(new Date(), "hh:mm")
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: breezeTheme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        id: dateText
                        text: Qt.formatDate(new Date(), "ddd, d MMM")
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 9
                        color: breezeTheme.textDim
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            var d = new Date()
                            timeText.text = Qt.formatTime(d, "hh:mm")
                            dateText.text = Qt.formatDate(d, "ddd, d MMM")
                        }
                    }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleCalendar()
                }
            }
        }
    }

    // Context menu for active taskbar applications
    Menu {
        id: taskContextMenu
        property var targetApp: null

        background: Rectangle {
            implicitWidth: 200
            color: breezeTheme.surfaceElevated
            radius: breezeTheme.radiusCard
            border.color: breezeTheme.borderSubtle
            border.width: 1

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(0, 0, 0, 0.20)
                z: -1
            }
        }

        delegate: MenuItem {
            id: taskMenuItem
            implicitHeight: 34
            contentItem: Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 10
                rightPadding: 10

                Text {
                    text: taskMenuItem.text
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 12
                    color: taskMenuItem.highlighted ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            background: Rectangle {
                radius: breezeTheme.radiusButton
                anchors.fill: parent
                anchors.margins: 2
                color: taskMenuItem.highlighted ? breezeTheme.accent : (taskMenuItem.down ? breezeTheme.buttonPressed : "transparent")
            }
        }

        Action {
            text: "Закрыть окно"
            onTriggered: {
                if (blocker && taskContextMenu.targetApp && taskContextMenu.targetApp.pid) {
                    blocker.closeWindow(taskContextMenu.targetApp.pid)
                }
            }
        }

        Action {
            text: "Закрепить на рабочем столе"
            onTriggered: {
                if (config && taskContextMenu.targetApp) {
                    var a = taskContextMenu.targetApp
                    config.addShortcut(a.id || a.binary, a.name, a.exec || a.binary, a.icon || a.binary, "Desktop")
                }
            }
        }
    }
}
