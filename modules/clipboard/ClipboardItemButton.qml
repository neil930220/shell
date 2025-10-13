import qs.components
import qs.config
import qs.components.controls
import qs.services
import Quickshell
import QtQuick
import QtQuick.Controls

StyledRect {
    id: root

    required property var item

    implicitWidth: parent?.width ?? 0
    implicitHeight: contentRow.implicitHeight + Appearance.padding.normal * 2

    color: Colours.tPalette.m3surfaceContainerLow
    radius: Appearance.rounding.normal

    Row {
        id: contentRow
        anchors.fill: parent
        anchors.margins: Appearance.padding.normal
        spacing: Appearance.spacing.normal

        // Index badge
        StyledRect {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 40
            implicitHeight: 32
            
            color: Colours.palette.m3secondaryContainer
            radius: Appearance.rounding.small

            StyledText {
                anchors.centerIn: parent
                text: root.item.index.toString()
                color: Colours.palette.m3onSecondaryContainer
                font.pointSize: Appearance.font.size.small
                font.weight: 600
            }
        }

        // Content area
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40 - removeBtn.width - parent.spacing * 2
            implicitHeight: root.item.type === "image" && root.item.imagePath 
                ? imagePreview.implicitHeight 
                : textContent.implicitHeight

            // Text content
            Column {
                id: textContent
                visible: root.item.type !== "image" || !root.item.imagePath
                anchors.fill: parent
                spacing: Appearance.spacing.tiny

                StyledText {
                    width: parent.width
                    text: root.item.preview
                    color: Colours.palette.m3onSurface
                    font.pointSize: Appearance.font.size.normal
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }

                StyledText {
                    text: root.item.type + " • " + root.item.text.length + " chars"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                }
            }

            // Image preview
            StyledRect {
                id: imagePreview
                visible: root.item.type === "image" && root.item.imagePath
                anchors.fill: parent
                
                implicitHeight: 120
                color: Colours.tPalette.m3surfaceContainerHighest
                radius: Appearance.rounding.small
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
                    anchors.margins: Appearance.padding.small
                    
                    text: "Image"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.small
                }
            }
        }

        // Remove button
        IconButton {
            id: removeBtn
            anchors.verticalCenter: parent.verticalCenter
            
            icon: "delete"
            label.color: Colours.palette.m3error
            
            onClicked: Clipboard.removeItem(root.item)
            
            ToolTip.visible: stateLayer.containsMouse
            ToolTip.text: qsTr("Remove")
        }
    }

    StateLayer {
        color: Colours.palette.m3onSurface
        
        function onClicked() {
            Clipboard.selectItem(root.item);
        }
    }
}

