import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var theme
    required property var motion
    property bool open: false
    property bool rendered: false
    property int cardWidth: 340
    property int rightOffset: 8
    default property alias contentData: content.data
    signal dismissRequested

    visible: rendered
    onOpenChanged: {
        if (open)
            rendered = true;
        else if (rendered)
            closeTimer.restart();
    }
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.dismissRequested()

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissRequested()
        }
    }

    Rectangle {
        id: card
        anchors { top: parent.top; topMargin: 36; right: parent.right; rightMargin: root.rightOffset }
        width: root.cardWidth
        height: content.implicitHeight + 28
        radius: 12
        color: root.theme.background
        border.width: 1
        border.color: Qt.alpha(root.theme.foreground, 0.2)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopRight

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Item {
            id: content
            anchors { fill: parent; margins: 18 }
            implicitHeight: childrenRect.height
        }

        Behavior on opacity { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
        Behavior on scale { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
    }

    Timer {
        id: closeTimer
        interval: root.motion.normal
        onTriggered: root.rendered = false
    }
}
