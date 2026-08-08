pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    readonly property real contentMargin: Tokens.padding.large
    readonly property real availableWidth: width - contentMargin * 2
    readonly property real titleBoxHeight: titleRow.implicitHeight + Tokens.padding.small * 2
    readonly property real availableHeight: height - contentMargin * 2 - titleBoxHeight - col.spacing * 2
    readonly property real gifSideTarget: Tokens.sizes.dashboard.mediaCoverArtSize
    readonly property real maxGifSide: Math.max(0, Math.min(gifSideTarget, availableWidth, availableHeight))

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    clip: true
    implicitWidth: Math.max(Tokens.sizes.dashboard.mediaWidth, Tokens.sizes.dashboard.mediaCoverArtSize + Tokens.padding.extraLarge * 2)
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight

    ServiceRef {
        service: Audio.beatTracker
    }

    ColumnLayout {
        id: col

        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: Tokens.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        AnimatedImage {
            id: gif

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.maxGifSide
            Layout.preferredHeight: root.maxGifSide
            playing: Players.active?.isPlaying ?? false
            speed: Audio.beatTracker.bpm / 150
            source: Paths.absolutePath(Config.paths.mediaGif)
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: root.titleBoxHeight
            color: "transparent"
            radius: Tokens.rounding.small

            RowLayout {
                id: titleRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: "music_note"
                    color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.large.build()
                }

                Item {
                    id: marquee

                    readonly property bool hasActive: !!Players.active
                    readonly property string mediaTitle: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
                    readonly property string mediaArtist: (Players.active?.trackArtist ?? "") || qsTr("Unknown artist")
                    readonly property string mediaAlbum: (Players.active?.trackAlbum ?? "") || qsTr("Unknown album")
                    readonly property string displayText: hasActive ? `${mediaTitle} — ${mediaArtist} — ${mediaAlbum}` : qsTr("No media")
                    readonly property color textColor: hasActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    readonly property bool shouldScroll: title.width > width && hasActive

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: title.implicitHeight
                    clip: true

                    Row {
                        id: scrollRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.padding.large * 3

                        StyledText {
                            id: title

                            text: marquee.displayText
                            color: marquee.textColor
                            font: Tokens.font.body.large
                            elide: Text.ElideRight
                        }

                        StyledText {
                            visible: marquee.shouldScroll
                            text: marquee.displayText
                            color: marquee.textColor
                            font: Tokens.font.body.large
                        }
                    }

                    Binding {
                        target: scrollRow
                        property: "x"
                        value: 0
                        when: !marquee.shouldScroll
                    }

                    NumberAnimation {
                        target: scrollRow
                        property: "x"
                        from: 0
                        to: -(title.width + scrollRow.spacing)
                        duration: Math.max(4000, (title.width + scrollRow.spacing) * 20)
                        loops: Animation.Infinite
                        running: marquee.shouldScroll

                        onStopped: scrollRow.x = 0
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
