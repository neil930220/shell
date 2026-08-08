import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    StyledFlickable {
        anchors.fill: parent
        contentHeight: content.height
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: parent
        }

        Column {
            id: content

            width: parent.width
            spacing: Tokens.spacing.small

            // Empty state
            Item {
                visible: Clipboard.paginatedItems.length === 0
                width: parent.width
                height: 300

                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "content_paste_off"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.size(Tokens.font.icon.extraLarge.pointSize * 2).build()
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clipboard.filterText || Clipboard.filterType !== "all" ? qsTr("No matching clipboard items") : qsTr("No clipboard history")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.title.medium
                        font.weight: 500
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Clipboard.filterText || Clipboard.filterType !== "all" ? qsTr("Try adjusting your filters") : qsTr("Copy something to get started")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                    }
                }
            }

            // Clipboard items
            Repeater {
                model: ScriptModel {
                    values: Clipboard.paginatedItems
                }

                ClipboardItemButton {
                    required property var modelData

                    item: modelData
                    width: parent.width
                }
            }
        }
    }
}
