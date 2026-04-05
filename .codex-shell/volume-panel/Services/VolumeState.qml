pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string basePath: "/home/Arch/Downloads/vscode/Archthings/.codex-shell/volume-panel"
    readonly property string stateScript: `${basePath}/scripts/volume-panel-state.sh`
    readonly property string actionScript: `${basePath}/scripts/volume-panel-action.sh`
    readonly property string initialStateJson: Quickshell.env("QS_VOLUME_STATE_INITIAL")

    property string speakerLabel: "扬声器"
    property string speakerDetail: ""
    property string speakerIcon: "󰕾"
    property int speakerId: 0
    property int speakerVolume: 0
    property bool speakerMuted: false

    property string micLabel: "麦克风"
    property string micDetail: ""
    property string micIcon: "󰍬"
    property int micId: 0
    property int micVolume: 0
    property bool micMuted: false
    property var sinkDevices: []
    property var sourceDevices: []

    property bool loading: false
    property bool initialized: false

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
            const speaker = data.speaker || {};
            const mic = data.mic || {};
            speakerId = speaker.id ?? 0;
            speakerLabel = speaker.label ?? "扬声器";
            speakerDetail = speaker.detail ?? "";
            speakerIcon = speaker.icon ?? "󰕾";
            speakerVolume = speaker.volume ?? 0;
            speakerMuted = !!speaker.muted;
            micId = mic.id ?? 0;
            micLabel = mic.label ?? "麦克风";
            micDetail = mic.detail ?? "";
            micIcon = mic.icon ?? "󰍬";
            micVolume = mic.volume ?? 0;
            micMuted = !!mic.muted;
            sinkDevices = data.sinks || [];
            sourceDevices = data.sources || [];
            initialized = true;
            changed();
        } catch (e) {
            console.warn("VolumeState: failed to parse state", e, raw);
        }
    }

    function setSpeakerVolume(percent) {
        const clamped = Math.max(0, Math.min(100, Math.round(percent)));
        if (actionProc.running)
            return;
        speakerVolume = clamped;
        changed();
        actionProc.mode = "set-volume";
        actionProc.device = "speaker";
        actionProc.value = String(clamped / 100);
        actionProc.running = true;
    }

    function setMicVolume(percent) {
        const clamped = Math.max(0, Math.min(100, Math.round(percent)));
        if (actionProc.running)
            return;
        micVolume = clamped;
        changed();
        actionProc.mode = "set-volume";
        actionProc.device = "mic";
        actionProc.value = String(clamped / 100);
        actionProc.running = true;
    }

    function toggleSpeakerMute() {
        if (actionProc.running)
            return;
        speakerMuted = !speakerMuted;
        changed();
        actionProc.mode = "set-mute";
        actionProc.device = "speaker";
        actionProc.value = speakerMuted ? "1" : "0";
        actionProc.running = true;
    }

    function toggleMicMute() {
        if (actionProc.running)
            return;
        micMuted = !micMuted;
        changed();
        actionProc.mode = "set-mute";
        actionProc.device = "mic";
        actionProc.value = micMuted ? "1" : "0";
        actionProc.running = true;
    }

    function setSpeakerDevice(id) {
        if (actionProc.running || id === speakerId)
            return;
        speakerId = id;
        for (const device of sinkDevices) {
            if (device.id === id) {
                speakerLabel = device.label;
                speakerDetail = device.detail ?? "";
                break;
            }
        }
        changed();
        actionProc.mode = "set-default";
        actionProc.device = "";
        actionProc.value = String(id);
        actionProc.running = true;
    }

    function setMicDevice(id) {
        if (actionProc.running || id === micId)
            return;
        micId = id;
        for (const device of sourceDevices) {
            if (device.id === id) {
                micLabel = device.label;
                micDetail = device.detail ?? "";
                break;
            }
        }
        changed();
        actionProc.mode = "set-default";
        actionProc.device = "";
        actionProc.value = String(id);
        actionProc.running = true;
    }

    Component.onCompleted: {
        if (initialStateJson && initialStateJson.length > 0)
            applyState(initialStateJson);
        refresh();
    }

    Timer {
        interval: 4000
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
                console.warn("VolumeState: state script exited with", exitCode);
            }
        }
    }

    Process {
        id: actionProc
        property string mode: ""
        property string device: ""
        property string value: ""

        command: {
            if (!mode || !value)
                return [];
            if (mode === "set-default")
                return [root.actionScript, mode, value];
            if (!device)
                return [];
            return [root.actionScript, mode, device, value];
        }
        running: false

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("VolumeState: action exited with", exitCode, mode, device, value);
            root.refresh();
        }
    }
}
