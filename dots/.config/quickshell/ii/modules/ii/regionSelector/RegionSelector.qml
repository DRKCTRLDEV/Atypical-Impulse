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
import Quickshell.Widgets
import Quickshell.Hyprland

Scope {
    id: root

    function dismiss() {
        GlobalStates.regionSelectorOpen = false;
    }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var rulerMode: null

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: regionSelectorLoader
            required property var modelData
            active: GlobalStates.regionSelectorOpen

            sourceComponent: RegionSelection {
                screen: regionSelectorLoader.modelData
                onRequestDismiss: root.dismiss()
                action: root.action
                selectionMode: root.selectionMode
                rulerMode: root.rulerMode
            }
        }
    }

    function openWith(action, mode) {
        root.rulerMode = null;
        root.action = action;
        root.selectionMode = mode ?? RegionSelection.SelectionMode.RectCorners;
        GlobalStates.regionSelectorOpen = true;
    }
    function openRuler(mode) {
        root.rulerMode = mode ?? RegionSelection.RulerMode.Crosshair;
        GlobalStates.regionSelectorOpen = true;
    }
    function screenshot() {
        root.openWith(RegionSelection.SnipAction.Copy);
    }
    function search() {
        root.openWith(RegionSelection.SnipAction.Search, Config.options.regionSelector.circleSelection ? RegionSelection.SelectionMode.Circle : undefined);
    }

    function ocr() {
        root.openWith(RegionSelection.SnipAction.CharRecognition);
    }

    function _toggleRecord(action) {
        root.rulerMode = null;
        root.action = action;
        root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        if (GlobalStates.regionSelectorOpen)
            GlobalStates.regionSelectorOpen = false;
        GlobalStates.regionSelectorOpen = true;
    }
    function record() {
        root._toggleRecord(RegionSelection.SnipAction.Record);
    }
    function recordWithSound() {
        root._toggleRecord(RegionSelection.SnipAction.RecordWithSound);
    }

    IpcHandler {
        target: "region"
        function screenshot() {
            root.screenshot();
        }
        function search() {
            root.search();
        }
        function ocr() {
            root.ocr();
        }
        function record() {
            root.record();
        }
        function recordWithSound() {
            root.recordWithSound();
        }
    }

    IpcHandler {
        target: "ruler"
        function open() {
            root.openRuler();
        }
        function crosshair() {
            root.openRuler(RegionSelection.RulerMode.Crosshair);
        }
        function horizontal() {
            root.openRuler(RegionSelection.RulerMode.Horizontal);
        }
        function vertical() {
            root.openRuler(RegionSelection.RulerMode.Vertical);
        }
    }

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: root.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: root.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: root.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: root.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: root.recordWithSound()
    }
    GlobalShortcut {
        name: "screenRuler"
        description: "Opens the screen ruler tool"
        onPressed: root.openRuler()
    }
}
