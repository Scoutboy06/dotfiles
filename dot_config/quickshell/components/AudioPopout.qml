import Quickshell
import QtQuick

PopoutLayer {
    id: root

    required property var audio

    Column {
        width: parent.width
        spacing: 14

        Row {
            width: parent.width

            Text {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                text: "Audio"
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
                onClicked: Quickshell.execDetached(["sh", "-lc", "omarchy launch audio"])
            }
        }

        Text {
            text: "Output"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Row {
            width: parent.width
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 45
                text: root.audio.sink?.description ?? "No output"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.audio.volume * 100) + "%"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            width: parent.width
            spacing: 8

            AudioSlider {
                width: parent.width - muteOutput.width - parent.spacing
                theme: root.theme
                motion: root.motion
                value: root.audio.volume
                onMoved: root.audio.setVolume(value)
            }

            ActionButton {
                id: muteOutput
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                text: root.audio.muted ? "󰖁" : "󰕾"
                textColor: root.audio.muted ? root.theme.urgent : root.theme.foreground
                onClicked: root.audio.sink.audio.muted = !root.audio.muted
            }
        }

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: root.audio.sinks

                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 34
                    radius: 8
                    color: modelData === root.audio.sink ? root.theme.accent : hover.hovered ? Qt.lighter(root.theme.surface, 1.2) : root.theme.surface

                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: parent.width - 20
                        text: (modelData === root.audio.sink ? "●  " : "○  ") + modelData.description
                        color: modelData === root.audio.sink ? root.theme.background : root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    HoverHandler { id: hover }
                    TapHandler { onTapped: root.audio.selectSink(modelData) }
                    Behavior on color { ColorAnimation { duration: root.motion.fast } }
                }
            }
        }

        Item { width: 1; height: 8 }

        Text {
            text: "Microphone"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Row {
            width: parent.width
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 45
                text: root.audio.source?.description ?? "No microphone"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.audio.sourceVolume * 100) + "%"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 12
            }
        }

        Row {
            width: parent.width
            spacing: 8

            AudioSlider {
                width: parent.width - muteInput.width - parent.spacing
                theme: root.theme
                motion: root.motion
                value: root.audio.sourceVolume
                onMoved: root.audio.setSourceVolume(value)
            }

            ActionButton {
                id: muteInput
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                text: root.audio.sourceMuted ? "󰍭" : "󰍬"
                textColor: root.audio.sourceMuted ? root.theme.urgent : root.theme.foreground
                onClicked: root.audio.source.audio.muted = !root.audio.sourceMuted
            }
        }
    }
}
