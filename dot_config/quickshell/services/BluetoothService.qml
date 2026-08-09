import Quickshell.Bluetooth
import QtQuick

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    property var devices: []

    function refreshDevices() {
        devices = Bluetooth.devices.values.filter(device => device.paired || device.bonded);
    }

    function toggleAdapter() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function toggleDevice(device) {
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    Component.onCompleted: refreshDevices()

    property Connections deviceConnections: Connections {
        target: Bluetooth.devices
        function onValuesChanged() { root.refreshDevices(); }
    }
}
