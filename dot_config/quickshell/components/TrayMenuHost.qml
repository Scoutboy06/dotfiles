import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: root

    required property var theme
    required property var motion
    property var menu: null
    property real requestedCenter: width / 2
    property bool open: false
    property bool rendered: false
    property bool positionAnimationEnabled: false

    function showMenu(nextMenu, center) {
        if (!nextMenu || (open && menu === nextMenu))
            return;
        const wasOpen = open;
        closeTimer.stop();
        positionAnimationEnabled = wasOpen;
        requestedCenter = center;
        menu = nextMenu;
        rendered = true;
        open = true;
        const page = pageComponent.createObject(stack, { handle: nextMenu, isSubmenu: false });
        if (wasOpen)
            stack.replace(page);
        else
            stack.replace(page, StackView.Immediate);
        if (!wasOpen)
            positionAnimationTimer.restart();
    }

    function dismiss() {
        positionAnimationEnabled = false;
        open = false;
        closeTimer.restart();
    }

    visible: true
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
        Region { x: 0; y: 0; width: root.rendered ? root.width : 0; height: root.rendered ? root.height : 0 }
        Region { x: 0; y: 0; width: root.width; height: 36; intersection: Intersection.Subtract }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.dismiss()
        MouseArea { anchors.fill: parent; onClicked: root.dismiss() }
    }

    Rectangle {
        id: card
        x: Math.max(8, Math.min(root.width - width - 8, root.requestedCenter - width / 2))
        y: 36
        width: 224
        height: Math.min(root.height - 44, stack.currentItem?.implicitHeight ?? 48)
        radius: 12
        color: root.theme.background
        border.width: 1
        border.color: Qt.alpha(root.theme.foreground, 0.2)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopRight
        clip: true

        MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

        StackView {
            id: stack
            anchors.fill: parent
            pushEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.motion.fast } }
            pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.motion.fast } }
            popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.motion.fast } }
            popExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: root.motion.fast } }
        }

        Behavior on x {
            enabled: root.positionAnimationEnabled
            NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
        }
        Behavior on height {
            enabled: root.positionAnimationEnabled
            NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
        }
        Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
        Behavior on scale { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
    }

    Component {
        id: pageComponent

        Item {
            id: page
            required property var handle
            property bool isSubmenu: false
            implicitWidth: 224
            implicitHeight: entries.implicitHeight + 12

            QsMenuOpener { id: opener; menu: page.handle }

            Column {
                id: entries
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 3

                Repeater {
                    model: opener.children

                    delegate: Rectangle {
                        id: entry
                        required property var modelData
                        width: entries.width
                        height: modelData.isSeparator ? 1 : 26
                        radius: 8
                        color: modelData.isSeparator ? Qt.alpha(root.theme.foreground, 0.18)
                            : modelData.enabled && hover.hovered ? Qt.lighter(root.theme.surface, 1.25) : "transparent"

                        Item {
                            id: marker
                            visible: !entry.modelData.isSeparator
                            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                            width: 14
                            height: 14

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 14
                                source: entry.modelData.icon
                                visible: entry.modelData.icon !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: entry.modelData.icon === "" && entry.modelData.buttonType !== QsMenuButtonType.None
                                text: entry.modelData.checkState === Qt.Checked ? "✓" : entry.modelData.buttonType === QsMenuButtonType.RadioButton ? "○" : ""
                                color: root.theme.accent
                                font.family: root.theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            visible: !entry.modelData.isSeparator
                            anchors {
                                left: marker.right
                                leftMargin: 6
                                right: arrow.left
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            text: entry.modelData.text
                            color: entry.modelData.enabled ? root.theme.foreground : Qt.alpha(root.theme.foreground, 0.45)
                            font.family: root.theme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            id: arrow
                            visible: !entry.modelData.isSeparator
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            width: 12
                            text: entry.modelData.hasChildren ? "›" : ""
                            color: root.theme.foreground
                            font.family: root.theme.fontFamily
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignRight
                        }

                        HoverHandler { id: hover; enabled: entry.modelData.enabled && !entry.modelData.isSeparator }
                        TapHandler {
                            enabled: entry.modelData.enabled && !entry.modelData.isSeparator
                            onTapped: {
                                if (entry.modelData.hasChildren)
                                    stack.push(pageComponent.createObject(stack, { handle: entry.modelData, isSubmenu: true }));
                                else {
                                    entry.modelData.triggered();
                                    root.dismiss();
                                }
                            }
                        }
                        Behavior on color { ColorAnimation { duration: root.motion.fast } }
                    }
                }

                Rectangle {
                    visible: page.isSubmenu
                    width: parent.width
                    height: 26
                    radius: 8
                    color: backHover.hovered ? Qt.lighter(root.theme.surface, 1.25) : root.theme.surface

                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        text: "‹  Back"
                        color: root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                    }

                    HoverHandler { id: backHover }
                    TapHandler { onTapped: stack.pop() }
                    Behavior on color { ColorAnimation { duration: root.motion.fast } }
                }
            }
        }
    }

    Timer {
        id: positionAnimationTimer
        interval: root.motion.normal + 40
        onTriggered: root.positionAnimationEnabled = true
    }

    Timer {
        id: closeTimer
        interval: root.motion.normal
        onTriggered: root.rendered = false
    }
}
