import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "components"

PanelWindow {
    id: root

    required property var theme
    required property var motion
    property bool exiting: false
    property bool shown: false

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 40
    exclusiveZone: 40
    color: "transparent"

    Component.onCompleted: reveal.start()

    Timer {
        id: reveal
        interval: 1
        onTriggered: root.shown = true
    }

    Rectangle {
        id: panel

        x: 8
        y: root.shown && !root.exiting ? 4 : -height - 4
        width: parent.width - 16
        height: 32
        radius: 10
        opacity: root.shown && !root.exiting ? 1 : 0
        color: root.theme.background

        WorkspaceList {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            screen: root.screen
            theme: root.theme
            motion: root.motion
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
            color: root.theme.foreground
            font.pixelSize: 13
            font.bold: true

            Behavior on color {
                ColorAnimation { duration: root.motion.normal }
            }
        }

        RowLayout {
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 12

            Text {
                text: "NET"
                color: root.theme.success
                font.pixelSize: 12
            }

            Text {
                text: "BAT"
                color: root.theme.warning
                font.pixelSize: 12
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.motion.normal
                easing.type: root.exiting ? Easing.InCubic : root.motion.emphasizedEasing
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.motion.fast
                easing.type: root.motion.spatialEasing
            }
        }

        Behavior on color {
            ColorAnimation { duration: root.motion.normal }
        }
    }
}
