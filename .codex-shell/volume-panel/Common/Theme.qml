pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: Qt.rgba(51 / 255, 51 / 255, 51 / 255, 0.98)
    readonly property color card: Qt.rgba(0.15, 0.15, 0.15, 0.92)
    readonly property color cardSoft: Qt.rgba(0.14, 0.14, 0.14, 0.88)
    readonly property color border: Qt.rgba(1, 1, 1, 0.08)
    readonly property color text: "#f3f7fc"
    readonly property color subtext: Qt.rgba(243 / 255, 247 / 255, 252 / 255, 0.76)
    readonly property color accent: "#8cb8ff"
    readonly property color accentText: "#11111b"
    readonly property color progressBg: Qt.rgba(1, 1, 1, 0.10)
    readonly property color progressFg: "#8cb8ff"
    readonly property color switchOn: "#8cb8ff"
    readonly property color switchKnob: "#f3f7fc"
    readonly property color line: Qt.rgba(1, 1, 1, 0.07)
    readonly property color danger: "#ff9d8c"
}
