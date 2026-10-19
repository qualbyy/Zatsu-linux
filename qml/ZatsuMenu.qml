import QtQuick
import QtQuick.Controls

Popup {
    id: root

    width: 660
    height: 560
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    signal requestAddApp(string mode)
    signal requestChangeWallpaper()

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

    contentItem: Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Top Header: Title & Close
        Item {
            width: parent.width
            height: 32

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    width: 24
                    height: 24
                    source: "image://icon/start-here-kde"
                    sourceSize.width: 24
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Zatsu Focus"
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: breezeTheme.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: closeMenuMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.1)) : "transparent"

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
                    id: closeMenuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.close()
                }
            }
        }

        // 5 Tabs Bar
        Row {
            width: parent.width
            height: 34
            spacing: 4

            readonly property var tabs: ["Фокусировка", "Рабочий стол", "Программы", "Горячие клавиши", "Внешний вид"]
            property int currentTab: 0

            id: tabRow

            Repeater {
                model: tabRow.tabs

                Rectangle {
                    width: (tabRow.width - (tabRow.tabs.length - 1) * tabRow.spacing) / tabRow.tabs.length
                    height: 34
                    radius: breezeTheme.radiusButton
                    color: (tabRow.currentTab === index) ? breezeTheme.accent : (tabMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 6
                        text: modelData
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 11
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: tabRow.currentTab === index ? Font.Bold : Font.Normal
                        color: tabRow.currentTab === index ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: tabRow.currentTab = index
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: breezeTheme.borderSubtle
        }

        // Tab Contents Container
        Item {
            width: parent.width
            height: parent.height - y - 10

            // -------------------------------------------------------------
            // -------------------------------------------------------------
            // TAB 1: ФОКУСИРОВКА
            // -------------------------------------------------------------
            Flickable {
                anchors.fill: parent
                visible: tabRow.currentTab === 0
                contentHeight: tab1Col.implicitHeight + 20
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: tab1Col
                    width: parent.width - 10
                    spacing: 12

                    // 1. Strict Mode Card
                    Rectangle {
                        width: parent.width
                        height: 72
                        radius: breezeTheme.radiusCard
                        color: breezeTheme.surfaceCard
                        readonly property bool isStrict: (config && config.strictMode) ? true : false
                        border.color: isStrict ? breezeTheme.danger : breezeTheme.borderSubtle
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                width: parent.width - 70
                                spacing: 3
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    spacing: 6
                                    Text {
                                        text: "Строгий режим (Strict Blocker)"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: parent.parent.parent.parent.isStrict ? "АКТИВЕН" : "ВЫКЛ"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: parent.parent.parent.parent.isStrict ? breezeTheme.danger : breezeTheme.textDim
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    text: "Автоматически закрывает любые сторонние процессы, отсутствующие в белом списке."
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 10
                                    color: breezeTheme.textSecondary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Switch {
                                checked: (config && config.strictMode) ? true : false
                                anchors.verticalCenter: parent.verticalCenter
                                onToggled: {
                                    if (config) config.strictMode = checked
                                }
                            }
                        }
                    }

                    // 2. Session Duration & Pomodoro Card
                    Rectangle {
                        width: parent.width
                        height: 180
                        radius: breezeTheme.radiusCard
                        color: breezeTheme.surfaceCard
                        border.color: breezeTheme.borderSubtle
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 28

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (config && config.timerMode === "pomodoro") 
                                          ? ("Pomodoro: " + ((systemService && systemService.remainingFormatted) ? systemService.remainingFormatted : "25:00") + 
                                             (systemService && systemService.pomodoroPhase === "break" ? " (Перерыв)" : " (Фокус)"))
                                          : ("Таймер: " + ((systemService && systemService.remainingFormatted) ? systemService.remainingFormatted : "25:00") + " (осталось)")
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: (systemService && systemService.pomodoroPhase === "break") ? "#2ecc71" : breezeTheme.textPrimary
                                }

                                // Mode Selector (Countdown vs Pomodoro)
                                Row {
                                    anchors.right: parent.right
                                    spacing: 4
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        id: ordBtn
                                        width: Math.max(76, tOrd.implicitWidth + 18)
                                        height: 24
                                        radius: 12
                                        readonly property bool isSel: (!config || config.timerMode !== "pomodoro")
                                        color: isSel ? breezeTheme.accent : breezeTheme.buttonBg
                                        border.color: breezeTheme.borderSubtle
                                        border.width: 1

                                        Text {
                                            id: tOrd
                                            anchors.centerIn: parent
                                            text: "Обычный"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: ordBtn.isSel ? Font.Bold : Font.Normal
                                            color: ordBtn.isSel ? breezeTheme.textOnAccent : breezeTheme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (config) config.timerMode = "countdown"
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: pomoBtn
                                        width: Math.max(106, tPomo.implicitWidth + 18)
                                        height: 24
                                        radius: 12
                                        readonly property bool isSel: (config && config.timerMode === "pomodoro")
                                        color: isSel ? breezeTheme.accent : breezeTheme.buttonBg
                                        border.color: breezeTheme.borderSubtle
                                        border.width: 1

                                        Text {
                                            id: tPomo
                                            anchors.centerIn: parent
                                            text: "Pomodoro 25/5"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: pomoBtn.isSel ? Font.Bold : Font.Normal
                                            color: pomoBtn.isSel ? breezeTheme.textOnAccent : breezeTheme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (config) {
                                                    config.timerMode = "pomodoro"
                                                    config.sessionDurationMinutes = 25
                                                    if (systemService) systemService.setSessionMinutes(25)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Presets
                            Grid {
                                columns: 4
                                spacing: 6
                                width: parent.width

                                readonly property var presets: [
                                    { label: "15 мин", mins: 15 },
                                    { label: "25 мин", mins: 25 },
                                    { label: "45 мин", mins: 45 },
                                    { label: "1 час", mins: 60 },
                                    { label: "2 часа", mins: 120 },
                                    { label: "4 часа", mins: 240 },
                                    { label: "8 часов", mins: 480 },
                                    { label: "12 часов", mins: 720 }
                                ]

                                Repeater {
                                    model: parent.presets

                                    Rectangle {
                                        width: (parent.width - 18) / 4
                                        height: 28
                                        radius: breezeTheme.radiusButton
                                        readonly property bool isSelected: (config ? config.sessionDurationMinutes === modelData.mins : modelData.mins === 25)
                                        color: isSelected ? breezeTheme.accent : (pMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: parent.isSelected ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                        }

                                        MouseArea {
                                            id: pMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (config) config.sessionDurationMinutes = modelData.mins
                                                if (systemService) systemService.setSessionMinutes(modelData.mins)
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 10
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: Math.max(150, tRes.implicitWidth + 24)
                                    height: 26
                                    radius: breezeTheme.radiusButton
                                    color: resMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                                    border.color: breezeTheme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: tRes
                                        anchors.centerIn: parent
                                        text: "Перезапустить таймер"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textPrimary
                                    }

                                    MouseArea {
                                        id: resMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (systemService) systemService.reset_timer()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Productivity Analytics & Streak Card
                    Rectangle {
                        width: parent.width
                        height: 148
                        radius: breezeTheme.radiusCard
                        color: breezeTheme.surfaceCard
                        border.color: breezeTheme.borderSubtle
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 22

                                Row {
                                    spacing: 6
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        width: 16
                                        height: 16
                                        source: "image://icon/office-chart-bar"
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        fillMode: Image.PreserveAspectFit
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Статистика продуктивности"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Сохраняется в stats.json"
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 10
                                    color: breezeTheme.textDim
                                }
                            }

                            // 4 Metrics Row
                            Row {
                                width: parent.width
                                spacing: 6

                                // Today
                                Rectangle {
                                    width: (parent.width - 18) / 4
                                    height: 44
                                    radius: breezeTheme.radiusButton
                                    color: breezeTheme.surfaceElevated
                                    border.color: breezeTheme.borderSubtle
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            text: (statsService && statsService.todayMinutesFormatted) ? statsService.todayMinutesFormatted : "0 мин"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: breezeTheme.accent
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: "Сегодня"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 9
                                            color: breezeTheme.textDim
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                // Streak
                                Rectangle {
                                    width: (parent.width - 18) / 4
                                    height: 44
                                    radius: breezeTheme.radiusButton
                                    color: breezeTheme.surfaceElevated
                                    border.color: breezeTheme.borderSubtle
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            text: ((statsService ? statsService.streakDays : 0) + " дн.")
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: "#e67e22"
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: "Серия"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 9
                                            color: breezeTheme.textDim
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                // Pomodoros
                                Rectangle {
                                    width: (parent.width - 18) / 4
                                    height: 44
                                    radius: breezeTheme.radiusButton
                                    color: breezeTheme.surfaceElevated
                                    border.color: breezeTheme.borderSubtle
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            text: "" + (statsService ? statsService.pomodoroCycles : 0)
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: "#2ecc71"
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: "Pomodoro"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 9
                                            color: breezeTheme.textDim
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }

                                // Total
                                Rectangle {
                                    width: (parent.width - 18) / 4
                                    height: 44
                                    radius: breezeTheme.radiusButton
                                    color: breezeTheme.surfaceElevated
                                    border.color: breezeTheme.borderSubtle
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            text: (statsService && statsService.totalFocusFormatted) ? statsService.totalFocusFormatted : "0 мин"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: breezeTheme.textPrimary
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                        Text {
                                            text: "Всего"
                                            font.family: breezeTheme.fontFamily
                                            font.pixelSize: 9
                                            color: breezeTheme.textDim
                                            horizontalAlignment: Text.AlignHCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }
                                }
                            }

                            // 7-Day Mini Bar Chart
                            Row {
                                width: parent.width
                                height: 50
                                spacing: 4

                                Repeater {
                                    model: (statsService && statsService.weeklyData) ? statsService.weeklyData : []

                                    Rectangle {
                                        width: (parent.width - 24) / 7
                                        height: parent.height
                                        color: "transparent"

                                        Column {
                                            anchors.fill: parent
                                            spacing: 3

                                            Item {
                                                width: parent.width
                                                height: 32

                                                Rectangle {
                                                    width: parent.width - 6
                                                    height: Math.max(4, 32 * modelData.heightPct)
                                                    radius: 3
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    color: modelData.isToday ? breezeTheme.accent : (modelData.minutes > 0 ? Qt.rgba(0.24, 0.51, 0.89, 0.45) : breezeTheme.buttonBg)
                                                }
                                            }

                                            Text {
                                                text: modelData.day
                                                font.family: breezeTheme.fontFamily
                                                font.pixelSize: 9
                                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                                color: modelData.isToday ? breezeTheme.accent : breezeTheme.textDim
                                                horizontalAlignment: Text.AlignHCenter
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 4. Smart Focus Tools Card
                    Rectangle {
                        width: parent.width
                        height: 136
                        radius: breezeTheme.radiusCard
                        color: breezeTheme.surfaceCard
                        border.color: breezeTheme.borderSubtle
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Web Blocker Row
                            Row {
                                width: parent.width
                                height: 32
                                spacing: 8

                                Image {
                                    width: 18
                                    height: 18
                                    source: "image://icon/internet-web-browser"
                                    sourceSize.width: 18
                                    sourceSize.height: 18
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: "Блокировщик отвлекающих сайтов"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Блокирует YouTube, соцсети и развлекательные страницы"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 9
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (webBlocker && webBlocker.enabled) ? true : false
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (webBlocker) webBlocker.toggle()
                                    }
                                }
                            }

                            // Do Not Disturb Row
                            Row {
                                width: parent.width
                                height: 32
                                spacing: 8

                                Image {
                                    width: 18
                                    height: 18
                                    source: "image://icon/notifications-disabled"
                                    sourceSize.width: 18
                                    sourceSize.height: 18
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: "Режим «Не беспокоить» (KDE Plasma DND)"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Временно отключает системные всплывающие уведомления"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 9
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (systemService ? systemService.doNotDisturb : false)
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (systemService) systemService.doNotDisturb = checked
                                    }
                                }
                            }

                            // Mini-Timer PiP Row
                            Row {
                                width: parent.width
                                height: 32
                                spacing: 8

                                Image {
                                    width: 18
                                    height: 18
                                    source: "image://icon/view-restore"
                                    sourceSize.width: 18
                                    sourceSize.height: 18
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: "Плавающий мини-таймер (PiP)"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Перетаскиваемый компактный виджет поверх всех окон (Meta+T)"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 9
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (config && config.showMiniTimer) ? true : false
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (config) config.showMiniTimer = checked
                                    }
                                }
                            }
                        }
                    }

                    // 5. Exit Focus Mode Button (Breeze system icon)
                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: breezeTheme.radiusCard
                        color: exitMouse.containsMouse ? "#d94343" : breezeTheme.danger

                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Image {
                                width: 20
                                height: 20
                                source: "image://icon/system-log-out"
                                sourceSize.width: 20
                                sourceSize.height: 20
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Покинуть режим фокусировки"
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: exitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (shellManager) shellManager.exit_focus_mode()
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // TAB 2: РАБОЧИЙ СТОЛ
            // -------------------------------------------------------------
            Column {
                anchors.fill: parent
                visible: tabRow.currentTab === 1
                spacing: 10

                // Desktop Widgets Controls Card
                Rectangle {
                    width: parent.width
                    height: 124
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Row 1: Clock & Todo
                        Row {
                            width: parent.width
                            spacing: 16

                            // Clock Widget Switch
                            Row {
                                width: (parent.width - 16) / 2
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Column {
                                    width: parent.width - 56
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Фокус-часы"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Большие часы по центру"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (config ? config.showDesktopClock : true)
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (config) config.showDesktopClock = checked
                                    }
                                }
                            }

                            // Todo Widget Switch
                            Row {
                                width: (parent.width - 16) / 2
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Column {
                                    width: parent.width - 56
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Виджет задач"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Цели и задачи дня (Todo)"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (config ? config.showTodoWidget : true)
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (config) config.showTodoWidget = checked
                                    }
                                }
                            }
                        }

                        // Divider line
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: breezeTheme.borderSubtle
                            opacity: 0.5
                        }

                        // Row 2: Media Player & Free Positioning
                        Row {
                            width: parent.width
                            spacing: 16

                            // Media Player Switch (Default OFF)
                            Row {
                                width: (parent.width - 16) / 2
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Column {
                                    width: parent.width - 56
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Медиаплеер"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Плеер MPRIS и трек"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (config ? config.showDesktopMedia : false)
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (config) config.showDesktopMedia = checked
                                    }
                                }
                            }

                            // Free Positioning Switch
                            Row {
                                width: (parent.width - 16) / 2
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Column {
                                    width: parent.width - 56
                                    spacing: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "Свободный порядок"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: breezeTheme.textPrimary
                                    }
                                    Text {
                                        text: "Произвольное перемещение"
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textDim
                                    }
                                }

                                Switch {
                                    checked: (config ? config.desktopFreePositioning : false)
                                    anchors.verticalCenter: parent.verticalCenter
                                    onToggled: {
                                        if (config) config.desktopFreePositioning = checked
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 28

                    Text {
                        text: "Ярлыки на рабочем столе (" + ((config && config.desktopShortcuts) ? config.desktopShortcuts.length : 0) + ")"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: breezeTheme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: Math.max(140, addDeskText.implicitWidth + 24)
                        height: 28
                        radius: breezeTheme.radiusButton
                        color: addDeskMouse.containsMouse ? breezeTheme.buttonPressed : breezeTheme.accent
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: addDeskText
                            anchors.centerIn: parent
                            text: "+ Добавить ярлык"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: breezeTheme.textOnAccent
                        }

                        MouseArea {
                            id: addDeskMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.requestAddApp("desktop")
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 140
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1
                    clip: true

                    ListView {
                        id: shortcutsList
                        anchors.fill: parent
                        anchors.margins: 6
                        model: (config && config.desktopShortcuts) ? config.desktopShortcuts : []
                        spacing: 4

                        delegate: Rectangle {
                            width: shortcutsList.width
                            height: 42
                            radius: breezeTheme.radiusButton
                            color: scMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 10

                                Image {
                                    width: 26
                                    height: 26
                                    source: "image://icon/" + (modelData.icon || "application-x-executable")
                                    sourceSize.width: 26
                                    sourceSize.height: 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                Column {
                                    width: parent.width - 100
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1

                                    Text {
                                        text: modelData.name || ""
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: breezeTheme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.exec || ""
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 10
                                        color: breezeTheme.textDim
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: delScMouse.containsMouse ? breezeTheme.danger : "transparent"

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
                                        id: delScMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (config) config.removeShortcut(index)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: scMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: breezeTheme.radiusButton
                    color: gridBtnMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Image {
                            width: 14
                            height: 14
                            source: "image://icon/view-grid"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Выровнять все значки по сетке"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 12
                            color: breezeTheme.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: gridBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (config) config.alignShortcutsToGrid()
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // TAB 3: ПРОГРАММЫ (ФОНОВЫЙ БЕЛЫЙ СПИСОК)
            // -------------------------------------------------------------
            Column {
                anchors.fill: parent
                visible: tabRow.currentTab === 2
                spacing: 10

                Item {
                    width: parent.width
                    height: 28

                    Text {
                        text: "Разрешённые фоновые процессы (" + ((config && config.allowedBackgroundApps) ? config.allowedBackgroundApps.length : 0) + ")"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: breezeTheme.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 140
                        height: 28
                        radius: breezeTheme.radiusButton
                        color: addBgMouse.containsMouse ? breezeTheme.buttonPressed : breezeTheme.accent
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "+ Разрешить процесс"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: breezeTheme.textOnAccent
                        }

                        MouseArea {
                            id: addBgMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.requestAddApp("background")
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: parent.height - 40
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1
                    clip: true

                    ListView {
                        id: bgList
                        anchors.fill: parent
                        anchors.margins: 6
                        model: (config && config.allowedBackgroundApps) ? config.allowedBackgroundApps : []
                        spacing: 4

                        delegate: Rectangle {
                            width: bgList.width
                            height: 36
                            radius: breezeTheme.radiusButton
                            color: bgItemMouse.containsMouse ? (breezeTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Image {
                                    width: 16
                                    height: 16
                                    source: "image://icon/preferences-system"
                                    sourceSize.width: 16
                                    sourceSize.height: 16
                                    fillMode: Image.PreserveAspectFit
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: modelData
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: breezeTheme.textPrimary
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 80
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: delBgMouse.containsMouse ? breezeTheme.danger : "transparent"

                                    Image {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        source: "image://icon/edit-delete"
                                        sourceSize.width: 10
                                        sourceSize.height: 10
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    MouseArea {
                                        id: delBgMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (config) config.removeBackgroundApp(modelData)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: bgItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // TAB 4: ГОРЯЧИЕ КЛАВИШИ (HOTKEYS CONFIGURATION)
            // -------------------------------------------------------------
            Column {
                anchors.fill: parent
                visible: tabRow.currentTab === 3
                spacing: 8

                // Header with Reset button
                Item {
                    width: parent.width
                    height: 28

                    Text {
                        text: "Настройка горячих клавиш"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: breezeTheme.textPrimary
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 160
                        height: 26
                        radius: breezeTheme.radiusButton
                        color: resetHkMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                        border.color: breezeTheme.borderSubtle
                        border.width: 1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Сбросить по умолчанию"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 10
                            color: breezeTheme.textPrimary
                        }

                        MouseArea {
                            id: resetHkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (config) config.resetHotkeys()
                            }
                        }
                    }
                }

                // Scrollable list of hotkey items
                Rectangle {
                    width: parent.width
                    height: parent.height - 38
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: hkCol.implicitHeight
                        clip: true

                        Column {
                            id: hkCol
                            width: parent.width
                            spacing: 6

                            readonly property var hotkeyDefs: [
                                {
                                    key: "menu",
                                    name: "Главное меню Zatsu",
                                    desc: "Открытие/закрытие меню приложений и настроек",
                                    icon: "start-here-kde",
                                    current: (config ? config.hotkeyMenu : "Alt+F1"),
                                    presets: ["Alt+F1", "Ctrl+Esc"]
                                },
                                {
                                    key: "quick_runner",
                                    name: "Быстрый запуск (Quick Runner)",
                                    desc: "Всплывающий поиск программ, расчёт калькулятора и команды",
                                    icon: "system-search",
                                    current: (config ? config.hotkeyQuickRunner : "Meta+F"),
                                    presets: ["Meta+F", "Ctrl+Space", "Meta+K"]
                                },
                                {
                                    key: "layout_switch",
                                    name: "Смена раскладки клавиатуры",
                                    desc: "Переключение языка ввода (EN / RU)",
                                    icon: "preferences-desktop-keyboard",
                                    current: (config ? config.hotkeyLayoutSwitch : "Alt+Shift"),
                                    presets: ["Alt+Shift", "Ctrl+Shift", "Meta+Space"]
                                },
                                {
                                    key: "lock_screen",
                                    name: "Блокировка экрана",
                                    desc: "Мгновенная блокировка сеанса (loginctl)",
                                    icon: "system-lock-screen",
                                    current: (config ? config.hotkeyLockScreen : "Meta+L"),
                                    presets: ["Meta+L", "Ctrl+Alt+L"]
                                },
                                {
                                    key: "strict_mode",
                                    name: "Строгий режим блокировки",
                                    desc: "Включение / выключение принудительного закрытия сторонних программ",
                                    icon: "security-high",
                                    current: (config ? config.hotkeyStrictMode : "Meta+S"),
                                    presets: ["Meta+S", "Ctrl+Alt+S"]
                                },
                                {
                                    key: "reset_timer",
                                    name: "Сброс таймера сессии",
                                    desc: "Перезапуск таймера фокусировки или раунда Pomodoro",
                                    icon: "preferences-system-time",
                                    current: (config ? config.hotkeyResetTimer : "Meta+R"),
                                    presets: ["Meta+R", "Ctrl+Alt+R"]
                                },
                                {
                                    key: "clipboard",
                                    name: "История буфера обмена (Klipper)",
                                    desc: "Быстрый вызов контекстного меню буфера обмена KDE",
                                    icon: "klipper",
                                    current: (config ? config.hotkeyClipboard : "Meta+V"),
                                    presets: ["Meta+V", "Ctrl+Alt+V"]
                                },
                                {
                                    key: "scratchpad",
                                    name: "Быстрые мысли (Scratchpad)",
                                    desc: "Всплывающий блокнот для мгновенной фиксации идей",
                                    icon: "accessories-text-editor",
                                    current: (config ? config.hotkeyScratchpad : "Meta+N"),
                                    presets: ["Meta+N", "Ctrl+Alt+N"]
                                },
                                {
                                    key: "mini_timer",
                                    name: "Плавающий мини-таймер (PiP)",
                                    desc: "Компактный перетаскиваемый таймер поверх всех окон",
                                    icon: "view-restore",
                                    current: (config ? config.hotkeyMiniTimer : "Meta+T"),
                                    presets: ["Meta+T", "Ctrl+Alt+T"]
                                }
                            ]

                            Repeater {
                                model: hkCol.hotkeyDefs

                                Rectangle {
                                    id: hkDelegate
                                    property var hkItem: modelData
                                    width: hkCol.width
                                    height: 56
                                    radius: breezeTheme.radiusButton
                                    color: breezeTheme.surfaceElevated
                                    border.color: (systemService && systemService.recordingAction === hkDelegate.hkItem.key) ? breezeTheme.danger : breezeTheme.borderSubtle
                                    border.width: 1

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Image {
                                            width: 22
                                            height: 22
                                            source: "image://icon/" + hkDelegate.hkItem.icon
                                            sourceSize.width: 22
                                            sourceSize.height: 22
                                            anchors.verticalCenter: parent.verticalCenter
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                        }

                                        Column {
                                            width: parent.width - rightControlRow.width - 42
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2

                                            Text {
                                                text: hkDelegate.hkItem.name
                                                font.family: breezeTheme.fontFamily
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                                color: breezeTheme.textPrimary
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }

                                            Text {
                                                text: hkDelegate.hkItem.desc
                                                font.family: breezeTheme.fontFamily
                                                font.pixelSize: 10
                                                color: breezeTheme.textDim
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                        }

                                        // Right side: Active combo badge, Record button, Presets
                                        Row {
                                            id: rightControlRow
                                            spacing: 6
                                            anchors.verticalCenter: parent.verticalCenter

                                            // Active badge / Recording indicator
                                            Rectangle {
                                                readonly property bool isRecording: (systemService && systemService.recordingAction === hkDelegate.hkItem.key)
                                                width: Math.max(76, curHkText.implicitWidth + 16)
                                                height: 26
                                                radius: 4
                                                color: isRecording ? Qt.rgba(0.9, 0.2, 0.2, 0.25) : breezeTheme.surfaceCard
                                                border.color: isRecording ? breezeTheme.danger : breezeTheme.accent
                                                border.width: isRecording ? 2 : 1

                                                Text {
                                                    id: curHkText
                                                    anchors.centerIn: parent
                                                    text: parent.isRecording ? "Нажмите клавиши..." : hkDelegate.hkItem.current
                                                    font.family: breezeTheme.fontFamily
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    color: parent.isRecording ? breezeTheme.danger : breezeTheme.accent
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (systemService) {
                                                            if (systemService.recordingAction === hkDelegate.hkItem.key) {
                                                                systemService.stopRecordingHotkey()
                                                            } else {
                                                                systemService.startRecordingHotkey(hkDelegate.hkItem.key)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Record / Cancel Button
                                            Rectangle {
                                                width: Math.max(64, recBtnText.implicitWidth + 14)
                                                height: 26
                                                radius: 4
                                                readonly property bool isRecording: (systemService && systemService.recordingAction === hkDelegate.hkItem.key)
                                                color: isRecording ? breezeTheme.danger : (recMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)
                                                border.color: breezeTheme.borderSubtle
                                                border.width: 1

                                                Text {
                                                    id: recBtnText
                                                    anchors.centerIn: parent
                                                    text: parent.isRecording ? "Отмена" : "Задать..."
                                                    font.family: breezeTheme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                    color: parent.isRecording ? "#ffffff" : breezeTheme.textPrimary
                                                }

                                                MouseArea {
                                                    id: recMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (systemService) {
                                                            if (systemService.recordingAction === hkDelegate.hkItem.key) {
                                                                systemService.stopRecordingHotkey()
                                                            } else {
                                                                systemService.startRecordingHotkey(hkDelegate.hkItem.key)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Presets pills
                                            Row {
                                                spacing: 4
                                                anchors.verticalCenter: parent.verticalCenter

                                                Repeater {
                                                    model: hkDelegate.hkItem.presets

                                                    Rectangle {
                                                        width: Math.max(46, pText.implicitWidth + 10)
                                                        height: 24
                                                        radius: 4
                                                        readonly property bool isCur: modelData === hkDelegate.hkItem.current
                                                        color: isCur ? breezeTheme.accent : (pMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)
                                                        border.color: isCur ? breezeTheme.accent : breezeTheme.borderSubtle
                                                        border.width: 1

                                                        Text {
                                                            id: pText
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.family: breezeTheme.fontFamily
                                                            font.pixelSize: 10
                                                            font.weight: parent.isCur ? Font.Bold : Font.Normal
                                                            color: parent.isCur ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                                        }

                                                        MouseArea {
                                                            id: pMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (config) config.setHotkey(hkDelegate.hkItem.key, modelData)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -------------------------------------------------------------
            // TAB 5: ВНЕШНИЙ ВИД
            // -------------------------------------------------------------
            Column {
                anchors.fill: parent
                visible: tabRow.currentTab === 4
                spacing: 12

                // Wallpaper card
                Rectangle {
                    width: parent.width
                    height: (config && config.wallpaperMode === "custom") ? 132 : 94
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Обои рабочего стола"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: breezeTheme.textPrimary
                        }

                        Row {
                            spacing: 12
                            width: parent.width

                            Rectangle {
                                width: Math.max(140, wpSysText.implicitWidth + 24)
                                height: 32
                                radius: breezeTheme.radiusButton
                                readonly property bool isSystem: (config ? config.wallpaperMode === "system" : true)
                                color: isSystem ? breezeTheme.accent : breezeTheme.buttonBg

                                Text {
                                    id: wpSysText
                                    anchors.centerIn: parent
                                    text: "Системные KDE"
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 12
                                    color: parent.isSystem ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (config) config.wallpaperMode = "system"
                                    }
                                }
                            }

                            Rectangle {
                                width: Math.max(140, wpCustText.implicitWidth + 24)
                                height: 32
                                radius: breezeTheme.radiusButton
                                readonly property bool isCustom: (config ? config.wallpaperMode === "custom" : false)
                                color: isCustom ? breezeTheme.accent : breezeTheme.buttonBg

                                Text {
                                    id: wpCustText
                                    anchors.centerIn: parent
                                    text: "Пользовательские"
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 12
                                    color: parent.isCustom ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (config) config.wallpaperMode = "custom"
                                        root.requestChangeWallpaper()
                                    }
                                }
                            }
                        }

                        // Path and Browse button for custom wallpaper
                        Row {
                            width: parent.width
                            spacing: 8
                            visible: config ? config.wallpaperMode === "custom" : false

                            Text {
                                text: (config && config.customWallpaperPath) ? config.customWallpaperPath.split("/").pop() : "Файл не выбран"
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 11
                                color: breezeTheme.textDim
                                elide: Text.ElideMiddle
                                width: parent.width - 100
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 90
                                height: 26
                                radius: breezeTheme.radiusButton
                                color: wpPickMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg
                                border.color: breezeTheme.borderSubtle
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "Выбрать..."
                                    font.family: breezeTheme.fontFamily
                                    font.pixelSize: 11
                                    color: breezeTheme.textPrimary
                                }

                                MouseArea {
                                    id: wpPickMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.requestChangeWallpaper()
                                }
                            }
                        }
                    }
                }

                // Panel Scaling Card
                Rectangle {
                    width: parent.width
                    height: 82
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Масштаб панели задач: " + Math.round((config ? config.panelHeightScale : 1.0) * 100) + "%"
                            font.family: breezeTheme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: breezeTheme.textPrimary
                        }

                        Row {
                            spacing: 8
                            width: parent.width

                            readonly property var scales: [
                                { label: "75%", val: 0.75 },
                                { label: "100%", val: 1.0 },
                                { label: "125%", val: 1.25 },
                                { label: "150%", val: 1.5 }
                            ]

                            Repeater {
                                model: parent.scales

                                Rectangle {
                                    width: (parent.width - 24) / 4
                                    height: 28
                                    radius: breezeTheme.radiusButton
                                    readonly property bool isCurScale: (config ? Math.abs(config.panelHeightScale - modelData.val) < 0.05 : modelData.val === 1.0)
                                    color: isCurScale ? breezeTheme.accent : (scBtnMouse.containsMouse ? breezeTheme.buttonHover : breezeTheme.buttonBg)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: breezeTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: parent.isCurScale ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                    }

                                    MouseArea {
                                        id: scBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (config) config.panelHeightScale = modelData.val
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // OLED Secondary Screen Blackout Card
                Rectangle {
                    width: parent.width
                    height: 72
                    radius: breezeTheme.radiusCard
                    color: breezeTheme.surfaceCard
                    border.color: breezeTheme.borderSubtle
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Column {
                            width: parent.width - 70
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "Заливка черным для вторичных экранов"
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: breezeTheme.textPrimary
                            }

                            Text {
                                text: "Защита OLED (#000000) и полное устранение отвлекающих факторов."
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 11
                                color: breezeTheme.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Switch {
                            checked: (config && config.oledSecondaryBlackout) ? true : false
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: {
                                if (config) config.oledSecondaryBlackout = checked
                            }
                        }
                    }
                }
            }
        }
    }
}
