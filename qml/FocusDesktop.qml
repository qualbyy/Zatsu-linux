import QtQuick
import QtQuick.Controls

Item {
    id: root

    BreezeTheme { id: breezeTheme }

    signal openSettingsRequested()
    signal addAppRequested()
    signal changeWallpaperRequested()

    // Wallpaper background
    Image {
        id: bgImage
        anchors.fill: parent
        source: (systemService && systemService.activeWallpaper) ? "file://" + systemService.activeWallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: false

        // Fallback subtle gradient if image is loading or missing
        Rectangle {
            anchors.fill: parent
            visible: bgImage.status !== Image.Ready
            gradient: Gradient {
                GradientStop { position: 0.0; color: breezeTheme.isDark ? "#1b1916" : "#4a6984" }
                GradientStop { position: 1.0; color: breezeTheme.isDark ? "#0d0c0a" : "#233342" }
            }
        }
    }

    function refreshWallpaper() {
        if (!systemService) return
        var wp = systemService.activeWallpaper
        bgImage.source = ""
        Qt.callLater(function() {
            bgImage.source = wp ? ("file://" + wp) : ""
        })
    }

    Connections {
        target: systemService ? systemService : null
        function onWallpaperChanged() {
            root.refreshWallpaper()
        }
    }

    Connections {
        target: config ? config : null
        function onWallpaperChanged() {
            root.refreshWallpaper()
        }
    }

    // Interactive canvas for icons
    Item {
        id: iconsContainer
        anchors.fill: parent

        Repeater {
            model: (config && config.desktopShortcuts) ? config.desktopShortcuts : []

            DesktopIcon {
                appId: modelData.id || ""
                appName: modelData.name || ""
                appExec: modelData.exec || ""
                appIcon: modelData.icon || "application-x-executable"
                initX: modelData.x !== undefined ? modelData.x : 48
                initY: modelData.y !== undefined ? modelData.y : 48
            }
        }
    }

    // Format helper for seconds -> MM:SS
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "00:00"
        var s = Math.floor(seconds)
        var m = Math.floor(s / 60)
        var sec = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
    }

    // =================================================================
    // 1. ULTRA-TALL CONDENSED DIGITAL CLOCK (HH:mm:ss) CENTERED TOP
    // =================================================================
    Item {
        id: topClockWidget
        visible: (config && config.showDesktopClock !== undefined) ? config.showDesktopClock : true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 48
        width: Math.max(500, timeDisplay.implicitWidth + 40)
        height: 140

        Text {
            id: timeDisplay
            anchors.centerIn: parent
            text: Qt.formatTime(new Date(), "hh:mm:ss")
            font.family: "DejaVu Serif Condensed, Liberation Serif, DejaVu Serif, serif"
            font.pixelSize: 112
            font.weight: Font.DemiBold
            color: "#e8dfd1"
            horizontalAlignment: Text.AlignHCenter

            // Gentle text shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                z: -1
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                timeDisplay.text = Qt.formatTime(new Date(), "hh:mm:ss")
            }
        }
    }

    // =================================================================
    // 2. CENTER FLOATING CARDS (Media Player + Calendar)
    // Dark golden-brown palette matching reference screenshot (#211d18 / #28231c)
    // =================================================================
    Row {
        id: centerCardsRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: topClockWidget.bottom
        anchors.topMargin: 36
        spacing: 24

        // -------------------------------------------------------------
        // LEFT CARD: MEDIA PLAYER WIDGET
        // -------------------------------------------------------------
        Rectangle {
            id: mediaCard
            width: 380
            height: 380
            radius: 20
            color: Qt.rgba(0.13, 0.115, 0.095, 0.92) // #211d18
            border.color: Qt.rgba(0.24, 0.20, 0.16, 0.8)
            border.width: 1.5

            // Outer drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                z: -1
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                // Top: Album Art and Track Info
                Row {
                    width: parent.width
                    spacing: 16

                    Rectangle {
                        width: 108
                        height: 108
                        radius: 12
                        color: Qt.rgba(0.18, 0.15, 0.12, 0.9)
                        border.color: Qt.rgba(0.3, 0.25, 0.2, 0.6)
                        border.width: 1
                        clip: true

                        Image {
                            id: albumArtImg
                            anchors.fill: parent
                            source: (mpris && mpris.artUrl) ? mpris.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            source: "image://icon/audio-x-generic"
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: !albumArtImg.visible
                        }
                    }

                    Column {
                        width: parent.width - 124
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: (mpris && mpris.title) ? mpris.title : "Медиаплеер"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: "#f5eee6"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: (mpris && mpris.artist) ? mpris.artist : "Исполнитель не указан"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#c2b6a6"
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: (mpris && mpris.album) ? mpris.album : "Zatsu Ambient & Music"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: "#8a7e70"
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                // Seekbar / Progress
                Column {
                    width: parent.width
                    spacing: 4

                    Slider {
                        id: cardSeekSlider
                        width: parent.width
                        from: 0
                        to: Math.max(1, (mpris && mpris.duration) ? mpris.duration : 1)
                        value: (mpris && mpris.position) ? mpris.position : 0
                        enabled: mpris && mpris.duration > 0

                        onMoved: {
                            if (mpris) mpris.seek(value)
                        }

                        background: Rectangle {
                            x: cardSeekSlider.leftPadding
                            y: cardSeekSlider.topPadding + cardSeekSlider.availableHeight / 2 - height / 2
                            width: cardSeekSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Qt.rgba(0.25, 0.22, 0.18, 0.8)

                            Rectangle {
                                width: cardSeekSlider.visualPosition * parent.width
                                height: parent.height
                                color: breezeTheme.accent
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: cardSeekSlider.leftPadding + cardSeekSlider.visualPosition * (cardSeekSlider.availableWidth - width)
                            y: cardSeekSlider.topPadding + cardSeekSlider.availableHeight / 2 - height / 2
                            width: 12
                            height: 12
                            radius: 6
                            color: cardSeekSlider.pressed ? "#ffffff" : breezeTheme.accent
                            border.color: "#ffffff"
                            border.width: 1.5
                        }
                    }

                    Item {
                        width: parent.width
                        height: 16

                        Text {
                            anchors.left: parent.left
                            text: formatTime(mpris ? mpris.position : 0)
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: "#8a7e70"
                        }

                        Text {
                            anchors.right: parent.right
                            text: formatTime(mpris ? mpris.duration : 0)
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: "#8a7e70"
                        }
                    }
                }

                // Playback Controls
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24

                    // Previous Track
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: prevMouse.containsMouse ? Qt.rgba(0.28, 0.24, 0.20, 0.9) : Qt.rgba(0.20, 0.17, 0.14, 0.8)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "image://icon/media-skip-backward"
                            sourceSize.width: 18
                            sourceSize.height: 18
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mpris) mpris.previousTrack()
                            }
                        }
                    }

                    // Play / Pause
                    Rectangle {
                        width: 54
                        height: 54
                        radius: 27
                        color: breezeTheme.accent
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: (mpris && mpris.playbackStatus === "Playing")
                                    ? "image://icon/media-playback-pause"
                                    : "image://icon/media-playback-start"
                            sourceSize.width: 24
                            sourceSize.height: 24
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mpris) mpris.playPause()
                            }
                        }
                    }

                    // Next Track
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: nextMouse.containsMouse ? Qt.rgba(0.28, 0.24, 0.20, 0.9) : Qt.rgba(0.20, 0.17, 0.14, 0.8)
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "image://icon/media-skip-forward"
                            sourceSize.width: 18
                            sourceSize.height: 18
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mpris) mpris.nextTrack()
                            }
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // RIGHT CARD: TODO WIDGET (DAILY GOALS / TASKS)
        // -------------------------------------------------------------
        Rectangle {
            id: todoCard
            width: 380
            height: 380
            radius: 20
            color: Qt.rgba(0.13, 0.115, 0.095, 0.92) // #211d18
            border.color: Qt.rgba(0.24, 0.20, 0.16, 0.8)
            border.width: 1.5
            visible: (config && config.showTodoWidget !== undefined) ? config.showTodoWidget : true

            // Outer drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: parent.radius + 1
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                z: -1
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Header Row: Title & Counter Pill
                Item {
                    width: parent.width
                    height: 28

                    Row {
                        anchors.left: parent.left
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            width: 18
                            height: 18
                            source: "image://icon/view-list-details"
                            sourceSize.width: 18
                            sourceSize.height: 18
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Фокус дня"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: "#e9e2d7"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Done / Total Tasks Pill
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 24
                        width: pillText.implicitWidth + 16
                        radius: 12
                        color: Qt.rgba(0.22, 0.19, 0.15, 0.8)
                        border.color: Qt.rgba(0.35, 0.30, 0.24, 0.6)
                        border.width: 1

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: {
                                var tasks = (config && config.focusTasks) ? config.focusTasks : []
                                var done = 0
                                for (var i = 0; i < tasks.length; i++) {
                                    if (tasks[i].done) done++
                                }
                                return done + " / " + tasks.length
                            }
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: breezeTheme.accent
                        }
                    }
                }

                // Tasks List View
                Item {
                    width: parent.width
                    height: 250
                    clip: true

                    ListView {
                        id: tasksListView
                        anchors.fill: parent
                        model: (config && config.focusTasks) ? config.focusTasks : []
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            active: tasksListView.moving || tasksListView.flicking
                            policy: ScrollBar.AsNeeded
                            width: 4
                        }

                        delegate: Rectangle {
                            id: taskDelegate
                            width: tasksListView.width - 6
                            height: 38
                            radius: 8
                            color: taskMouse.containsMouse ? Qt.rgba(0.25, 0.21, 0.17, 0.6) : Qt.rgba(0.18, 0.15, 0.12, 0.4)
                            border.color: taskMouse.containsMouse ? Qt.rgba(0.35, 0.30, 0.24, 0.7) : Qt.rgba(0.22, 0.19, 0.15, 0.4)
                            border.width: 1

                            MouseArea {
                                id: taskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter

                                // Checkbox
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.done ? breezeTheme.accent : "transparent"
                                    border.color: modelData.done ? breezeTheme.accent : Qt.rgba(0.5, 0.44, 0.38, 0.8)
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.bold: true
                                        visible: modelData.done
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!modelData.done && statsService) {
                                                statsService.recordTaskDone()
                                            }
                                            if (config) config.toggleFocusTask(modelData.id)
                                        }
                                    }
                                }

                                // Task description
                                Text {
                                    width: parent.width - 20 - 24 - 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.text || ""
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 12
                                    font.strikeout: modelData.done
                                    color: modelData.done ? Qt.rgba(0.65, 0.60, 0.55, 0.45) : "#e9e2d7"
                                    elide: Text.ElideRight
                                }

                                // Delete Button
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: delMouse.containsMouse ? Qt.rgba(0.8, 0.2, 0.2, 0.35) : "transparent"
                                    visible: taskMouse.containsMouse

                                    Image {
                                        anchors.centerIn: parent
                                        width: 12
                                        height: 12
                                        source: "image://icon/edit-delete"
                                        sourceSize.width: 12
                                        sourceSize.height: 12
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (config) config.removeFocusTask(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Empty State
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: (!config || !config.focusTasks || config.focusTasks.length === 0)

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 32
                            height: 32
                            source: "image://icon/view-list-details"
                            sourceSize.width: 32
                            sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit
                            opacity: 0.35
                        }

                        Text {
                            text: "Нет активных задач
Добавьте цель на текущую сессию"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: Qt.rgba(0.7, 0.65, 0.6, 0.5)
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Add Task Input Row
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Qt.rgba(0.18, 0.15, 0.12, 0.8)
                    border.color: newTaskInput.activeFocus ? breezeTheme.accent : Qt.rgba(0.32, 0.27, 0.22, 0.7)
                    border.width: 1

                    TextInput {
                        id: newTaskInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: addBtnRect.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 12
                        color: "#e9e2d7"
                        clip: true
                        selectByMouse: true
                        onAccepted: {
                            if (text.trim().length > 0) {
                                if (config) config.addFocusTask(text.trim())
                                text = ""
                            }
                        }

                        Text {
                            anchors.fill: parent
                            text: "+ Новая задача (Enter для добавления)..."
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 12
                            color: Qt.rgba(0.65, 0.6, 0.55, 0.4)
                            visible: !newTaskInput.text && !newTaskInput.activeFocus
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Rectangle {
                        id: addBtnRect
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 6
                        color: addBtnMouse.containsMouse ? breezeTheme.accent : Qt.rgba(0.28, 0.24, 0.19, 0.8)

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: addBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (newTaskInput.text.trim().length > 0) {
                                    if (config) config.addFocusTask(newTaskInput.text.trim())
                                    newTaskInput.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Right-click context menu
    MouseArea {
        id: desktopMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                contextMenu.x = mouse.x
                contextMenu.y = mouse.y
                contextMenu.open()
            }
        }
    }

    Menu {
        id: contextMenu

        background: Rectangle {
            implicitWidth: 220
            color: breezeTheme.surfaceElevated
            radius: breezeTheme.radiusCard
            border.color: breezeTheme.borderSubtle
            border.width: 1

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(0, 0, 0, 0.15)
                z: -1
            }
        }

        delegate: MenuItem {
            id: menuItem
            implicitHeight: 36
            contentItem: Row {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 12
                rightPadding: 12

                Text {
                    text: menuItem.text
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 13
                    color: menuItem.highlighted ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            background: Rectangle {
                radius: breezeTheme.radiusButton
                anchors.fill: parent
                anchors.margins: 3
                color: menuItem.highlighted ? breezeTheme.accent : (menuItem.down ? breezeTheme.buttonPressed : "transparent")
            }
        }

        Action {
            text: "Добавить программу..."
            onTriggered: root.addAppRequested()
        }

        Action {
            text: "Выровнять по сетке"
            onTriggered: {
                if (config) config.alignShortcutsToGrid()
            }
        }

        MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: breezeTheme.borderSubtle
                anchors.leftMargin: 8
                anchors.rightMargin: 8
            }
        }

        Action {
            text: "Сменить обои"
            onTriggered: root.changeWallpaperRequested()
        }

        Action {
            text: "Открыть настройки Zatsu"
            onTriggered: root.openSettingsRequested()
        }
    }
}
