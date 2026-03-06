import QtQuick
import QtQuick.Layouts
import qs.modules.common

RippleButton {
    Layout.fillHeight: true
    buttonRadius: Appearance.rounding.full
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
}
