pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: parent.width
    implicitHeight: mainColumn.implicitHeight

    Component.onCompleted: Themes.reload()

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall

        // Create row
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            StyledTextField {
                id: nameInput

                Layout.preferredWidth: 320
                placeholderText: qsTr("Theme name")
            }

            IconTextButton {
                icon: "add"
                text: qsTr("Create from current")
                defaultRadius: Tokens.rounding.medium

                onClicked: {
                    console.log("ThemeSwitcher: Create from current clicked", nameInput.text);
                    if (nameInput.text.trim().length === 0)
                        return;
                    Themes.exportCurrent(nameInput.text.trim());
                    nameInput.text = "";
                }
            }

            IconTextButton {
                icon: "layers_clear"
                text: qsTr("Default mode")
                defaultRadius: Tokens.rounding.medium

                onClicked: {
                    root.screenState.launcher = false;
                    Themes.deactivate();
                }
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

                spacing: Tokens.spacing.medium

                Repeater {
                    model: Themes.themes

                    delegate: StyledRect {
                        id: card

                        required property var modelData

                        width: 280
                        height: 200
                        radius: Tokens.rounding.large
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
                                anchors.margins: Tokens.padding.medium
                                spacing: Tokens.spacing.small

                                // Theme name at top (centered horizontally)
                                StyledText {
                                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                                    text: card.modelData.name
                                    elide: Text.ElideRight
                                    font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                                    color: "white"
                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                // Buttons at bottom (centered horizontally with space between)
                                RowLayout {
                                    Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                                    spacing: Tokens.spacing.medium

                                    IconTextButton {
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 100
                                        Layout.alignment: Qt.AlignHCenter
                                        icon: "done"
                                        text: qsTr("Apply")
                                        defaultRadius: Tokens.rounding.medium

                                        onClicked: {
                                            root.screenState.launcher = false;
                                            Themes.apply(card.modelData.name);
                                        }
                                    }

                                    IconTextButton {
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 100
                                        Layout.alignment: Qt.AlignHCenter
                                        icon: "delete"
                                        text: qsTr("Delete")
                                        label.color: Colours.palette.m3error
                                        stateLayer.color: Colours.palette.m3error
                                        defaultRadius: Tokens.rounding.medium

                                        onClicked: Themes.remove(card.modelData.name)
                                    }
                                }
                            }

                            // Fallback when no preview available
                            StyledText {
                                anchors.centerIn: parent
                                text: card.modelData.preview && card.modelData.preview.length > 0 ? "" : "No preview"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                visible: !parent.children[0].visible
                            }
                        }
                    }
                }
            }
        }
    }
}
