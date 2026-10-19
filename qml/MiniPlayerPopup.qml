import QtQuick
import QtQuick.Controls

Popup {
    id: root

    BreezeTheme { id: breezeTheme }

    width: 380
    height: 520
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    property int currentView: 0 // 0: MPRIS, 1: Ambient Soundscapes

    background: Rectangle {
        radius: breezeTheme.radiusPopup
        color: breezeTheme.surfaceElevated
        border.color: breezeTheme.borderSubtle
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.25)
            border.width: 1
            z: -1
        }
    }

    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "00:00"
        var s = Math.floor(seconds)
        var m = Math.floor(s / 60)
        var sec = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (sec < 10 ? "0" : "") + sec
    }

    contentItem: Column {
        spacing: 12
        anchors.fill: parent
        anchors.margins: 16

        // Header: Title & Close button
        Item {
            width: parent.width
            height: 24

            Text {
                text: root.currentView === 0 ? "Медиаплеер" : "Звуковые пейзажи фокуса"
                font.family: breezeTheme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: breezeTheme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: closeMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    source: "image://icon/window-close"
                    sourceSize.width: 12
                    sourceSize.height: 12
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.close()
                }
            }
        }

        // Tab switcher: MPRIS vs Ambient
        Row {
            width: parent.width
            height: 28
            spacing: 6

            Rectangle {
                width: (parent.width - 6) / 2
                height: 28
                radius: breezeTheme.radiusButton
                color: root.currentView === 0 ? breezeTheme.accent : (mprisTabMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Image {
                        source: "image://icon/audio-x-generic"
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Медиаплеер"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: root.currentView === 0 ? Font.Bold : Font.Normal
                        color: root.currentView === 0 ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: mprisTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentView = 0
                }
            }

            Rectangle {
                width: (parent.width - 6) / 2
                height: 28
                radius: breezeTheme.radiusButton
                color: root.currentView === 1 ? breezeTheme.accent : (ambTabMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Image {
                        source: "image://icon/audio-headphones"
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Звуки фокуса"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: root.currentView === 1 ? Font.Bold : Font.Normal
                        color: root.currentView === 1 ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: ambTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.currentView = 1
                }
            }
        }

        // Container for Views
        Item {
            width: parent.width
            height: 416

            // =================================================================
            // VIEW 0: MPRIS PLAYER VIEW
            // =================================================================
            Column {
                width: parent.width
                height: parent.height
                spacing: 12
                visible: root.currentView === 0

            // Top section: Album Art + Track Info
            Row {
                width: parent.width
                spacing: 14

            Rectangle {
                width: 72
                height: 72
                radius: 8
                color: breezeTheme.surfaceCard
                border.color: breezeTheme.borderSubtle
                border.width: 1
                clip: true

                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: (mpris && mpris.artUrl) ? mpris.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Image {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: "image://icon/audio-x-generic"
                    sourceSize.width: 32
                    sourceSize.height: 32
                    fillMode: Image.PreserveAspectFit
                    visible: !coverImg.visible
                }
            }

            Column {
                width: parent.width - 86
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: (mpris && mpris.title) ? mpris.title : "Неизвестный трек"
                    width: parent.width
                    elide: Text.ElideRight
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: breezeTheme.textPrimary
                }

                Text {
                    text: (mpris && mpris.artist) ? mpris.artist : "Неизвестный артист"
                    width: parent.width
                    elide: Text.ElideRight
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 12
                    color: breezeTheme.textSecondary
                }

                Text {
                    text: (mpris && mpris.album) ? mpris.album : ""
                    width: parent.width
                    elide: Text.ElideRight
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 11
                    color: breezeTheme.textDim
                    visible: text.length > 0
                }
            }
        }

        // Progress Bar & Timers
        Column {
            width: parent.width
            spacing: 2

            Slider {
                id: progressSlider
                width: parent.width
                from: 0
                to: Math.max(1, (mpris && mpris.duration) ? mpris.duration : 1)
                value: (mpris && mpris.position) ? mpris.position : 0
                enabled: mpris && mpris.duration > 0

                onMoved: {
                    if (mpris) mpris.seek(value)
                }

                background: Rectangle {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: progressSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: breezeTheme.surfaceCard

                    Rectangle {
                        width: progressSlider.visualPosition * parent.width
                        height: parent.height
                        color: breezeTheme.accent
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: progressSlider.pressed ? breezeTheme.buttonHover : "#ffffff"
                    border.color: breezeTheme.accent
                    border.width: 2
                }
            }

            Item {
                width: parent.width
                height: 16

                Text {
                    text: formatTime(mpris ? mpris.position : 0)
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 10
                    color: breezeTheme.textDim
                }

                Text {
                    anchors.right: parent.right
                    text: formatTime(mpris ? mpris.duration : 0)
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 10
                    color: breezeTheme.textDim
                }
            }
        }

        // Playback Buttons with Breeze Icons
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            // Previous
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: prevMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "image://icon/media-skip-backward"
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mpris) mpris.previousTrack()
                    }
                }
            }

            // Play / Pause
            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: breezeTheme.accent

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: (mpris && mpris.playbackStatus === "Playing")
                            ? "image://icon/media-playback-pause"
                            : "image://icon/media-playback-start"
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (mpris) mpris.playPause()
                    }
                }
            }

            // Next
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: nextMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "image://icon/media-skip-forward"
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mpris) mpris.nextTrack()
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: breezeTheme.borderSubtle
        }

        // Synchronized Lyrics View
        Item {
            width: parent.width
            height: parent.height - y - 16

            Text {
                anchors.centerIn: parent
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: (mpris && mpris.plainLyrics) ? mpris.plainLyrics : "Текст песни не найден."
                font.family: breezeTheme.fontFamily
                font.pixelSize: 13
                color: breezeTheme.textDim
                visible: !mpris || !mpris.syncedLyrics || mpris.syncedLyrics.length === 0
            }

            ListView {
                id: lyricsList
                anchors.fill: parent
                clip: true
                model: (mpris && mpris.syncedLyrics) ? mpris.syncedLyrics : []
                visible: mpris && mpris.syncedLyrics && mpris.syncedLyrics.length > 0
                spacing: 6

                delegate: Item {
                    width: lyricsList.width
                    height: lyricText.implicitHeight + 8
                    readonly property bool isActive: (mpris && index === mpris.currentLyricIndex)

                    Text {
                        id: lyricText
                        width: parent.width - 16
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: modelData.text || "..."
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: isActive ? 14 : 12
                        font.weight: isActive ? Font.Bold : Font.Normal
                        color: isActive ? breezeTheme.accent : breezeTheme.textDim

                        Behavior on color {
                            ColorAnimation { duration: 180 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mpris && modelData.time !== undefined) {
                                mpris.seek(modelData.time)
                            }
                        }
                    }
                }

                Connections {
                    target: mpris ? mpris : null
                    function onCurrentLyricIndexChanged(idx) {
                        if (idx >= 0 && idx < lyricsList.count) {
                            lyricsList.positionViewAtIndex(idx, ListView.Center)
                        }
                    }
                }
            }
        }
        }

        // =================================================================
        // VIEW 1: AMBIENT SOUNDSCAPES VIEW
        // =================================================================
        Column {
            width: parent.width
            height: parent.height
            spacing: 10
            visible: root.currentView === 1

            // Volume Control & Master Play/Stop
            Rectangle {
                width: parent.width
                height: 48
                radius: breezeTheme.radiusCard
                color: breezeTheme.surfaceCard
                border.color: breezeTheme.borderSubtle
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    // Master Toggle Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: (ambientService && ambientService.isPlaying) ? breezeTheme.accent : breezeTheme.buttonBg
                        border.color: breezeTheme.borderSubtle
                        border.width: 1
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: (ambientService && ambientService.isPlaying)
                                    ? "image://icon/media-playback-pause"
                                    : "image://icon/media-playback-start"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (ambientService) ambientService.togglePlay()
                            }
                        }
                    }

                    Image {
                        width: 16
                        height: 16
                        source: "image://icon/audio-volume-high"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Slider {
                        id: ambVolSlider
                        width: parent.width - 100
                        anchors.verticalCenter: parent.verticalCenter
                        from: 0
                        to: 100
                        value: (ambientService ? ambientService.volume : 45)
                        onMoved: {
                            if (ambientService) ambientService.setVolume(value)
                        }

                        background: Rectangle {
                            x: ambVolSlider.leftPadding
                            y: ambVolSlider.topPadding + ambVolSlider.availableHeight / 2 - height / 2
                            implicitWidth: 100
                            implicitHeight: 4
                            width: ambVolSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: breezeTheme.buttonBg

                            Rectangle {
                                width: ambVolSlider.visualPosition * parent.width
                                height: parent.height
                                color: breezeTheme.accent
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: ambVolSlider.leftPadding + ambVolSlider.visualPosition * (ambVolSlider.availableWidth - width)
                            y: ambVolSlider.topPadding + ambVolSlider.availableHeight / 2 - height / 2
                            implicitWidth: 12
                            implicitHeight: 12
                            radius: 6
                            color: ambVolSlider.pressed ? breezeTheme.buttonHover : "#ffffff"
                            border.color: breezeTheme.accent
                            border.width: 2
                        }
                    }

                    Text {
                        text: Math.round(ambVolSlider.value) + "%"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: breezeTheme.textDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Sound Presets List
            ListView {
                id: ambientList
                width: parent.width
                height: parent.height - 58
                clip: true
                spacing: 8
                model: (ambientService && ambientService.presets) ? ambientService.presets : []

                delegate: Rectangle {
                    id: ambDelegate
                    width: ambientList.width
                    height: 54
                    radius: breezeTheme.radiusCard
                    readonly property bool isCurrent: (ambientService && ambientService.activeSound === modelData.id)
                    readonly property bool isPlayingNow: (isCurrent && ambientService && ambientService.isPlaying)
                    color: isPlayingNow ? Qt.rgba(0.24, 0.51, 0.89, 0.18) : (ambCardMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.surfaceCard)
                    border.color: isPlayingNow ? breezeTheme.accent : breezeTheme.borderSubtle
                    border.width: isPlayingNow ? 1.5 : 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        // Icon container
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: ambDelegate.isPlayingNow ? breezeTheme.accent : breezeTheme.buttonBg
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: "image://icon/" + (modelData.icon || "audio-headphones")
                                sourceSize.width: 16
                                sourceSize.height: 16
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        // Texts
                        Column {
                            width: parent.width - 86
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: modelData.name || ""
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: ambDelegate.isPlayingNow ? Font.Bold : Font.DemiBold
                                color: ambDelegate.isPlayingNow ? breezeTheme.accent : breezeTheme.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.desc || ""
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 10
                                color: breezeTheme.textDim
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Play / Pause Icon Button
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: ambDelegate.isPlayingNow ? breezeTheme.accent : breezeTheme.buttonBg
                            border.color: breezeTheme.borderSubtle
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                source: ambDelegate.isPlayingNow ? "image://icon/media-playback-pause" : "image://icon/media-playback-start"
                                sourceSize.width: 12
                                sourceSize.height: 12
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                    }

                    MouseArea {
                        id: ambCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (ambientService) {
                                ambientService.playSound(modelData.id)
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
