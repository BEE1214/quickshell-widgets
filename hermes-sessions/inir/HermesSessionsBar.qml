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
    readonly property bool busy: HermesSessions.working > 0

    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: HermesSessions.refresh()

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            fill: root.busy ? 1 : 0
            text: "hub"
            iconSize: Appearance.font.pixelSize.large
            color: root.busy ? Appearance.colors.colPrimary : root.textColor
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.textColor
            text: HermesSessions.total
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.busy ? Appearance.colors.colPrimary : root.textColor
            opacity: root.busy ? 1 : 0.5
            text: "· " + HermesSessions.working
        }
    }

    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            anchors.centerIn: parent
            implicitWidth: 300
            spacing: 6

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Hermes")
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.normal }
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: Translation.tr("Sessions · %1").arg(HermesSessions.total)
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.smaller }
                color: Appearance.colors.colOnSurfaceVariant
            }
            Repeater {
                model: HermesSessions.sessions
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
                            readonly property bool recent: modelData.idle_s !== null && modelData.idle_s < 120
                            color: recent ? Appearance.colors.colPrimary : "transparent"
                            border.width: recent ? 0 : 1
                            border.color: Appearance.colors.colOutline
                            Layout.alignment: Qt.AlignVCenter
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: modelData.title
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            text: modelData.kind + " · " + modelData.profile
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: modelData.idle_s !== null ? HermesSessions.durationText(modelData.idle_s)
                                : HermesSessions.durationText(modelData.age_s)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                    StyledText {
                        visible: text !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        elide: Text.ElideRight
                        text: modelData.activity
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            StyledText {
                Layout.topMargin: 4
                text: HermesSessions.working > 0 ? Translation.tr("Subagents working · %1").arg(HermesSessions.working)
                    : Translation.tr("No subagents working")
                font { weight: Font.Medium; pixelSize: Appearance.font.pixelSize.smaller }
                color: Appearance.colors.colOnSurfaceVariant
            }
            Repeater {
                model: HermesSessions.agents
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
                            color: Appearance.colors.colPrimary
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
                            text: modelData.source
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: HermesSessions.durationText(modelData.age_s)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                        }
                    }
                    StyledText {
                        visible: text !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        elide: Text.ElideRight
                        text: modelData.detail
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
