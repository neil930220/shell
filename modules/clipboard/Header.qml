import qs.components
import qs.config
import qs.components.controls
import qs.components.containers
import qs.services
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Controls

Column {
    id: root

    z: typeFilterButton ? 10 : 0


    // Search bar row
    StyledRect {
        width: parent.width
        implicitHeight: Math.max(searchIcon.implicitHeight, searchField.implicitHeight, refreshButton.implicitHeight, clearButton.implicitHeight)
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.small

        Row {
            anchors.fill: parent
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: 0

            // Left side: search components
            MaterialIcon {
                id: searchIcon
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.large
            }

            StyledTextField {
                id: searchField
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - searchIcon.width - buttonsRow.width - parent.spacing * 3 - parent.anchors.leftMargin - parent.anchors.rightMargin

                placeholderText: qsTr("Filter clipboard history...")
                text: Clipboard.filterText

                topPadding: Appearance.padding.larger
                bottomPadding: Appearance.padding.larger

                onTextChanged: {
                    Clipboard.filterText = text;
                    Clipboard.currentPage = 0;
                }

                onAccepted: {
                    if (Clipboard.paginatedItems.length > 0) {
                        Clipboard.selectItem(Clipboard.paginatedItems[0]);
                    }
                }

                Component.onCompleted: forceActiveFocus()
            }

            // Right side: all buttons grouped together
            Row {
                id: buttonsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacing.small

                SplitButton {
                    id: typeFilterButton
                    anchors.verticalCenter: parent.verticalCenter

                    type: SplitButton.Tonal

                    label.elide: Text.ElideRight

                    menuItems: filterItems.instances

                    active: menuItems.find(item => item.value === Clipboard.filterType) ?? menuItems[0]

                    menu.onItemSelected: item => {
                        Clipboard.filterType = item.value;
                        Clipboard.currentPage = 0;
                    }

                    Variants {
                        id: filterItems

                        model: [
                            { label: qsTr("All Types"), value: "all", icon: "filter_list", activeIcon: "filter_list" },
                            { label: qsTr("Text"), value: "text", icon: "text_fields", activeIcon: "text_fields" },
                            { label: qsTr("Multiline"), value: "multiline", icon: "article", activeIcon: "article" },
                            { label: qsTr("Image"), value: "image", icon: "image", activeIcon: "image" },
                            { label: qsTr("HTML"), value: "html", icon: "code", activeIcon: "code" },
                            { label: qsTr("URL"), value: "url", icon: "link", activeIcon: "link" },
                            { label: qsTr("Other"), value: "non-text", icon: "help_outline", activeIcon: "help_outline" }
                        ]

                        MenuItem {
                            required property var modelData

                            // Leading checkmark when selected
                            icon: Clipboard.filterType === modelData.value ? "check" : ""
                            // Button face
                            activeIcon: modelData.activeIcon
                            activeText: modelData.label
                            // Menu row text
                            text: modelData.label
                            // Store the value for use in menu.onItemSelected
                            readonly property string value: modelData.value
                        }
                    }
                }

                IconButton {
                    id: refreshButton
                    anchors.verticalCenter: parent.verticalCenter

                icon: "refresh"
                label.color: Colours.palette.m3onSurfaceVariant

                    onClicked: Clipboard.refreshClipboard()

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Refresh (F5)")
                }

                IconButton {
                    id: clearButton
                    anchors.verticalCenter: parent.verticalCenter

                icon: "delete_sweep"
                label.color: Colours.palette.m3error

                    onClicked: Clipboard.clearHistory()

                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Clear history")
                }
            }
        }
    }
}

