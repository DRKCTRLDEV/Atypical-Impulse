import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

Item {
    id: root

    required property QtObject visibilityTarget
    signal dismiss()

    // Direct children go into toolbarSlot — keeps them in the caller's scope
    // so IDs like `root` resolve correctly even with pragma ComponentBehavior: Bound
    default property alias data: toolbarSlot.data

    z: 10
    anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: -innerRow.height
    }
    implicitWidth: innerRow.implicitWidth
    implicitHeight: innerRow.implicitHeight
    opacity: 0

    Connections {
        target: root.visibilityTarget
        function onVisibleChanged() {
            if (!root.visibilityTarget.visible) return;
            root.anchors.bottomMargin = 8;
            root.opacity = 1;
        }
    }

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on anchors.bottomMargin {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    Row {
        id: innerRow
        spacing: 6

        // Toolbar slot: direct children are parented here
        Item {
            id: toolbarSlot
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
            implicitHeight: children.length > 0 ? children[0].implicitHeight : 56
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: closeFab.implicitWidth
            implicitHeight: closeFab.implicitHeight
            StyledRectangularShadow {
                target: closeFab
                radius: closeFab.buttonRadius
            }
            FloatingActionButton {
                id: closeFab
                baseSize: toolbarSlot.implicitHeight
                buttonRadius: baseSize / 2
                iconText: "close"
                onClicked: root.dismiss()
                StyledToolTip {
                    text: Translation.tr("Close")
                }
                colBackground: Appearance.colors.colTertiaryContainer
                colBackgroundHover: Appearance.colors.colTertiaryContainerHover
                colRipple: Appearance.colors.colTertiaryContainerActive
                colOnBackground: Appearance.colors.colOnTertiaryContainer
            }
        }
    }
}
