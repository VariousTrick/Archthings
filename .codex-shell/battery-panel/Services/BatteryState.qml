pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string basePath: "/home/Arch/Downloads/vscode/Archthings/.codex-shell/battery-panel"
    readonly property string stateScript: `${basePath}/scripts/battery-panel-state.sh`
    readonly property string actionScript: `${basePath}/scripts/battery-panel-action.sh`
    readonly property string initialStateJson: Quickshell.env("QS_BATTERY_STATE_INITIAL")

    property int capacity: 0
    property string status: "Unknown"
    property string statusText: "状态读取中"
    property string timeText: "--:--"
    property bool careEnabled: false
    property int careLimit: 100
    property string profile: "balanced"
    property string profileText: "平衡"
    property bool loading: false
    property bool initialized: false

    signal changed

    function refresh() {
        if (!stateProc.running) {
            loading = true;
            stateProc.running = true;
        }
    }

    function setProfile(nextProfile) {
        if (nextProfile === profile || actionProc.running)
            return;
        profile = nextProfile;
        switch (nextProfile) {
        case "power-saver":
            profileText = "节能";
            break;
        case "performance":
            profileText = "性能";
            break;
        default:
            profile = "balanced";
            profileText = "平衡";
            break;
        }
        changed();
        actionProc.mode = "set-profile";
        actionProc.targetProfile = profile;
        actionProc.running = true;
    }

    function toggleCare() {
        if (actionProc.running)
            return;
        careEnabled = !careEnabled;
        careLimit = careEnabled ? 80 : 100;
        changed();
        actionProc.mode = "toggle-care";
        actionProc.targetProfile = "";
        actionProc.running = true;
    }

    function applyState(raw) {
        if (!raw || raw.trim().length === 0)
            return;
        try {
            const data = JSON.parse(raw.trim());
            capacity = data.capacity ?? 0;
            status = data.status ?? "Unknown";
            statusText = data.status_text ?? "状态未知";
            timeText = data.time_text ?? "--:--";
            careEnabled = !!data.care_enabled;
            careLimit = data.care_limit ?? 100;
            profile = data.profile ?? "balanced";
            profileText = data.profile_text ?? "平衡";
            initialized = true;
            changed();
        } catch (e) {
            console.warn("BatteryState: failed to parse state", e, raw);
        }
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
                console.warn("BatteryState: state script exited with", exitCode);
            }
        }
    }

    Process {
        id: actionProc
        property string mode: ""
        property string targetProfile: ""

        command: {
            if (mode === "set-profile" && targetProfile.length > 0)
                return [root.actionScript, "set-profile", targetProfile];
            if (mode === "toggle-care")
                return [root.actionScript, "toggle-care"];
            return [];
        }
        running: false

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("BatteryState: action exited with", exitCode, mode, targetProfile);
            root.refresh();
        }
    }
}
