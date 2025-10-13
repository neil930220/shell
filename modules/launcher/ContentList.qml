pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Item {
    id: root

    required property var content
    required property PersistentProperties visibilities
    required property var panels
    required property real maxHeight
    required property StyledTextField search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${Config.launcher.actionPrefix}wallpaper `)
    readonly property bool showThemes: search.text.startsWith(`${Config.launcher.actionPrefix}theme `)
    readonly property Item currentList: showWallpapers ? null : appList.item

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: showThemes ? "themes" : (showWallpapers ? "wallpapers" : "apps")

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: Config.launcher.sizes.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(1300, Config.launcher.sizes.itemWidth * 2.5)
                // Reduce height to only what's currently visible; don't reserve space for hidden sections
                root.implicitHeight: Math.min(
                    root.maxHeight,
                    wallpaperSwitcher.item ? wallpaperSwitcher.item.implicitHeight : 0
                )
                wallpaperSwitcher.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "themes"

            PropertyChanges {
                root.implicitWidth: Math.max(1000, Config.launcher.sizes.itemWidth * 2)
                root.implicitHeight: Math.min(
                    root.maxHeight,
                    themeSwitcher.item ? themeSwitcher.item.implicitHeight : 0
                )
                themeSwitcher.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Behavior on state {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.anim.durations.small
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.anim.durations.small
            }
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            search: root.search
            visibilities: root.visibilities
        }
    }

    Loader {
        id: wallpaperSwitcher

        active: false

        anchors.fill: parent

        sourceComponent: WallpaperSwitcherContent {
            visibilities: root.visibilities
        }
    }

    Loader {
        id: themeSwitcher

        active: false

        anchors.fill: parent

        sourceComponent: ThemeSwitcherContent {
            visibilities: root.visibilities
        }
    }

    Row {
        id: empty

        opacity: (root.state === "apps" && root.currentList?.count === 0) ? 1 : 0
        scale: (root.state === "apps" && root.currentList?.count === 0) ? 1 : 0.5

        spacing: Appearance.spacing.normal
        padding: Appearance.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: "manage_search"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: qsTr("No results")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.larger
                font.weight: 500
            }

            StyledText {
                text: qsTr("Try searching for something else")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
            }
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.visibilities.launcher

        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }

    Behavior on implicitHeight {
        enabled: root.visibilities.launcher

        Anim {
            duration: Appearance.anim.durations.large
            easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
        }
    }
}
