import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: vpn
  property var state: ({enabled: false, phase: "off"})
  property string commandError: ""
  readonly property bool active: state.enabled === true
  readonly property bool busy: action.running
  readonly property var profiles: active && state.profiles instanceof Array ? state.profiles : []
  readonly property string phase: state.phase || "off"
  readonly property string error: commandError || state.error || ""
  readonly property string selectedId: state.selectedId || ""
  readonly property var connectedIds: state.connectedIds || []

  function toggle() { execute(["vpnctl", active ? "off" : "on"]) }
  function select(id) { if (active) execute(["vpnctl", "select", id]) }
  function execute(args) {
    if (busy) return
    commandError = ""
    action.command = args
    action.running = true
  }

  // This only observes a local file written by the on-demand service. Opening
  // the popup, booting, or reloading the shell never starts a VPN process.
  FileView {
    id: statusFile
    path: Quickshell.env("XDG_RUNTIME_DIR") + "/vpnctl/status.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { vpn.state = JSON.parse(text()) }
      catch (e) { vpn.commandError = "Could not read local VPN state." }
    }
    onLoadFailed: vpn.state = ({enabled: false, phase: "off"})
  }

  // vpnctl publishes with an atomic rename. A QFileSystemWatcher can stop
  // following the path when that swaps the inode, leaving one screen stale.
  // Retrying the local read keeps every per-screen service converged.
  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: statusFile.reload()
  }

  Process {
    id: action
    stderr: StdioCollector { id: actionError }
    onExited: function(code) {
      if (code !== 0) vpn.commandError = actionError.text.trim() || "VPN command failed."
      statusFile.reload()
    }
  }
}
