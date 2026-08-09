import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    required property var power
    signal closeRequested

    property string confirmation: ""
    readonly property var actions: {
        const items = [
            { action: "screensaver", icon: "󱄄", label: "Screensaver", urgent: false },
            { action: "lock", icon: "", label: "Lock", urgent: false }
        ];
        if (power.suspendAvailable)
            items.push({ action: "suspend", icon: "󰒲", label: "Suspend", urgent: false });
        if (power.hibernateAvailable)
            items.push({ action: "hibernate", icon: "󰤁", label: "Hibernate", urgent: false });
        items.push(
            { action: "logout", icon: "󰍃", label: "Logout", urgent: false },
            { action: "restart", icon: "󰜉", label: "Restart", urgent: true },
            { action: "shutdown", icon: "󰐥", label: "Shutdown", urgent: true }
        );
        return items;
    }

    implicitWidth: 300
    implicitHeight: (confirmation === "" ? menuContent.implicitHeight : confirmationContent.implicitHeight) + 36

    function execute(action) {
        closeRequested();
        power.execute(action);
    }

    onEnabledChanged: {
        if (enabled) {
            confirmation = "";
            power.refresh();
        } else {
            confirmation = "";
        }
    }

    Column {
        id: menuContent
        visible: root.confirmation === ""
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 8

        Text {
            text: "System"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 15
        }

        Repeater {
            model: root.actions

            delegate: Rectangle {
                id: actionRow
                required property var modelData
                width: menuContent.width
                height: 38
                radius: 8
                color: hover.hovered ? Qt.lighter(root.theme.surface, 1.22) : root.theme.surface

                Text {
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 24
                    text: actionRow.modelData.icon
                    color: actionRow.modelData.urgent ? root.theme.urgent : root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors { left: parent.left; leftMargin: 48; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: actionRow.modelData.label
                    color: actionRow.modelData.urgent ? root.theme.urgent : root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 13
                }

                HoverHandler { id: hover }
                TapHandler {
                    onTapped: {
                        const action = actionRow.modelData.action;
                        if (action === "logout" || action === "restart" || action === "shutdown")
                            root.confirmation = action;
                        else
                            root.execute(action);
                    }
                }
                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }
        }
    }

    Column {
        id: confirmationContent
        visible: root.confirmation !== ""
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 14

        Text {
            width: parent.width
            text: root.confirmation.charAt(0).toUpperCase() + root.confirmation.slice(1) + "?"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: "Unsaved work may be lost."
            color: root.theme.foreground
            opacity: 0.7
            font.family: root.theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rectangle {
                width: 106
                height: 34
                radius: 8
                color: cancelHover.hovered ? Qt.lighter(root.theme.surface, 1.22) : root.theme.surface

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.pixelSize: 12
                }
                HoverHandler { id: cancelHover }
                TapHandler { onTapped: root.confirmation = "" }
                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }

            Rectangle {
                width: 106
                height: 34
                radius: 8
                color: confirmHover.hovered ? Qt.lighter(root.theme.urgent, 1.15) : root.theme.urgent

                Text {
                    anchors.centerIn: parent
                    text: root.confirmation.charAt(0).toUpperCase() + root.confirmation.slice(1)
                    color: root.theme.background
                    font.family: root.theme.fontFamily
                    font.bold: true
                    font.pixelSize: 12
                }
                HoverHandler { id: confirmHover }
                TapHandler { onTapped: root.execute(root.confirmation) }
                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }
        }
    }
}
