pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Claude subscription usage (5h session / weekly limits).
 * Data comes from ~/.config/quickshell/claude-usage/fetch-usage.py, which
 * reads Claude Code's OAuth token and caches the response for 60 s.
 * Active subagents (busy, not opened in Claude Desktop) come from list-agents.py (local only).
 */
Singleton {
    id: root

    property var windows: []
    property string error: ""
    property bool loaded: false

    readonly property var session: windows.find(w => w.id === "five_hour") ?? null
    readonly property var weekly: windows.find(w => w.id === "seven_day") ?? null
    readonly property real peak: windows.reduce((m, w) => Math.max(m, w.utilization), 0)

    property var agents: []
    property int busyCount: 0
    property int totalAgents: 0

    function refresh() { fetcher.running = true; agentsProc.running = true }

    function durationText(sec) {
        const m = Math.floor(sec / 60)
        const d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60)
        if (d > 0) return `${d}d ${h}h`
        if (h > 0) return `${h}h ${m % 60}m`
        return `${m}m`
    }

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

    Process {
        id: agentsProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/claude-usage/list-agents.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    root.agents = r.agents
                    root.busyCount = r.busy
                    root.totalAgents = r.total
                } catch (e) {}
            }
        }
    }

    // Agents change quickly and the script is local-only, so poll it faster.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: agentsProc.running = true
    }

    Timer {
        interval: 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetcher.running = true
    }
}
