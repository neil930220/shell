pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.config
import Caelestia.Services
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// Persistent right-side media panel: GIF + basic player controls
StyledRect {
    id: root

    required property PersistentProperties visibilities

    radius: Appearance.rounding.small
    clip: true

    // Width large enough to fit the media-tab sized circle (cover + visualiser)
    implicitWidth: Math.max(
        Config.dashboard.sizes.mediaWidth,
        Config.dashboard.sizes.mediaCoverArtSize + Config.dashboard.sizes.mediaVisualiserSize * 2
    )

    readonly property real contentMargin: Appearance.padding.large
    readonly property real availableWidth: width - contentMargin * 2
    readonly property real titleBoxHeight: titleRow.implicitHeight + Appearance.padding.small * 2
    readonly property real availableHeight: height - contentMargin * 2 - titleBoxHeight - col.spacing * 2
    // match media tab's circle: cover size plus visualiser margins
    readonly property real gifSideTarget: Config.dashboard.sizes.mediaCoverArtSize + Config.dashboard.sizes.mediaVisualiserSize * 2
    readonly property real maxGifSide: Math.max(0, Math.min(gifSideTarget, availableWidth, availableHeight))

    // Track progress for slider binding
    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";
        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");
        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    // Keep slider value in sync while playing
    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    // Optional tempo-following for gif speed
    ServiceRef { service: Audio.beatTracker }

    ColumnLayout {
        id: col
        
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal

        // Top spacer to vertically center the content stack
        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        // GIF
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

        // Media title with icon (fixed left) and marquee text
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: titleRow.implicitHeight + Appearance.padding.small * 2
            color: "transparent"
            radius: Appearance.rounding.small

            RowLayout {
                id: titleRow
                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                spacing: Appearance.spacing.small

                // Left-aligned icon stays fixed
                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: "music_note"
                    color: Players.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.large
                }

                // Marquee container for "Title — Artist — Album"
                Item {
                    id: marquee

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: title.implicitHeight
                    clip: true

                    readonly property bool hasActive: !!Players.active
                    readonly property string mediaTitle: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
                    readonly property string mediaArtist: (Players.active?.trackArtist ?? "") || qsTr("Unknown artist")
                    readonly property string mediaAlbum: (Players.active?.trackAlbum ?? "") || qsTr("Unknown album")
                    readonly property string displayText: hasActive ? `${mediaTitle} — ${mediaArtist} — ${mediaAlbum}` : qsTr("No media")
                    readonly property color textColor: hasActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    readonly property bool shouldScroll: title.width > width && hasActive

                    Row {
                        id: scrollRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Appearance.padding.large * 3

                        StyledText {
                            id: title
                            text: marquee.displayText
                            color: marquee.textColor
                            font.pointSize: Appearance.font.size.large
                            elide: Text.ElideRight
                        }

                        // Second copy for seamless looping when scrolling
                        StyledText {
                            visible: marquee.shouldScroll
                            text: marquee.displayText
                            color: marquee.textColor
                            font.pointSize: Appearance.font.size.large
                        }
                    }

                    // Keep still when not scrolling
                    Binding {
                        target: scrollRow
                        property: "x"
                        value: 0
                        when: !marquee.shouldScroll
                    }

                    // Horizontal marquee animation
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

        // Bottom spacer to vertically center
        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }

    // No player controls in this persistent pane
}


