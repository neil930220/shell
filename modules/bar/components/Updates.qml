pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick


StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary

    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.full
    clip: true

    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: updateColumn.implicitHeight + Appearance.padding.normal * 2

    Component.onCompleted: Updates.refCount++
    Component.onDestruction: Updates.refCount--

    Column {
        id: updateColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        spacing: Appearance.spacing.small

        MaterialIcon {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter

            text: Updates.getIcon()


            Behavior on color {
                Anim {}
            }
        }

        StyledText {
            id: countText

            anchors.horizontalCenter: parent.horizontalCenter

            text: Updates.updateCount.toString()
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono

            opacity: Updates.hasUpdates ? 1.0 : 0.5

            Behavior on color {
                Anim {}
            }

            Behavior on opacity {
                Anim {}
            }
        }
    }

    StateLayer {
        anchors.fill: parent
        radius: Appearance.rounding.full

        function onClicked(): void {
            Updates.triggerUpdate();
        }
    }
}

