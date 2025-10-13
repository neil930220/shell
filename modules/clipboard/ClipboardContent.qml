import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick

Item {
    id: root

    implicitWidth: 500
    implicitHeight: 700

    // Close on escape
    Keys.onEscapePressed: {
        console.log("[Clipboard] Escape pressed; closing and resetting filters")
        Clipboard.resetFilters();
        Clipboard.visible = false;
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F5) {
            console.log("[Clipboard] F5 pressed; refreshing clipboard")
            Clipboard.refreshClipboard();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            console.log("[Clipboard] PageUp pressed; previous page")
            Clipboard.previousPage();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            console.log("[Clipboard] PageDown pressed; next page")
            Clipboard.nextPage();
            event.accepted = true;
        }
    }

    StyledClippingRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surface
        radius: Appearance.rounding.normal

        Behavior on color {
            CAnim {}
        }

        Item {
            anchors.fill: parent
            anchors.margins: Appearance.padding.large

            Column {
                anchors.fill: parent
                spacing: Appearance.spacing.normal

                Header {
                    id: header
                    width: parent.width
                }

                ResultsList {
                    id: resultsList
                    width: parent.width
                    height: parent.height - header.height - pagination.height - parent.spacing * 2
                }

                PaginationControls {
                    id: pagination
                    width: parent.width
                }
            }
        }
    }

    Component.onCompleted: {
        // Initial load
        console.log("[Clipboard] Component completed; itemsCount=" + Clipboard.clipboardItems.length)
        if (Clipboard.clipboardItems.length === 0) {
            console.log("[Clipboard] Initial refresh due to empty items")
            Clipboard.refreshClipboard();
        }
    }
}

