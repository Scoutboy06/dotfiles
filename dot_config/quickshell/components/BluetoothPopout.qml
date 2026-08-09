import Quickshell
import Quickshell.Bluetooth
import QtQuick

Item {
    id: root

    required property var bluetooth
    required property var theme
    required property var motion
    signal closeRequested
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 36

    function hasConnected() {
        return bluetooth.devices.some(device => device.connected);
    }

    function hasDisconnected() {
        return bluetooth.devices.some(device => !device.connected);
    }

    Column {
        id: content
        anchors { fill: parent; margins: 18 }
        spacing: 14

        Row {
            width: parent.width

            Text {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 15
            }

            Item { width: parent.width - title.implicitWidth - settings.width - power.width - 8; height: 1 }

            ActionButton {
                id: settings
                theme: root.theme
                motion: root.motion
                text: "󰒓"
                textColor: root.theme.accent
                onClicked: {
                    Quickshell.execDetached(["sh", "-lc", "omarchy launch bluetooth"]);
                    root.closeRequested();
                }
            }

            Rectangle {
                id: power
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 18
                radius: 9
                color: root.bluetooth.enabled ? root.theme.accent : root.theme.surface

                Rectangle {
                    x: root.bluetooth.enabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: root.bluetooth.enabled ? root.theme.background : root.theme.foreground
                    Behavior on x { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
                }

                TapHandler { onTapped: root.bluetooth.toggleAdapter() }
                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }
        }

        Text {
            visible: root.bluetooth.enabled && root.hasConnected()
            text: "Connected"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Column {
            visible: root.bluetooth.enabled && root.hasConnected()
            width: parent.width
            spacing: 6

            Repeater {
                model: root.bluetooth.devices
                delegate: BluetoothDeviceRow {
                    required property var modelData
                    visible: modelData.connected
                    width: parent.width
                    device: modelData
                    bluetooth: root.bluetooth
                    theme: root.theme
                    motion: root.motion
                }
            }
        }

        Text {
            visible: root.bluetooth.enabled && root.hasDisconnected()
            text: "Paired devices"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Column {
            visible: root.bluetooth.enabled && root.hasDisconnected()
            width: parent.width
            spacing: 6

            Repeater {
                model: root.bluetooth.devices
                delegate: BluetoothDeviceRow {
                    required property var modelData
                    visible: !modelData.connected
                    width: parent.width
                    device: modelData
                    bluetooth: root.bluetooth
                    theme: root.theme
                    motion: root.motion
                }
            }
        }

        Text {
            width: parent.width
            visible: !root.bluetooth.enabled || root.bluetooth.devices.length === 0
            text: !root.bluetooth.enabled ? "Bluetooth is disabled" : "No paired devices"
            color: root.theme.foreground
            opacity: 0.65
            font.family: root.theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
