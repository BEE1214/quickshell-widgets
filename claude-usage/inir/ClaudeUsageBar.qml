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
    readonly property color warnColor: Appearance.inirEverywhere ? Appearance.inir.colError : Appearance.colors.colError

    function levelColor(pct) {
        return pct >= 90 ? warnColor : textColor
    }

    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: ClaudeUsage.refresh()

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            fill: 0
            text: ClaudeUsage.error !== "" ? "error" : "data_usage"
            iconSize: Appearance.font.pixelSize.large
            color: ClaudeUsage.error !== "" ? root.warnColor : root.levelColor(ClaudeUsage.peak)
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.levelColor(ClaudeUsage.peak)
            text: !ClaudeUsage.loaded || ClaudeUsage.error !== "" || !ClaudeUsage.session ? "--"
                : Math.round(ClaudeUsage.session.utilization) + "%"
                    + (ClaudeUsage.weekly ? " · " + Math.round(ClaudeUsage.weekly.utilization) + "%" : "")
        }
        MaterialSymbol {
            fill: ClaudeUsage.busyCount > 0 ? 1 : 0
            text: "terminal"
            iconSize: Appearance.font.pixelSize.large
            color: ClaudeUsage.busyCount > 0 ? Appearance.colors.colPrimary : root.textColor
            opacity: ClaudeUsage.busyCount > 0 ? 1 : 0.5
            Layout.leftMargin: 4
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: ClaudeUsage.busyCount > 0 ? Appearance.colors.colPrimary : root.textColor
            opacity: ClaudeUsage.busyCount > 0 ? 1 : 0.5
            text: ClaudeUsage.busyCount
        }
    }

    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            anchors.centerIn: parent
            implicitWidth: 260
            spacing: 8

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Claude usage")
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.normal }
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                visible: ClaudeUsage.error !== ""
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: ClaudeUsage.error
                color: Appearance.colors.colError
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            Repeater {
                model: ClaudeUsage.windows
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            text: Math.round(modelData.utilization) + "%"
                            font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.smaller }
                            color: modelData.utilization >= 90 ? Appearance.colors.colError : Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Appearance.colors.colLayer2
                        Rectangle {
                            width: parent.width * Math.min(modelData.utilization, 100) / 100
                            height: parent.height
                            radius: 3
                            color: modelData.utilization >= 90 ? Appearance.colors.colError : Appearance.colors.colPrimary
                        }
                    }
                    StyledText {
                        text: Translation.tr("Resets in %1").arg(ClaudeUsage.resetText(modelData.resets_at))
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            StyledText {
                Layout.topMargin: 4
                text: ClaudeUsage.busyCount > 0 ? Translation.tr("Active subagents · %1").arg(ClaudeUsage.busyCount)
                    : Translation.tr("No active subagents")
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.smaller }
                color: Appearance.colors.colOnSurfaceVariant
            }
            Repeater {
                model: ClaudeUsage.agents
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 1
                    RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: modelData.status === "busy" ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                        Layout.alignment: Qt.AlignVCenter
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: modelData.parent
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: ClaudeUsage.durationText(modelData.uptime_s)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                    }
                    StyledText {
                        visible: text !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        elide: Text.ElideRight
                        text: modelData.brief !== "" ? modelData.brief : modelData.task
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
