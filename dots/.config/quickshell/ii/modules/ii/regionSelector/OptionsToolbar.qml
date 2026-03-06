pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick

Toolbar {
    id: root

    property var action
    property var selectionMode

    ToolbarTabBar {
        id: tabBar
        tabButtonList: [
            {"icon": "activity_zone", "name": Translation.tr("Rect")},
            {"icon": "gesture", "name": Translation.tr("Circle")}
        ]
        currentIndex: root.selectionMode === RegionSelection.SelectionMode.RectCorners ? 0 : 1
        delegate: ToolbarTabButton {
            required property int index
            required property var modelData
            current: index == tabBar.currentIndex
            text: modelData.name
            materialSymbol: modelData.icon
            onClicked: {
                root.selectionMode = index === 0 ? RegionSelection.SelectionMode.RectCorners : RegionSelection.SelectionMode.Circle;
            }
        }
    }
}
