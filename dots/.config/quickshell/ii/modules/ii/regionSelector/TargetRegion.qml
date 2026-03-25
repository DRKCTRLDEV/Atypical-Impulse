pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var clientDimensions
    property color colBackground: Qt.alpha("#88111111", 0.9)
    property color colForeground: "#ddffffff"
    property bool showLabel: Config.options.regionSelector.targetRegions.showLabel
    property bool showIcon: false
    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    property string text: ""
    property real textPadding: 10

    z: 2
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 4 : 2
    radius: 4
    visible: opacity > 0

    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(root)
    }

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    Loader {
        x: root.textPadding
        y: root.textPadding
        active: root.showLabel

        sourceComponent: Rectangle {
            readonly property real verticalPadding: 5
            readonly property real horizontalPadding: 10

            radius: 10
            color: root.colBackground
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            implicitWidth: regionInfoRow.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfoRow.implicitHeight + verticalPadding * 2

            Row {
                id: regionInfoRow
                anchors.centerIn: parent
                spacing: 4

                IconImage {
                    visible: root.showIcon
                    implicitSize: Appearance.font.pixelSize.larger
                    source: root.showIcon ? Quickshell.iconPath(AppSearch.guessIcon(root.text), "image-missing") : ""
                }

                StyledText {
                    text: root.text
                    color: root.colForeground
                }
            }
        }
    }
}
