pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.common

/**
 * Ollama server status: loaded models and their memory use (/api/ps).
 * Server URL comes from bar.ollama.host (default: local server).
 */
Singleton {
    id: root

    readonly property string host: Config.options?.bar?.ollama?.host ?? "http://127.0.0.1:11434"

    property bool online: false
    property var models: []

    readonly property real totalBytes: models.reduce((s, m) => s + (m.size ?? 0), 0)
    readonly property real vramBytes: models.reduce((s, m) => s + (m.size_vram ?? 0), 0)

    function refresh() {
        const xhr = new XMLHttpRequest()
        xhr.timeout = 2000
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    root.models = JSON.parse(xhr.responseText).models ?? []
                    root.online = true
                    return
                } catch (e) {}
            }
            root.models = []
            root.online = false
        }
        xhr.open("GET", root.host + "/api/ps")
        xhr.send()
    }

    function formatBytes(b) {
        return b >= 1073741824 ? (b / 1073741824).toFixed(1) + " GB" : Math.round(b / 1048576) + " MB"
    }

    function unloadText(iso) {
        if (!iso) return ""
        const ms = new Date(iso).getTime() - Date.now()
        if (ms <= 0) return "now"
        const m = Math.ceil(ms / 60000)
        return m >= 60 ? `${Math.floor(m / 60)}h ${m % 60}m` : `${m}m`
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
