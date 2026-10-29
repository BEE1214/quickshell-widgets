//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Floating Claude usage card. Run with: qs -c claude-usage
ShellRoot {
    id: root

    property var windows: []
    property string error: ""
    property bool loaded: false

    function barColor(pct) {
        return pct >= 90 ? "#f38ba8" : pct >= 70 ? "#f9e2af" : "#a6e3a1";
    }

    function resetText(iso) {
        if (!iso) return "";
        const ms = new Date(iso).getTime() - Date.now();
        if (ms <= 0) return "resets now";
        const m = Math.floor(ms / 60000);
        const d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60);
        if (d > 0) return `resets in ${d}d ${h}h`;
        if (h > 0) return `resets in ${h}h ${m % 60}m`;
        return `resets in ${m}m`;
    }

    Process {
        id: fetcher
        command: [Quickshell.env("HOME") + "/.config/quickshell/claude-usage/fetch-usage.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.windows = r.windows;
                    root.error = r.ok ? "" : r.error;
                } catch (e) {
                    root.error = "Bad response from fetch script";
                }
                root.loaded = true;
            }
        }
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetcher.running = true
    }

    PanelWindow {
        id: panel
        anchors { top: true; right: true }
        margins { top: 12; right: 12 }
        implicitWidth: 260
        implicitHeight: col.implicitHeight + 24
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "claude-usage"

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#e61e1e2e"
            border.color: "#45475a"
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: fetcher.running = true
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                Text {
                    text: "Claude usage"
                    color: "#cdd6f4"
                    font { pixelSize: 13; bold: true }
                }

                Text {
                    visible: root.error !== ""
                    Layout.fillWidth: true
                    text: root.error
                    color: "#f38ba8"
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                }

                Text {
                    visible: !root.loaded
                    text: "Loading…"
                    color: "#a6adc8"
                    font.pixelSize: 11
                }

                Repeater {
                    model: root.windows
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.label
                                color: "#cdd6f4"
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                            Text {
                                text: Math.round(modelData.utilization) + "%"
                                color: root.barColor(modelData.utilization)
                                font { pixelSize: 11; bold: true }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: "#313244"
                            Rectangle {
                                width: parent.width * Math.min(modelData.utilization, 100) / 100
                                height: parent.height
                                radius: 3
                                color: root.barColor(modelData.utilization)
                            }
                        }
                        Text {
                            text: root.resetText(modelData.resets_at)
                            color: "#7f849c"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
