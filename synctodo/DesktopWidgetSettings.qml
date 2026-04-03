// DesktopWidgetSettings.qml — SyncTodo widget settings import QtQuick import QtQuick.Layouts import qs.Commons import qs.Widgets
ColumnLayout { id: root property var pluginApi: null property var widgetData: null spacing: Style.marginM
// Max items slider
RowLayout {
    Layout.fillWidth: true
    NText {
        text: "Max items shown"
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        Layout.fillWidth: true
    }
    NText {
        text: maxSlider.value.toString()
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        font.weight: Font.Bold
    }
}
Slider {
    id: maxSlider
    Layout.fillWidth: true
    from: 1; to: 10; stepSize: 1
    value: pluginApi?.pluginSettings?.maxItems ?? 5
    onValueChanged: {
        if (pluginApi) {
            pluginApi.pluginSettings.maxItems = value
            pluginApi.saveSettings()
        }
    }
}

// Show completed toggle
RowLayout {
    Layout.fillWidth: true
    NText {
        text: "Show completed tasks"
        color: Color.mOnSurface
        pointSize: Style.fontSizeS
        Layout.fillWidth: true
    }
    NSwitch {
        id: showDoneSwitch
        checked: pluginApi?.pluginSettings?.showDone ?? false
        onCheckedChanged: {
            if (pluginApi) {
                pluginApi.pluginSettings.showDone = checked
                pluginApi.saveSettings()
            }
        }
    }
}

// Custom cache path
NText {
    text: "Custom cache path (optional)"
    color: Color.mOnSurface
    pointSize: Style.fontSizeS
}
NTextInput {
    Layout.fillWidth: true
    placeholderText: "~/.local/share/synctodo/todos.json"
    text: pluginApi?.pluginSettings?.cachePath ?? ""
    onEditingFinished: {
        if (pluginApi) {
            pluginApi.pluginSettings.cachePath = text
            pluginApi.saveSettings()
        }
    }
}
}
