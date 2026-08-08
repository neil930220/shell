import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var item

    implicitWidth: parent?.width ?? 0
    implicitHeight: contentRow.implicitHeight + Tokens.padding.medium * 2
    color: Colours.tPalette.m3surfaceContainerLow
    radius: Tokens.rounding.medium

    Row {
        id: contentRow

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Index badge
        StyledRect {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 40
            implicitHeight: 32
            color: Colours.palette.m3secondaryContainer
            radius: Tokens.rounding.small

            StyledText {
                anchors.centerIn: parent
                text: root.item.index.toString()
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.label.small
                font.weight: 600
            }
        }

        // Content area
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40 - removeBtn.width - parent.spacing * 2
            implicitHeight: root.item.type === "image" && root.item.imagePath ? imagePreview.implicitHeight : textContent.implicitHeight

            // Text content
            Column {
                id: textContent

                visible: root.item.type !== "image" || !root.item.imagePath
                anchors.fill: parent
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    width: parent.width
                    text: root.item.preview
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.medium
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }

                StyledText {
                    text: root.item.type + " • " + root.item.text.length + " chars"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }

            // Image preview
            StyledRect {
                id: imagePreview

                visible: root.item.type === "image" && root.item.imagePath
                anchors.fill: parent
                implicitHeight: 120
                color: Colours.tPalette.m3surfaceContainerHighest
                radius: Tokens.rounding.small
                clip: true

                Image {
                    anchors.centerIn: parent
                    width: Math.min(sourceSize.width, parent.width)
                    height: Math.min(sourceSize.height, parent.height)
                    source: root.item.imagePath ? ("file://" + root.item.imagePath) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }

                StyledText {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: Tokens.padding.small
                    text: "Image"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Remove button
        IconButton {
            id: removeBtn

            anchors.verticalCenter: parent.verticalCenter
            icon: "delete"
            label.color: Colours.palette.m3error
            ToolTip.visible: stateLayer.containsMouse
            ToolTip.text: qsTr("Remove")

            onClicked: Clipboard.removeItem(root.item)
        }
    }

    StateLayer {
        function onClicked() {
            Clipboard.selectItem(root.item);
        }

        color: Colours.palette.m3onSurface
    }
}
