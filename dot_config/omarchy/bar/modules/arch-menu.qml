import QtQuick
import qs.Ui

WidgetButton {
  id: root

  property string moduleName: ""
  property var settings: ({})

  text: "\uf303"
  fontFamily: bar ? bar.fontFamily : "monospace"
  horizontalMargin: 7.5

  onPressed: function(button) {
    if (!bar) return
    if (button === Qt.RightButton) bar.run("xdg-terminal-exec")
    else bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
  }
}
