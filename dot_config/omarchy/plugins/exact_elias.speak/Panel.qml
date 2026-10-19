import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "elias.speak"
  ipcTarget: "elias.speak"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string speedText: speak.speed.toFixed(2).replace(/0$/, "").replace(/\.0$/, ".0") + "x"
  readonly property string metaText: {
    if (!speak.connected || speak.state === "off") return "Off"
    if (speak.state === "idle") return "Idle"
    var t = speak.paused ? "Paused" : "Playing"
    t += " · " + speedText
    if (speak.queued > 0) t += " · " + speak.queued + " queued"
    return t
  }
  property int cursor: -1

  function activate() {
    speak.toggle()
  }
  onOpenedChanged: if (opened) {
    cursor = -1
    Qt.callLater(function() { keys.forceActiveFocus() })
  }
  Service { id: speak }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: speak.paused ? "󰏤" : "󰔊"
    tooltipText: ""
    foreground: speak.playing || speak.paused ? root.barForeground : Qt.darker(root.barForeground, 1.55)
    onPressed: function(b) { if (b === Qt.MiddleButton) speak.toggle(); else root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(400))
    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.activate()
      onMoveRequested: function(dx, dy) {
        if (dx > 0) speak.faster()
        else if (dx < 0) speak.slower()
      }
      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "+" || k === "=") speak.faster()
        else if (k === "-") speak.slower()
        else if (k === "s") speak.stop()
        else if (k === " " || k === "p") speak.toggle()
      }
      Column {
        id: column
        width: parent.width
        spacing: Style.space(14)
        PanelHero {
          id: hero
          title: "Speech"
          meta: root.metaText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: speak.playing || speak.paused ? 1 : 0.5
          iconComponent: Component {
            Text { text: "󰔊"; color: hero.foreground; font.family: hero.fontFamily; font.pixelSize: Style.font.display }
          }
        }
        Text {
          visible: speak.current !== ""
          width: parent.width
          text: speak.current
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          maximumLineCount: 4
          elide: Text.ElideRight
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(10)
          PanelActionButton {
            iconText: "󰍴"
            tooltipText: "Slower"
            size: Style.space(34)
            fontSize: Style.font.icon
            foreground: root.foreground
            hasCursor: root.cursor === 0
            onHovered: function(on) { if (on) root.cursor = 0 }
            onClicked: speak.slower()
          }
          PanelActionButton {
            iconText: speak.playing ? "󰏤" : "󰐊"
            tooltipText: speak.playing ? "Pause" : "Play"
            size: Style.space(34)
            fontSize: Style.font.icon
            foreground: root.foreground
            hasCursor: root.cursor === 1
            onHovered: function(on) { if (on) root.cursor = 1 }
            onClicked: speak.toggle()
          }
          PanelActionButton {
            iconText: "󰐕"
            tooltipText: "Faster"
            size: Style.space(34)
            fontSize: Style.font.icon
            foreground: root.foreground
            hasCursor: root.cursor === 2
            onHovered: function(on) { if (on) root.cursor = 2 }
            onClicked: speak.faster()
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.speedText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "space play/pause · ←/→ − / + speed · s stop"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }
}
