import qs.components
import qs.config
import qs.components.controls
import qs.services
import Quickshell
import QtQuick
import QtQuick.Controls

Item {
    id: root

    visible: Clipboard.totalPages > 1
    height: visible ? implicitHeight : 0

    implicitHeight: Math.max(prevButton.implicitHeight, pageIndicator.implicitHeight, nextButton.implicitHeight)

    IconButton {
        id: prevButton
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        enabled: Clipboard.currentPage > 0

        icon: "chevron_left"
        label.color: enabled ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant

        onClicked: Clipboard.previousPage()

        ToolTip.visible: hovered
        ToolTip.text: qsTr("Previous page (Page Up)")
    }

    StyledRect {
        id: pageIndicator
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: pageText.implicitWidth + Appearance.padding.large * 2
        implicitHeight: pageText.implicitHeight + Appearance.padding.normal * 2

        radius: Appearance.rounding.small

        Row {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            StyledText {
                id: pageText
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Page %1 of %2").arg(Clipboard.currentPage + 1).arg(Clipboard.totalPages)
                color: Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "(" + Clipboard.filteredItems.length + " items)"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
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

        onClicked: Clipboard.nextPage()

        ToolTip.visible: hovered
        ToolTip.text: qsTr("Next page (Page Down)")
    }

    Behavior on height {
        Anim {}
    }
}

