import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string appId: ""
    property string appName: ""
    property string appExec: ""
    property string appIcon: "application-x-executable"
    property int initX: 48
    property int initY: 48

    property int dragStartX: initX
    property int dragStartY: initY
    property bool isSelected: false

    width: 96
    height: 104
    x: initX
    y: initY

    onInitXChanged: {
        root.x = initX
        root.dragStartX = initX
    }
    onInitYChanged: {
        root.y = initY
        root.dragStartY = initY
    }

    // Determine icon source
    readonly property string resolvedIconSource: {
        if (!appIcon) return "image://icon/application-x-executable"
        if (appIcon.startsWith("/") || appIcon.startsWith("file://")) {
            return appIcon.startsWith("file://") ? appIcon : "file://" + appIcon
        }
        return "image://icon/" + appIcon
    }

    Rectangle {
        id: hoverBg
        anchors.fill: parent
        anchors.margins: -4
        radius: 8
        color: root.isSelected
               ? (breezeTheme.isDark ? Qt.rgba(0.24, 0.45, 0.65, 0.45) : Qt.rgba(0.24, 0.45, 0.65, 0.25))
               : (mouseArea.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)) : "transparent")
        border.color: root.isSelected ? breezeTheme.accent : (mouseArea.containsMouse ? breezeTheme.accent : "transparent")
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 6
        width: parent.width

        Item {
            width: 52
            height: 52
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: iconImg
                anchors.fill: parent
                source: root.resolvedIconSource
                sourceSize.width: 52
                sourceSize.height: 52
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }

        Text {
            id: label
            text: root.appName
            width: parent.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: breezeTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "#ffffff"
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.85)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.threshold: 16
        drag.minimumX: 16
        drag.minimumY: 16
        drag.maximumX: (root.parent ? root.parent.width - root.width - 16 : 3000)
        drag.maximumY: (root.parent ? root.parent.height - root.height - 60 : 3000)

        onPressed: function(mouse) {
            root.dragStartX = root.x
            root.dragStartY = root.y
            root.isSelected = true
        }

        onDoubleClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton && root.appExec) {
                if (systemService) {
                    systemService.launchApp(root.appExec)
                }
            }
        }

        onReleased: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                var distMoved = Math.abs(root.x - root.dragStartX) + Math.abs(root.y - root.dragStartY)

                if (distMoved >= 20) {
                    // Actual deliberate drag occurred: snap to clean desktop grid
                    var startX = 48
                    var startY = 48
                    var spacingX = 116
                    var spacingY = 116

                    var col = Math.max(0, Math.round((root.x - startX) / spacingX))
                    var row = Math.max(0, Math.round((root.y - startY) / spacingY))

                    var finalX = startX + col * spacingX
                    var finalY = startY + row * spacingY

                    root.x = finalX
                    root.y = finalY
                    root.dragStartX = finalX
                    root.dragStartY = finalY

                    if (config) {
                        config.updateShortcutPosition(root.appId, finalX, finalY)
                    }
                } else {
                    // Click / micro-motion: strictly restore position without diagonal jump
                    root.x = root.dragStartX
                    root.y = root.dragStartY
                }
            }
        }
    }
}
