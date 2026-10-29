pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    readonly property color textColor: Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
    readonly property bool active: OllamaUsage.models.length > 0

    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: OllamaUsage.refresh()

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        opacity: OllamaUsage.online ? 1 : 0.5

        MaterialSymbol {
            fill: root.active ? 1 : 0
            text: "smart_toy"
            iconSize: Appearance.font.pixelSize.large
            color: root.textColor
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.textColor
            text: !OllamaUsage.online ? "off"
                : root.active ? OllamaUsage.formatBytes(OllamaUsage.totalBytes)
                : "idle"
        }
    }

    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            anchors.centerIn: parent
            implicitWidth: 230
            spacing: 8

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Ollama")
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.normal }
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                visible: !OllamaUsage.online || !root.active
                Layout.alignment: Qt.AlignHCenter
                text: OllamaUsage.online ? Translation.tr("No models loaded") : Translation.tr("Server not running")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            Repeater {
                model: OllamaUsage.models
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData.name
                            font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.smaller }
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            text: OllamaUsage.formatBytes(modelData.size)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    StyledText {
                        text: Translation.tr("%1% on GPU · unloads in %2")
                            .arg(modelData.size > 0 ? Math.round(100 * modelData.size_vram / modelData.size) : 0)
                            .arg(OllamaUsage.unloadText(modelData.expires_at))
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
