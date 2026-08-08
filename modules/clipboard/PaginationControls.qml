import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    visible: Clipboard.totalPages > 1
    height: visible ? implicitHeight : 0
    implicitHeight: Math.max(prevButton.implicitHeight, pageIndicator.implicitHeight, nextButton.implicitHeight)

    Behavior on height {
        Anim {}
    }

    IconButton {
        id: prevButton

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        enabled: Clipboard.currentPage > 0
        icon: "chevron_left"
        label.color: enabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        ToolTip.visible: hovered
        ToolTip.text: qsTr("Previous page (Page Up)")

        onClicked: Clipboard.previousPage()
    }

    StyledRect {
        id: pageIndicator

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: pageText.implicitWidth + Tokens.padding.large * 2
        implicitHeight: pageText.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.small

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            StyledText {
                id: pageText

                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Page %1 of %2").arg(Clipboard.currentPage + 1).arg(Clipboard.totalPages)
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.medium
                font.weight: 500
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "(" + Clipboard.filteredItems.length + " items)"
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }
        }
    }

    IconButton {
        id: nextButton

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        enabled: Clipboard.currentPage < Clipboard.totalPages - 1
        icon: "chevron_right"
        label.color: enabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        ToolTip.visible: hovered
        ToolTip.text: qsTr("Next page (Page Down)")

        onClicked: Clipboard.nextPage()
    }
}
