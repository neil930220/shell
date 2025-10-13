pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var visibilities

    implicitWidth: parent.width
    implicitHeight: mainColumn.implicitHeight

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Appearance.spacing.smaller

        // Create row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.spacing.small

            StyledTextField {
                id: nameInput
                Layout.preferredWidth: 320
                placeholderText: qsTr("Theme name")
            }

            IconTextButton {
                icon: "add"
                text: qsTr("Create from current")
                onClicked: {
                    console.log("ThemeSwitcher: Create from current clicked", nameInput.text)
                    if (nameInput.text.trim().length === 0)
                        return;
                    Themes.exportCurrent(nameInput.text.trim());
                    nameInput.text = "";
                }
                radius: Appearance.rounding.small
            }

            IconTextButton {
                icon: "layers_clear"
                text: qsTr("Default mode")
                onClicked: Themes.deactivate()
                radius: Appearance.rounding.small
            }
        }

        // Themes list
        StyledFlickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            contentWidth: listRow.implicitWidth
            contentHeight: listRow.implicitHeight
            clip: true
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: listRow
                spacing: Appearance.spacing.normal

                Repeater {
                    model: Themes.themes

                    delegate: StyledRect {
                        id: card

                        required property var modelData

                        width: 280
                        height: 200
                        radius: Appearance.rounding.normal
                        color: Colours.palette.m3surface
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant

                        // Wallpaper preview takes most of the card
                        StyledClippingRect {
                            anchors.fill: parent
                            radius: card.radius
                            color: Colours.palette.m3surfaceContainer

                            Image {
                                anchors.fill: parent
                                source: card.modelData.preview && card.modelData.preview.length > 0 ? `file://${card.modelData.preview}` : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready

                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        console.log("Failed to load preview image:", source);
                                    }
                                }
                            }

                            // Dark overlay for text readability
                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: 0.4
                                radius: parent.radius
                            }

                            // Floating overlay content
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                spacing: Appearance.spacing.small

                                // Theme name at top (centered horizontally)
                                StyledText {
                                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                                    text: card.modelData.name
                                    elide: Text.ElideRight
                                    font.pointSize: Appearance.font.size.large
                                    font.bold: true
                                    color: "white"
                                }

                                Item { Layout.fillHeight: true }

                                // Buttons at bottom (centered horizontally with space between)
                                RowLayout {
                                    Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                                    spacing: Appearance.spacing.normal

                                    IconTextButton {
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 100
                                        Layout.alignment: Qt.AlignHCenter
                                        icon: "done"
                                        text: qsTr("Apply")
                                        onClicked: Themes.apply(card.modelData.name)
                                        radius: Appearance.rounding.small
                                    }

                                    IconTextButton {
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 100
                                        Layout.alignment: Qt.AlignHCenter
                                        icon: "delete"
                                        text: qsTr("Delete")
                                        label.color: Colours.palette.m3error
                                        stateLayer.color: Colours.palette.m3error
                                        onClicked: Themes.remove(card.modelData.name)
                                        radius: Appearance.rounding.small
                                    }
                                }
                            }

                            // Fallback when no preview available
                            StyledText {
                                anchors.centerIn: parent
                                text: card.modelData.preview && card.modelData.preview.length > 0 ? "" : "No preview"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.small
                                visible: !parent.children[0].visible
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: Themes.reload()
}


