import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "elias.vpn"
  ipcTarget: "elias.vpn"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  property int cursor: -1

  function activate() {
    if (cursor === 0) vpn.toggle()
    else if (cursor > 0 && cursor <= vpn.profiles.length) vpn.select(vpn.profiles[cursor - 1].id)
  }
  onOpenedChanged: if (opened) {
    cursor = -1
    Qt.callLater(function() { keys.forceActiveFocus() })
  }
  Service { id: vpn }
  Connections {
    target: vpn
    function onProfilesChanged() { root.cursor = Math.min(root.cursor, vpn.profiles.length) }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰦝"
    tooltipText: ""
    foreground: vpn.active ? root.barForeground : Qt.darker(root.barForeground, 1.55)
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keys
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))
    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.activate()
      onMoveRequested: function(dx, dy) {
        root.cursor = Math.max(0, Math.min(vpn.profiles.length, root.cursor + dy))
        if (root.cursor > 0) {
          var row = rows.itemAt(root.cursor - 1)
          if (row) {
            var y = row.mapToItem(column, 0, 0).y
            if (y < scroll.contentY) scroll.contentY = y
            else if (y + row.height > scroll.contentY + scroll.height)
              scroll.contentY = y + row.height - scroll.height
          }
        }
      }
      onTextKey: function(t) { if (t.toLowerCase() === "t") vpn.toggle() }
      Flickable {
        id: scroll
        anchors.fill: parent
        contentHeight: column.implicitHeight
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        Column {
          id: column
          width: parent.width
          spacing: Style.space(14)
          PanelHero {
            id: hero
            title: "VPN"
            meta: vpn.busy ? "Updating…" : !vpn.active ? "Off" : vpn.phase === "connected" ? "Connected" : vpn.phase === "error" ? "Connection unavailable" : "Connecting…"
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: vpn.active ? 1 : 0.5
            iconComponent: Component {
              Text { text: "󰦝"; color: hero.foreground; font.family: hero.fontFamily; font.pixelSize: Style.font.display }
            }
            trailingControl: Component {
              ToggleSwitch {
                checked: vpn.active
                busy: vpn.busy
                hasCursor: root.cursor === 0
                foreground: hero.foreground
                onHovered: function(on) { if (on) root.cursor = 0 }
                onToggled: vpn.toggle()
              }
            }
          }
          Detail {
            visible: vpn.error !== ""
            text: vpn.error
            color: Color.urgent
          }
          Detail {
            visible: !vpn.active && !vpn.error
            text: "Enable to connect and load available VPNs."
          }
          PanelSeparator { visible: vpn.active; foreground: root.foreground }
          PanelSectionHeader { visible: vpn.active; text: "VPN PROFILES"; foreground: root.foreground; fontFamily: root.fontFamily }
          Repeater {
            id: rows
            model: vpn.profiles
            CursorSurface {
              id: row
              required property var modelData
              required property int index
              width: column.width
              implicitHeight: labels.implicitHeight + Style.spacing.rowPaddingX
              foreground: root.foreground
              current: vpn.connectedIds.indexOf(modelData.id) !== -1 && vpn.phase === "connected"
              hasCursor: root.cursor === index + 1
              Column {
                id: labels
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(10)
                spacing: Style.space(2)
                Detail { text: (row.current ? "✓  " : "") + row.modelData.name; color: root.foreground; font.pixelSize: Style.font.body }
                Detail { text: row.modelData.id === vpn.selectedId && vpn.phase !== "connected" ? "Connecting…" : row.modelData.splitTunneling ? "Selected destinations" : "All proxy traffic" }
              }
              MouseArea {
                anchors.fill: parent
                enabled: !vpn.busy
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) root.cursor = row.index + 1
                onClicked: vpn.select(row.modelData.id)
              }
            }
          }
          Detail {
            visible: vpn.active && vpn.phase === "connected"
            text: "For applications using the system proxy."
          }
        }
      }
    }
  }
  component Detail: Text {
    width: parent.width
    textFormat: Text.PlainText
    wrapMode: Text.Wrap
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }
}
