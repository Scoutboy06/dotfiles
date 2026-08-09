import Quickshell
import QtQuick

Item {
    id: root

    required property var network
    required property var theme
    required property var motion
    signal closeRequested

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 36

    Column {
        id: content
        anchors { fill: parent; margins: 18 }
        spacing: 14

        Row {
            width: parent.width

            Text {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                text: "Network"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 15
            }

            Item { width: parent.width - title.implicitWidth - settings.width; height: 1 }

            ActionButton {
                id: settings
                theme: root.theme
                motion: root.motion
                text: "󰒓"
                textColor: root.theme.accent
                onClicked: {
                    Quickshell.execDetached(["sh", "-lc", "omarchy launch wifi"]);
                    root.closeRequested();
                }
            }
        }

        Text {
            visible: root.network.wired.length > 0 || root.network.connectedSsid !== ""
            text: "Connected"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: root.network.wired
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 32

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "Ethernet" + (modelData.default ? " · Default route" : ""); color: root.theme.foreground; font.family: root.theme.fontFamily; font.pixelSize: 12 }
                        Text { text: modelData.name + (modelData.address ? "  ·  " + modelData.address : ""); color: root.theme.foreground; opacity: 0.65; font.family: root.theme.fontFamily; font.pixelSize: 12 }
                    }
                }
            }

            Item {
                visible: root.network.connectedSsid !== ""
                width: parent.width
                height: visible ? 32 : 0

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Wi-Fi · " + root.network.connectedSsid; color: root.theme.foreground; font.family: root.theme.fontFamily; font.pixelSize: 12 }
                    Text { text: root.network.wifiAddress; color: root.theme.foreground; opacity: 0.65; font.family: root.theme.fontFamily; font.pixelSize: 12 }
                }
            }
        }

        Row {
            visible: root.network.wifiAvailable
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wi-Fi"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 13
            }

            Item { width: parent.width - 77; height: 1 }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 18
                radius: 9
                color: root.network.wifiEnabled ? root.theme.accent : root.theme.surface

                Rectangle {
                    x: root.network.wifiEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: root.network.wifiEnabled ? root.theme.background : root.theme.foreground
                    Behavior on x { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
                }

                TapHandler { onTapped: root.network.toggleWifi() }
                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }
        }

        Text {
            visible: root.network.wifiAvailable && root.network.wifiEnabled && root.network.networks.length > 0
            text: "Known networks"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Column {
            visible: root.network.wifiAvailable && root.network.wifiEnabled && root.network.networks.length > 0
            width: parent.width
            spacing: 6

            Repeater {
                model: root.network.networks
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 36
                    radius: 8
                    color: modelData.connected ? root.theme.accent : hover.hovered ? Qt.lighter(root.theme.surface, 1.2) : root.theme.surface

                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: parent.width - signalText.width - 30
                        text: (modelData.connected ? "●  " : "") + modelData.name
                        color: modelData.connected ? root.theme.background : root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        id: signalText
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        text: root.network.changingNetwork === modelData.name ? "Working…" : modelData.signal + "%"
                        color: modelData.connected ? root.theme.background : root.theme.foreground
                        opacity: 0.75
                        font.family: root.theme.fontFamily
                        font.pixelSize: 11
                    }

                    HoverHandler { id: hover }
                    TapHandler { onTapped: root.network.toggleNetwork(modelData) }
                    Behavior on color { ColorAnimation { duration: root.motion.fast } }
                }
            }
        }
    }
}
