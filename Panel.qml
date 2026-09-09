import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Momovox bar widget: hear text instead of reading it.
//
// The bar entry shows "Vox" (plus ▶ while audio plays). Left click opens a
// small panel with Play clipboard / Stop / Replay last; right click plays
// the clipboard immediately. Voice and speed come from the plugin settings
// (empty = saved `momovox --select-voice` default). All work happens in
// bin/*.sh helpers so QML never blocks: play/replay detach, stop/status
// return instantly. State is polled every 2s via `momovox --status`.
Panel {
  id: root

  moduleName: "joisephdev.momovox"
  ipcTarget: "joisephdev.momovox"

  // Same readability rule as other widgets: popup content must not use the
  // animated barForeground (dark-on-dark when the bar goes transparent).
  readonly property color foreground: Color.popups.text
  readonly property color dim: Util.alpha(Color.popups.text, 0.62)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string pluginDir: (Quickshell.env("HOME") || "")
    + "/.config/omarchy/plugins/joisephdev.momovox"
  readonly property string voice: String(root.setting("voice", "")).trim()
  readonly property string speed: String(root.setting("speed", "")).trim()

  property bool speaking: false
  property bool busy: false
  property string lastError: ""

  readonly property string stateText: root.speaking ? "Speaking" : "Idle"
  readonly property string voiceText: root.voice !== "" ? root.voice : "default"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---- actions -------------------------------------------------------------

  function refreshStatus() {
    if (statusProcess.running) return
    statusProcess.command = [root.pluginDir + "/bin/status.sh"]
    statusProcess.running = true
  }

  function runHelper(id, script, args) {
    if (root.busy) return
    root.busy = true
    root.lastError = ""
    helperProcess.command = [root.pluginDir + "/bin/" + script].concat(args || [])
    helperProcess.running = true
    helperDeadline.restart()
    helperProcess.setProperty("tag", id)
  }

  function playClipboard() {
    var args = []
    if (root.voice !== "") args.push(root.voice)
    else if (root.speed !== "") args.push("") // keep position: [voice] [speed]
    if (root.speed !== "") args.push(root.speed)
    root.runHelper("play", "play-clipboard.sh", args)
  }

  function stopPlayback() {
    root.runHelper("stop", "stop.sh", [])
  }

  function replayLast() {
    root.runHelper("replay", "replay-last.sh", [])
  }

  function finishHelper(ok, tag) {
    helperDeadline.stop()
    root.busy = false
    if (!ok && root.lastError === "") {
      if (tag === "replay") root.lastError = "Nothing to replay yet"
      else if (tag === "play") root.lastError = "Clipboard is empty or voice failed (see widget.log)"
      else root.lastError = "Action failed"
    }
    Qt.callLater(root.refreshStatus)
  }

  onOpenedChanged: if (opened) {
    root.lastError = ""
    root.refreshStatus()
  }

  Component.onCompleted: root.refreshStatus()

  Timer {
    id: statusTimer
    interval: 2000
    repeat: true
    running: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: helperDeadline
    interval: 10000
    repeat: false
    onTriggered: {
      if (helperProcess.running) {
        helperProcess.running = false
        root.busy = false
        if (root.lastError === "") root.lastError = "Action timed out"
      }
    }
  }

  Process {
    id: statusProcess
    command: []
    running: false

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.speaking = String(text || "").trim() === "playing"
      }
    }
  }

  Process {
    id: helperProcess
    command: []
    running: false
    property string tag: ""

    stdout: StdioCollector {
      waitForEnd: true
    }

    onExited: function(exitCode) {
      var tag = helperProcess.tag
      helperProcess.tag = ""
      if (exitCode !== 0) console.warn(root.moduleName + ": helper exited", exitCode)
      root.finishHelper(exitCode === 0, tag)
    }
  }

  // ---- bar entry -----------------------------------------------------------

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.speaking ? "Vox ▶" : "Vox"
    fontSize: Style.font.bodySmall
    horizontalMargin: 6.5
    tooltipText: "Momovox (" + root.stateText + ", voice: " + root.voiceText + ") — click for controls, right-click plays clipboard"

    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        root.playClipboard()
      } else {
        root.toggle()
      }
    }
  }

  // ---- control panel ---------------------------------------------------------

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: playButton
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight, Style.space(400))

    PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.spacing.md

        Text {
          width: parent.width
          text: "Momovox · " + root.stateText
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Text {
          width: parent.width
          text: "Voice: " + root.voiceText + (root.speed !== "" ? " · " + root.speed : "")
          textFormat: Text.PlainText
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Button {
          id: playButton
          width: parent.width
          text: root.busy ? "Working…" : "▶  Play clipboard"
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          bordered: true
          focusable: true
          enabled: !root.busy
          onClicked: root.playClipboard()
        }

        Button {
          width: parent.width
          text: "■  Stop"
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          bordered: true
          focusable: true
          enabled: !root.busy && root.speaking
          onClicked: root.stopPlayback()
        }

        Button {
          width: parent.width
          text: "↻  Replay last"
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.bodySmall
          bordered: true
          focusable: true
          enabled: !root.busy
          onClicked: root.replayLast()
        }

        Text {
          width: parent.width
          visible: root.lastError !== ""
          text: root.lastError
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.bar ? root.bar.urgent : Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          width: parent.width
          text: "Change the default voice any time: momovox --select-voice"
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
