pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property int rulerMode: Config.options.screenRuler.defaultMode

    function open(mode) {
        root.rulerMode = mode ?? Config.options.screenRuler.defaultMode;
        GlobalStates.screenRulerOpen = true;
    }

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: rulerLoader
            required property var modelData
            active: GlobalStates.screenRulerOpen
            sourceComponent: RulerOverlay {
                screen: rulerLoader.modelData
                rulerMode: root.rulerMode
                onDismiss: GlobalStates.screenRulerOpen = false
            }
        }
    }

    IpcHandler {
        target: "ruler"
        function open()       { root.open(); }
        function crosshair()  { root.open(RulerOverlay.RulerMode.Crosshair); }
        function horizontal() { root.open(RulerOverlay.RulerMode.Horizontal); }
        function vertical()   { root.open(RulerOverlay.RulerMode.Vertical); }
        function triangle()   { root.open(RulerOverlay.RulerMode.Triangle); }
        function square()     { root.open(RulerOverlay.RulerMode.Square); }
    }

    GlobalShortcut {
        name: "screenRuler"
        description: "Opens the screen ruler tool"
        onPressed: root.open()
    }
}
