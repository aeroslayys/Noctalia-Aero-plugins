// DesktopWidget.qml — SyncTodo desktop widget
// Draggable, scalable todo list on the Noctalia desktop.
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
    id: root

    property var pluginApi: null

    // ── Widget size ───────────────────────────────────────────────────────────
    implicitWidth: 280
    implicitHeight: contentCol.implicitHeight + Style.marginL * 2
    width: implicitWidth * widgetScale
    height: implicitHeight * widgetScale

    // ── Settings ──────────────────────────────────────────────────────────────
    property int maxItems: pluginApi?.pluginSettings?.maxItems ?? 5
    property bool showDone: pluginApi?.pluginSettings?.showDone ?? false

    property string cachePath: {
        var custom = pluginApi?.pluginSettings?.cachePath || ""
        if (custom !== "") return custom
        return StandardPaths.writableLocation(StandardPaths.HomeLocation)
            + "/.local/share/synctodo/todos.json"
    }

    // ── State ─────────────────────────────────────────────────────────────────
    property var todos: []
    property bool loaded: false

    // ── Content ───────────────────────────────────────────────────────────────
    ColumnLayout {
        id: contentCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.marginL
        }
        spacing: Style.marginS

        // Header row
        RowLayout {
            Layout.fillWidth: true

            NText {
                text: "SyncTodo"
                pointSize: Style.fontSizeM
                font.weight: Font.Bold
                color: Color.mOnSurface
                Layout.fillWidth: true
            }

            NText {
                text: {
                    var pending = root.todos.filter(function(t) { return !t.done }).length
                    return pending + "/" + root.todos.length
                }
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.mOutlineVariant
            opacity: 0.4
        }

        // Todo list
        Repeater {
            id: todoRepeater
            model: {
                var filtered = root.showDone
                    ? root.todos
                    : root.todos.filter(function(t) { return !t.done })
                // Sort: undone first, high priority first
                var order = { high: 0, normal: 1, low: 2 }
                filtered.sort(function(a, b) {
                    if (a.done !== b.done) return a.done ? 1 : -1
                    return (order[a.priority] || 1) - (order[b.priority] || 1)
                })
                return filtered.slice(0, root.maxItems)
            }

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                // Priority dot
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: {
                        var p = modelData.priority || "normal"
                        if (p === "high")   return Color.mError
                        if (p === "low")    return Color.mSuccess
                        return Color.mPrimary
                    }
                    opacity: modelData.done ? 0.3 : 1.0
                }

                NText {
                    text: modelData.title
                    pointSize: Style.fontSizeS
                    color: modelData.done ? Color.mOnSurfaceVariant : Color.mOnSurface
                    font.strikeout: modelData.done
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Done checkmark
                NText {
                    text: "✓"
                    pointSize: Style.fontSizeS
                    color: Color.mSuccess
                    visible: modelData.done
                }
            }
        }

        // Empty / loading state
        NText {
            visible: root.loaded && root.todos.filter(function(t) { return !t.done }).length === 0
            text: "✓  All caught up!"
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }

        NText {
            visible: !root.loaded
            text: "Loading..."
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // ── File reading ──────────────────────────────────────────────────────────
    Process {
        id: catProcess
        command: ["cat", root.cachePath]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    root.todos = JSON.parse(catProcess.stdout)
                    root.loaded = true
                } catch(e) {
                    root.todos = []
                    root.loaded = true
                }
            }
        }
    }

    Timer {
        interval: 15000   // refresh every 15 s
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: catProcess.start()
    }

    Component.onCompleted: {
        Logger.i("SyncTodo", "Desktop widget loaded")
    }
}
