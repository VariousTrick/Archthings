pragma Singleton

import QtQuick

QtObject {
    readonly property color bg: Qt.rgba(51 / 255, 51 / 255, 51 / 255, 0.98)
    readonly property color panel: Qt.rgba(45 / 255, 45 / 255, 45 / 255, 0.98)
    readonly property color tile: Qt.rgba(1, 1, 1, 0.028)
    readonly property color tileHover: Qt.rgba(1, 1, 1, 0.05)
    readonly property color tileActive: Qt.rgba(228 / 255, 225 / 255, 221 / 255, 0.82)
    readonly property color tileActiveText: "#27231f"
    readonly property color text: "#f3f1ee"
    readonly property color subtext: Qt.rgba(243 / 255, 241 / 255, 238 / 255, 0.62)
    readonly property color border: Qt.rgba(1, 1, 1, 0.055)
    readonly property color divider: Qt.rgba(1, 1, 1, 0.055)
    readonly property color sliderTrack: Qt.rgba(1, 1, 1, 0.14)
    readonly property color sliderFill: "#d9d6d2"
    readonly property color sliderKnob: "#8f8b87"
    readonly property color success: "#bfe3c7"
    readonly property color rowFill: Qt.rgba(1, 1, 1, 0.028)
    readonly property color rowHover: Qt.rgba(1, 1, 1, 0.052)
    readonly property color actionFill: Qt.rgba(1, 1, 1, 0.04)
    readonly property color actionHover: Qt.rgba(1, 1, 1, 0.065)
}
