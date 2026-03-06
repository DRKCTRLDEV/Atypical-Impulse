pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

Toolbar {
    id: root
    property int rulerMode

    // Group 0: Measure (Crosshair / Horizontal / Vertical)
    // Group 1: Shape   (Triangle / Square)
    readonly property int activeGroup: (rulerMode <= 2) ? 0 : 1

    // Sub-mode icons & names within each group
    readonly property var measureModes: [
        { mode: 0, icon: "add",                   name: Translation.tr("Crosshair") },
        { mode: 1, icon: "horizontal_rule",        name: Translation.tr("Horizontal") },
        { mode: 2, icon: "vertical_align_center",  name: Translation.tr("Vertical") }
    ]
    readonly property var shapeModes: [
        { mode: 3, icon: "change_history", name: Translation.tr("Triangle") },
        { mode: 4, icon: "crop_square",    name: Translation.tr("Rectangle") }
    ]

    // Current sub-indices
    readonly property int measureIdx: Math.min(Math.max(rulerMode, 0), 2)
    readonly property int shapeIdx: rulerMode >= 3 ? rulerMode - 3 : 0

    ToolbarTabBar {
        id: tabBar
        // Two group buttons whose icon/name reflect current sub-mode
        tabButtonList: [
            { "icon": root.measureModes[root.measureIdx].icon, "name": root.measureModes[root.measureIdx].name },
            { "icon": root.shapeModes[root.shapeIdx].icon,     "name": root.shapeModes[root.shapeIdx].name }
        ]
        currentIndex: root.activeGroup
        delegate: ToolbarTabButton {
            required property int index
            required property var modelData
            current: index == tabBar.currentIndex
            text: modelData.name
            materialSymbol: modelData.icon
            onClicked: {
                if (index === 0) {
                    // Measure group: if already active, cycle sub-mode
                    if (root.activeGroup === 0) {
                        root.rulerMode = (root.rulerMode + 1) % 3;
                    } else {
                        root.rulerMode = root.measureIdx;
                    }
                } else {
                    // Shape group: if already active, cycle sub-mode
                    if (root.activeGroup === 1) {
                        root.rulerMode = root.rulerMode === 3 ? 4 : 3;
                    } else {
                        root.rulerMode = root.shapeModes[root.shapeIdx].mode;
                    }
                }
            }
        }
    }
}
