pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.mediaControls
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

ColumnLayout {
    id: root
    width: parent?.width ?? 0
    spacing: 10
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight

    readonly property var meaningfulPlayers: MprisController.meaningfulPlayers
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var playersToShow: meaningfulPlayers.length > 0
        ? meaningfulPlayers
        : (activePlayer ? [activePlayer] : [])
    visible: playersToShow.length > 0
    implicitHeight: playersToShow.length > 0
        ? playersToShow.length * widgetHeight + Math.max(0, playersToShow.length - 1) * spacing
        : 0

    Repeater {
        model: ScriptModel {
            values: root.playersToShow
        }
        delegate: PlayerControl {
            required property MprisPlayer modelData
            player: modelData
            clip: true
            Layout.fillWidth: true
            implicitHeight: root.widgetHeight
            radius: Appearance.rounding.normal
        }
    }
}
