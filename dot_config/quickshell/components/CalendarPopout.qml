import QtQuick
import QtQuick.Controls.Basic as Basic

Item {
    id: root

    required property var theme
    required property var motion

    property date now: new Date()
    property int displayedMonth: now.getMonth()
    property int displayedYear: now.getFullYear()

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 36

    function changeMonth(offset) {
        const date = new Date(displayedYear, displayedMonth + offset, 1);
        displayedMonth = date.getMonth();
        displayedYear = date.getFullYear();
    }

    function showToday() {
        now = new Date();
        displayedMonth = now.getMonth();
        displayedYear = now.getFullYear();
    }

    Column {
        id: content
        anchors { fill: parent; margins: 18 }
        spacing: 12

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM yyyy")
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 15
        }

        Row {
            width: parent.width

            ActionButton {
                id: previous
                theme: root.theme
                motion: root.motion
                text: "‹"
                onClicked: root.changeMonth(-1)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - previous.width - next.width
                text: Qt.formatDate(new Date(root.displayedYear, root.displayedMonth, 1), "MMMM yyyy")
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
            }

            ActionButton {
                id: next
                theme: root.theme
                motion: root.motion
                text: "›"
                onClicked: root.changeMonth(1)
            }
        }

        Basic.DayOfWeekRow {
            width: parent.width
            locale: Qt.locale("en_GB")
            spacing: 6
            delegate: Text {
                required property string shortName
                width: (content.width - 36) / 7
                height: 22
                text: shortName.slice(0, 2)
                color: root.theme.foreground
                opacity: 0.65
                font.family: root.theme.fontFamily
                font.bold: true
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Basic.MonthGrid {
            width: parent.width
            height: 210
            month: root.displayedMonth
            year: root.displayedYear
            locale: Qt.locale("en_GB")
            spacing: 6

            delegate: Rectangle {
                required property var model
                readonly property bool today: model.year === root.now.getFullYear() && model.month === root.now.getMonth() && model.day === root.now.getDate()

                width: (content.width - 36) / 7
                height: 30
                radius: 9
                color: today ? root.theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: model.day
                    color: parent.today ? root.theme.background : root.theme.foreground
                    opacity: model.month === root.displayedMonth ? 1 : 0.35
                    font.family: root.theme.fontFamily
                    font.bold: parent.today
                    font.pixelSize: 12
                }

                Behavior on color { ColorAnimation { duration: root.motion.fast } }
            }
        }

        Row {
            width: parent.width
            Item { width: (parent.width - todayButton.width) / 2; height: 1 }
            ActionButton {
                id: todayButton
                theme: root.theme
                motion: root.motion
                text: "Today"
                textColor: root.theme.accent
                onClicked: root.showToday()
            }
        }
    }
}
