import QtQuick
import Quickshell
import Quickshell.Io

// One Service exists per screen's bar widget, but only one `speak ... --follow`
// process may run. Every instance launches follow.sh under `flock`: the
// instance that wins the lock runs the follower and mirrors each pushed line
// into a state file; the others block on the lock (no polling, no processes)
// and take over if the leader goes away. Everyone reads state from the file.
Item {
  id: speak
  readonly property string bin: "speak"
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
  readonly property string stateFile: runtimeDir + "/elias.speak.state.json"
  property string state: "off"
  property real speed: 1.0
  property string voice: ""
  property int queued: 0
  property string current: ""
  readonly property bool playing: state === "playing"
  readonly property bool paused: state === "paused"
  readonly property bool connected: state !== "off"

  function toggle() { run("toggle") }
  function faster() { run("faster") }
  function slower() { run("slower") }
  function stop() { run("stop") }
  function run(verb) {
    action.command = [bin, verb]
    action.running = true
  }

  function apply(line) {
    var s
    try { s = JSON.parse(line) } catch (e) { return }
    state = s.state || "off"
    speed = s.speed !== undefined ? s.speed : 1.0
    voice = s.voice || ""
    queued = s.queued || 0
    current = s.current || ""
  }

  FileView {
    id: stateView
    path: speak.stateFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: speak.apply(text())
  }

  Process {
    id: follow
    command: ["flock", speak.runtimeDir + "/elias.speak.lock", Qt.resolvedUrl("follow.sh").toString().replace("file://", "")]
    running: true
    stdout: SplitParser { onRead: function(line) { speak.apply(line) } }
    onExited: restart.restart()
  }
  Timer {
    id: restart
    interval: 3000
    onTriggered: follow.running = true
  }

  Process { id: action }
}
