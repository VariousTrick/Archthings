import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    implicitWidth: 450
    implicitHeight: 484

    property string currentPage: "home"
    property bool wifiEnabled: true
    property bool powerSaverEnabled: true
    property string wifiName: "Galaxy Z Fold7 D84D"
    property int speakerVolume: 54
    property int batteryLevel: 78
    property string batteryMode: "节能"
    property int brightnessValue: 72
    property bool wifiCurrentExpanded: false
    property string wifiPasswordSsid: ""
    property string wifiPasswordText: ""

    function cardTitle() {
        switch (currentPage) {
        case "wifi":
            return "WLAN";
        case "bluetooth":
            return "蓝牙";
        case "volume":
            return "声音输出";
        case "battery":
            return "电源和电池";
        default:
            return "快速设置";
        }
    }

    function wifiSummary() {
        if (!WifiState.initialized)
            return "正在读取";
        if (!WifiState.wifiEnabled)
            return "已关闭";
        return WifiState.connectedSsid && WifiState.connectedSsid.length > 0 ? WifiState.connectedSsid : "未连接";
    }

    function bluetoothSummary() {
        return BluetoothState.summary();
    }

    function batterySummary() {
        return `${batteryLevel}% · ${batteryMode}`;
    }

    function pageBack() {
        currentPage = "home";
    }

    component WinToggle: Switch {
        id: toggle
        implicitWidth: 44
        implicitHeight: 26

        indicator: Rectangle {
            implicitWidth: 44
            implicitHeight: 26
            radius: 13
            color: toggle.checked ? "#cfd7df" : Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            border.color: toggle.checked ? Qt.rgba(0, 0, 0, 0.08) : Theme.border

            Rectangle {
                width: 18
                height: 18
                radius: 9
                x: toggle.checked ? 22 : 4
                y: 4
                color: toggle.checked ? "#050505" : "#f4f1ed"
            }
        }

        contentItem: Item {}
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.panel
        border.width: 1
        border.color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

            Rectangle {
                Layout.fillWidth: true
                color: "transparent"
                implicitHeight: (root.currentPage === "home" || root.currentPage === "wifi" || root.currentPage === "bluetooth") ? 0 : 42
                visible: root.currentPage !== "home" && root.currentPage !== "wifi" && root.currentPage !== "bluetooth"

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Button {
                    visible: root.currentPage !== "home"
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    hoverEnabled: true
                    onClicked: root.pageBack()

                    background: Rectangle {
                        radius: 17
                        color: parent.down ? Qt.rgba(1, 1, 1, 0.10) : (parent.hovered ? Theme.tileHover : "transparent")
                    }

                    contentItem: Label {
                        text: "←"
                        color: Theme.text
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: root.cardTitle()
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.Medium
                    }

                    Label {
                        text: ""
                        color: Theme.subtext
                        font.pixelSize: 11
                    }
                }
            }
        }

        StackLayout {
            id: pages
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentPage === "home"
                          ? 0
                          : (root.currentPage === "wifi"
                             ? 1
                             : (root.currentPage === "bluetooth"
                                ? 2
                                : (root.currentPage === "volume"
                                   ? 3
                                   : 4)))

            HomePage {}
            WifiPage {}
            QuickBluetoothPage {
                onBackRequested: root.pageBack()
            }
            VolumePage {}
            BatteryPage {}
        }
    }

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.divider
    }

    component TileButton: Item {
        id: tile
        required property string title
        required property string summary
        required property string icon
        property bool active: false
        property bool showArrow: false
        signal clicked()

        width: 119
        height: 103

        Rectangle {
            id: tileSurface
            width: 119
            height: 60
            radius: 11
            color: mouse.pressed
                   ? (tile.active ? Qt.darker(Theme.tileActive, 1.04) : Qt.rgba(1, 1, 1, 0.12))
                   : (tile.active ? Theme.tileActive : (mouse.containsMouse ? Theme.tileHover : Theme.tile))
            border.width: 1
            border.color: tile.active ? Qt.rgba(1, 1, 1, 0.04) : Theme.border

            Row {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 0

                Label {
                    width: tile.showArrow ? (parent.width - 18) : parent.width
                    text: tile.icon
                    color: tile.active ? Theme.tileActiveText : Theme.text
                    font.pixelSize: 21
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: tile.showArrow ? Text.AlignLeft : Text.AlignHCenter
                }

                Label {
                    visible: tile.showArrow
                    text: "›"
                    color: tile.active ? Theme.tileActiveText : Theme.subtext
                    font.pixelSize: 17
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Column {
            width: tileSurface.width
            anchors.horizontalCenter: tileSurface.horizontalCenter
            anchors.top: tileSurface.bottom
            anchors.topMargin: 7
            spacing: 1

            Label {
                width: parent.width
                text: tile.title
                color: Theme.text
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width
                text: tile.summary
                color: Theme.subtext
                font.pixelSize: 11
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: tileSurface
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component SlimRow: Item {
        id: row
        required property string icon
        required property string title
        required property string summary
        property string actionText: ""
        signal action()

        implicitHeight: 54

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Label {
                text: row.icon
                color: Theme.text
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Label {
                    text: row.title
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Label {
                    text: row.summary
                    color: Theme.subtext
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Button {
                visible: row.actionText.length > 0
                Layout.preferredWidth: 82
                Layout.preferredHeight: 28
                text: row.actionText
                hoverEnabled: true
                onClicked: row.action()

                background: Rectangle {
                    radius: 14
                    color: parent.down ? Qt.rgba(1, 1, 1, 0.10) : (parent.hovered ? Theme.actionHover : Theme.actionFill)
                    border.width: 1
                    border.color: Theme.border
                }

                contentItem: Label {
                    text: parent.text
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    component BluetoothRow: Rectangle {
        required property var deviceData
        required property string actionKind

        width: parent.width
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.048)
        border.width: 1
        border.color: Theme.border
        implicitHeight: 62

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            Label {
                text: deviceData.icon
                color: Theme.text
                font.pixelSize: 22
                width: 34
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: Text.AlignVCenter
            }

            Column {
                width: parent.width - 34 - 12 - (deviceData.canForget ? 44 : 0) - 96
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    text: deviceData.name
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: deviceData.details
                    color: Theme.subtext
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Button {
                id: forgetButton
                width: 32
                height: 32
                hoverEnabled: true
                visible: deviceData.canForget
                anchors.verticalCenter: parent.verticalCenter
                onClicked: BluetoothState.forgetDevice(deviceData.device)

                background: Rectangle {
                    radius: 16
                    color: parent.down ? Qt.rgba(1, 1, 1, 0.14) : (parent.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.085))
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.11)
                }

                contentItem: Label {
                    text: "󰆴"
                    color: Theme.text
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: actionButton
                width: 88
                height: 36
                text: deviceData.actionLabel
                hoverEnabled: true
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    if (actionKind === "disconnect")
                        BluetoothState.disconnectDevice(deviceData.device);
                    else if (actionKind === "connect")
                        BluetoothState.connectDevice(deviceData.device);
                    else
                        BluetoothState.pairDevice(deviceData.device);
                }

                background: Rectangle {
                    radius: 10
                    color: parent.down ? Qt.rgba(1, 1, 1, 0.14) : (parent.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.085))
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.11)
                }

                contentItem: Label {
                    text: actionButton.text
                    color: Theme.text
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    component HomePage: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Item {
            anchors.fill: parent

            Item {
                id: tileArea
                x: 30
                y: 28
                width: 389
                height: 238

                Grid {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 17

                    TileButton {
                    title: "Wi‑Fi"
                    summary: root.wifiSummary()
                    icon: WifiState.wifiEnabled ? "󰤨" : "󰤭"
                    active: WifiState.wifiEnabled
                    showArrow: true
                    onClicked: root.currentPage = "wifi"
                }

                    TileButton {
                    title: "蓝牙"
                    summary: root.bluetoothSummary()
                    icon: BluetoothState.bluetoothEnabled ? "󰂯" : "󰂲"
                    active: BluetoothState.bluetoothEnabled
                    showArrow: true
                    onClicked: root.currentPage = "bluetooth"
                }

                    TileButton {
                    title: "电池"
                    summary: root.batterySummary()
                    icon: "󰁹"
                    active: true
                    onClicked: root.currentPage = "battery"
                }

                    TileButton {
                    title: "音量"
                    summary: `${root.speakerVolume}%`
                    icon: "󰕾"
                    active: true
                    onClicked: root.currentPage = "volume"
                }

                    TileButton {
                    title: "节能模式"
                    summary: root.batteryMode
                    icon: "󰌪"
                    active: root.powerSaverEnabled
                    onClicked: root.currentPage = "battery"
                }

                    TileButton {
                    title: "飞行模式"
                    summary: "未接入"
                    icon: "󰀝"
                    active: false
                    onClicked: {}
                }
                }
            }

            Rectangle {
                x: 30
                y: 266
                width: parent.width - 60
                height: 1
                color: Theme.divider
            }

            Item {
                id: sliderArea
                x: 30
                y: 267
                width: parent.width - 60
                height: 156

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 20
                    spacing: 28

                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 8
                            Label { text: "󰃠"; color: Theme.text; font.pixelSize: 18 }
                            Label { text: "亮度"; color: Theme.subtext; font.pixelSize: 11 }
                        }

                        Slider {
                            width: parent.width
                            from: 0
                            to: 100
                            value: root.brightnessValue
                            enabled: false
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: parent.availableWidth
                                height: 6
                                radius: 999
                                color: Theme.sliderTrack

                                Rectangle {
                                    width: parent.parent.visualPosition * parent.width
                                    height: parent.height
                                    radius: 999
                                    color: Theme.sliderFill
                                }
                            }

                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: 20
                                height: 20
                                radius: 10
                                color: Theme.sliderKnob
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 8
                            Label { text: "󰕾"; color: Theme.text; font.pixelSize: 18 }
                            Label { text: "音量"; color: Theme.subtext; font.pixelSize: 11 }
                        }

                        Slider {
                            width: parent.width
                            from: 0
                            to: 100
                            value: root.speakerVolume
                            enabled: false
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: parent.availableWidth
                                height: 6
                                radius: 999
                                color: Theme.sliderTrack

                                Rectangle {
                                    width: parent.parent.visualPosition * parent.width
                                    height: parent.height
                                    radius: 999
                                    color: Theme.sliderFill
                                }
                            }

                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: 20
                                height: 20
                                radius: 10
                                color: Theme.sliderKnob
                            }
                        }
                    }
                }
            }

            Rectangle {
                x: 30
                y: 423
                width: parent.width - 60
                height: 1
                color: Theme.divider
            }

            Item {
                x: 30
                y: 424
                width: parent.width - 60
                height: 60

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    spacing: 12

                    Label {
                        text: `󰁹 ${root.batteryLevel}%`
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "󰒓"
                        color: Theme.subtext
                        font.pixelSize: 17
                    }
                }
            }
        }
    }

    component WifiPage: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color pageRowFill: Qt.rgba(1, 1, 1, 0.048)
        readonly property color pageRowExpandedFill: Qt.rgba(1, 1, 1, 0.065)
        readonly property color pageButtonFill: Qt.rgba(1, 1, 1, 0.085)
        readonly property color pageButtonHover: Qt.rgba(1, 1, 1, 0.12)
        readonly property color pageInputFill: Qt.rgba(42 / 255, 36 / 255, 33 / 255, 0.98)
        readonly property color pageInputBorder: Qt.rgba(1, 1, 1, 0.11)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                color: "transparent"
                implicitHeight: 32

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 12

                    Item {
                        Layout.fillWidth: true

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Item {
                                width: 20
                                height: 20

                                Label {
                                    anchors.centerIn: parent
                                    text: "←"
                                    color: Theme.text
                                    font.pixelSize: 18
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.pageBack()
                                }
                            }

                            Label {
                                text: "WLAN"
                                color: Theme.text
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    WinToggle {
                        Layout.alignment: Qt.AlignVCenter
                        checked: WifiState.wifiEnabled
                        onClicked: WifiState.toggleWifi()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.fill: parent
                    spacing: 12

                    ScrollView {
                        width: parent.width
                        height: 312
                        clip: true

                        Column {
                            width: parent.width
                            spacing: 4

                            Rectangle {
                                width: parent.width
                                radius: 14
                                color: root.wifiCurrentExpanded ? pageRowExpandedFill : pageRowFill
                                border.width: 1
                                border.color: root.wifiCurrentExpanded ? Qt.rgba(1, 1, 1, 0.095) : Theme.border
                                implicitHeight: WifiState.connectedSsid.length === 0 ? 0 : (root.wifiCurrentExpanded ? 126 : 62)
                                visible: WifiState.connectedSsid.length > 0

                                Column {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    anchors.topMargin: 4
                                    anchors.bottomMargin: root.wifiCurrentExpanded ? 10 : 4
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 54

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.wifiCurrentExpanded = !root.wifiCurrentExpanded
                                        }

                                        Row {
                                            anchors.fill: parent
                                            spacing: 12

                                            Label {
                                                text: "󰤨"
                                                color: Theme.text
                                                font.pixelSize: 23
                                                width: 34
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            Column {
                                                width: parent.width - 34 - 12 - 28
                                                spacing: 2
                                                anchors.verticalCenter: parent.verticalCenter

                                                Label {
                                                    width: parent.width
                                                    text: WifiState.connectedSsid
                                                    color: Theme.text
                                                    font.pixelSize: 14
                                                    font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                }

                                                Label {
                                                    width: parent.width
                                                    text: "已连接，安全"
                                                    color: Theme.subtext
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item { width: 24; height: 1 }
                                        }
                                    }

                                    Item {
                                        visible: root.wifiCurrentExpanded
                                        width: parent.width
                                        height: 50

                                                Button {
                                                    anchors.right: parent.right
                                                    width: 154
                                                    height: 40
                                                    text: "断开连接"
                                                    hoverEnabled: true
                                                    onClicked: {
                                                        WifiState.disconnect();
                                                        root.wifiCurrentExpanded = false;
                                                    }

                                            background: Rectangle {
                                                radius: 10
                                                color: parent.down ? Qt.rgba(1, 1, 1, 0.14) : (parent.hovered ? pageButtonHover : pageButtonFill)
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.1)
                                            }

                                            contentItem: Label {
                                                text: parent.text
                                                color: Theme.text
                                                font.pixelSize: 12
                                                font.weight: Font.Medium
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: WifiState.networks.filter(network => !network.active)

                                delegate: Rectangle {
                                    width: parent.width
                                    radius: 12
                                    color: root.wifiPasswordSsid === modelData.ssid ? pageRowExpandedFill : pageRowFill
                                    border.width: 1
                                    border.color: root.wifiPasswordSsid === modelData.ssid ? Qt.rgba(1, 1, 1, 0.09) : Theme.border
                                    implicitHeight: root.wifiPasswordSsid === modelData.ssid ? 104 : 54

                                    Column {
                                        anchors.fill: parent
                                        spacing: 4

                                        Item {
                                            width: parent.width
                                            height: 54

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.secure) {
                                                        root.wifiPasswordSsid = root.wifiPasswordSsid === modelData.ssid ? "" : modelData.ssid;
                                                        if (root.wifiPasswordSsid !== modelData.ssid)
                                                            root.wifiPasswordText = "";
                                                    } else {
                                                        root.wifiPasswordSsid = "";
                                                        root.wifiPasswordText = "";
                                                        WifiState.connectOpen(modelData.ssid);
                                                    }
                                                }
                                            }

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 12

                                                Label {
                                                    text: modelData.icon || "󰤥"
                                                    color: Theme.text
                                                    font.pixelSize: 23
                                                    width: 34
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                Column {
                                                    width: parent.width - 34 - 12
                                                    spacing: 2
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Label {
                                                        width: parent.width
                                                        text: modelData.ssid
                                                        color: Theme.text
                                                        font.pixelSize: 14
                                                        font.weight: Font.Medium
                                                        elide: Text.ElideRight
                                                    }

                                                    Label {
                                                        width: parent.width
                                                        text: modelData.secure ? "安全" : "开放网络"
                                                        color: Theme.subtext
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            visible: root.wifiPasswordSsid === modelData.ssid
                                            width: parent.width
                                            height: 46

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 52
                                                anchors.rightMargin: 6
                                                spacing: 8

                                                TextField {
                                                    id: passwordField
                                                    width: parent.width - 96
                                                    height: 36
                                                    placeholderText: "输入密码"
                                                    echoMode: TextInput.Password
                                                    color: Theme.text
                                                    selectionColor: Theme.tileActive
                                                    selectedTextColor: Theme.tileActiveText
                                                    text: root.wifiPasswordText
                                                    onTextChanged: root.wifiPasswordText = text

                                                    background: Rectangle {
                                                        radius: 10
                                                        color: pageInputFill
                                                        border.width: 1
                                                        border.color: pageInputBorder
                                                    }
                                                }

                                                Button {
                                                    width: 88
                                                    height: 36
                                                    text: "连接"
                                                    hoverEnabled: true
                                                    enabled: root.wifiPasswordText.length > 0
                                                    onClicked: {
                                                        WifiState.connectSecure(modelData.ssid, root.wifiPasswordText);
                                                        root.wifiPasswordSsid = "";
                                                        root.wifiPasswordText = "";
                                                    }

                                                    background: Rectangle {
                                                        radius: 10
                                                        color: parent.enabled
                                                               ? (parent.down ? Qt.rgba(1, 1, 1, 0.14) : (parent.hovered ? pageButtonHover : pageButtonFill))
                                                               : Qt.rgba(1, 1, 1, 0.03)
                                                        border.width: 1
                                                        border.color: Qt.rgba(1, 1, 1, 0.1)
                                                    }

                                                    contentItem: Label {
                                                        text: parent.text
                                                        color: parent.enabled ? Theme.text : Theme.subtext
                                                        font.pixelSize: 12
                                                        font.weight: Font.Medium
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 1 }

                    Rectangle {
                        width: parent.width
                        height: 52
                        color: pageRowFill
                        border.width: 1
                        border.color: Theme.border

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WifiState.triggerRefresh()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Label {
                                text: "更多 Wi‑Fi 设置"
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: "󰑐"
                                color: Theme.text
                                font.pixelSize: 18
                            }
                        }
                    }
                }
            }
        }
    }

    component BluetoothPage: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color pageRowFill: Qt.rgba(1, 1, 1, 0.048)
        readonly property color pageButtonFill: Qt.rgba(1, 1, 1, 0.085)
        readonly property color pageButtonHover: Qt.rgba(1, 1, 1, 0.12)
        readonly property color pageInputBorder: Qt.rgba(1, 1, 1, 0.11)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                color: "transparent"
                implicitHeight: 32

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 12

                    Item {
                        Layout.fillWidth: true

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Item {
                                width: 20
                                height: 20

                                Label {
                                    anchors.centerIn: parent
                                    text: "←"
                                    color: Theme.text
                                    font.pixelSize: 18
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.pageBack()
                                }
                            }

                            Label {
                                text: "蓝牙"
                                color: Theme.text
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    WinToggle {
                        Layout.alignment: Qt.AlignVCenter
                        checked: BluetoothState.bluetoothEnabled
                        onClicked: BluetoothState.toggleBluetooth()
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Column {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        radius: 14
                        color: pageRowFill
                        border.width: 1
                        border.color: Theme.border
                        height: 62

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Label {
                                text: BluetoothState.bluetoothEnabled ? "󰂯" : "󰂲"
                                color: Theme.text
                                font.pixelSize: 22
                                Layout.preferredWidth: 34
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    Layout.fillWidth: true
                                    text: BluetoothState.bluetoothEnabled ? "蓝牙" : "蓝牙已关闭"
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: BluetoothState.bluetoothEnabled
                                          ? (BluetoothState.controllerName.length > 0 ? `控制器：${BluetoothState.controllerName}` : BluetoothState.summary())
                                          : "无法发现设备"
                                    color: Theme.subtext
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        visible: BluetoothState.connectedDevices.length > 0

                        Label {
                            text: "已连接"
                            color: Theme.subtext
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Repeater {
                            model: BluetoothState.connectedDevices
                            delegate: BluetoothRow {
                                deviceData: modelData
                                actionKind: "disconnect"
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        visible: BluetoothState.pairedDevices.length > 0

                        Label {
                            text: "已配对"
                            color: Theme.subtext
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Repeater {
                            model: BluetoothState.pairedDevices
                            delegate: BluetoothRow {
                                deviceData: modelData
                                actionKind: "connect"
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6
                        visible: BluetoothState.availableDevices.length > 0

                        Label {
                            text: "设备"
                            color: Theme.subtext
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Repeater {
                            model: BluetoothState.availableDevices
                            delegate: BluetoothRow {
                                deviceData: modelData
                                actionKind: "pair"
                            }
                        }
                    }

                    Item { width: 1; height: 1 }

                    Rectangle {
                        width: parent.width
                        height: 52
                        color: pageRowFill
                        border.width: 1
                        border.color: Theme.border

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothState.triggerRefresh()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Label {
                                text: "更多蓝牙设置"
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: BluetoothState.discovering ? "󰑓" : "󰑐"
                                color: Theme.text
                                font.pixelSize: 18
                            }
                        }
                    }
                }
            }
        }

    }

    component VolumePage: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Label {
                text: "输出设备"
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Repeater {
                model: [
                    { label: "扬声器 (Realtek(R) Audio)", detail: "" },
                    { label: "Dolby Atmos for Speakers", detail: "" },
                    { label: "用于耳机的 Windows Sonic", detail: "" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    radius: 11
                    color: Theme.rowFill
                    implicitHeight: 52

                    SlimRow {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        icon: "󰓃"
                        title: modelData.label
                        summary: modelData.detail || ""
                        actionText: ""
                        onAction: {}
                    }
                }
            }

            SectionDivider {}

            Label {
                text: "音量合成器"
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "󰕾"; color: Theme.text; font.pixelSize: 18 }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: root.speakerVolume
                        enabled: false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "󰍬"; color: Theme.text; font.pixelSize: 18 }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: 46
                        enabled: false
                    }
                }
            }
        }
    }

    component BatteryPage: Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.rowFill
                implicitHeight: 84

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Label {
                        text: `${root.batteryLevel}%`
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.Medium
                    }

                    Label {
                        text: "已接通电源 · 2:41"
                        color: Theme.subtext
                        font.pixelSize: 11
                    }

                    Label {
                        text: `当前模式：${root.batteryMode}`
                        color: Theme.subtext
                        font.pixelSize: 11
                    }
                }
            }

            Label {
                text: "电源模式"
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        { label: "节能", value: "power-saver" },
                        { label: "平衡", value: "balanced" },
                        { label: "性能", value: "performance" }
                    ]

                    delegate: Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        text: modelData.label
                        hoverEnabled: true
                        onClicked: {
                            root.batteryMode = modelData.label;
                            root.powerSaverEnabled = modelData.value === "power-saver";
                        }

                        background: Rectangle {
                            radius: 17
                            color: ((modelData.value === "power-saver" && root.powerSaverEnabled)
                                    || (modelData.value === "balanced" && root.batteryMode === "平衡")
                                    || (modelData.value === "performance" && root.batteryMode === "性能"))
                                   ? Theme.tileActive
                                   : (parent.down ? Qt.rgba(1, 1, 1, 0.12) : (parent.hovered ? Theme.tileHover : Theme.tile))
                            border.width: 1
                            border.color: (((modelData.value === "power-saver" && root.powerSaverEnabled)
                                            || (modelData.value === "balanced" && root.batteryMode === "平衡")
                                            || (modelData.value === "performance" && root.batteryMode === "性能"))
                                           ? Qt.rgba(1, 1, 1, 0.04) : Theme.border)
                        }

                        contentItem: Label {
                            text: parent.text
                            color: (((modelData.value === "power-saver" && root.powerSaverEnabled)
                                     || (modelData.value === "balanced" && root.batteryMode === "平衡")
                                     || (modelData.value === "performance" && root.batteryMode === "性能"))
                                    ? Theme.tileActiveText : Theme.text)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
