import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    clip: true
    implicitWidth: 452
    implicitHeight: 484
    property Item dragTarget: null
    property bool batteryProgressHovered: false
    property bool careToggleHovered: false

    signal dragFinished()

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
                        text: "电量和电池"
                        color: Theme.text
                        font.pixelSize: 21
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "实验版 Plasma 风格电池面板"
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
            color: Theme.card
            implicitHeight: 138

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2

                        Label {
                            text: `${BatteryState.capacity}%`
                            color: Theme.text
                            font.pixelSize: 32
                            font.weight: Font.Black
                        }

                        Label {
                            text: BatteryState.statusText
                            color: Theme.subtext
                            font.pixelSize: 15
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 4

                        Label {
                            text: `剩余时间：${BatteryState.timeText}`
                            color: Theme.subtext
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight
                        }

                        Label {
                            text: `充电保护：${BatteryState.careEnabled ? `已开启（${BatteryState.careLimit}%）` : "已关闭"}`
                            color: Theme.subtext
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                ProgressBar {
                    id: batteryProgress
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: BatteryState.capacity

                    HoverHandler {
                        onHoveredChanged: root.batteryProgressHovered = hovered
                    }

                    background: Rectangle {
                        implicitHeight: 12
                        radius: 999
                        color: root.batteryProgressHovered ? Qt.rgba(1, 1, 1, 0.15) : Theme.progressBg
                    }

                    contentItem: Item {
                        implicitHeight: 12
                        Rectangle {
                            width: parent.width * batteryProgress.visualPosition
                            height: parent.height
                            radius: 999
                            color: root.batteryProgressHovered ? Qt.lighter(Theme.progressFg, 1.08) : Theme.progressFg
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Theme.cardSoft
            implicitHeight: 128

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: "电源管理方案"
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { key: "power-saver", label: "节能" },
                            { key: "balanced", label: "平衡" },
                            { key: "performance", label: "性能" }
                        ]

                        delegate: Button {
                            id: modeButton
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 44
                            text: modelData.label

                            background: Rectangle {
                                radius: 10
                                color: BatteryState.profile === modelData.key
                                       ? Theme.accent
                                       : (modeButton.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                                border.width: BatteryState.profile === modelData.key ? 0 : 1
                                border.color: modeButton.hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                            }

                            contentItem: Label {
                                text: modeButton.text
                                color: BatteryState.profile === modeButton.modelData.key ? Theme.accentText : Theme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: BatteryState.setProfile(modelData.key)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Theme.cardSoft
            implicitHeight: 96
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Label {
                        text: "限制充电到 80%"
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "用于日常插电时减少长期满充"
                        color: Theme.subtext
                        font.pixelSize: 13
                    }
                }

                Item {
                    id: careToggle
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 32
                    Layout.minimumWidth: 56
                    Layout.minimumHeight: 32
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: BatteryState.careEnabled
                               ? (root.careToggleHovered ? Qt.lighter(Theme.switchOn, 1.08) : Theme.switchOn)
                               : (root.careToggleHovered ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.12))

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            x: BatteryState.careEnabled ? parent.width - width - 4 : 4
                            y: 4
                            color: Theme.switchKnob
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onContainsMouseChanged: root.careToggleHovered = containsMouse
                        onClicked: BatteryState.toggleCare()
                    }
                }
            }
        }
    }
}
