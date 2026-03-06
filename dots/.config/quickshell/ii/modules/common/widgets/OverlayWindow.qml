pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    property string wlrNamespace: "quickshell:overlay"
    WlrLayershell.namespace: wlrNamespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors { left: true; right: true; top: true; bottom: true }

    signal dismiss()

    property color overlayColor: ColorUtils.transparentize("#000000", 0.4)
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale

    property string screenshotDir: Directories.screenshotTemp
    property string screenshotPath: `${screenshotDir}/image-${screen.name}`
    property alias screenshotProcess: screenshotProc
    signal screenshotFinished(int exitCode, int exitStatus)

    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => root.screenshotFinished(exitCode, exitStatus)
    }
}
