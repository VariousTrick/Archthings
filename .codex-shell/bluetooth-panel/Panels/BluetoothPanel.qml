import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    clip: true
    implicitWidth: 430
    implicitHeight: 520
    property Item dragTarget: null
    property string expandedDevicePath: ""
    property bool bluetoothToggleHovered: false

    signal dragFinished()

    function hoverColor(hovered) {
        return hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04);
    }

    function toggleExpanded(path) {
        if (!path || path.length === 0)
            return;
        expandedDevicePath = expandedDevicePath === path ? "" : path;
    }

    function isExpanded(modelData) {
        return !!(modelData && modelData.path && expandedDevicePath === modelData.path);
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
        anchors.margins: 16
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            color: "transparent"
            implicitHeight: 42

            RowLayout {
                anchors.fill: parent
                spacing: 10

                ColumnLayout {
                    spacing: 2

                    Label {
                        text: "蓝牙"
                        color: Theme.text
                        font.pixelSize: 21
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "Bluetooth 面板"
                        color: Theme.subtext
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: refreshButton
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 10
                    color: refreshMouseArea.pressed ? Qt.rgba(1, 1, 1, 0.09) : root.hoverColor(refreshMouseArea.containsMouse)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.04)

                    Label {
                        anchors.centerIn: parent
                        text: BluetoothState.discovering ? "󰑓" : "󰑐"
                        color: Theme.text
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothState.triggerRefresh()
                    }
                }

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
            implicitHeight: 68

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 999
                    color: Qt.rgba(1, 1, 1, 0.05)

                    Label {
                        anchors.centerIn: parent
                        text: BluetoothState.bluetoothEnabled ? "󰂯" : "󰂲"
                        color: Theme.text
                        font.pixelSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "启用蓝牙"
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: BluetoothState.bluetoothEnabled
                              ? (BluetoothState.controllerName.length > 0 ? `控制器：${BluetoothState.controllerName}` : "可查看附近蓝牙设备")
                              : "蓝牙已关闭"
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
                        color: BluetoothState.bluetoothEnabled
                               ? (root.bluetoothToggleHovered ? Qt.lighter(Theme.switchOn, 1.08) : Theme.switchOn)
                               : (root.bluetoothToggleHovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.12))

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            x: BluetoothState.bluetoothEnabled ? parent.width - width - 4 : 4
                            y: 4
                            color: Theme.switchKnob

                            Behavior on x {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.bluetoothToggleHovered = true
                        onExited: root.bluetoothToggleHovered = false
                        onClicked: BluetoothState.toggleBluetooth()
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Column {
                width: root.width - 32
                spacing: 12

                Repeater {
                    model: [
                        {
                            title: "已连接",
                            devices: BluetoothState.connectedDevices
                        },
                        {
                            title: "已配对",
                            devices: BluetoothState.pairedDevices
                        },
                        {
                            title: "设备",
                            devices: BluetoothState.availableDevices
                        }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        radius: 16
                        color: Theme.cardSoft
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)
                        visible: modelData.devices.length > 0
                        implicitHeight: visible ? sectionColumn.implicitHeight + 24 : 0

                        Column {
                            id: sectionColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10

                            Label {
                                text: modelData.title
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: modelData.devices

                                    delegate: Rectangle {
                                        width: parent.width
                                        radius: 14
                                        color: Qt.rgba(1, 1, 1, 0.04)
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.04)
                                        implicitHeight: itemColumn.implicitHeight + 24

                                        Column {
                                            id: itemColumn
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 12
                                            spacing: 10

                                            RowLayout {
                                                width: parent.width
                                                spacing: 10

                                                Label {
                                                    text: modelData.icon
                                                    color: Theme.text
                                                    font.pixelSize: 18
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 2

                                                    Label {
                                                        text: modelData.name
                                                        color: Theme.text
                                                        font.pixelSize: 15
                                                        font.weight: Font.DemiBold
                                                        elide: Text.ElideRight
                                                    }

                                                    Label {
                                                        text: root.detailText(modelData)
                                                        color: Theme.subtext
                                                        font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                Button {
                                                    visible: modelData.canForget
                                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                    Layout.preferredWidth: 30
                                                    Layout.preferredHeight: 28
                                                    enabled: BluetoothState.bluetoothEnabled
                                                    hoverEnabled: true

                                                    onClicked: BluetoothState.forgetDevice(modelData.device)

                                                    background: Rectangle {
                                                        radius: 14
                                                        color: parent.down
                                                               ? Qt.rgba(1, 1, 1, 0.12)
                                                               : (parent.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05))
                                                        border.width: 1
                                                        border.color: parent.hovered ? Theme.border : Qt.rgba(1, 1, 1, 0.06)
                                                    }

                                                    contentItem: Label {
                                                        text: "󰆴"
                                                        color: Theme.subtext
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                        font.pixelSize: 13
                                                    }
                                                }

                                                Button {
                                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                                    Layout.preferredWidth: 74
                                                    Layout.preferredHeight: 28
                                                    enabled: BluetoothState.bluetoothEnabled
                                                    hoverEnabled: true
                                                    text: modelData.actionLabel

                                                    onClicked: {
                                                        if (modelData.action === "disconnect")
                                                            BluetoothState.disconnectDevice(modelData.device);
                                                        else if (modelData.action === "connect")
                                                            BluetoothState.connectDevice(modelData.device);
                                                        else
                                                            BluetoothState.pairDevice(modelData.device);
                                                    }

                                                    background: Rectangle {
                                                        radius: 14
                                                        color: parent.down
                                                               ? Qt.rgba(1, 1, 1, 0.12)
                                                               : (parent.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.05))
                                                        border.width: 1
                                                        border.color: parent.hovered ? Qt.lighter(Theme.border, 1.15) : Theme.border
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
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    radius: 16
                    color: Theme.cardSoft
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.04)
                    visible: BluetoothState.connectedDevices.length === 0
                             && BluetoothState.pairedDevices.length === 0
                             && BluetoothState.availableDevices.length === 0
                    implicitHeight: 80

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: BluetoothState.bluetoothEnabled
                                  ? (BluetoothState.discovering ? "正在扫描附近设备" : "没有发现蓝牙设备")
                                  : "蓝牙已关闭"
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: BluetoothState.bluetoothEnabled ? "可点右上角刷新重新扫描" : "打开蓝牙后可查看附近设备"
                            color: Theme.subtext
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    function detailText(deviceData) {
        if (deviceData.secondaryName && deviceData.secondaryName.length > 0) {
            if (deviceData.details && deviceData.details.length > 0)
                return `${deviceData.secondaryName} · ${deviceData.details}`;
            return deviceData.secondaryName;
        }
        return deviceData.details || "";
    }
}
