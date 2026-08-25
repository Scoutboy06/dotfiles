import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function specialWorkspaces() {
    var workspaces = []
    var values = Hyprland.workspaces.values
    var monitors = Hyprland.monitors.values

    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      if (workspace.name.indexOf("special:") !== 0) continue

      var active = false
      for (var j = 0; j < monitors.length; j++) {
        var special = monitors[j].lastIpcObject.specialWorkspace
        if (special && special.name === workspace.name) {
          active = true
          break
        }
      }

      if (workspace.toplevels.values.length > 0 || active) workspaces.push(workspace)
    }

    workspaces.sort(function(left, right) { return left.name.localeCompare(right.name) })
    return workspaces
  }

  function specialWorkspaceLabel(name) {
    var labels = {
      music: "m",
      vesktop: "d",
      terminal: "ö",
      scratchpad: "s"
    }
    return labels[name] || name.slice(0, 1).toLowerCase()
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function toggleSpecialWorkspace(name) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.workspace.toggle_special(" + JSON.stringify(name) + ")"))
  }

  readonly property var barWindow: root.QsWindow.window
  readonly property var monitor: barWindow && barWindow.screen ? Hyprland.monitorFor(barWindow.screen) : null
  readonly property string activeSpecial: {
    var special = monitor ? monitor.lastIpcObject.specialWorkspace : null
    return special && special.name ? special.name : ""
  }
  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name !== "activespecial") return
      Hyprland.refreshMonitors()
      Hyprland.refreshWorkspaces()
    }
  }

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length + root.specialWorkspaces().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: focused ? "\uDB85\uDCFB" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }

    Repeater {
      model: root.specialWorkspaces()

      WidgetButton {
        required property var modelData

        readonly property string specialName: modelData.name.slice("special:".length)
        readonly property bool selected: modelData.name === root.activeSpecial

        bar: root.bar
        text: selected ? "\uDB85\uDCFB" : root.specialWorkspaceLabel(specialName)
        opacity: modelData.toplevels.values.length > 0 || selected ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        tooltipText: specialName
        onPressed: function() { root.toggleSpecialWorkspace(specialName) }
      }
    }
  }
}
