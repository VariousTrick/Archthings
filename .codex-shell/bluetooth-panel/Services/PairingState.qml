pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string basePath: "/home/Arch/Downloads/vscode/Archthings/.codex-shell/bluetooth-panel"
    readonly property string stateScript: `${basePath}/scripts/bluetooth-pairing-state.sh`
    readonly property string actionScript: `${basePath}/scripts/bluetooth-pairing-action.sh`

    property bool helperReady: false
    property var request: ({})
    property string requestToken: ""
    property bool sessionOpen: false
    property string sessionDevicePath: ""
    property string lastStatusSignature: ""
    property string statusMessage: ""
    property string statusTone: "info"
    property string statusDevicePath: ""
    property string pendingPairPath: ""
    property string pinInput: ""
    property string passkeyInput: ""

    readonly property bool active: sessionOpen && requestToken.length > 0

    signal changed

    function clearRequest() {
        request = ({});
        requestToken = "";
        pinInput = "";
        passkeyInput = "";
    }

    function refresh() {
        if (!stateProc.running)
            stateProc.running = true;
    }

    function setStatus(devicePath, message, tone) {
        statusDevicePath = devicePath || "";
        statusMessage = message || "";
        statusTone = tone || "info";
        lastStatusSignature = `${statusDevicePath}|${statusTone}|${statusMessage}`;
        if (statusMessage.length > 0)
            statusTimer.restart();
        changed();
    }

    function finishSession() {
        sessionOpen = false;
        sessionDevicePath = "";
        pendingPairPath = "";
        clearRequest();
        changed();
    }

    function applyState(raw) {
        helperReady = false;

        if (!raw || raw.trim().length === 0)
            return;

        try {
            const data = JSON.parse(raw.trim());
            helperReady = !!(data && data.helperReady);

            const requestData = data && data.request ? data.request : null;
            if (requestData && requestData.token && sessionOpen && requestData.devicePath === sessionDevicePath) {
                request = requestData;
                requestToken = requestData.token;
                pendingPairPath = requestData.devicePath || pendingPairPath;
            } else {
                clearRequest();
            }

            const statusData = data && data.status ? data.status : null;
            if (statusData && statusData.message) {
                const signature = `${statusData.devicePath || ""}|${statusData.tone || "info"}|${statusData.message || ""}`;
                if (signature !== lastStatusSignature) {
                    setStatus(statusData.devicePath || "", statusData.message || "", statusData.tone || "info");
                    if (statusData.devicePath === sessionDevicePath
                            && (statusData.tone === "success" || statusData.tone === "error" || statusData.tone === "muted"))
                        finishSession();
                }
            }

            changed();
        } catch (e) {
            console.warn("PairingState: failed to parse state", e, raw);
        }
    }

    function startPair(devicePath) {
        if (!helperReady || !devicePath || pairProc.running || responseProc.running)
            return;

        sessionOpen = true;
        sessionDevicePath = devicePath;
        clearRequest();
        pendingPairPath = devicePath;
        setStatus(devicePath, "正在发起配对", "info");
        pairProc.devicePath = devicePath;
        pairProc.running = true;
    }

    function accept() {
        if (!requestToken || responseProc.running)
            return;

        const type = request.requestType || "";
        let value = "";
        if (type === "pin")
            value = pinInput.trim();
        else if (type === "passkey")
            value = passkeyInput.trim();

        if ((type === "pin" || type === "passkey") && value.length === 0)
            return;

        const token = requestToken;
        const devicePath = request.devicePath || pendingPairPath;
        sessionOpen = false;
        clearRequest();
        setStatus(devicePath, "正在继续配对", "info");
        responseProc.mode = "accept";
        responseProc.token = token;
        responseProc.requestType = type;
        responseProc.value = value;
        responseProc.devicePath = devicePath;
        responseProc.running = true;
    }

    function reject() {
        if (!requestToken || responseProc.running)
            return;

        const token = requestToken;
        const type = request.requestType || "";
        const devicePath = request.devicePath || pendingPairPath;
        sessionOpen = false;
        clearRequest();
        setStatus(devicePath, "已取消本次配对", "muted");
        responseProc.mode = "reject";
        responseProc.token = token;
        responseProc.requestType = type;
        responseProc.value = "";
        responseProc.devicePath = devicePath;
        responseProc.running = true;
    }

    function isBusy(path) {
        if (!path || path.length === 0)
            return false;
        if (active && request && request.devicePath === path)
            return true;
        if ((pairProc.running || sessionOpen) && pendingPairPath === path)
            return true;
        if (responseProc.running && responseProc.devicePath === path)
            return true;
        return false;
    }

    function statusForPath(path) {
        if (!path || path.length === 0)
            return "";
        if (active && request && request.devicePath === path)
            return "等待配对确认";
        if (statusDevicePath === path && statusMessage.length > 0)
            return statusMessage;
        return "";
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: statusTimer
        interval: 2200
        repeat: false
        onTriggered: {
            root.statusMessage = "";
            root.statusTone = "info";
            root.statusDevicePath = "";
            root.lastStatusSignature = "";
            root.changed();
        }
    }

    Process {
        id: stateProc
        command: [root.stateScript]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyState(text)
        }
    }

    Process {
        id: pairProc
        property string devicePath: ""
        command: devicePath.length > 0 ? [root.actionScript, "pair", devicePath] : []
        running: false

        onExited: {
            root.refresh();
        }
    }

    Process {
        id: responseProc
        property string mode: ""
        property string token: ""
        property string requestType: ""
        property string value: ""
        property string devicePath: ""
        command: {
            if (!mode || !token)
                return [];
            if (mode === "accept")
                return [root.actionScript, "accept", token, requestType, value];
            return [root.actionScript, "reject", token, requestType, devicePath];
        }
        running: false

        onExited: {
            mode = "";
            token = "";
            requestType = "";
            value = "";
            devicePath = "";
            root.refresh();
        }
    }
}
