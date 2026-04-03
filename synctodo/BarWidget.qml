// BarWidget.qml — SyncTodo bar indicator
// Shows pending todo count. Click to refresh.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    // ── Plugin API (injected by PluginService) ────────────────────────────────
    property var pluginApi: null

    // ── Required bar widget properties ────────────────────────────────────────
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    // ── State ─────────────────────────────────────────────────────────────────
    property int pendingCount: 0
    property bool loaded: false

    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight
    color: Style.capsuleColor
    radius: Style.radiusM

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
            icon: "check_circle"
            color: root.pendingCount > 0 ? Color.mPrimary : Color.mOnSurfaceVariant
        }

        NText {
            text: root.loaded
                ? (root.pendingCount > 0 ? root.pendingCount + " todo" + (root.pendingCount > 1 ? "s" : "") : "All done ✓")
                : "..."
            color: root.pendingCount > 0 ? Color.mOnSurface : Color.mOnSurfaceVariant
            pointSize: Style.fontSizeS
        }
    }

    // ── Click to refresh ──────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: refreshTimer.restart()
    }

    // ── File reading via Process ──────────────────────────────────────────────
    property string cachePath: {
        var custom = pluginApi?.pluginSettings?.cachePath || ""
        if (custom !== "") return custom
        return StandardPaths.writableLocation(StandardPaths.HomeLocation)
            + "/.local/share/synctodo/todos.json"
    }

    Process {
        id: catProcess
        command: ["cat", root.cachePath]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    var todos = JSON.parse(catProcess.stdout)
                    root.pendingCount = todos.filter(function(t) { return !t.done }).length
                    root.loaded = true
                } catch(e) {
                    root.pendingCount = 0
                    root.loaded = true
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 30000   // poll every 30 s
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: catProcess.start()
    }

    Component.onCompleted: {
        Logger.i("SyncTodo", "Bar widget loaded, cache:", root.cachePath)
    }
}
