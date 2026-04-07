pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool bluetoothEnabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property string controllerName: adapter?.name ?? adapter?.adapterName ?? ""

    signal changed

    readonly property var connectedDevices: {
        if (!adapter?.devices)
            return [];

        return adapter.devices.values
            .filter(dev => dev && dev.connected && !dev.blocked)
            .sort(root.deviceSort)
            .map(dev => root.decorateDevice(dev, "disconnect"));
    }

    readonly property var pairedDevices: {
        if (!adapter?.devices)
            return [];

        return adapter.devices.values
            .filter(dev => dev && !dev.connected && !dev.blocked && (dev.paired || dev.trusted))
            .sort(root.deviceSort)
            .map(dev => root.decorateDevice(dev, "connect"));
    }

    readonly property var availableDevices: {
        if (!adapter?.devices)
            return [];

        return adapter.devices.values
            .filter(dev => dev && !dev.connected && !dev.blocked && !dev.paired && !dev.trusted)
            .sort(root.deviceSort)
            .map(dev => root.decorateDevice(dev, "pair"));
    }

    function summary() {
        if (!bluetoothEnabled)
            return "已关闭";
        if (connectedDevices.length > 0)
            return connectedDevices[0].name;
        if (pairedDevices.length > 0)
            return "已配对";
        return "未连接";
    }

    function deviceSort(a, b) {
        const aSignal = a?.signalStrength ?? 0;
        const bSignal = b?.signalStrength ?? 0;
        if (aSignal !== bSignal)
            return bSignal - aSignal;
        const aName = root.humanizeName(a).toLowerCase();
        const bName = root.humanizeName(b).toLowerCase();
        return aName.localeCompare(bName);
    }

    function rawName(device) {
        return device?.name || device?.deviceName || "";
    }

    function looksLikeMac(name) {
        return /^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/i.test(name);
    }

    function looksLikeMachineCode(name) {
        if (!name)
            return false;
        if (/[\u4e00-\u9fff]/.test(name))
            return false;
        if (/[a-z]/.test(name))
            return false;
        if (/\s/.test(name))
            return false;
        return /^[-_A-Z0-9]+$/.test(name) && /[-_]/.test(name);
    }

    function humanizeName(device) {
        const raw = root.rawName(device);
        if (!raw)
            return "未知蓝牙设备";
        if (root.looksLikeMac(raw))
            return "未知蓝牙设备";
        if (root.looksLikeMachineCode(raw)) {
            const parts = raw.split(/[-_]/).filter(Boolean);
            const tail = parts.length > 0 ? parts[parts.length - 1] : "";
            return tail.length > 0 ? `蓝牙设备 ${tail}` : "蓝牙设备";
        }
        return raw;
    }

    function secondaryName(device) {
        const raw = root.rawName(device);
        const display = root.humanizeName(device);
        if (!raw || raw === display)
            return "";
        return raw;
    }

    function deviceIcon(device) {
        if (!device)
            return "󰂯";

        const icon = (device.icon || "").toLowerCase();
        const name = (device.name || device.deviceName || "").toLowerCase();

        if (icon.includes("headset") || icon.includes("headphone") || name.includes("airpod") || name.includes("headset"))
            return "󰋋";
        if (icon.includes("mouse") || name.includes("mouse"))
            return "󰍽";
        if (icon.includes("keyboard") || name.includes("keyboard"))
            return "󰌌";
        if (icon.includes("phone") || name.includes("phone") || name.includes("iphone") || name.includes("android"))
            return "󰄜";
        if (icon.includes("speaker") || name.includes("speaker") || name.includes("hearing"))
            return "󰓃";
        return "󰂯";
    }

    function deviceDetails(device) {
        if (!device)
            return "";

        const bits = [];
        if (device.batteryAvailable && device.battery > 0)
            bits.push(`${Math.round(device.battery * 100)}% 电量`);

        if (device.connected)
            bits.push("已连接");
        else if (device.paired || device.trusted)
            bits.push("已配对，可连接");
        else if (device.pairing)
            bits.push("配对中");
        else if (root.discovering)
            bits.push("附近设备");
        else
            bits.push("可配对");

        return bits.join("，");
    }

    function decorateDevice(device, action) {
        return {
            device: device,
            path: device.dbusPath ?? "",
            mac: device.address ?? "",
            name: root.humanizeName(device),
            secondaryName: root.secondaryName(device),
            icon: root.deviceIcon(device),
            details: root.deviceDetails(device),
            actionLabel: action === "disconnect" ? "断开" : (action === "connect" ? "连接" : "配对"),
            action: action,
            canForget: !!(device?.paired || device?.trusted)
        };
    }

    function toggleBluetooth() {
        if (!adapter)
            return;
        adapter.enabled = !adapter.enabled;
        if (!adapter.enabled)
            adapter.discovering = false;
        changed();
    }

    function triggerRefresh() {
        if (!adapter)
            return;
        if (!adapter.enabled)
            adapter.enabled = true;
        adapter.discovering = true;
        scanStopper.restart();
        changed();
    }

    function connectDevice(device) {
        if (!device)
            return;
        device.trusted = true;
        device.connect();
    }

    function disconnectDevice(device) {
        if (!device)
            return;
        device.disconnect();
    }

    function pairDevice(device) {
        if (!device)
            return;
        if (PairingState.helperReady && device.dbusPath)
            PairingState.startPair(device.dbusPath);
        else
            device.pair();
    }

    function forgetDevice(device) {
        if (!device)
            return;
        if (device.connected)
            device.disconnect();
        device.forget();
    }

    Timer {
        id: scanStopper
        interval: 8000
        repeat: false
        onTriggered: {
            if (root.adapter)
                root.adapter.discovering = false;
        }
    }
}
