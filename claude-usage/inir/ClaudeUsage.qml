pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Claude subscription usage (5h session / weekly limits).
 * Data comes from ~/.config/quickshell/claude-usage/fetch-usage.py, which
 * reads Claude Code's OAuth token and caches the response for 60 s.
 */
Singleton {
    id: root

    property var windows: []
    property string error: ""
    property bool loaded: false

    readonly property var session: windows.find(w => w.id === "five_hour") ?? null
    readonly property var weekly: windows.find(w => w.id === "seven_day") ?? null
    readonly property real peak: windows.reduce((m, w) => Math.max(m, w.utilization), 0)

    function refresh() { fetcher.running = true }

    function resetText(iso) {
        if (!iso) return ""
        const ms = new Date(iso).getTime() - Date.now()
        if (ms <= 0) return "now"
        const m = Math.floor(ms / 60000)
        const d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60)
        if (d > 0) return `${d}d ${h}h`
        if (h > 0) return `${h}h ${m % 60}m`
        return `${m}m`
    }

    Process {
        id: fetcher
        command: [Quickshell.env("HOME") + "/.config/quickshell/claude-usage/fetch-usage.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    root.windows = r.windows
                    root.error = r.ok ? "" : r.error
                } catch (e) {
                    root.error = "Bad response from fetch script"
                }
                root.loaded = true
            }
        }
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
