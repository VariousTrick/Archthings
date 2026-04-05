pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string basePath: "/home/Arch/Downloads/vscode/Archthings/.codex-shell/wifi-panel"
    readonly property string stateScript: `${basePath}/scripts/wifi-panel-state.sh`
    readonly property string actionScript: `${basePath}/scripts/wifi-panel-action.sh`
    readonly property string initialStateJson: Quickshell.env("QS_WIFI_STATE_INITIAL")

    property bool wifiEnabled: true
    property string wifiDevice: ""
    property string connectedSsid: ""
    property var networks: []
    property bool loading: false
    property bool initialized: false
    property string pendingAction: ""

    signal changed

    function refresh() {
        if (!stateProc.running) {
            loading = true;
            stateProc.running = true;
        }
    }

    function applyState(raw) {
        if (!raw || raw.trim().length === 0)
            return;
        try {
            const data = JSON.parse(raw.trim());
            wifiEnabled = !!data.wifiEnabled;
            wifiDevice = data.wifiDevice ?? "";
            connectedSsid = data.connectedSsid ?? "";
            networks = data.networks || [];
            initialized = true;
            changed();
        } catch (e) {
            console.warn("WifiState: failed to parse state", e, raw);
        }
    }

    function toggleWifi() {
        if (actionProc.running)
            return;
        wifiEnabled = !wifiEnabled;
        changed();
        pendingAction = "toggle";
        actionProc.command = [actionScript, "toggle", wifiEnabled ? "on" : "off"];
        actionProc.running = true;
    }

    function disconnect() {
        if (actionProc.running)
            return;
        pendingAction = "disconnect";
        actionProc.command = [actionScript, "disconnect"];
        actionProc.running = true;
    }

    function connectOpen(ssid) {
        if (actionProc.running || !ssid)
            return;
        pendingAction = "connect-open";
        actionProc.command = [actionScript, "connect-open", ssid];
        actionProc.running = true;
    }

    function connectSecure(ssid, password) {
        if (actionProc.running || !ssid || !password)
            return;
        pendingAction = "connect-secure";
        actionProc.command = [actionScript, "connect-secure", ssid, password];
        actionProc.running = true;
    }

    Component.onCompleted: {
        if (initialStateJson && initialStateJson.length > 0)
            applyState(initialStateJson);
        refresh();
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    Process {
        id: stateProc
        command: [root.stateScript]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                root.applyState(text);
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.loading = false;
                console.warn("WifiState: state script exited with", exitCode);
            }
        }
    }

    Process {
        id: actionProc
        property var command: []
        running: false

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("WifiState: action exited with", exitCode, pendingAction);
            pendingAction = "";
            root.refresh();
        }
    }
}
