import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
    id: root
    required property var screen
    required property var theme
    required property var motion
    property bool hoverEnabled: true

    property bool open: false
    property var notifications: []
    implicitWidth: button.implicitWidth
    implicitHeight: 24

    function refresh() { history.running = true; }
    function run(command) { Quickshell.execDetached(["sh", "-lc", command]); }

    ActionButton {
        id: button
        anchors.centerIn: parent
        theme: root.theme
        motion: root.motion
        text: "󰂚 " + root.notifications.length
        textColor: root.notifications.length > 0 ? root.theme.accent : root.theme.foreground
        hoverEnabled: root.hoverEnabled
        onClicked: { root.open = !root.open; root.refresh(); }
    }

    Process {
        id: history
        command: ["makoctl", "list", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.notifications = JSON.parse(text); }
                catch (error) { root.notifications = []; }
            }
        }
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: refreshDelay; interval: 150; onTriggered: root.refresh() }

    PanelWindow {
        screen: root.screen
        visible: root.open
        anchors { top: true; right: true }
        margins { top: 36; right: 8 }
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        implicitWidth: 360
        implicitHeight: Math.min(420, content.implicitHeight + 24)
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: root.theme.background

            Column {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "Notifications"; color: root.theme.foreground; font.family: root.theme.fontFamily; font.bold: true; font.pixelSize: 14 }
                    Item { width: parent.width - 180; height: 1 }
                    Text {
                        visible: root.notifications.length > 0
                        text: "dismiss all"
                        color: root.theme.accent
                        font.family: root.theme.fontFamily
                        TapHandler { onTapped: { root.run("makoctl dismiss --all --no-history"); refreshDelay.restart(); } }
                    }
                }

                Repeater {
                    model: root.notifications.slice(0, 6)
                    delegate: Rectangle {
                        required property var modelData
                        width: content.width
                        height: message.implicitHeight + 18
                        radius: 8
                        color: root.theme.surface
                        Column {
                            id: message
                            anchors { left: parent.left; right: dismiss.left; verticalCenter: parent.verticalCenter; leftMargin: 9; rightMargin: 6 }
                            Text { width: parent.width; text: modelData.summary || modelData.app_name; color: root.theme.foreground; font.family: root.theme.fontFamily; font.bold: true; elide: Text.ElideRight }
                            Text { width: parent.width; text: modelData.body || ""; color: root.theme.foreground; font.family: root.theme.fontFamily; opacity: 0.75; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                        }

                        Text {
                            id: dismiss
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            text: "×"
                            color: root.theme.urgent
                            font.family: root.theme.fontFamily
                            font.pixelSize: 20
                            TapHandler {
                                onTapped: {
                                    root.run("makoctl dismiss -n " + modelData.id + " --no-history");
                                    refreshDelay.restart();
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: root.notifications.length === 0
                    text: "No active notifications"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    opacity: 0.65
                }
            }
        }
    }
}
