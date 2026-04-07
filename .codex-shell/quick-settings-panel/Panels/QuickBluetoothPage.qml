import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    anchors.fill: parent

    signal backRequested()

    readonly property color pageRowFill: Qt.rgba(1, 1, 1, 0.048)
    readonly property color pageButtonFill: Qt.rgba(1, 1, 1, 0.085)
    readonly property color pageButtonHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color pageInputBorder: Qt.rgba(1, 1, 1, 0.11)

    function pairingTitle() {
        const type = PairingState.request.requestType || "";
        if (type === "pin")
            return "输入蓝牙 PIN";
        if (type === "passkey")
            return "输入配对码";
        if (type === "confirm")
            return "确认配对码";
        return "蓝牙配对";
    }

    function pairingConfirmText() {
        const type = PairingState.request.requestType || "";
        if (type === "pin" || type === "passkey")
            return "提交";
        return "确认";
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

    component ActionButton: Button {
        id: button
        implicitWidth: 90
        implicitHeight: 36
        hoverEnabled: true

        background: Rectangle {
            radius: 18
            color: button.down ? Qt.rgba(1, 1, 1, 0.14) : (button.hovered ? root.pageButtonHover : root.pageButtonFill)
            border.width: 1
            border.color: root.pageInputBorder
        }

        contentItem: Label {
            text: button.text
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component TrashButton: Button {
        id: button
        implicitWidth: 32
        implicitHeight: 32
        hoverEnabled: true

        background: Rectangle {
            radius: 16
            color: button.down ? Qt.rgba(1, 1, 1, 0.14) : (button.hovered ? root.pageButtonHover : root.pageButtonFill)
            border.width: 1
            border.color: root.pageInputBorder
        }

        contentItem: Label {
            text: "󰆴"
            color: Theme.text
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component SectionBlock: Column {
        id: sectionRoot
        required property string title
        required property var items
        required property string actionKind

        width: parent ? parent.width : 390
        spacing: 6
        visible: items.length > 0

        Label {
            text: parent.title
            color: Theme.subtext
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Repeater {
            model: sectionRoot.items

            delegate: Rectangle {
                required property var modelData

                width: parent.width
                radius: 12
                color: root.pageRowFill
                border.width: 1
                border.color: Theme.border
                implicitHeight: 64

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Label {
                        id: iconLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        text: modelData.icon
                        color: Theme.text
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        id: actionArea
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 130
                        height: 36

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Item {
                                width: 32
                                height: 32

                                TrashButton {
                                    anchors.fill: parent
                                    visible: modelData.canForget
                                    enabled: modelData.canForget
                                    onClicked: BluetoothState.forgetDevice(modelData.device)
                                }
                            }

                            ActionButton {
                                width: 90
                                height: 36
                                text: modelData.actionLabel
                                enabled: !PairingState.isBusy(modelData.path || "")
                                onClicked: {
                                    if (sectionRoot.actionKind === "disconnect")
                                        BluetoothState.disconnectDevice(modelData.device);
                                    else if (sectionRoot.actionKind === "connect")
                                        BluetoothState.connectDevice(modelData.device);
                                    else
                                        BluetoothState.pairDevice(modelData.device);
                                }
                            }
                        }
                    }

                    Column {
                        anchors.left: iconLabel.right
                        anchors.leftMargin: 12
                        anchors.right: actionArea.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Label {
                            width: parent.width
                            text: modelData.name
                            color: Theme.text
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Label {
                            width: parent.width
                            text: PairingState.statusForPath(modelData.path || "") !== "" ? PairingState.statusForPath(modelData.path || "") : modelData.details
                            color: PairingState.statusForPath(modelData.path || "") !== "" ? Theme.text : Theme.subtext
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

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
                                onClicked: root.backRequested()
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                spacing: 12

                ScrollView {
                    width: parent.width
                    height: PairingState.active ? 226 : 312
                    clip: true

                    contentWidth: availableWidth

                    Column {
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            width: parent.width
                            visible: PairingState.active
                            radius: 16
                            color: root.pageRowFill
                            border.width: 1
                            border.color: Theme.border
                            implicitHeight: pairingColumn.implicitHeight + 24

                            Column {
                                id: pairingColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 10

                                Column {
                                    width: parent.width
                                    spacing: 4

                                    Label {
                                        text: root.pairingTitle()
                                        color: Theme.text
                                        font.pixelSize: 17
                                        font.weight: Font.DemiBold
                                    }

                                    Label {
                                        text: PairingState.request.deviceName || "蓝牙设备"
                                        color: Theme.subtext
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    radius: 14
                                    color: Qt.rgba(1, 1, 1, 0.04)
                                    implicitHeight: requestBody.implicitHeight + 18

                                    Column {
                                        id: requestBody
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        spacing: 10

                                        Label {
                                            visible: PairingState.request.requestType === "confirm"
                                            width: parent.width
                                            text: "配对码"
                                            color: Theme.subtext
                                            font.pixelSize: 12
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Label {
                                            visible: PairingState.request.requestType === "confirm"
                                            width: parent.width
                                            text: PairingState.request.passkey ? String(PairingState.request.passkey).padStart(6, "0") : ""
                                            color: Theme.text
                                            font.pixelSize: 24
                                            font.weight: Font.DemiBold
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        TextField {
                                            visible: PairingState.request.requestType === "pin"
                                            width: parent.width
                                            placeholderText: "输入 PIN"
                                            color: Theme.text
                                            placeholderTextColor: Theme.subtext
                                            text: PairingState.pinInput
                                            onTextChanged: PairingState.pinInput = text
                                            background: Rectangle {
                                                radius: 12
                                                color: Qt.rgba(1, 1, 1, 0.05)
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.08)
                                            }
                                        }

                                        TextField {
                                            visible: PairingState.request.requestType === "passkey"
                                            width: parent.width
                                            placeholderText: "输入 6 位配对码"
                                            color: Theme.text
                                            placeholderTextColor: Theme.subtext
                                            text: PairingState.passkeyInput
                                            onTextChanged: PairingState.passkeyInput = text
                                            background: Rectangle {
                                                radius: 12
                                                color: Qt.rgba(1, 1, 1, 0.05)
                                                border.width: 1
                                                border.color: Qt.rgba(1, 1, 1, 0.08)
                                            }
                                        }

                                        RowLayout {
                                            width: parent.width
                                            spacing: 10

                                            Item { Layout.fillWidth: true }

                                            Button {
                                                Layout.preferredWidth: 72
                                                Layout.preferredHeight: 32
                                                text: "取消"
                                                hoverEnabled: true
                                                onClicked: PairingState.reject()

                                                background: Rectangle {
                                                    radius: 16
                                                    color: parent.down
                                                           ? Qt.rgba(1, 1, 1, 0.12)
                                                           : (parent.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05))
                                                    border.width: 1
                                                    border.color: Theme.border
                                                }

                                                contentItem: Label {
                                                    text: parent.text
                                                    color: Theme.text
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            Button {
                                                Layout.preferredWidth: 86
                                                Layout.preferredHeight: 32
                                                text: root.pairingConfirmText()
                                                hoverEnabled: true
                                                onClicked: PairingState.accept()

                                                background: Rectangle {
                                                    radius: 16
                                                    color: parent.down
                                                           ? Qt.darker(Theme.tileActive, 1.05)
                                                           : (parent.hovered ? Qt.lighter(Theme.tileActive, 1.03) : Theme.tileActive)
                                                }

                                                contentItem: Label {
                                                    text: parent.text
                                                    color: Theme.tileActiveText
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

                        SectionBlock {
                            width: parent.width
                            title: "已连接"
                            items: BluetoothState.connectedDevices
                            actionKind: "disconnect"
                        }

                        SectionBlock {
                            width: parent.width
                            title: "已配对"
                            items: BluetoothState.pairedDevices
                            actionKind: "connect"
                        }

                        SectionBlock {
                            width: parent.width
                            title: "设备"
                            items: BluetoothState.availableDevices
                            actionKind: "pair"
                        }
                    }
                }

                Item { width: 1; height: 1 }

                Rectangle {
                    width: parent.width
                    height: 52
                    color: root.pageRowFill
                    border.width: 1
                    border.color: Theme.border
                    radius: 12

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
                            text: "刷新设备列表"
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
