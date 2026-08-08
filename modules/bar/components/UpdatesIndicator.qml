pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full
    clip: true
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: updateColumn.implicitHeight + Tokens.padding.medium * 2

    Component.onCompleted: Updates.refCount++
    Component.onDestruction: Updates.refCount--

    Column {
        id: updateColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

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
            font: Tokens.font.mono.small
            opacity: Updates.hasUpdates ? 1.0 : 0.5

            Behavior on opacity {
                Anim {}
            }
            Behavior on color {
                Anim {}
            }
        }
    }

    StateLayer {
        function onClicked(): void {
            Updates.triggerUpdate();
        }

        anchors.fill: parent
        radius: Tokens.rounding.full
    }
}
