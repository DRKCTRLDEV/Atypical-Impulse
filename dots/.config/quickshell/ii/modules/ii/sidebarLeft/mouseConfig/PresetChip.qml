pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * DPI Preset Chip component for mouse configuration sidebar.
 * Displays a DPI value and allows selection and removal.
 */
GroupButton {
    id: root

    property int dpiValue: 800
    property int presetIndex: 0
    property bool isSelected: false
    property bool leftmost: false
    property bool rightmost: false

    leftRadius: (isSelected || leftmost) ? (height / 2) : Appearance.rounding.unsharpenmore
    rightRadius: (isSelected || rightmost) ? (height / 2) : Appearance.rounding.unsharpenmore

    signal presetSelected(int index)
    signal presetRemoveRequested(int index)

    baseWidth: chipRow.implicitWidth + horizontalPadding * 2
    baseHeight: 36
    bounce: false
    clip: true

    toggled: isSelected

    colBackgroundToggled: Appearance.colors.colPrimaryContainer
    colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover
    colBackgroundToggledActive: Appearance.colors.colPrimaryContainerActive

    onClicked: {
        presetSelected(presetIndex)
    }

    MouseArea {
        id: rightClickArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.RightButton
        onClicked: {
            presetRemoveRequested(presetIndex)
        }
    }

    contentItem: RowLayout {
        id: chipRow
        Item {
            implicitWidth: dpiText.implicitWidth
            implicitHeight: dpiText.implicitHeight
            StyledText {
                id: dpiText
                text: root.dpiValue.toString()
                font.pixelSize: Appearance.font.pixelSize.normal
                animateChange: true
                color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
                Layout.alignment: Qt.AlignVCenter
            }
        }
        Rectangle {
            id: closeButton
            implicitWidth: 24; implicitHeight: 24
            color: "transparent"
            visible: root.hovered || root.isSelected
            MaterialSymbol {
                id: closeIcon
                anchors.centerIn: parent
                text: "close"
                iconSize: Appearance.font.pixelSize.larger
                color: root.isSelected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            }
            MouseArea {
                id: closeMouseArea
                anchors.centerIn: parent
                width: 32; height: 32
                hoverEnabled: true
                onClicked: {
                    root.presetRemoveRequested(root.presetIndex)
                }
            }
        }
    }
}
