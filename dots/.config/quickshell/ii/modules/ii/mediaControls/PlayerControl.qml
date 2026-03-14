pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artFilePath: `${Directories.coverArt}/${Qt.md5(artUrl)}`
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    property bool downloaded: false
    readonly property real playerVolume: root.player?.volume ?? 1.0
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius
    property string displayedArtFilePath: (root.downloaded && root.artUrl.length > 0) ? Qt.resolvedUrl(artFilePath) : ""

    component TrackChangeButton: GroupButton {
        Layout.fillWidth: false
        Layout.fillHeight: false
        baseWidth: 22
        baseHeight: 22
        property var iconName
        background: Rectangle {
            color: "transparent"
        }
        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer {
        // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.media.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged();
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = Appearance.m3colors.m3secondaryContainer;
            root.downloaded = false;
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl;
        coverArtDownloader.artFilePath = root.artFilePath;
        // Download
        root.downloaded = false;
        coverArtDownloader.running = true;
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true;
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0 // 2^0 = 1 color
        rescaleSize: 1 // Rescale to 1x1 pixel for faster processing
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            sourceSize.width: background.width
            sourceSize.height: background.height
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                radius: root.radius
            }
        }

        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            live: root.player?.isPlaying
            points: root.visualizerPoints
            maxVisualizerValue: root.maxVisualizerValue
            smoothing: root.visualizerSmoothing
            color: blendedColors.colPrimary
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                if (root.player) {
                    const delta = event.angleDelta.y / 120;
                    root.player.volume = Math.max(0.0, Math.min(1.0, root.player.volume + delta * 0.05));
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: 10

            RowLayout {
                anchors.fill: parent

                Rectangle { // Art background
                    id: artBackground
                    Layout.fillHeight: true
                    implicitWidth: artBackground.height
                    Layout.rightMargin: 8
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artBackground.width
                            height: artBackground.height
                            radius: artBackground.radius
                        }
                    }

                    StyledImage { // Art image
                        id: mediaArt
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        sourceSize.width: parent.height
                        sourceSize.height: parent.height
                    }

                    Rectangle {
                        id: iconShadow
                        anchors.centerIn: playPauseIcon
                        width: playPauseIcon.width + 16
                        height: width
                        radius: width / 2
                        color: ColorUtils.transparentize(blendedColors.colLayer0, 0.3)
                        scale: playPauseIcon.scale
                    }

                    MaterialSymbol {
                        id: playPauseIcon
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.hugeass * 1.8
                        fill: 1
                        color: blendedColors.colOnLayer0
                        text: root.player?.isPlaying ? "pause" : "play_arrow"
                        scale: artMouseArea.containsMouse ? 1 : 0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    MouseArea {
                        id: artMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.player?.togglePlaying()
                    }
                }

                ColumnLayout {
                    // Info & controls
                    Layout.fillWidth: true

                    Item { // Marquee Container
                        id: titleContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: trackTitleMain.implicitHeight
                        clip: true

                        property bool runMarquee: width > 0 && trackTitleMain.implicitWidth > width + 2
                        property real scrollSpeed: 30
                        property bool leftFadeActive: runMarquee && movingRow.x < -1

                        // Fade edges using opacity mask
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: LinearGradient {
                                width: titleContainer.width
                                height: titleContainer.height
                                start: Qt.point(0, 0)
                                end: Qt.point(width, 0)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0
                                        color: titleContainer.leftFadeActive ? "transparent" : "white"
                                    }
                                    GradientStop {
                                        position: 0.08
                                        color: "white"
                                    }
                                    GradientStop {
                                        position: 0.92
                                        color: "white"
                                    }
                                    GradientStop {
                                        position: 1
                                        color: "transparent"
                                    }
                                }
                            }
                        }

                        Row {
                            id: movingRow
                            spacing: 40

                            Binding {
                                target: movingRow
                                property: "x"
                                value: 0
                                when: !titleContainer.runMarquee
                            }

                            SequentialAnimation {
                                id: marqueeAnim
                                running: titleContainer.runMarquee
                                loops: Animation.Infinite

                                PropertyAction {
                                    target: movingRow
                                    property: "x"
                                    value: 0
                                }
                                PauseAnimation {
                                    duration: 3000
                                }
                                NumberAnimation {
                                    target: movingRow
                                    property: "x"
                                    from: 0
                                    to: -(trackTitleMain.width + movingRow.spacing)
                                    duration: (trackTitleMain.width + movingRow.spacing) * (1000 / titleContainer.scrollSpeed)
                                    easing.type: Easing.Linear
                                }
                            }
                            StyledText {
                                id: trackTitleMain
                                font.pixelSize: Appearance.font.pixelSize.large
                                color: blendedColors.colOnLayer0
                                animateChange: true
                                text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"

                                onTextChanged: {
                                    movingRow.x = 0;
                                    if (titleContainer.runMarquee) {
                                        marqueeAnim.restart();
                                    }
                                }
                            }
                            StyledText {
                                visible: titleContainer.runMarquee
                                font: trackTitleMain.font
                                color: trackTitleMain.color
                                text: trackTitleMain.text
                            }
                        }
                    }
                    Item { // Artist Container with animation
                        id: artistContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: trackArtist.implicitHeight
                        Layout.topMargin: -4
                        clip: true

                        Row {
                            id: movingArtistRow
                            spacing: 40

                            Binding {
                                target: movingArtistRow
                                property: "x"
                                value: 0
                                when: !artistContainer.runAnimation
                            }

                            SequentialAnimation {
                                id: artistAnim
                                running: artistContainer.runAnimation
                                loops: Animation.Infinite

                                PropertyAction {
                                    target: movingArtistRow
                                    property: "x"
                                    value: 0
                                }
                                PauseAnimation {
                                    duration: 3000
                                }
                                NumberAnimation {
                                    target: movingArtistRow
                                    property: "x"
                                    from: 0
                                    to: -(trackArtist.width + movingArtistRow.spacing)
                                    duration: (trackArtist.width + movingArtistRow.spacing) * (1000 / 30)
                                    easing.type: Easing.Linear
                                }
                            }
                            StyledText {
                                id: trackArtist
                                color: blendedColors.colSubtext
                                text: root.player?.trackArtist
                                animateChange: true
                                animationDistanceX: 6
                                animationDistanceY: 0

                                onTextChanged: {
                                    movingArtistRow.x = 0;
                                    if (artistContainer.runAnimation) {
                                        artistAnim.restart();
                                    }
                                }
                            }
                            StyledText {
                                visible: artistContainer.runAnimation
                                font: trackArtist.font
                                color: trackArtist.color
                                text: trackArtist.text
                            }
                        }

                        property bool runAnimation: width > 0 && trackArtist.implicitWidth > width + 2
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    ColumnLayout {
                        spacing: -2 // pull closer together
                        RowLayout {
                            StyledText {
                                id: trackTime
                                color: blendedColors.colSubtext
                                text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                Layout.rightMargin: -2 // align to skip_next btn
                                StyledText {
                                    color: blendedColors.colSubtext
                                    text: Math.round(root.playerVolume * 100) + "%"
                                }
                                MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: blendedColors.colSubtext
                                    fill: 1
                                    text: root.playerVolume <= 0 ? "volume_off" : root.playerVolume < 0.5 ? "volume_down" : "volume_up"
                                }
                            }
                        }
                        RowLayout {
                            id: sliderRow
                            Layout.fillWidth: true
                            TrackChangeButton {
                                iconName: "skip_previous"
                                Layout.leftMargin: -4
                                releaseAction: () => root.player?.previous()
                            }
                            Item {
                                id: progressBarContainer
                                Layout.fillWidth: true
                                implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                                Loader {
                                    id: sliderLoader
                                    anchors.fill: parent
                                    active: root.player?.canSeek ?? false
                                    sourceComponent: StyledSlider {
                                        configuration: StyledSlider.Configuration.Wavy
                                        highlightColor: blendedColors.colPrimary
                                        trackColor: blendedColors.colSecondaryContainer
                                        handleColor: blendedColors.colPrimary
                                        handleHeight: 18
                                        stopIndicatorValues: []
                                        property real sliderValue: root.player?.position / root.player?.length ?? 0
                                        value: sliderValue
                                        onPressedChanged: {
                                            if (!pressed && !seekTimer.running) {
                                                sliderValue = Qt.binding(() => root.player?.position / root.player?.length ?? 0);
                                            }
                                        }
                                        onMoved: {
                                            sliderValue = value;
                                            seekTimer.pendingValue = value;
                                            seekTimer.restart();
                                        }

                                        Timer {
                                            id: seekTimer
                                            property real pendingValue: 0
                                            interval: 200
                                            repeat: false
                                            onTriggered: {
                                                root.player.position = pendingValue * root.player.length;
                                                sliderValue = Qt.binding(() => root.player?.position / root.player?.length ?? 0);
                                            }
                                        }
                                    }
                                }

                                Loader {
                                    id: progressBarLoader
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left
                                        right: parent.right
                                    }
                                    active: !(root.player?.canSeek ?? false)
                                    sourceComponent: StyledProgressBar {
                                        wavy: root.player?.isPlaying
                                        highlightColor: blendedColors.colPrimary
                                        trackColor: blendedColors.colSecondaryContainer
                                        value: root.player?.position / root.player?.length
                                    }
                                }
                            }
                            TrackChangeButton {
                                iconName: "skip_next"
                                Layout.rightMargin: -3 // visually neater,
                                releaseAction: () => root.player?.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
