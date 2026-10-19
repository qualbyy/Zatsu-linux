import QtQuick
import QtQuick.Controls

Popup {
    id: root

    width: 580
    height: Math.min(420, 76 + resultsList.count * 48)
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 12

    property int selectedIndex: 0

    BreezeTheme {
        id: breezeTheme
    }

    onOpened: {
        searchInput.text = ""
        root.selectedIndex = 0
        searchInput.forceActiveFocus()
    }

    function toggle() {
        if (visible) close()
        else open()
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

    // Helper: evaluate simple math expressions safely
    function evaluateMath(expr) {
        var clean = expr.trim()
        if (!clean || !/^[0-9+\-*/().\s^%]+$/.test(clean)) return null
        if (!/[+\-*/%]/.test(clean)) return null // Must contain an operator
        try {
            var res = Function('"use strict"; return (' + clean + ')')()
            if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                return Number(res.toFixed(4)).toString()
            }
        } catch (e) {
            return null
        }
        return null
    }

    // Helper: compile results list
    readonly property var currentResults: {
        var rawQ = searchInput.text.trim()
        var q = rawQ.toLowerCase()
        var items = []

        // 1. Math Evaluation -> Copies result to clipboard on Enter
        var mathRes = evaluateMath(q)
        if (mathRes !== null) {
            items.push({
                type: "math",
                name: "= " + mathRes,
                desc: "Нажмите Enter, чтобы скопировать результат в буфер обмена",
                icon: "accessories-calculator",
                action: function() {
                    if (systemService) {
                        systemService.copyToClipboard(mathRes)
                    }
                    root.close()
                }
            })
        }

        // 2. Terminal Commands (prefixed with '>' or '!')
        if (rawQ.startsWith(">") || rawQ.startsWith("!")) {
            var termCmd = rawQ.substring(1).trim()
            if (termCmd) {
                items.push({
                    type: "terminal",
                    name: "Запустить в терминале: " + termCmd,
                    desc: "Выполнить команду в Konsole/Alacritty",
                    icon: "utilities-terminal",
                    action: function() {
                        if (systemService) {
                            systemService.runInTerminal(termCmd)
                        }
                        root.close()
                    }
                })
            }
        }

        // 3. Built-in Commands
        if (q && ("заблокировать экран".indexOf(q) !== -1 || "lock".indexOf(q) !== -1)) {
            items.push({
                type: "cmd",
                name: "Заблокировать экран",
                desc: "Мгновенная блокировка сессии (loginctl)",
                icon: "system-lock-screen",
                action: function() {
                    if (systemService) systemService.lockScreen()
                    root.close()
                }
            })
        }

        if (q && ("строгий режим".indexOf(q) !== -1 || "strict".indexOf(q) !== -1)) {
            items.push({
                type: "cmd",
                name: "Переключить строгий режим",
                desc: (config && config.strictMode) ? "Сейчас включен (нажмите для выключения)" : "Сейчас выключен (нажмите для включения)",
                icon: "security-high",
                action: function() {
                    if (config) config.strictMode = !config.strictMode
                    root.close()
                }
            })
        }

        if (q && ("перезапустить таймер".indexOf(q) !== -1 || "reset".indexOf(q) !== -1)) {
            items.push({
                type: "cmd",
                name: "Перезапустить таймер сессии",
                desc: "Сбросить таймер на исходное время",
                icon: "preferences-system-time",
                action: function() {
                    if (systemService) systemService.reset_timer()
                    root.close()
                }
            })
        }

        if (q && ("буфер обмена".indexOf(q) !== -1 || "klipper".indexOf(q) !== -1 || "clipboard".indexOf(q) !== -1)) {
            items.push({
                type: "cmd",
                name: "История буфера обмена (Klipper)",
                desc: "Открыть контекстное меню Klipper",
                icon: "klipper",
                action: function() {
                    if (systemService) systemService.openKlipper()
                    root.close()
                }
            })
        }

        if (q && ("выход".indexOf(q) !== -1 || "exit".indexOf(q) !== -1 || "quit".indexOf(q) !== -1)) {
            items.push({
                type: "cmd",
                name: "Выйти из режима Zatsu",
                desc: "Восстановить KDE Plasma 6 и завершить сеанс",
                icon: "system-shutdown",
                action: function() {
                    if (shellManager) shellManager.exit_focus_mode()
                    root.close()
                }
            })
        }

        // 4. Application Search from Desktop Scanner
        var appsList = (desktopScanner && desktopScanner.allApps) ? desktopScanner.allApps : ((desktopScanner && desktopScanner.apps) ? desktopScanner.apps : [])
        if (appsList && appsList.length > 0) {
            for (var i = 0; i < appsList.length; i++) {
                var app = appsList[i]
                var nameMatch = app.name && app.name.toLowerCase().indexOf(q) !== -1
                var execMatch = app.exec && app.exec.toLowerCase().indexOf(q) !== -1
                var commentMatch = app.comment && app.comment.toLowerCase().indexOf(q) !== -1

                if (!q || nameMatch || execMatch || commentMatch) {
                    items.push({
                        type: "app",
                        name: app.name || app.exec,
                        desc: app.comment || app.exec,
                        icon: app.icon || "application-x-executable",
                        action: (function(execCmd) {
                            return function() {
                                if (systemService && execCmd) {
                                    systemService.launchApp(execCmd)
                                }
                                root.close()
                            }
                        })(app.exec)
                    })
                    if (items.length >= 8) break
                }
            }
        }

        return items
    }

    contentItem: Column {
        width: root.availableWidth
        height: root.availableHeight
        spacing: 10

        // Search Input Bar
        Rectangle {
            width: parent.width
            height: 44
            radius: breezeTheme.radiusButton
            color: breezeTheme.surfaceCard
            border.color: searchInput.activeFocus ? breezeTheme.accent : breezeTheme.borderSubtle
            border.width: searchInput.activeFocus ? 2 : 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Image {
                    width: 20
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://icon/system-search"
                    sourceSize.width: 20
                    sourceSize.height: 20
                    fillMode: Image.PreserveAspectFit
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 70
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: breezeTheme.fontFamily
                    font.pixelSize: 15
                    color: breezeTheme.textPrimary
                    selectByMouse: true
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Запуск программы, расчёт (25*4) или команда..."
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 15
                        color: breezeTheme.textDim
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onDownPressed: {
                        if (root.selectedIndex < root.currentResults.length - 1) {
                            root.selectedIndex++
                            resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                        }
                    }

                    Keys.onUpPressed: {
                        if (root.selectedIndex > 0) {
                            root.selectedIndex--
                            resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                        }
                    }

                    Keys.onReturnPressed: {
                        if (root.currentResults.length > root.selectedIndex) {
                            var item = root.currentResults[root.selectedIndex]
                            if (item && item.action) item.action()
                        }
                    }

                    Keys.onEscapePressed: {
                        root.close()
                    }
                }

                // Esc badge hint
                Rectangle {
                    width: 32
                    height: 20
                    radius: 4
                    color: breezeTheme.buttonBg
                    border.color: breezeTheme.borderSubtle
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Esc"
                        font.family: breezeTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: breezeTheme.textDim
                    }
                }
            }
        }

        // Results List Container
        Rectangle {
            width: parent.width
            height: Math.min(320, resultsList.count * 48)
            radius: breezeTheme.radiusButton
            color: "transparent"
            clip: true
            visible: resultsList.count > 0

            ListView {
                id: resultsList
                anchors.fill: parent
                spacing: 2
                model: root.currentResults

                delegate: Rectangle {
                    id: itemDelegate
                    width: resultsList.width
                    height: 44
                    radius: 6
                    readonly property bool isCurrent: index === root.selectedIndex
                    color: isCurrent ? breezeTheme.accent : (itemMouse.containsMouse ? breezeTheme.buttonHover : "transparent")

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Image {
                            width: 24
                            height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            source: "image://icon/" + (modelData.icon || "application-x-executable")
                            sourceSize.width: 24
                            sourceSize.height: 24
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Column {
                            width: parent.width - 44
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: modelData.name || ""
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: itemDelegate.isCurrent ? breezeTheme.textOnAccent : breezeTheme.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.desc || ""
                                font.family: breezeTheme.fontFamily
                                font.pixelSize: 10
                                color: itemDelegate.isCurrent ? breezeTheme.textOnAccent : breezeTheme.textDim
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = index
                            if (modelData.action) modelData.action()
                        }
                    }
                }
            }
        }
    }
}
