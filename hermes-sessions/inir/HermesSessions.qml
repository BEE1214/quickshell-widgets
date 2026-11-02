pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Hermes sessions and the subagents currently working.
 * Data comes from ~/.config/quickshell/hermes-sessions/hermes-status.py
 * (local files only, read-only).
 */
Singleton {
    id: root

    property var sessions: []
    property var agents: []
    property int working: 0
    property int total: 0

    function refresh() { proc.running = true }

    function durationText(sec) {
        if (sec === null || sec === undefined) return ""
        if (sec < 60) return `${sec}s`
        const m = Math.floor(sec / 60)
        const d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60)
        if (d > 0) return `${d}d ${h}h`
        if (h > 0) return `${h}h ${m % 60}m`
        return `${m}m`
    }

    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.config/quickshell/hermes-sessions/hermes-status.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    root.sessions = r.sessions
                    root.agents = r.agents
                    root.working = r.working
                    root.total = r.total
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
