import QtQuick
import QtQuick.Controls

Dialog {
    id: root

    title: "Добавление программы"
    width: 620
    height: 520
    modal: true
    focus: true
    anchors.centerIn: parent

    property string targetMode: "desktop" // "desktop" or "background"

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
            border.color: Qt.rgba(0, 0, 0, 0.3)
            border.width: 1
            z: -1
        }
    }

    header: Rectangle {
        width: parent.width
        height: 56
        color: "transparent"

        Item {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            Text {
                text: root.targetMode === "desktop" ? "Добавить ярлык на рабочий стол" : "Добавить разрешённую фоновую программу"
                font.family: breezeTheme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
                color: breezeTheme.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: closeBtnMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "image://icon/window-close"
                    sourceSize.width: 14
                    sourceSize.height: 14
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: breezeTheme.borderSubtle
        }
    }

    contentItem: Column {
        spacing: 12
        anchors.fill: parent
        anchors.margins: 16

        // Search Bar & Manual File Button
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                width: parent.width - 150
                height: 36
                radius: breezeTheme.radiusButton
                color: breezeTheme.surfaceCard
                border.color: searchInput.activeFocus ? breezeTheme.accent : breezeTheme.borderSubtle
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Image {
                        width: 14
                        height: 14
                        source: "image://icon/edit-find"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    TextInput {
                        id: searchInput
                        width: parent.width - 32
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 13
                        color: breezeTheme.textPrimary
                        selectByMouse: true

                        Text {
                            text: "Быстрый поиск программ..."
                            color: breezeTheme.textDim
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 13
                            visible: !searchInput.text && !searchInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onTextChanged: {
                            if (desktopScanner) {
                                desktopScanner.filter_apps(text, categoryCombo.currentText)
                            }
                        }
                    }
                }
            }

            // Custom Binary / Script button with Breeze icon
            Rectangle {
                width: 140
                height: 36
                radius: breezeTheme.radiusButton
                color: manualMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                border.color: breezeTheme.borderSubtle
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Image {
                        width: 16
                        height: 16
                        source: "image://icon/document-open"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Обзор файла..."
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: breezeTheme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: manualMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mainController) {
                            mainController.pick_custom_file_dialog(root.targetMode)
                        }
                        root.close()
                    }
                }
            }
        }

        // Category Pills
        Row {
            spacing: 6
            width: parent.width

            ComboBox {
                id: categoryCombo
                model: (desktopScanner && desktopScanner.categories) ? desktopScanner.categories : ["Все"]
                width: 160
                height: 30

                background: Rectangle {
                    color: breezeTheme.surfaceCard
                    radius: breezeTheme.radiusButton
                    border.color: breezeTheme.borderSubtle
                    border.width: 1
                }

                contentItem: Text {
                    leftPadding: 10
                    text: categoryCombo.displayText
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 12
                    color: breezeTheme.textPrimary
                    verticalAlignment: Text.AlignVCenter
                }

                onCurrentTextChanged: {
                    if (desktopScanner) {
                        desktopScanner.filter_apps(searchInput.text, currentText)
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Найдено: " + ((desktopScanner && desktopScanner.searchResults) ? desktopScanner.searchResults.length : 0)
                font.family: breezeTheme.fontFamily
                font.pixelSize: 11
                color: breezeTheme.textDim
            }
        }

        // Applications List
        Rectangle {
            width: parent.width
            height: parent.height - y - 10
            color: breezeTheme.surfaceCard
            radius: breezeTheme.radiusCard
            border.color: breezeTheme.borderSubtle
            border.width: 1
            clip: true

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: 4
                model: (desktopScanner && desktopScanner.searchResults) ? desktopScanner.searchResults : []
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: itemDelegate
                    width: appList.width
                    height: 52
                    radius: breezeTheme.radiusButton
                    color: itemMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.08)) : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icon
                        Item {
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: "image://icon/" + (modelData.icon || "application-x-executable")
                                sourceSize.width: 36
                                sourceSize.height: 36
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }
                        }

                        // Name & Details
                        Column {
                            width: parent.width - 140
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: modelData.name || ""
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: breezeTheme.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: (modelData.comment || modelData.binary || modelData.exec || "")
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 11
                                color: breezeTheme.textDim
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Add Button
                        Rectangle {
                            width: 80
                            height: 28
                            radius: breezeTheme.radiusButton
                            anchors.verticalCenter: parent.verticalCenter
                            color: addBtnMouse.containsMouse ? breezeTheme.buttonPressed : breezeTheme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "+ Выбрать"
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: breezeTheme.textOnAccent
                            }

                            MouseArea {
                                id: addBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (config) {
                                        if (root.targetMode === "desktop") {
                                            config.addShortcut(
                                                modelData.id,
                                                modelData.name,
                                                modelData.exec,
                                                modelData.icon,
                                                modelData.category,
                                                48, 48
                                            )
                                        } else {
                                            config.addBackgroundApp(modelData.binary || modelData.exec)
                                        }
                                    }
                                    root.close()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }
}
