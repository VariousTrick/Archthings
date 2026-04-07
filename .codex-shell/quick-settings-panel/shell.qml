//@ pragma UseQApplication

import QtQuick
import QtCore
import Quickshell
import Quickshell.Wayland
import "./Panels"
import "./Services"

ShellRoot {
    id: root

    PanelWindow {
        id: overlay

        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        visible: PanelControl.panelVisible
        color: "transparent"

        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.namespace: "codex:quick-settings-panel"
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
                onActivated: PanelControl.panelVisible = false
            }

            MouseArea {
                x: 0
                y: 0
                width: overlay.width
                height: Math.max(0, panel.y)
                onPressed: PanelControl.panelVisible = false
            }

            MouseArea {
                x: 0
                y: panel.y
                width: Math.max(0, panel.x)
                height: panel.height
                onPressed: PanelControl.panelVisible = false
            }

            MouseArea {
                x: panel.x + panel.width
                y: panel.y
                width: Math.max(0, overlay.width - (panel.x + panel.width))
                height: panel.height
                onPressed: PanelControl.panelVisible = false
            }

            MouseArea {
                x: 0
                y: panel.y + panel.height
                width: overlay.width
                height: Math.max(0, overlay.height - (panel.y + panel.height))
                onPressed: PanelControl.panelVisible = false
            }

            QuickSettingsPanel {
                id: panel
                width: implicitWidth
                height: implicitHeight
                x: Math.max(24, overlay.width - width - 34)
                y: Math.max(24, overlay.height - height - 62)
            }
        }
    }
}
