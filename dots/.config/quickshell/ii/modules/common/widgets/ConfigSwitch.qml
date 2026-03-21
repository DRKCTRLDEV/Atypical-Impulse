import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property alias iconSize: iconWidget.iconSize

    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    font.pixelSize: Appearance.font.pixelSize.small
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    
    onClicked: checked = !checked

    contentItem: RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
            Layout.leftMargin: 8
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            font: root.font
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
        StyledSwitch {
            id: switchWidget
            down: root.down
            Layout.fillWidth: false
            Layout.rightMargin: 8
            checked: root.checked
            onClicked: root.clicked()
        }
    }
}

