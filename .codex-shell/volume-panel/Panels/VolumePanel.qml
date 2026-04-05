import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../Common"
import "../Services"

Item {
    id: root
    clip: false
    implicitWidth: 452
    implicitHeight: 268
    property Item dragTarget: null
    property bool speakerDevicesExpanded: false
    property bool micDevicesExpanded: false

    signal dragFinished()

    function sliderTrackColor(muted) {
        return muted ? Qt.rgba(1, 1, 1, 0.06) : Theme.progressFg;
    }

    function hoverColor(hovered) {
        return hovered ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04);
    }

    function popupX(anchorItem, popupWidth) {
        const point = anchorItem.mapToItem(root, 0, anchorItem.height + 8);
        return Math.max(12, Math.min(point.x, root.width - popupWidth - 12));
    }

    function popupY(anchorItem, popupHeight) {
        const point = anchorItem.mapToItem(root, 0, anchorItem.height + 8);
        return Math.max(60, Math.min(point.y, root.height - popupHeight - 12));
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
                        text: "音量控制"
                        color: Theme.text
                        font.pixelSize: 21
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "实验版 Plasma 风格音量面板"
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
            implicitHeight: 86

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 999
                        color: speakerMuteArea.pressed ? Qt.rgba(1, 1, 1, 0.12)
                               : (speakerMuteArea.containsMouse ? root.hoverColor(true) : root.hoverColor(false))

                        Label {
                            anchors.centerIn: parent
                            text: VolumeState.speakerMuted ? "󰝟" : VolumeState.speakerIcon
                            color: VolumeState.speakerMuted ? Theme.danger : Theme.text
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: speakerMuteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: VolumeState.toggleSpeakerMute()
                        }
                    }

                    Rectangle {
                        id: speakerChip
                        radius: 999
                        color: speakerChipArea.containsMouse ? root.hoverColor(true) : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: speakerChipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                        implicitHeight: 32
                        implicitWidth: speakerChipRow.implicitWidth + 18

                        RowLayout {
                            id: speakerChipRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: VolumeState.speakerLabel
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: root.speakerDevicesExpanded ? "▴" : "▾"
                                color: Theme.subtext
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: speakerChipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.speakerDevicesExpanded = !root.speakerDevicesExpanded;
                                if (root.speakerDevicesExpanded)
                                    root.micDevicesExpanded = false;
                            }
                        }

                        ToolTip.visible: speakerChipArea.containsMouse && VolumeState.speakerDetail.length > 0
                        ToolTip.delay: 350
                        ToolTip.text: VolumeState.speakerDetail
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: `${VolumeState.speakerVolume}%`
                        color: Theme.subtext
                        font.pixelSize: 14
                    }
                }

                Slider {
                    id: speakerSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    live: true
                    value: pressed ? value : VolumeState.speakerVolume
                    onMoved: VolumeState.speakerVolume = Math.round(value)
                    onPressedChanged: {
                        if (!pressed)
                            VolumeState.setSpeakerVolume(value);
                    }

                    HoverHandler {
                        id: speakerSliderHover
                    }

                    background: Rectangle {
                        x: speakerSlider.leftPadding
                        y: speakerSlider.topPadding + speakerSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        width: speakerSlider.availableWidth
                        implicitHeight: 10
                        height: implicitHeight
                        radius: 999
                        color: speakerSliderHover.hovered ? Qt.rgba(1, 1, 1, 0.14) : Theme.progressBg

                        Rectangle {
                            width: speakerSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 999
                            color: speakerSliderHover.hovered
                                   ? Qt.lighter(root.sliderTrackColor(VolumeState.speakerMuted), 1.08)
                                   : root.sliderTrackColor(VolumeState.speakerMuted)
                        }
                    }

                    handle: Rectangle {
                        x: speakerSlider.leftPadding + speakerSlider.visualPosition * (speakerSlider.availableWidth - width)
                        y: speakerSlider.topPadding + speakerSlider.availableHeight / 2 - height / 2
                        implicitWidth: speakerSliderHover.hovered ? 20 : 18
                        implicitHeight: speakerSliderHover.hovered ? 20 : 18
                        radius: 999
                        color: Theme.switchKnob
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.12)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: 16
            color: Theme.cardSoft
            implicitHeight: 86

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 999
                        color: micMuteArea.pressed ? Qt.rgba(1, 1, 1, 0.12)
                               : (micMuteArea.containsMouse ? root.hoverColor(true) : root.hoverColor(false))

                        Label {
                            anchors.centerIn: parent
                            text: VolumeState.micMuted ? "󰍭" : VolumeState.micIcon
                            color: VolumeState.micMuted ? Theme.danger : Theme.text
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: micMuteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: VolumeState.toggleMicMute()
                        }
                    }

                    Rectangle {
                        id: micChip
                        radius: 999
                        color: micChipArea.containsMouse ? root.hoverColor(true) : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: micChipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                        implicitHeight: 32
                        implicitWidth: micChipRow.implicitWidth + 18

                        RowLayout {
                            id: micChipRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: VolumeState.micLabel
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Label {
                                text: root.micDevicesExpanded ? "▴" : "▾"
                                color: Theme.subtext
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            id: micChipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.micDevicesExpanded = !root.micDevicesExpanded;
                                if (root.micDevicesExpanded)
                                    root.speakerDevicesExpanded = false;
                            }
                        }

                        ToolTip.visible: micChipArea.containsMouse && VolumeState.micDetail.length > 0
                        ToolTip.delay: 350
                        ToolTip.text: VolumeState.micDetail
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: `${VolumeState.micVolume}%`
                        color: Theme.subtext
                        font.pixelSize: 14
                    }
                }

                Slider {
                    id: micSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    live: true
                    value: pressed ? value : VolumeState.micVolume
                    onMoved: VolumeState.micVolume = Math.round(value)
                    onPressedChanged: {
                        if (!pressed)
                            VolumeState.setMicVolume(value);
                    }

                    HoverHandler {
                        id: micSliderHover
                    }

                    background: Rectangle {
                        x: micSlider.leftPadding
                        y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        width: micSlider.availableWidth
                        implicitHeight: 10
                        height: implicitHeight
                        radius: 999
                        color: micSliderHover.hovered ? Qt.rgba(1, 1, 1, 0.14) : Theme.progressBg

                        Rectangle {
                            width: micSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 999
                            color: micSliderHover.hovered
                                   ? Qt.lighter(root.sliderTrackColor(VolumeState.micMuted), 1.08)
                                   : root.sliderTrackColor(VolumeState.micMuted)
                        }
                    }

                    handle: Rectangle {
                        x: micSlider.leftPadding + micSlider.visualPosition * (micSlider.availableWidth - width)
                        y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                        implicitWidth: micSliderHover.hovered ? 20 : 18
                        implicitHeight: micSliderHover.hovered ? 20 : 18
                        radius: 999
                        color: Theme.switchKnob
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.12)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    Item {
        anchors.fill: parent
        z: 20

        Rectangle {
            id: speakerPopup
            visible: root.speakerDevicesExpanded
            width: 258
            x: root.popupX(speakerChip, width)
            y: root.popupY(speakerChip, height)
            radius: 14
            color: Qt.rgba(0.15, 0.15, 0.15, 0.97)
            border.width: 1
            border.color: Theme.border
            implicitHeight: speakerPopupColumn.implicitHeight + 12

            ColumnLayout {
                id: speakerPopupColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Repeater {
                    model: VolumeState.sinkDevices

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: modelData.detail && modelData.detail.length > 0 ? 50 : 34
                        radius: 8
                        color: modelData.id === VolumeState.speakerId
                               ? Theme.accent
                               : (speakerDeviceArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: modelData.label
                                    color: modelData.id === VolumeState.speakerId ? Theme.accentText : Theme.text
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: modelData.id === VolumeState.speakerId ? "当前" : ""
                                    color: modelData.id === VolumeState.speakerId ? Theme.accentText : Theme.subtext
                                    font.pixelSize: 12
                                }
                            }

                            Label {
                                visible: modelData.detail && modelData.detail.length > 0
                                text: modelData.detail
                                color: modelData.id === VolumeState.speakerId
                                       ? Qt.rgba(1, 1, 1, 0.78)
                                       : Theme.subtext
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: speakerDeviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                VolumeState.setSpeakerDevice(parent.modelData.id);
                                root.speakerDevicesExpanded = false;
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: micPopup
            visible: root.micDevicesExpanded
            width: 258
            x: root.popupX(micChip, width)
            y: root.popupY(micChip, height)
            radius: 14
            color: Qt.rgba(0.15, 0.15, 0.15, 0.97)
            border.width: 1
            border.color: Theme.border
            implicitHeight: micPopupColumn.implicitHeight + 12

            ColumnLayout {
                id: micPopupColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                Repeater {
                    model: VolumeState.sourceDevices

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: modelData.detail && modelData.detail.length > 0 ? 50 : 34
                        radius: 8
                        color: modelData.id === VolumeState.micId
                               ? Theme.accent
                               : (micDeviceArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: modelData.label
                                    color: modelData.id === VolumeState.micId ? Theme.accentText : Theme.text
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: modelData.id === VolumeState.micId ? "当前" : ""
                                    color: modelData.id === VolumeState.micId ? Theme.accentText : Theme.subtext
                                    font.pixelSize: 12
                                }
                            }

                            Label {
                                visible: modelData.detail && modelData.detail.length > 0
                                text: modelData.detail
                                color: modelData.id === VolumeState.micId
                                       ? Qt.rgba(1, 1, 1, 0.78)
                                       : Theme.subtext
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: micDeviceArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                VolumeState.setMicDevice(parent.modelData.id);
                                root.micDevicesExpanded = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
