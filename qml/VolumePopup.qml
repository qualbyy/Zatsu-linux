import QtQuick
import QtQuick.Controls

Popup {
    id: root

    width: 260
    height: 120
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 12

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

    BreezeTheme {
        id: breezeTheme
    }

    contentItem: Column {
        width: root.availableWidth
        height: root.availableHeight
        spacing: 10

        // Header: Volume percentage & Mute toggle
        Item {
            width: parent.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: (systemService && systemService.isMuted) ? "Звук выключен" : ("Громкость: " + (systemService ? systemService.volume : 0) + "%")
                font.family: breezeTheme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: (systemService && systemService.isMuted) ? breezeTheme.danger : breezeTheme.textPrimary
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: muteMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (systemService && systemService.isMuted) ? "image://icon/audio-volume-muted" : "image://icon/audio-volume-high"
                    sourceSize.width: 16
                    sourceSize.height: 16
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) systemService.toggleMute()
                    }
                }
            }
        }

        // Volume Slider in KDE Breeze Style
        Slider {
            id: volSlider
            width: parent.width
            from: 0
            to: 100
            stepSize: 1
            value: systemService ? systemService.volume : 50

            onMoved: {
                if (systemService) {
                    systemService.setVolume(Math.round(volSlider.value))
                }
            }

            background: Rectangle {
                x: volSlider.leftPadding
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 6
                width: volSlider.availableWidth
                height: implicitHeight
                radius: 3
                color: breezeTheme.buttonBg

                Rectangle {
                    width: volSlider.visualPosition * parent.width
                    height: parent.height
                    color: (systemService && systemService.isMuted) ? breezeTheme.danger : breezeTheme.accent
                    radius: 3
                }
            }

            handle: Rectangle {
                x: volSlider.leftPadding + volSlider.visualPosition * (volSlider.availableWidth - width)
                y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: volSlider.pressed ? breezeTheme.buttonPressed : "#ffffff"
                border.color: breezeTheme.accent
                border.width: 2
            }
        }

        // Quick mute / 100% buttons
        Row {
            width: parent.width
            spacing: 8

            Rectangle {
                width: (parent.width - 8) / 2
                height: 24
                radius: breezeTheme.radiusButton
                color: btn1Mouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                Text {
                    anchors.centerIn: parent
                    text: "Без звука"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 11
                    color: breezeTheme.textDim
                }

                MouseArea {
                    id: btn1Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) systemService.setVolume(0)
                    }
                }
            }

            Rectangle {
                width: (parent.width - 8) / 2
                height: 24
                radius: breezeTheme.radiusButton
                color: btn2Mouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                Text {
                    anchors.centerIn: parent
                    text: "100%"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 11
                    color: breezeTheme.textDim
                }

                MouseArea {
                    id: btn2Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) systemService.setVolume(100)
                    }
                }
            }
        }
    }
}
