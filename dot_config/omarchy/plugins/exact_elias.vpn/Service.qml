import QtQuick
import Quickshell.Io

Item {
  id: vpn
  property bool detailsVisible: false
  property var state: ({})
  property string error: ""
  property string notice: ""
  property string pendingProfile: ""
  property double requestedAt: 0
  property string previousUpdate: ""
  property int generation: 0
  property bool refreshQueued: false
  property double now: Date.now()
  readonly property string splitProfile: state.profiles ? state.profiles.split : ""
  readonly property string fullProfile: state.profiles ? state.profiles.full : ""
  readonly property bool full: fullProfile !== "" && state.connected === fullProfile
  readonly property bool known: typeof state.connected === "string"
  readonly property bool stale: !known || !isFinite(Date.parse(state.updated)) || now - Date.parse(state.updated) > 120000
  readonly property bool busy: action.running || pendingProfile !== ""
  readonly property bool available: known && !stale && error === ""
  readonly property bool switching: known && state.desired !== state.connected
  readonly property bool canChange: available && !busy && !switching

  function refresh() {
    if (status.running || action.running) { refreshQueued = true; return }
    refreshQueued = false
    status.generation = generation
    status.running = true
  }

  function request(command, minutes) {
    if (!canChange) return
    if (["split", "full", "renew"].indexOf(command) < 0) return
    if (command !== "split" && (!Number.isInteger(minutes) || minutes < 1 || minutes > 720)) return
    pendingProfile = command === "split" ? splitProfile : fullProfile
    requestedAt = Date.now()
    previousUpdate = state.updated
    generation++
    notice = command === "split" ? "Restoring split tunnel…" : "Requesting " + minutes + " minute lease…"
    error = ""
    // Argument arrays avoid shell interpolation. Bound SSH/authentication hangs,
    // including the expected interruption when the full tunnel takes over.
    action.command = ["timeout", "--kill-after=2s", "25s", "vpnctl", command].concat(command === "split" ? [] : [String(minutes)])
    action.running = true
  }

  Process {
    id: status
    property int generation: 0
    command: ["timeout", "--kill-after=2s", "20s", "vpnctl", "snapshot"]
    stdout: StdioCollector { id: statusOut }
    stderr: StdioCollector { id: statusErr }
    onExited: function(code) {
      // Discard reads started before the command. They can arrive after the
      // write and otherwise replace the UI with an obsolete profile.
      if (generation !== vpn.generation) {
        Qt.callLater(vpn.refresh)
        return
      }
      if (vpn.refreshQueued) Qt.callLater(vpn.refresh)
      if (code !== 0) {
        error = code === 124 || code === 137 ? "VPN laptop did not respond. Retrying…" : (statusErr.text.trim() || "Could not read VPN status.")
        return
      }
      try {
        var next = JSON.parse(statusOut.text.replace(/^\uFEFF/, "").trim())
        if (!next || typeof next.connected !== "string" || !isFinite(Date.parse(next.updated))) throw new Error("Invalid agent status")
        if (!next.profiles || typeof next.profiles.split !== "string" || !next.profiles.split || typeof next.profiles.full !== "string" || !next.profiles.full || next.profiles.split === next.profiles.full) throw new Error("Invalid profiles")
        state = next
        now = Date.now()
        error = ""
        // Compare two agent timestamps, not clocks on different machines.
        if (!action.running && pendingProfile !== "" && next.connected === pendingProfile && next.desired === pendingProfile && next.updated !== previousUpdate) {
          pendingProfile = ""
          notice = ""
        }
      } catch (e) {
        error = "Could not parse VPN agent status."
      }
    }
  }

  Process {
    id: action
    stdout: StdioCollector { id: actionOut }
    stderr: StdioCollector {}
    onExited: function(code) {
      if (code !== 0) {
        // A dropped connection does not establish whether the write reached
        // the agent. Keep polling for confirmation instead of claiming failure.
        notice = "Connection interrupted; checking whether the profile changed…"
      } else {
        notice = "Waiting for the VPN laptop…"
      }
      vpn.refresh()
    }
  }

  Timer {
    interval: vpn.detailsVisible || vpn.pendingProfile !== "" ? 5000 : 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      vpn.now = Date.now()
      if (vpn.pendingProfile !== "" && vpn.now - vpn.requestedAt > 90000) {
        vpn.pendingProfile = ""
        vpn.notice = "Could not confirm the request. Check the current profile before retrying."
      }
      vpn.refresh()
    }
  }
}
