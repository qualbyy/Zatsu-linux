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

    // -----------------------------------------------------------------
    // DESKTOP WIDGETS LAYOUT & POSITIONING LOGIC
    // Supports both Clean Centered Grid and Arbitrary Free Positioning
    // -----------------------------------------------------------------
    readonly property bool isFreeLayout: (config && config.desktopFreePositioning)

    readonly property real defaultClockX: Math.round((root.width - topClockWidget.width) / 2)
    readonly property real defaultClockY: 48

    readonly property real cardsTopY: (topClockWidget.visible ? (topClockWidget.y + topClockWidget.height + 36) : 64)

    readonly property real defaultMediaX: {
        if (mediaCard.visible && todoCard.visible) {
            return Math.round((root.width - (380 * 2 + 24)) / 2)
        } else {
            return Math.round((root.width - 380) / 2)
        }
    }
    readonly property real defaultMediaY: cardsTopY

    readonly property real defaultTodoX: {
        if (mediaCard.visible && todoCard.visible) {
            return defaultMediaX + 380 + 24
        } else {
            return Math.round((root.width - 380) / 2)
        }
    }
    readonly property real defaultTodoY: cardsTopY

    // =================================================================
    // 1. ULTRA-TALL CONDENSED DIGITAL CLOCK (HH:mm:ss) CENTERED TOP
    // =================================================================
    Item {
        id: topClockWidget
        visible: (config && config.showDesktopClock !== undefined) ? config.showDesktopClock : true
        width: Math.max(500, timeDisplay.implicitWidth + 40)
        height: 140

        x: isFreeLayout
           ? ((config && config.widgetPositions["clock"] && config.widgetPositions["clock"].x !== undefined) ? config.widgetPositions["clock"].x : defaultClockX)
           : defaultClockX
        y: isFreeLayout
           ? ((config && config.widgetPositions["clock"] && config.widgetPositions["clock"].y !== undefined) ? config.widgetPositions["clock"].y : defaultClockY)
           : defaultClockY

        Behavior on x {
            enabled: !isFreeLayout || !clockDragArea.drag.active
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: !isFreeLayout || !clockDragArea.drag.active
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: clockDragArea
            anchors.fill: parent
            enabled: isFreeLayout
            drag.target: topClockWidget
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 16
            drag.minimumY: 16
            drag.maximumX: Math.max(16, root.width - topClockWidget.width - 16)
            drag.maximumY: Math.max(16, root.height - topClockWidget.height - 60)
            cursorShape: isFreeLayout ? Qt.SizeAllCursor : Qt.ArrowCursor

            onReleased: {
                if (isFreeLayout && config) {
                    config.setWidgetPosition("clock", Math.round(topClockWidget.x), Math.round(topClockWidget.y))
                }
            }
        }

        Text {
            id: timeDisplay
            anchors.centerIn: parent
            text: Qt.formatTime(new Date(), "hh:mm:ss")
            font.family: "DejaVu Serif Condensed, Liberation Serif, DejaVu Serif, serif"
            font.pixelSize: 112
            font.weight: Font.DemiBold
            color: breezeTheme.textPrimary
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
    // 2. MEDIA PLAYER WIDGET CARD (Default OFF, Draggable in Free Mode)
    // =================================================================
    Rectangle {
        id: mediaCard
        width: 380
        height: 380
        radius: 20
        visible: (config && config.showDesktopMedia !== undefined) ? config.showDesktopMedia : false

        x: isFreeLayout
           ? ((config && config.widgetPositions["media"] && config.widgetPositions["media"].x !== undefined) ? config.widgetPositions["media"].x : defaultMediaX)
           : defaultMediaX
        y: isFreeLayout
           ? ((config && config.widgetPositions["media"] && config.widgetPositions["media"].y !== undefined) ? config.widgetPositions["media"].y : defaultMediaY)
           : defaultMediaY

        Behavior on x {
            enabled: !isFreeLayout || !mediaDragArea.drag.active
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: !isFreeLayout || !mediaDragArea.drag.active
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        color: breezeTheme.isDark
               ? Qt.rgba(breezeTheme.background.r * 0.82, breezeTheme.background.g * 0.82, breezeTheme.background.b * 0.82, 0.94)
               : Qt.rgba(1.0, 1.0, 1.0, 0.94)
        border.color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.18)
        border.width: 1.5

        // Drag handler on card background
        MouseArea {
            id: mediaDragArea
            anchors.fill: parent
            enabled: isFreeLayout
            drag.target: mediaCard
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 16
            drag.minimumY: 16
            drag.maximumX: Math.max(16, root.width - mediaCard.width - 16)
            drag.maximumY: Math.max(16, root.height - mediaCard.height - 60)
            cursorShape: isFreeLayout ? Qt.SizeAllCursor : Qt.ArrowCursor
            z: -1

            onReleased: {
                if (isFreeLayout && config) {
                    config.setWidgetPosition("media", Math.round(mediaCard.x), Math.round(mediaCard.y))
                }
            }
        }

        // Move badge when free layout is active
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 12
            width: 22
            height: 22
            radius: 11
            color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.15)
            visible: isFreeLayout
            z: 20

            Image {
                anchors.centerIn: parent
                width: 12
                height: 12
                source: "image://icon/transform-move"
                sourceSize.width: 12
                sourceSize.height: 12
                fillMode: Image.PreserveAspectFit
                opacity: 0.8
            }
        }

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
            visible: (config && config.showTodoWidget !== undefined) ? config.showTodoWidget : true

            x: isFreeLayout
               ? ((config && config.widgetPositions["todo"] && config.widgetPositions["todo"].x !== undefined) ? config.widgetPositions["todo"].x : defaultTodoX)
               : defaultTodoX
            y: isFreeLayout
               ? ((config && config.widgetPositions["todo"] && config.widgetPositions["todo"].y !== undefined) ? config.widgetPositions["todo"].y : defaultTodoY)
               : defaultTodoY

            Behavior on x {
                enabled: !isFreeLayout || !todoDragArea.drag.active
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                enabled: !isFreeLayout || !todoDragArea.drag.active
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            color: breezeTheme.isDark
                   ? Qt.rgba(breezeTheme.background.r * 0.82, breezeTheme.background.g * 0.82, breezeTheme.background.b * 0.82, 0.94)
                   : Qt.rgba(1.0, 1.0, 1.0, 0.94)
            border.color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.18)
            border.width: 1.5

            // Drag handler on card background
            MouseArea {
                id: todoDragArea
                anchors.fill: parent
                enabled: isFreeLayout
                drag.target: todoCard
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 16
                drag.minimumY: 16
                drag.maximumX: Math.max(16, root.width - todoCard.width - 16)
                drag.maximumY: Math.max(16, root.height - todoCard.height - 60)
                cursorShape: isFreeLayout ? Qt.SizeAllCursor : Qt.ArrowCursor
                z: -1

                onReleased: {
                    if (isFreeLayout && config) {
                        config.setWidgetPosition("todo", Math.round(todoCard.x), Math.round(todoCard.y))
                    }
                }
            }

            // Move badge when free layout is active
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 12
                width: 22
                height: 22
                radius: 11
                color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.15)
                visible: isFreeLayout
                z: 20

                Image {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: "image://icon/transform-move"
                    sourceSize.width: 12
                    sourceSize.height: 12
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.8
                }
            }

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
                            color: breezeTheme.textPrimary
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
                        color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.08)
                        border.color: Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.15)
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
                            color: taskMouse.containsMouse ? Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.10) : Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.05)
                            border.color: taskMouse.containsMouse ? Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.20) : Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.10)
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
                                    border.color: modelData.done ? breezeTheme.accent : Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.3)
                                    border.width: 1.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: breezeTheme.textOnAccent
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
                                    color: modelData.done ? Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.35) : breezeTheme.textPrimary
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
                            text: "Нет активных задач\nДобавьте цель на текущую сессию"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            color: breezeTheme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Add Task Input Row
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Qt.rgba(breezeTheme.background.r, breezeTheme.background.g, breezeTheme.background.b, 0.6)
                    border.color: newTaskInput.activeFocus ? breezeTheme.accent : Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.15)
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
                        color: breezeTheme.textPrimary
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
                            color: breezeTheme.textSecondary
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
                        color: addBtnMouse.containsMouse ? breezeTheme.accent : Qt.rgba(breezeTheme.foreground.r, breezeTheme.foreground.g, breezeTheme.foreground.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 16
                            font.bold: true
                            color: addBtnMouse.containsMouse ? breezeTheme.textOnAccent : breezeTheme.textPrimary
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
            text: (config && config.desktopFreePositioning) ? "✓ Произвольный порядок" : "Произвольный порядок"
            onTriggered: {
                if (config) config.desktopFreePositioning = !config.desktopFreePositioning
            }
        }

        Action {
            text: "Выровнять значки по сетке"
            onTriggered: {
                if (config) config.alignShortcutsToGrid()
            }
        }

        Action {
            text: "Сбросить позиции виджетов"
            enabled: isFreeLayout
            onTriggered: {
                if (config) config.resetWidgetPositions()
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
