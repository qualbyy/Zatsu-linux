import QtQuick
import QtQuick.Controls

Popup {
    id: root

    width: 380
    height: 360
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    padding: 12

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
        spacing: 8

        // Header
        Item {
            width: parent.width
            height: 28

            Row {
                spacing: 8
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    width: 20
                    height: 20
                    source: "image://icon/klipper"
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "История буфера обмена (Klipper)"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: breezeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: closeBtnMouse.containsMouse ? breezeTheme.buttonHover : "transparent"

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
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: breezeTheme.borderSubtle
        }

        // Empty state
        Text {
            visible: !clipList.count
            width: parent.width
            text: "История буфера обмена пуста"
            font.family: breezeTheme.fontFamily
            font.pixelSize: 12
            color: breezeTheme.textDim
            horizontalAlignment: Text.AlignHCenter
            topPadding: 30
        }

        // Clipboard History List
        ListView {
            id: clipList
            width: parent.width
            height: parent.height - 44
            clip: true
            spacing: 4
            model: (systemService && systemService.clipboardHistory) ? systemService.clipboardHistory : []

            delegate: Rectangle {
                id: itemCard
                width: clipList.width
                height: Math.max(34, itemText.implicitHeight + 14)
                radius: breezeTheme.radiusButton
                color: itemMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.surfaceCard
                border.color: breezeTheme.borderSubtle
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Image {
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://icon/edit-copy"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: itemText
                        width: parent.width - 24
                        text: modelData || ""
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        color: breezeTheme.textPrimary
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WrapAnywhere
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (systemService) {
                            systemService.selectClipboardItem(modelData)
                        }
                        root.close()
                    }
                }
            }
        }
    }
}
