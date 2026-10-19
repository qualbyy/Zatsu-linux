import QtQuick

Rectangle {
    id: root

    // Solid pitch black for OLED protection and zero distraction
    color: "#000000"
    anchors.fill: parent

    // Inconspicuous subtle watermark in the corner (almost invisible 5% opacity)
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 16
        text: "Zatsu Focus • Secondary Screen Disabled"
        font.family: "Noto Sans, sans-serif"
        font.pixelSize: 11
        color: Qt.rgba(1, 1, 1, 0.08)
    }
}
