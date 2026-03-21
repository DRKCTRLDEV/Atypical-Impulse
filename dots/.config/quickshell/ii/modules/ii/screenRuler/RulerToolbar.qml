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
        {
            mode: 0,
            icon: "add",
            name: Translation.tr("Crosshair")
        },
        {
            mode: 1,
            icon: "arrow_range",
            name: Translation.tr("Horizontal")
        },
        {
            mode: 2,
            icon: "height",
            name: Translation.tr("Vertical")
        }
    ]
    readonly property var shapeModes: [
        {
            mode: 3,
            icon: "square_foot",
            name: Translation.tr("Triangle")
        },
        {
            mode: 4,
            icon: "crop_square",
            name: Translation.tr("Rectangle")
        }
    ]

    // Track last-used sub-indices per group so icons don't shift when
    // switching groups (previously measureIdx clamped shape modes to 2,
    // making the Measure tab appear to jump to Vertical).
    property int lastMeasureIdx: 0
    property int lastShapeIdx: 0

    onRulerModeChanged: {
        if (rulerMode >= 0 && rulerMode <= 2 && lastMeasureIdx !== rulerMode)
            lastMeasureIdx = rulerMode;
        else if (rulerMode >= 3 && rulerMode <= 4 && lastShapeIdx !== rulerMode - 3)
            lastShapeIdx = rulerMode - 3;
    }

    ToolbarTabBar {
        id: tabBar
        // Two group buttons whose icon/name reflect current sub-mode
        tabButtonList: [
            {
                "icon": root.measureModes[root.lastMeasureIdx].icon,
                "name": root.measureModes[root.lastMeasureIdx].name
            },
            {
                "icon": root.shapeModes[root.lastShapeIdx].icon,
                "name": root.shapeModes[root.lastShapeIdx].name
            }
        ]
        currentIndex: root.activeGroup
        delegate: ToolbarTabButton {
            required property int index
            required property var modelData
            current: index == tabBar.currentIndex
            text: modelData.name
            materialSymbol: modelData.icon
            onClicked: {
                const currentMode = root.rulerMode;
                const currentGroup = currentMode <= 2 ? 0 : 1;

                if (index === 0) {
                    // Measure group: if already active, cycle sub-mode
                    if (currentGroup === 0) {
                        root.rulerMode = (currentMode + 1) % 3;
                    } else {
                        // Switch back to Measure group's last-used sub-mode
                        root.rulerMode = root.lastMeasureIdx;
                    }
                } else {
                    // Shape group: if already active, cycle sub-mode
                    if (currentGroup === 1) {
                        root.rulerMode = currentMode === 3 ? 4 : 3;
                    } else {
                        // Switch to Shape group's last-used sub-mode
                        root.rulerMode = root.shapeModes[root.lastShapeIdx].mode;
                    }
                }
            }
        }
    }
}
