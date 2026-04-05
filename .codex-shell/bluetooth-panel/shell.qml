//@ pragma UseQApplication

import QtQuick
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Wayland
import "./Panels"
import "./Services"

ShellRoot {
    id: root

    Settings {
        id: panelSettings
        category: "bluetoothPanel"
        property real panelX: -1
        property real panelY: -1
    }

    function defaultPanelX() {
        return Math.max(12, overlay.width - panel.width - 102);
    }

    function defaultPanelY() {
        return Math.max(12, overlay.height - panel.height - 38);
    }

    function clampPanel() {
        const maxX = Math.max(12, overlay.width - panel.width - 12);
        const maxY = Math.max(12, overlay.height - panel.height - 12);
        panel.x = Math.min(Math.max(panel.x, 12), maxX);
        panel.y = Math.min(Math.max(panel.y, 12), maxY);
    }

    function restorePanelPosition() {
        if (!overlay.width || !overlay.height || !panel.width || !panel.height)
            return;
        panel.x = panelSettings.panelX >= 0 ? panelSettings.panelX : defaultPanelX();
        panel.y = panelSettings.panelY >= 0 ? panelSettings.panelY : defaultPanelY();
        clampPanel();
    }

    function persistPanelPosition() {
        clampPanel();
        panelSettings.panelX = panel.x;
        panelSettings.panelY = panel.y;
    }

    PanelWindow {
        id: overlay

        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        visible: PanelControl.panelVisible
        color: "transparent"

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "codex:bluetooth-panel"
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Shortcut {
                sequence: "Escape"
                onActivated: Qt.quit()
            }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => {
                    const insidePanel = mouse.x >= panel.x
                            && mouse.x <= panel.x + panel.width
                            && mouse.y >= panel.y
                            && mouse.y <= panel.y + panel.height;
                    if (!insidePanel)
                        PanelControl.panelVisible = false;
                }
            }

            BluetoothPanel {
                id: panel
                width: implicitWidth
                height: implicitHeight
                x: root.defaultPanelX()
                y: root.defaultPanelY()
                dragTarget: panel
                z: 1

                onDragFinished: root.persistPanelPosition()
            }

            Component.onCompleted: root.restorePanelPosition()
            onWidthChanged: root.restorePanelPosition()
            onHeightChanged: root.restorePanelPosition()
        }
    }
}
