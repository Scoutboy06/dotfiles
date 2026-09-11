import QtQuick
import QtQuick.Controls
import Quickshell
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
  property int leaseIndex: 1
  readonly property var leases: [30, 60, 120, 240]

  function toggleFull() { vpn.request(vpn.full ? "split" : "full", leases[leaseIndex]) }
  function activate() {
    if (cursor === 0) toggleFull()
    else if (cursor === 1) vpn.request("split", 0)
    else if (cursor === 2) vpn.request("full", leases[leaseIndex])
    else if (cursor === 4 && vpn.full) vpn.request("renew", leases[leaseIndex])
    else if (cursor === 5) vpn.refresh()
  }

  onOpenedChanged: if (opened) {
    cursor = -1
    vpn.refresh()
    Qt.callLater(function() { keys.forceActiveFocus() })
  }

  Service { id: vpn; detailsVisible: root.opened }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰦝"
    tooltipText: ""
    foreground: vpn.available ? root.barForeground : Qt.darker(root.barForeground, 1.55)
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
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(620))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.activate()
      onMoveRequested: function(dx, dy) {
        if (root.cursor < 0) { root.cursor = 0; return }
        if (dy) root.cursor = Math.max(0, Math.min(5, root.cursor + dy))
        if (dx && root.cursor === 3) root.leaseIndex = Math.max(0, Math.min(3, root.leaseIndex + dx))
      }
      onTextKey: function(t) {
        if (t.toLowerCase() === "r") vpn.refresh()
        if (t.toLowerCase() === "t") root.toggleFull()
      }

      Flickable {
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
            title: "Work VPN"
            meta: !vpn.available ? "Status unavailable" : vpn.busy || vpn.switching ? "Switching profile…" : vpn.state.connected ? "Connected" : "Disconnected"
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text { text: "󰦝"; color: hero.foreground; font.family: hero.fontFamily; font.pixelSize: Style.font.display }
            }
          }

          Item {
            width: parent.width
            implicitHeight: fullSwitch.implicitHeight
            visible: vpn.available
            Detail {
              width: parent.width - fullSwitch.width - Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              text: "Full tunnel"
              color: root.foreground
              font.pixelSize: Style.font.body
            }
              ToggleSwitch {
                id: fullSwitch
                checked: vpn.full
                anchors.right: parent.right
                busy: !vpn.canChange
                interactive: vpn.canChange
                opacity: vpn.canChange ? 1 : 0.5
                hasCursor: root.cursor === 0
                foreground: hero.foreground
                onHovered: function(on) { if (on) root.cursor = 0 }
                onToggled: root.toggleFull()
              }
          }

          Detail {
            visible: vpn.error !== "" || vpn.notice !== ""
            text: vpn.error || vpn.notice
            color: vpn.error ? Color.urgent : root.dim
          }
          PanelSeparator { foreground: root.foreground }
          PanelSectionHeader { text: "VPN PROFILES"; foreground: root.foreground; fontFamily: root.fontFamily }

          ProfileRow {
            rowIndex: 1
            title: vpn.splitProfile || "Split tunnel"
            subtitle: "Split tunnel · default"
            selected: vpn.state.connected === vpn.splitProfile
          }
          ProfileRow {
            rowIndex: 2
            title: vpn.fullProfile || "Full tunnel"
            subtitle: "Full tunnel · timed lease"
            selected: vpn.full
          }

          PanelSectionHeader { text: "FULL TUNNEL LEASE"; foreground: root.foreground; fontFamily: root.fontFamily }
          ButtonGroup {
            options: [{value: "0", label: "30m"}, {value: "1", label: "1h"}, {value: "2", label: "2h"}, {value: "3", label: "4h"}]
            value: String(root.leaseIndex)
            foreground: root.foreground
            fontFamily: root.fontFamily
            focusable: false
            cursorIndex: root.cursor === 3 ? root.leaseIndex : -1
            onChanged: function(value) { root.leaseIndex = Number(value) }
            onHovered: function(index, on) { if (on) root.cursor = 3 }
          }
          Detail { text: "Returns to split tunnel when the lease expires. Switching may briefly interrupt access to the laptop." }

          Column {
            visible: vpn.known
            width: parent.width
            spacing: Style.space(6)
            PanelSeparator { foreground: root.foreground }
            Detail { visible: vpn.state.desired !== vpn.state.connected; text: "Requested: " + (vpn.state.desired || "Unknown") }
            Detail { text: "Tailnet: " + (vpn.state.tailnetOnline === true ? "Online" : "Offline") }
            Detail { text: "Agent: " + (vpn.state.reason || "Unknown") + " · " + (vpn.stale ? "stale" : "updated " + Qt.formatDateTime(new Date(vpn.state.updated), "HH:mm:ss")) }
          }
          Row {
            spacing: Style.space(12)
            Button {
              text: "Renew lease"
              enabled: vpn.full && vpn.canChange
              foreground: root.foreground
              fontFamily: root.fontFamily
              hasCursor: root.cursor === 4
              onHovered: function(on) { if (on) root.cursor = 4 }
              onClicked: vpn.request("renew", root.leases[root.leaseIndex])
            }
            Button {
              text: "Refresh"
              foreground: root.foreground
              fontFamily: root.fontFamily
              hasCursor: root.cursor === 5
              onHovered: function(on) { if (on) root.cursor = 5 }
              onClicked: vpn.refresh()
            }
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

  component ProfileRow: CursorSurface {
    id: row
    required property int rowIndex
    required property string title
    required property string subtitle
    required property bool selected
    width: parent.width
    implicitHeight: labels.implicitHeight + Style.spacing.rowPaddingX
    foreground: root.foreground
    current: selected && vpn.available
    hasCursor: root.cursor === rowIndex
    opacity: vpn.canChange ? 1 : 0.55
    Column {
      id: labels
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: Style.space(10)
      spacing: Style.space(2)
      Detail { text: (row.selected && vpn.available ? "✓  " : "") + row.title; color: root.foreground; font.pixelSize: Style.font.body }
      Detail { text: row.subtitle }
    }
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      enabled: vpn.canChange
      cursorShape: Qt.PointingHandCursor
      onContainsMouseChanged: if (containsMouse) root.cursor = row.rowIndex
      onClicked: { root.cursor = row.rowIndex; root.activate() }
    }
  }
}
