pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool panelVisible: true

    IpcHandler {
        target: "bluetoothpanel"

        function toggle(): string {
            root.panelVisible = !root.panelVisible;
            return root.panelVisible ? "shown" : "hidden";
        }

        function show(): string {
            root.panelVisible = true;
            return "shown";
        }

        function hide(): string {
            root.panelVisible = false;
            return "hidden";
        }
    }
}
