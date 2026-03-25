pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Options toolbar
Toolbar {
    id: root

    // Use a synchronizer on these
    property var action
    property var selectionMode
    property var rulerMode
    // Signals
    signal dismiss

    readonly property bool isRuler: root.rulerMode !== null

    readonly property list<var> rulerModeForIndex: [RegionSelection.RulerMode.Horizontal, RegionSelection.RulerMode.Vertical, RegionSelection.RulerMode.Crosshair]
    readonly property list<var> selectionModeForIndex: [RegionSelection.SelectionMode.RectCorners, RegionSelection.SelectionMode.Circle]

    function updateIndexFromMode() {
        var index;
        if (root.isRuler) {
            index = Math.max(0, root.rulerModeForIndex.indexOf(root.rulerMode));
        } else {
            index = root.selectionModeForIndex.indexOf(root.selectionMode);
        }
        if (tabBar.currentIndex !== index)
            tabBar.setCurrentIndex(index);
    }

    ToolbarTabBar {
        id: tabBar
        tabButtonList: root.isRuler ? [
            {
                "icon": "arrow_range",
                "name": Translation.tr("Width")
            },
            {
                "icon": "height",
                "name": Translation.tr("Height")
            },
            {
                "icon": "add",
                "name": Translation.tr("Both")
            }
        ] : [
            {
                "icon": "activity_zone",
                "name": Translation.tr("Rect")
            },
            {
                "icon": "gesture",
                "name": Translation.tr("Circle")
            }
        ]

        onCurrentIndexChanged: {
            if (root.isRuler) {
                const newMode = root.rulerModeForIndex[currentIndex];
                if (newMode !== undefined && newMode !== root.rulerMode)
                    root.rulerMode = newMode;
            } else {
                const newSel = root.selectionModeForIndex[currentIndex];
                if (newSel !== undefined && newSel !== root.selectionMode)
                    root.selectionMode = newSel;
            }
        }
    }

    Connections {
        target: root
        function onRulerModeChanged() {
            Qt.callLater(root.updateIndexFromMode);
        }
        function onSelectionModeChanged() {
            if (!root.isRuler)
                Qt.callLater(root.updateIndexFromMode);
        }
    }
}
