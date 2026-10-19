import QtQuick
import QtQuick.Controls

Popup {
    id: root

    BreezeTheme { id: breezeTheme }

    width: 320
    height: 340
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 14

    property date displayedDate: new Date()
    property date today: new Date()

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

    readonly property var monthNames: [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
    ]
    readonly property var dayNames: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    function prevMonth() {
        var y = displayedDate.getFullYear()
        var m = displayedDate.getMonth() - 1
        if (m < 0) { m = 11; y--; }
        displayedDate = new Date(y, m, 1)
    }

    function nextMonth() {
        var y = displayedDate.getFullYear()
        var m = displayedDate.getMonth() + 1
        if (m > 11) { m = 0; y++; }
        displayedDate = new Date(y, m, 1)
    }

    function resetToToday() {
        today = new Date()
        displayedDate = new Date()
    }

    // Reactive calendar cells calculation (42 days)
    readonly property var calendarDays: {
        var y = displayedDate.getFullYear()
        var m = displayedDate.getMonth()

        var firstDayOfWeek = new Date(y, m, 1).getDay() // 0 is Sunday
        var startOffset = (firstDayOfWeek === 0 ? 6 : firstDayOfWeek - 1) // Monday is 0

        var daysInMonth = new Date(y, m + 1, 0).getDate()
        var daysInPrevMonth = new Date(y, m, 0).getDate()

        var cells = []

        // Previous month days
        for (var i = startOffset - 1; i >= 0; i--) {
            cells.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            })
        }

        // Current month days
        var tYear = today.getFullYear()
        var tMonth = today.getMonth()
        var tDate = today.getDate()

        for (var d = 1; d <= daysInMonth; d++) {
            var isTod = (y === tYear && m === tMonth && d === tDate)
            cells.push({
                day: d,
                isCurrentMonth: true,
                isToday: isTod
            })
        }

        // Next month days to fill 42 cells (6 rows * 7)
        var remaining = 42 - cells.length
        for (var nd = 1; nd <= remaining; nd++) {
            cells.push({
                day: nd,
                isCurrentMonth: false,
                isToday: false
            })
        }

        return cells
    }

    contentItem: Column {
        width: root.availableWidth
        height: root.availableHeight
        spacing: 10

        // Month Navigation Header
        Item {
            width: parent.width
            height: 32

            Rectangle {
                width: 28
                height: 28
                radius: breezeTheme.radiusButton
                color: prevMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: "image://icon/go-previous"
                    sourceSize.width: 14
                    sourceSize.height: 14
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.prevMonth()
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.monthNames[root.displayedDate.getMonth()] + " " + root.displayedDate.getFullYear()
                font.family: breezeTheme.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
                color: breezeTheme.textPrimary
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 60
                    height: 28
                    radius: breezeTheme.radiusButton
                    color: todayMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                    Text {
                        anchors.centerIn: parent
                        text: "Сегодня"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: breezeTheme.textPrimary
                    }

                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.resetToToday()
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: breezeTheme.radiusButton
                    color: nextMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg

                    Image {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        source: "image://icon/go-next"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.nextMonth()
                    }
                }
            }
        }

        // Days of week header
        Row {
            width: parent.width
            height: 24

            Repeater {
                model: root.dayNames

                Item {
                    width: parent.width / 7
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: (index >= 5) ? breezeTheme.warning : breezeTheme.textDim
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: breezeTheme.borderSubtle
        }

        // 42-day Month Grid
        Grid {
            columns: 7
            width: parent.width
            height: parent.height - y - 6

            Repeater {
                model: root.calendarDays

                Item {
                    width: parent.width / 7
                    height: (parent.height) / 6

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: modelData.isToday ? breezeTheme.accent : (cellMouse.containsMouse ? breezeTheme.buttonHover : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 12
                            font.weight: modelData.isToday ? Font.Bold : Font.Normal
                            color: modelData.isToday
                                   ? breezeTheme.textOnAccent
                                   : (modelData.isCurrentMonth ? breezeTheme.textPrimary : breezeTheme.textDim)
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }
    }
}
