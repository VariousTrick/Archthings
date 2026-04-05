import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    clip: true
    implicitWidth: 456
    implicitHeight: 560
    property Item dragTarget: null
    property string expandedSsid: ""
    property string passwordInput: ""
    property bool wifiToggleHovered: false

    signal dragFinished()

    function hoverColor(hovered) {
        return hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04);
    }

    function connectedNetworks() {
        return WifiState.networks.filter(network => network.active);
    }

    function availableNetworks() {
        return WifiState.networks.filter(network => !network.active);
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            color: "transparent"
            implicitHeight: 48

            RowLayout {
                anchors.fill: parent
                spacing: 12

                ColumnLayout {
                    spacing: 2

                    Label {
                        text: "网络"
                        color: Theme.text
                        font.pixelSize: 21
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "实验版 Plasma 风格 Wi‑Fi 面板"
                        color: Theme.subtext
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: dragHandle
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 10
                    color: dragArea.pressed ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.04)

                    Label {
                        anchors.centerIn: parent
                        text: "⠿"
                        color: Theme.subtext
                        font.pixelSize: 18
                        opacity: 0.88
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: root.dragTarget
                        onPressed: if (root.dragTarget) root.dragTarget.z = 10
                        onReleased: {
                            if (root.dragTarget)
                                root.dragTarget.z = 1;
                            root.dragFinished();
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Theme.cardSoft
            implicitHeight: 72

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 999
                    color: Qt.rgba(1, 1, 1, 0.05)

                    Label {
                        anchors.centerIn: parent
                        text: WifiState.wifiEnabled ? "󰤨" : "󰤭"
                        color: Theme.text
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "启用 Wi‑Fi"
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: WifiState.wifiEnabled
                              ? (WifiState.connectedSsid.length > 0 ? `当前网络：${WifiState.connectedSsid}` : "可查看附近网络")
                              : "无线网络已关闭"
                        color: Theme.subtext
                        font.pixelSize: 13
                    }
                }

                Item {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 32
                    Layout.minimumWidth: 56
                    Layout.minimumHeight: 32
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: WifiState.wifiEnabled
                               ? (root.wifiToggleHovered ? Qt.lighter(Theme.switchOn, 1.08) : Theme.switchOn)
                               : (root.wifiToggleHovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.12))

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            x: WifiState.wifiEnabled ? parent.width - width - 4 : 4
                            y: 4
                            color: Theme.switchKnob
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: root.wifiToggleHovered = containsMouse
                        onClicked: {
                            root.expandedSsid = "";
                            root.passwordInput = "";
                            WifiState.toggleWifi();
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Theme.card

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Column {
                    width: parent.width
                    spacing: 12

                    Column {
                        width: parent.width
                        spacing: 8
                        visible: WifiState.wifiEnabled && root.connectedNetworks().length > 0

                        Label {
                            text: "已连接"
                            color: Theme.subtext
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: root.connectedNetworks()

                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                radius: 12
                                color: Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.04)
                                implicitHeight: 74

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    Label {
                                        text: modelData.icon
                                        color: Theme.text
                                        font.pixelSize: 20
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: modelData.ssid
                                            color: Theme.text
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            text: modelData.details
                                            color: Theme.subtext
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Button {
                                        text: "断开"
                                        implicitHeight: 34
                                        implicitWidth: 74

                                        background: Rectangle {
                                            radius: 10
                                            color: parent.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.05)
                                        }

                                        contentItem: Label {
                                            text: parent.text
                                            color: Theme.text
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: WifiState.disconnect()
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8

                        Label {
                            text: "可用"
                            color: Theme.subtext
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            visible: WifiState.wifiEnabled
                        }

                        Repeater {
                            model: WifiState.wifiEnabled ? root.availableNetworks() : []

                            delegate: Rectangle {
                                id: networkCard
                                required property var modelData
                                width: parent.width
                                radius: 12
                                color: cardArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.04)
                                implicitHeight: root.expandedSsid === modelData.ssid && modelData.secure ? 132 : 74

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        Label {
                                            text: modelData.icon
                                            color: Theme.text
                                            font.pixelSize: 20
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Label {
                                                text: modelData.ssid
                                                color: Theme.text
                                                font.pixelSize: 15
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                text: modelData.details
                                                color: Theme.subtext
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Button {
                                            text: modelData.secure && root.expandedSsid !== modelData.ssid ? "连接" : (modelData.secure ? "加入" : "连接")
                                            implicitHeight: 34
                                            implicitWidth: 74

                                            background: Rectangle {
                                                radius: 10
                                                color: parent.hovered ? Theme.accent : Qt.rgba(1, 1, 1, 0.04)
                                                border.width: parent.hovered ? 0 : 1
                                                border.color: Qt.rgba(1, 1, 1, 0.05)
                                            }

                                            contentItem: Label {
                                                text: parent.text
                                                color: parent.hovered ? Theme.accentText : Theme.text
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            onClicked: {
                                                if (modelData.secure) {
                                                    root.expandedSsid = root.expandedSsid === modelData.ssid ? "" : modelData.ssid;
                                                    root.passwordInput = "";
                                                } else {
                                                    root.expandedSsid = "";
                                                    root.passwordInput = "";
                                                    WifiState.connectOpen(modelData.ssid);
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        visible: root.expandedSsid === modelData.ssid && modelData.secure
                                        implicitHeight: visible ? 40 : 0

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 10

                                            TextField {
                                                id: passwordField
                                                Layout.fillWidth: true
                                                placeholderText: "输入密码"
                                                echoMode: TextInput.Password
                                                text: root.passwordInput
                                                color: Theme.text
                                                placeholderTextColor: Theme.subtext
                                                selectByMouse: true
                                                onTextChanged: root.passwordInput = text

                                                background: Rectangle {
                                                    radius: 10
                                                    color: Qt.rgba(1, 1, 1, 0.05)
                                                    border.width: 1
                                                    border.color: Qt.rgba(1, 1, 1, 0.06)
                                                }
                                            }

                                            Button {
                                                text: "连接"
                                                enabled: root.passwordInput.trim().length > 0
                                                implicitHeight: 40
                                                implicitWidth: 74

                                                background: Rectangle {
                                                    radius: 10
                                                    color: parent.enabled
                                                           ? (parent.hovered ? Qt.lighter(Theme.accent, 1.05) : Theme.accent)
                                                           : Qt.rgba(1, 1, 1, 0.08)
                                                }

                                                contentItem: Label {
                                                    text: parent.text
                                                    color: parent.enabled ? Theme.accentText : Theme.subtext
                                                    font.pixelSize: 14
                                                    font.weight: Font.DemiBold
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                onClicked: {
                                                    WifiState.connectSecure(modelData.ssid, root.passwordInput.trim());
                                                    root.expandedSsid = "";
                                                    root.passwordInput = "";
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cardArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: mouse => {
                                        if (mouse.y > 48 || modelData.secure)
                                            return;
                                        if (!modelData.secure) {
                                            root.expandedSsid = "";
                                            root.passwordInput = "";
                                            WifiState.connectOpen(modelData.ssid);
                                        }
                                    }
                                    z: -1
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.04)
                            implicitHeight: 78
                            visible: WifiState.wifiEnabled && WifiState.networks.length === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "正在查找网络…"
                                    color: Theme.text
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "如果这里一直为空，再点一次 Wi‑Fi 按钮试试"
                                    color: Theme.subtext
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.04)
                            implicitHeight: 84
                            visible: !WifiState.wifiEnabled

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Wi‑Fi 已关闭"
                                    color: Theme.text
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "打开上方开关后查看附近网络"
                                    color: Theme.subtext
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
