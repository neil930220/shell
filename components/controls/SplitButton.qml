import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Row {
    id: root

    enum Type {
        Filled,
        Tonal
    }

    property real horizontalPadding: Appearance.padding.normal
    property real verticalPadding: Appearance.padding.smaller
    property int type: SplitButton.Filled
    property bool disabled
    property bool menuOnTop
    property string fallbackIcon
    property string fallbackText

    property alias menuItems: menu.items
    property alias active: menu.active
    property alias expanded: menu.expanded
    property alias menu: menu
    property alias iconLabel: iconLabel
    property alias label: label
    property alias stateLayer: stateLayer

    property color colour: type == SplitButton.Filled ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer
    property color textColour: type == SplitButton.Filled ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
    property color disabledColour: Qt.alpha(Colours.palette.m3onSurface, 0.1)
    property color disabledTextColour: Qt.alpha(Colours.palette.m3onSurface, 0.38)

    // Use window content as overlay root for menus to avoid clipping
    readonly property Item overlayRoot: Window.window?.contentItem ?? null

    spacing: Math.floor(Appearance.spacing.small / 2)

    StyledRect {
        radius: implicitHeight / 2
        topRightRadius: Appearance.rounding.small / 2
        bottomRightRadius: Appearance.rounding.small / 2
        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: textRow.implicitWidth + root.horizontalPadding * 2
        implicitHeight: expandBtn.implicitHeight

        StateLayer {
            id: stateLayer

            rect.topRightRadius: parent.topRightRadius
            rect.bottomRightRadius: parent.bottomRightRadius
            color: root.textColour
            disabled: root.disabled

            function onClicked(): void {
                root.active?.clicked();
            }
        }

        RowLayout {
            id: textRow

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: Math.floor(root.verticalPadding / 4)
            spacing: Appearance.spacing.small

            MaterialIcon {
                id: iconLabel

                Layout.alignment: Qt.AlignVCenter
                animate: true
                text: root.active?.activeIcon ?? root.fallbackIcon
                color: root.disabled ? root.disabledTextColour : root.textColour
                fill: 1
            }

            StyledText {
                id: label

                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                animate: true
                text: root.active?.activeText ?? root.fallbackText
                color: root.disabled ? root.disabledTextColour : root.textColour
                clip: true

                Behavior on Layout.preferredWidth {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }
        }
    }

    StyledRect {
        id: expandBtn

        property real rad: {
            if (root.expanded && root.menuOnTop) {
                return implicitHeight / 2;
            } else if (root.expanded && !root.menuOnTop) {
                return implicitHeight / 2;
            } else {
                return Appearance.rounding.small / 2
            }
        }

        property real topRightRad: {
            if (root.expanded && root.menuOnTop) {
                return Appearance.rounding.small / 2;
            } else if (root.expanded && !root.menuOnTop) {
                return implicitHeight / 2;
            } else {
                return implicitHeight / 2
            }
        }

        property real bottomRightRad: {
            if (root.expanded && root.menuOnTop) {
                return implicitHeight / 2;
            } else if (root.expanded && !root.menuOnTop) {
                return Appearance.rounding.small / 2;
            } else {
                return implicitHeight / 2
            }
        }

        property real topLeftRad: {
            if (root.expanded && root.menuOnTop) {
                return Appearance.rounding.small / 2;
            } else if (root.expanded && !root.menuOnTop) {
                return implicitHeight / 2;
            } else {
                return Appearance.rounding.small / 2
            }
        }

        property real bottomLeftRad: {
            if (root.expanded && root.menuOnTop) {
                return implicitHeight / 2;
            } else if (root.expanded && !root.menuOnTop) {
                return Appearance.rounding.small / 2;
            } else {
                return Appearance.rounding.small / 2
            }
        }

        radius: Appearance.rounding.small
        topLeftRadius: topLeftRad
        bottomLeftRadius: bottomLeftRad
        bottomRightRadius: bottomRightRad
        topRightRadius: topRightRad

        color: root.disabled ? root.disabledColour : root.colour

        implicitWidth: implicitHeight
        implicitHeight: expandIcon.implicitHeight + root.verticalPadding * 2

        StateLayer {
            id: expandStateLayer

            rect.topLeftRadius: parent.topLeftRadius
            rect.bottomLeftRadius: parent.bottomLeftRadius
            color: root.textColour
            disabled: root.disabled

            function onClicked(): void {
                root.expanded = !root.expanded;
            }
        }

        MaterialIcon {
            id: expandIcon

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.expanded ? 0 : -Math.floor(root.verticalPadding / 4)

            text: "expand_more"
            color: root.disabled ? root.disabledTextColour : root.textColour
            rotation: root.expanded ? 180 : 0

            Behavior on anchors.horizontalCenterOffset {
                Anim {}
            }

            Behavior on rotation {
                Anim {}
            }
        }

        Behavior on rad {
            Anim {}
        }

        Behavior on topLeftRad {
            Anim {}
        }

        Behavior on bottomLeftRad {
            Anim {}
        }

        Behavior on topRightRad {
            Anim {}
        }

        Behavior on bottomRightRad {
            Anim {}
        }

        Menu {
            id: menu

            // When possible, render in window overlay to avoid clipping by parents
            Component.onCompleted: {
                if (root.overlayRoot) {
                    // reparent to overlay on first use if expanded
                    if (menu.expanded) {
                        menu.anchors.top = undefined;
                        menu.anchors.bottom = undefined;
                        menu.anchors.right = undefined;
                        menu.parent = root.overlayRoot;
                        menu.updateOverlayPos();
                    }
                }
            }

            function updateOverlayPos() {
                if (!root.overlayRoot)
                    return;

                const overlay = root.overlayRoot;
                const spacing = Appearance.spacing.small;

                const btnTopLeft = expandBtn.mapToItem(overlay, 0, 0);
                const btnBottomLeft = expandBtn.mapToItem(overlay, 0, expandBtn.height);
                const btnTopRight = expandBtn.mapToItem(overlay, expandBtn.width, 0);

                const desiredX = btnTopRight.x - menu.implicitWidth;
                const desiredY = root.menuOnTop ? (btnTopLeft.y - menu.implicitHeight - spacing)
                                                : (btnBottomLeft.y + spacing);

                const minX = 0;
                const maxX = Math.max(0, overlay.width - menu.implicitWidth);
                const minY = 0;
                const maxY = Math.max(0, overlay.height - menu.implicitHeight);

                menu.x = Math.min(Math.max(desiredX, minX), maxX);
                menu.y = Math.min(Math.max(desiredY, minY), maxY);
                menu.z = 9999;
            }

            onExpandedChanged: {
                if (root.overlayRoot) {
                    if (expanded) {
                        menu.anchors.top = undefined;
                        menu.anchors.bottom = undefined;
                        menu.anchors.right = undefined;
                        menu.parent = root.overlayRoot;
                        menu.updateOverlayPos();
                    } else if (menu.parent !== expandBtn) {
                        menu.parent = expandBtn;
                    }
                }
            }

            onImplicitWidthChanged: if (expanded) updateOverlayPos()
            onImplicitHeightChanged: if (expanded) updateOverlayPos()

            Connections {
                target: root.overlayRoot
                enabled: target && menu.expanded
                function onWidthChanged() { menu.updateOverlayPos(); }
                function onHeightChanged() { menu.updateOverlayPos(); }
            }

            Connections {
                target: expandBtn
                enabled: menu.expanded
                function onXChanged() { menu.updateOverlayPos(); }
                function onYChanged() { menu.updateOverlayPos(); }
                function onWidthChanged() { menu.updateOverlayPos(); }
                function onHeightChanged() { menu.updateOverlayPos(); }
            }

            states: State {
                when: root.menuOnTop

                AnchorChanges {
                    target: menu
                    anchors.top: undefined
                    anchors.bottom: expandBtn.top
                }
            }

            anchors.top: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: Appearance.spacing.small
            anchors.bottomMargin: Appearance.spacing.small
        }
    }
}
