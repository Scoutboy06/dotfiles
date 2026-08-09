import QtQuick

ActionButton {
    id: root

    required property var notifications
    property bool active: false
    signal notificationClicked(var anchor)
    signal notificationHovered(var anchor)

    visible: notifications.notifications.length > 0
    text: "󰂚 " + notifications.notifications.length
    textColor: notifications.notifications.length > 0 ? theme.accent : theme.foreground
    highlighted: active

    onClicked: root.notificationClicked(root)
    onHoveredChanged: if (hovered) root.notificationHovered(root)
}
