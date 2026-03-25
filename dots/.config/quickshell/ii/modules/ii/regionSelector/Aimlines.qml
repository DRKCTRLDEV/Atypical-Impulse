import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    required property var edges
    required property real mouseX
    required property real mouseY
    required property color color
    required property color rulerLineColor
    required property var rulerMode
    required property bool breathingBorderOnly
    property bool showAimLines: true

    readonly property bool isRuler: root.rulerMode !== null
    readonly property bool showH: root.rulerMode === 0 || root.rulerMode === 1 // Crosshair | Horizontal
    readonly property bool showV: root.rulerMode === 0 || root.rulerMode === 2 // Crosshair | Vertical

    readonly property string measurementText: {
        if (!root.isRuler) return "";
        const e = root.edges;
        if (root.showH && root.showV)
            return `W: ${Math.round(e.width)}px  H: ${Math.round(e.height)}px`;
        if (root.showH)
            return `W: ${Math.round(e.width)}px`;
        return `H: ${Math.round(e.height)}px`;
    }

    // Non-ruler aimlines: thin crosshair guides at cursor
    Rectangle {
        visible: !root.isRuler && root.showAimLines && !root.breathingBorderOnly
        z: 3
        x: root.mouseX
        width: 1
        anchors { top: parent.top; bottom: parent.bottom }
        color: root.color
        opacity: 0.2
    }
    Rectangle {
        visible: !root.isRuler && root.showAimLines && !root.breathingBorderOnly
        z: 3
        y: root.mouseY
        height: 1
        anchors { left: parent.left; right: parent.right }
        color: root.color
        opacity: 0.2
    }

    // Ruler measurement lines (horizontal)
    Rectangle {
        visible: root.isRuler && root.showH
        z: 3
        x: root.edges.left
        y: root.mouseY - 1
        width: root.edges.width
        height: 3
        color: Qt.alpha(root.rulerLineColor, 0.25)
    }
    Rectangle {
        visible: root.isRuler && root.showH
        z: 3
        x: root.edges.left
        y: root.mouseY
        width: root.edges.width
        height: 1
        color: root.rulerLineColor
    }

    // Ruler measurement lines (vertical)
    Rectangle {
        visible: root.isRuler && root.showV
        z: 3
        x: root.mouseX - 1
        y: root.edges.top
        width: 3
        height: root.edges.height
        color: Qt.alpha(root.rulerLineColor, 0.25)
    }
    Rectangle {
        visible: root.isRuler && root.showV
        z: 3
        x: root.mouseX
        y: root.edges.top
        width: 1
        height: root.edges.height
        color: root.rulerLineColor
    }

    // Ruler tick marks
    Rectangle {
        visible: root.isRuler && root.showH
        z: 3
        x: root.edges.left
        y: root.mouseY - 5
        width: 1
        height: 11
        color: root.rulerLineColor
    }
    Rectangle {
        visible: root.isRuler && root.showH
        z: 3
        x: root.edges.right - 1
        y: root.mouseY - 5
        width: 1
        height: 11
        color: root.rulerLineColor
    }
    Rectangle {
        visible: root.isRuler && root.showV
        z: 3
        x: root.mouseX - 5
        y: root.edges.top
        width: 11
        height: 1
        color: root.rulerLineColor
    }
    Rectangle {
        visible: root.isRuler && root.showV
        z: 3
        x: root.mouseX - 5
        y: root.edges.bottom - 1
        width: 11
        height: 1
        color: root.rulerLineColor
    }
}
