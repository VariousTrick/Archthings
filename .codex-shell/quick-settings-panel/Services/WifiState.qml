pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string basePath: "/home/Arch/Downloads/vscode/Archthings/.codex-shell/quick-settings-panel"
    readonly property string stateScript: `${basePath}/scripts/wifi-state.sh`
    readonly property string actionScript: `${basePath}/scripts/wifi-action.sh`

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
            console.warn("QuickSettings WifiState parse failed", e, raw);
        }
    }

    function toggleWifi() {
        if (actionProc.running)
            return;
        pendingAction = "toggle";
        actionProc.mode = "toggle";
        actionProc.arg1 = wifiEnabled ? "off" : "on";
        actionProc.arg2 = "";
        actionProc.running = true;
    }

    function triggerRefresh() {
        if (actionProc.running)
            return;
        pendingAction = "refresh";
        actionProc.mode = "refresh";
        actionProc.arg1 = "";
        actionProc.arg2 = "";
        actionProc.running = true;
    }

    function disconnect() {
        if (actionProc.running)
            return;
        pendingAction = "disconnect";
        actionProc.mode = "disconnect";
        actionProc.arg1 = "";
        actionProc.arg2 = "";
        actionProc.running = true;
    }

    function connectOpen(ssid) {
        if (actionProc.running || !ssid)
            return;
        pendingAction = "connect-open";
        actionProc.mode = "connect-open";
        actionProc.arg1 = ssid;
        actionProc.arg2 = "";
        actionProc.running = true;
    }

    function connectSecure(ssid, password) {
        if (actionProc.running || !ssid || !password)
            return;
        pendingAction = "connect-secure";
        actionProc.mode = "connect-secure";
        actionProc.arg1 = ssid;
        actionProc.arg2 = password;
        actionProc.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 5000
        repeat: true
        running: true
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
                console.warn("QuickSettings WifiState state exited with", exitCode);
            }
        }
    }

    Process {
        id: actionProc
        property string mode: ""
        property string arg1: ""
        property string arg2: ""

        command: {
            if (!mode)
                return [];
            if (mode === "toggle")
                return [root.actionScript, "toggle", arg1];
            if (mode === "connect-open")
                return [root.actionScript, "connect-open", arg1];
            if (mode === "connect-secure")
                return [root.actionScript, "connect-secure", arg1, arg2];
            return [root.actionScript, mode];
        }
        running: false

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("QuickSettings WifiState action exited with", exitCode, pendingAction);
            pendingAction = "";
            mode = "";
            arg1 = "";
            arg2 = "";
            root.refresh();
        }
    }
}
