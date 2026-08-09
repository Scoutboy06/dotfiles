import Quickshell.Services.UPower
import QtQuick

Rectangle {
    id: root
    required property var theme
    required property var motion

    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged

    visible: battery.isLaptopBattery
    implicitWidth: visible ? label.implicitWidth + 12 : 0
    implicitHeight: 24
    radius: 12
    color: "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: (root.charging ? "󰂄 " : "󰁹 ") + Math.round(root.battery.percentage * 100) + "%"
        color: root.battery.percentage <= 0.2 && !root.charging ? root.theme.urgent : root.theme.foreground
        font.pixelSize: 12
        font.family: root.theme.fontFamily
    }
}
