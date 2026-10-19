import QtQuick
import QtQuick.Controls

Popup {
    id: root

    width: 560
    height: 420
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    padding: 14

    BreezeTheme {
        id: breezeTheme
    }

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
            border.color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1
            z: -1
        }
    }

    contentItem: Column {
        anchors.fill: parent
        spacing: 10

        // Header: Title, Copy, Clear, Close
        Item {
            width: parent.width
            height: 32

            Row {
                spacing: 8
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    width: 22
                    height: 22
                    source: "image://icon/accessories-text-editor"
                    sourceSize.width: 22
                    sourceSize.height: 22
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Быстрые мысли сессии (Scratchpad)"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: breezeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                spacing: 6
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                // Copy Button
                Rectangle {
                    width: Math.max(88, cpText.implicitWidth + 16)
                    height: 26
                    radius: breezeTheme.radiusButton
                    color: cpMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Text {
                        id: cpText
                        anchors.centerIn: parent
                        text: "Скопировать"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        color: breezeTheme.textPrimary
                    }

                    MouseArea {
                        id: cpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (systemService) {
                                systemService.copyToClipboard(notesArea.text)
                            }
                        }
                    }
                }

                // Clear Button
                Rectangle {
                    width: Math.max(68, clrText.implicitWidth + 16)
                    height: 26
                    radius: breezeTheme.radiusButton
                    color: clrMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Text {
                        id: clrText
                        anchors.centerIn: parent
                        text: "Очистить"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        color: breezeTheme.textDim
                    }

                    MouseArea {
                        id: clrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (scratchpadService) scratchpadService.clear()
                            notesArea.text = ""
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // Subtitle Info
        Text {
            text: "Автоматически сохраняется в ~/.config/zatsu-focus/scratchpad.md. Вызов по Meta+N."
            font.family: breezeTheme.fontFamily
            font.pixelSize: 10
            color: breezeTheme.textDim
        }

        // Text Editor Surface
        Rectangle {
            width: parent.width
            height: parent.height - 76
            radius: breezeTheme.radiusCard
            color: breezeTheme.surfaceCard
            border.color: breezeTheme.borderSubtle
            border.width: 1
            clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: notesArea.implicitHeight
                clip: true

                TextArea.flickable: TextArea {
                    id: notesArea
                    wrapMode: TextEdit.Wrap
                    font.family: "Monospace"
                    font.pixelSize: 12
                    color: breezeTheme.textPrimary
                    selectionColor: breezeTheme.accent
                    selectedTextColor: breezeTheme.textOnAccent
                    selectByMouse: true
                    text: (scratchpadService && scratchpadService.text) ? scratchpadService.text : ""

                    onTextChanged: {
                        if (scratchpadService && text !== scratchpadService.text) {
                            scratchpadService.saveText(text)
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}
