import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "components"

PanelWindow {
    id: root

    required property var theme
    required property var motion
    required property var audio
    required property var popupState
    property bool exiting: false
    property bool shown: false

    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    exclusiveZone: 40
    color: "transparent"

    Component.onCompleted: reveal.start()
    Timer { id: reveal; interval: 1; onTriggered: root.shown = true }

    Rectangle {
        id: panel
        x: 8
        y: root.shown && !root.exiting ? 4 : -height - 4
        width: parent.width - 16
        height: 32
        radius: 10
        opacity: root.shown && !root.exiting ? 1 : 0
        color: root.theme.background

        Row {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 5

            ActionButton {
                theme: root.theme
                motion: root.motion
                text: "󰣇"
                textColor: root.theme.accent
                onClicked: Quickshell.execDetached(["omarchy-launch-walker"])
            }

            WorkspaceList {
                anchors.verticalCenter: parent.verticalCenter
                screen: root.screen
                theme: root.theme
                motion: root.motion
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            MediaControls {
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
            }

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                Behavior on color { ColorAnimation { duration: root.motion.normal } }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 3

            SystemTray { anchors.verticalCenter: parent.verticalCenter; theme: root.theme; motion: root.motion }
            NotificationCenter { anchors.verticalCenter: parent.verticalCenter; screen: root.screen; theme: root.theme; motion: root.motion }
            BatteryStatus { anchors.verticalCenter: parent.verticalCenter; theme: root.theme; motion: root.motion }
            StatusControls {
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                audio: root.audio
                onAudioClicked: root.popupState.audioScreen = root.popupState.audioScreen === root.screen ? null : root.screen
            }
        }

        Behavior on y {
            NumberAnimation { duration: root.motion.normal; easing.type: root.exiting ? Easing.InCubic : root.motion.emphasizedEasing }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing }
        }
        Behavior on color { ColorAnimation { duration: root.motion.normal } }
    }

    AudioPopout {
        screen: root.screen
        theme: root.theme
        motion: root.motion
        audio: root.audio
        open: root.popupState.audioScreen === root.screen
        onDismissRequested: root.popupState.audioScreen = null
    }
}
