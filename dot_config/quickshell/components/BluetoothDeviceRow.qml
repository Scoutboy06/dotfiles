import Quickshell.Bluetooth
import QtQuick

Rectangle {
    id: root

    required property var device
    required property var bluetooth
    required property var theme
    required property var motion

    readonly property bool busy: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting

    height: visible ? 38 : 0
    radius: 8
    color: device.connected ? Qt.alpha(theme.accent, 0.18) : hover.hovered ? Qt.lighter(theme.surface, 1.2) : theme.surface

    Row {
        anchors { fill: parent; leftMargin: 10; rightMargin: 6 }
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - status.width - (action.visible ? action.width + 16 : 8)
            text: root.device.name || root.device.deviceName
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            text: root.busy ? (root.device.connected ? "Disconnecting…" : "Connecting…") : root.device.batteryAvailable ? Math.round(root.device.battery * 100) + "%" : ""
            color: root.theme.foreground
            opacity: 0.7
            font.family: root.theme.fontFamily
            font.pixelSize: 11
        }

        ActionButton {
            id: action
            anchors.verticalCenter: parent.verticalCenter
            visible: root.device.connected
            enabled: !root.busy
            theme: root.theme
            motion: root.motion
            text: root.busy ? "󰔟" : root.device.connected ? "󰌸" : "󰌷"
            textColor: root.device.connected ? root.theme.urgent : root.theme.accent
            onClicked: root.bluetooth.toggleDevice(root.device)
        }
    }

    HoverHandler { id: hover }
    Behavior on color { ColorAnimation { duration: root.motion.fast } }
}
