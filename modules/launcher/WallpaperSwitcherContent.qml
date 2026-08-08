pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    required property var panels
    required property var content
    property bool showCarousel

    implicitWidth: parent.width
    // Use layout's computed height so rows aren't clipped; loader contributes 0 when hidden
    implicitHeight: mainColumn.implicitHeight

    Component.onCompleted: {
        WallpaperSwitcher.selectedMonitor = Hypr.focusedMonitor?.name ?? "";
        WallpaperSwitcher.fetchWorkspaceWallpapers();
        WallpaperSwitcher.fetchAllWallpapers();
    }

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall

        // Workspace buttons
        StyledFlickable {
            id: workspaceRow

            property int realItemCount: 10
            property int duplicates: 3 // Number of full sets to duplicate for cycling

            property real itemWidth: 200 + Tokens.spacing.large
            property bool isRepositioning: false

            function centerOnCurrentWorkspace() {
                if (Hypr.activeWsId > 0 && Hypr.activeWsId <= realItemCount) {
                    // Always position in the middle duplicate set
                    var buttonIndex = (duplicates * realItemCount) + (Hypr.activeWsId - 1);
                    var buttonPosition = buttonIndex * itemWidth;
                    var centerPosition = buttonPosition - (width / 2) + (200 / 2);

                    isRepositioning = true;
                    Qt.callLater(() => {
                        workspaceRow.contentX = centerPosition;
                        isRepositioning = false;
                    });
                }
            }

            function wrapAround() {
                if (isRepositioning)
                    return;

                var singleSetWidth = realItemCount * itemWidth;
                var middleSetStart = duplicates * singleSetWidth;

                // If we scroll too far left, jump to equivalent position on the right
                if (contentX < (duplicates - 1) * singleSetWidth) {
                    isRepositioning = true;
                    contentX += singleSetWidth;
                    isRepositioning = false;
                } else
                // If we scroll too far right, jump to equivalent position on the left
                if (contentX > (duplicates + 1) * singleSetWidth) {
                    isRepositioning = true;
                    contentX -= singleSetWidth;
                    isRepositioning = false;
                }
            }

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 130
            contentWidth: workspaceButtonsRow.implicitWidth
            contentHeight: height
            clip: true
            flickableDirection: Flickable.HorizontalFlick

            onMovementEnded: wrapAround()
            onFlickEnded: wrapAround()
            Component.onCompleted: centerOnCurrentWorkspace()

            Row {
                id: workspaceButtonsRow

                spacing: Tokens.spacing.large

                // Create multiple duplicate sets for seamless cycling
                Repeater {
                    model: workspaceRow.realItemCount * (workspaceRow.duplicates * 2 + 1)

                    delegate: StyledRect {
                        id: workspaceButton

                        required property int index
                        // Map index to workspace ID (1-10), cycling through duplicates
                        readonly property int workspaceId: (index % workspaceRow.realItemCount) + 1
                        readonly property bool isFocused: Hypr.activeWsId === workspaceId
                        readonly property string wallpaperPath: WallpaperSwitcher.workspaceWallpapers[workspaceId] || ""

                        width: 200
                        height: 120
                        color: isFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
                        radius: Tokens.rounding.large
                        border.width: isFocused ? 2 : 0
                        border.color: Colours.palette.m3primary
                        scale: isFocused ? 1.05 : 1.0

                        onIsFocusedChanged: {
                            if (isFocused && !workspaceRow.isRepositioning) {
                                workspaceRow.centerOnCurrentWorkspace();
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        // Wallpaper background
                        StyledClippingRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.large

                            Image {
                                anchors.fill: parent
                                source: workspaceButton.wallpaperPath ? `file://${workspaceButton.wallpaperPath}` : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                                opacity: 0.8
                            }
                        }

                        // Dark overlay
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: 0.3
                            radius: parent.radius
                        }

                        // Workspace number
                        StyledText {
                            anchors.centerIn: parent
                            text: workspaceButton.workspaceId.toString()
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.headline.builders.large.weight(workspaceButton.isFocused ? Font.Bold : Font.Medium).build()
                        }

                        StateLayer {
                            function onClicked() {
                                WallpaperSwitcher.selectedWorkspaceId = workspaceButton.workspaceId;
                                WallpaperSwitcher.showAllWallpapers = true;
                            }

                            radius: parent.radius
                            color: Colours.palette.m3primary
                        }
                    }
                }
            }
        }

        // Action buttons rectangle
        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: actionRow.implicitWidth + Tokens.spacing.large
            Layout.preferredHeight: 50
            radius: Tokens.rounding.medium
            color: Colours.palette.m3surface

            Row {
                id: actionRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.large

                // Upload button
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: uploadMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "upload"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: uploadMouseArea

                        function onClicked() {
                            fileDialog.open();
                        }

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true
                    }
                }

                // Expand/collapse button
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: expandMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: WallpaperSwitcher.showAllWallpapers ? "expand_less" : "expand_more"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: expandMouseArea

                        function onClicked() {
                            WallpaperSwitcher.showAllWallpapers = !WallpaperSwitcher.showAllWallpapers;
                        }

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true
                    }
                }

                // Custom/All toggle button
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: customMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: WallpaperSwitcher.showCustomOnly ? "dashboard_customize" : "apps"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: customMouseArea

                        function onClicked() {
                            WallpaperSwitcher.showCustomOnly = !WallpaperSwitcher.showCustomOnly;
                        }

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true
                    }
                }

                // Folder filter button
                SplitButton {
                    id: folderFilter

                    // Show current selection or fallback
                    menuItems: folderItems.instances
                    active: menuItems.find(m => m.modelData === WallpaperSwitcher.selectedFolder) ?? menuItems[0]
                    fallbackIcon: "folder"
                    fallbackText: qsTr("Folders")
                    label.Layout.maximumWidth: 140
                    label.elide: Text.ElideRight
                    menuOnTop: true

                    menu.onItemSelected: item => WallpaperSwitcher.selectedFolder = item.modelData

                    Variants {
                        id: folderItems

                        // Empty string represents "All folders"
                        model: [""].concat(WallpaperSwitcher.folders)

                        MenuItem {
                            required property string modelData

                            // Leading checkmark when selected
                            icon: modelData === WallpaperSwitcher.selectedFolder ? "check" : ""
                            // Button face
                            activeIcon: "folder"
                            activeText: modelData === "" ? qsTr("All folders") : modelData
                            // Menu row text
                            text: modelData === "" ? qsTr("All folders") : modelData
                        }
                    }
                }

                // Keep the upstream wallpaper carousel available alongside
                // the per-workspace manager.
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: carouselMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.showCarousel ? "view_carousel" : "view_day"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: carouselMouseArea

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true

                        onClicked: root.showCarousel = !root.showCarousel
                    }
                }

                // Shuffle button
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: shuffleMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "shuffle"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: shuffleMouseArea

                        function onClicked() {
                            WallpaperSwitcher.setRandomWallpaper();
                        }

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true
                    }
                }

                // Refresh button
                StyledRect {
                    width: 80
                    height: 40
                    radius: Tokens.rounding.medium
                    color: refreshMouseArea.containsMouse ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "refresh"
                        color: Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.large
                    }

                    StateLayer {
                        id: refreshMouseArea

                        function onClicked() {
                            WallpaperSwitcher.reload();
                        }

                        radius: parent.radius
                        color: Colours.palette.m3primary
                        hoverEnabled: true
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: root.showCarousel ? Tokens.sizes.launcher.wallpaperHeight : 0
            active: root.showCarousel
            visible: active

            sourceComponent: WallpaperList {
                width: parent.width
                height: parent.height
                search: root.search
                screenState: root.screenState
                panels: root.panels
                content: root.content
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }

        // Wallpaper grid
        Loader {
            id: wallpaperLoader

            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperSwitcher.showAllWallpapers ? 120 : 0
            active: WallpaperSwitcher.showAllWallpapers
            visible: WallpaperSwitcher.showAllWallpapers

            sourceComponent: StyledFlickable {
                contentWidth: grid.implicitWidth
                contentHeight: grid.implicitHeight
                clip: true
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: grid

                    spacing: Tokens.spacing.extraSmall

                    Repeater {
                        model: WallpaperSwitcher.allWallpapers

                        delegate: Item {
                            id: tile

                            // capture the model value into a stable property for child access
                            required property string modelData
                            property string path: modelData

                            width: 140
                            height: 100

                            StyledClippingRect {
                                anchors.fill: parent
                                anchors.margins: 5
                                radius: Tokens.rounding.medium
                                color: Colours.palette.m3surfaceContainerHighest

                                Image {
                                    anchors.fill: parent
                                    source: `file://${tile.path}`
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Colours.palette.m3primary
                                    opacity: stateLayer.containsMouse ? 0.2 : 0
                                    radius: parent.radius

                                    Behavior on opacity {
                                        Anim {}
                                    }
                                }

                                StateLayer {
                                    id: stateLayer

                                    function onClicked() {
                                        WallpaperSwitcher.selectedMonitor = Hypr.focusedMonitor?.name ?? WallpaperSwitcher.selectedMonitor;
                                        WallpaperSwitcher.setWorkspaceWallpaper(WallpaperSwitcher.selectedWorkspaceId, tile.path);
                                    }

                                    radius: parent.radius
                                    color: Colours.palette.m3primary
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }

    FileDialog {
        id: fileDialog

        title: qsTr("Select a wallpaper")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions

        onAccepted: path => {
            WallpaperSwitcher.addWallpaper(path);
            // Wait a bit then reload
            Qt.callLater(() => {
                WallpaperSwitcher.fetchAllWallpapers();
            });
        }
    }
}
