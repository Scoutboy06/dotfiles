import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    required property var notifications

    implicitWidth: 360
    implicitHeight: Math.min(420, content.implicitHeight + 36)

    Column {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 8

        Row {
            width: parent.width

            Text {
                text: "Notifications"
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 14
            }

            Item { width: parent.width - 180; height: 1 }

            Text {
                visible: root.notifications.notifications.length > 0
                text: "dismiss all"
                color: root.theme.accent
                font.family: root.theme.fontFamily

                HoverHandler { id: dismissAllHover }
                TapHandler { onTapped: root.notifications.dismissAll() }

                opacity: dismissAllHover.hovered ? 0.7 : 1
                Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            }
        }

        Repeater {
            model: root.notifications.notifications.slice(0, 6)

            delegate: Rectangle {
                required property var modelData
                width: content.width
                height: message.implicitHeight + 18
                radius: 8
                color: root.theme.surface

                Column {
                    id: message
                    anchors {
                        left: parent.left
                        right: dismiss.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 9
                        rightMargin: 6
                    }

                    Text {
                        width: parent.width
                        text: modelData.summary || modelData.app_name
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.body || ""
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        opacity: 0.75
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: dismiss
                    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    text: "×"
                    color: root.theme.urgent
                    font.family: root.theme.fontFamily
                    font.pixelSize: 20
                    opacity: dismissHover.hovered ? 0.65 : 1

                    HoverHandler { id: dismissHover }
                    TapHandler { onTapped: root.notifications.dismiss(modelData.id) }
                    Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
                }
            }
        }

        Text {
            visible: root.notifications.notifications.length === 0
            text: "No active notifications"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            opacity: 0.65
        }
    }
}
