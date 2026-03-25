pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

OverlayWindow {
    id: root
    wlrNamespace: "quickshell:regionSelector"

    // Modes
    enum SnipAction {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }
    enum SelectionMode {
        RectCorners,
        Circle
    }
    enum RulerMode {
        Crosshair,
        Horizontal,
        Vertical
    }
    enum Phase {
        Select,
        Post
    }
    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var rulerMode: null
    property var phase: RegionSelection.Phase.Select
    signal requestDismiss

    // Styles (overlayColor, hyprlandMonitor, monitorScale, screenshotDir inherited from OverlayWindow)
    property color selectionBorderColor: ColorUtils.mix(Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0, Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary, 0.5)
    property color windowBorderColor: Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary
    property color windowFillColor: ColorUtils.transparentize(windowBorderColor, 0.85)
    property real targetRegionOpacity: Config.options.regionSelector.targetRegions.opacity
    property bool contentRegionOpacity: Config.options.regionSelector.targetRegions.contentRegionOpacity

    // Vars for indicators
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        if (a.floating === b.floating)
            return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Screen & interaction vars
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: RegionFunctions.filterWindowRegionsByLayers(root.windows.filter(w => w.workspace.id === root.activeWorkspaceId), root.layerRegions).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title
        };
    })
    readonly property list<var> layerRegions: {
        const topLayers = root.layers[root.hyprlandMonitor.name]?.levels["2"];
        if (!topLayers)
            return [];
        return topLayers.filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":verticalBar") || layer.namespace.includes(":dock"))).map(layer => ({
                    at: [layer.x - root.monitorOffsetX, layer.y - root.monitorOffsetY],
                    size: [layer.w, layer.h],
                    namespace: layer.namespace
                }));
    }

    // Config
    property bool isCircleSelection: (root.selectionMode === RegionSelection.SelectionMode.Circle)
    property bool enableWindowRegions: Config.options.regionSelector.targetRegions.windows && !isCircleSelection && root.rulerMode === null
    property bool enableLayerRegions: Config.options.regionSelector.targetRegions.layers && !isCircleSelection && root.rulerMode === null
    property bool enableContentRegions: Config.options.regionSelector.targetRegions.content && root.rulerMode === null

    // Target
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    function isTargeted(modelData) {
        return !root.draggedAway && root.targetedRegionX === modelData.at[0] && root.targetedRegionY === modelData.at[1] && root.targetedRegionWidth === modelData.size[0] && root.targetedRegionHeight === modelData.size[1];
    }

    readonly property list<var> allRegionDescriptors: {
        let result = [];
        if (root.enableWindowRegions) {
            for (const w of root.windowRegions)
                result.push({
                    at: w.at,
                    size: w.size,
                    z: 2,
                    borderColor: root.windowBorderColor,
                    fillColor: root.windowFillColor,
                    opacity: root.targetRegionOpacity,
                    text: w.class,
                    radius: Appearance.rounding.windowRounding,
                    showIcon: true
                });
        }
        if (root.enableLayerRegions) {
            for (const l of root.layerRegions)
                result.push({
                    at: l.at,
                    size: l.size,
                    z: 3,
                    borderColor: root.windowBorderColor,
                    fillColor: root.windowFillColor,
                    opacity: root.targetRegionOpacity,
                    text: l.namespace,
                    radius: Appearance.rounding.windowRounding
                });
        }
        if (root.enableContentRegions) {
            const imgBorder = Appearance.m3colors.darkmode ? Appearance.colors.colTertiary : Qt.lighter(Appearance.colors.colPrimary);
            for (const c of root.imageRegions)
                result.push({
                    at: c.at,
                    size: c.size,
                    z: 4,
                    borderColor: imgBorder,
                    fillColor: ColorUtils.transparentize(imgBorder, 0.85),
                    opacity: root.contentRegionOpacity,
                    text: Translation.tr("Content region")
                });
        }
        return result;
    }

    function updateTargetedRegion(x, y) {
        const hit = [...root.imageRegions, ...root.layerRegions, ...root.windowRegions].find(r => r.at[0] <= x && x <= r.at[0] + r.size[0] && r.at[1] <= y && y <= r.at[1] + r.size[1]);
        root.targetedRegionX = hit?.at[0] ?? -1;
        root.targetedRegionY = hit?.at[1] ?? -1;
        root.targetedRegionWidth = hit?.size[0] ?? 0;
        root.targetedRegionHeight = hit?.size[1] ?? 0;
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    // Screenshot stuff
    Connections {
        target: root.screenshotProcess
        function onExited(exitCode, exitStatus) {
            if (root.rulerMode !== null) {
                screenRuler.screenshotReady = true;
                screenRuler.loadScreenshot();
            }
            if (root.enableContentRegions)
                imageDetectionProcess.running = true;
            root.preparationDone = !checkRecordingProc.running;
        }
    }
    readonly property bool isRecordingAction: [RegionSelection.SnipAction.Record, RegionSelection.SnipAction.RecordWithSound].includes(root.action)
    property bool recordingShouldStop: false
    Process {
        id: checkRecordingProc
        running: root.rulerMode === null && root.isRecordingAction
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !root.screenshotProcess.running;
            root.recordingShouldStop = (exitCode === 0);
        }
    }
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone)
            return;
        if (root.rulerMode === null && root.isRecordingAction && root.recordingShouldStop) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            root.requestDismiss();
            return;
        }
        root.visible = true;
    }

    Process {
        id: imageDetectionProcess
        command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh ` + `--hyprctl ` + `--image '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' ` + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} ` + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector
            onStreamFinished: {
                imageRegions = RegionFunctions.filterImageRegions(JSON.parse(imageDimensionCollector.text), root.windowRegions);
            }
        }
    }

    readonly property var snipActionMap: ({
            [RegionSelection.SnipAction.Copy]: ScreenshotAction.Action.Copy,
            [RegionSelection.SnipAction.Edit]: ScreenshotAction.Action.Edit,
            [RegionSelection.SnipAction.Search]: ScreenshotAction.Action.Search,
            [RegionSelection.SnipAction.CharRecognition]: ScreenshotAction.Action.CharRecognition,
            [RegionSelection.SnipAction.Record]: ScreenshotAction.Action.Record,
            [RegionSelection.SnipAction.RecordWithSound]: ScreenshotAction.Action.RecordWithSound
        })

    // Execution after selection
    function snip() {
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.requestDismiss();
            return;
        }
        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));
        if (root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit) {
            root.action = root.mouseButton === Qt.RightButton ? RegionSelection.SnipAction.Edit : RegionSelection.SnipAction.Copy;
        }

        const screenshotAction = root.snipActionMap[root.action];
        if (screenshotAction === undefined) {
            console.warn("[Region Selector] Unknown snip action, skipping snip.");
            root.requestDismiss();
            return;
        }
        const command = ScreenshotAction.getCommand(root.regionX * root.monitorScale, root.regionY * root.monitorScale, root.regionWidth * root.monitorScale, root.regionHeight * root.monitorScale, root.screenshotPath, screenshotAction, Config.options.screenSnip.savePath || "");
        Quickshell.execDetached(command);
        if (root.isRecordingAction) {
            root.phase = RegionSelection.Phase.Post;
        } else {
            root.requestDismiss();
        }
    }

    // Only clickable in Selection phase
    mask: Region {
        item: root.phase === RegionSelection.Phase.Select ? mouseArea : null
    }

    ScreencopyView {
        // For freezing
        anchors.fill: parent
        live: false
        captureSource: root.screen
        visible: root.phase === RegionSelection.Phase.Select

        focus: root.visible
        readonly property var rulerKeyMap: ({
                [Qt.Key_1]: RegionSelection.RulerMode.Crosshair,
                [Qt.Key_2]: RegionSelection.RulerMode.Horizontal,
                [Qt.Key_3]: RegionSelection.RulerMode.Vertical
            })
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.requestDismiss();
            } else if (root.rulerMode !== null && event.key in rulerKeyMap) {
                root.rulerMode = rulerKeyMap[event.key];
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: root.rulerMode !== null ? Qt.BlankCursor : Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        focus: root.rulerMode !== null && root.visible

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton && root.rulerMode !== null) {
                root.requestDismiss();
                return;
            }
            if (root.rulerMode === null) {
                root.dragStartX = mouse.x;
                root.dragStartY = mouse.y;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragging = true;
            }
            root.mouseButton = mouse.button;
        }
        onReleased: mouse => {
            if (root.rulerMode !== null) {
                mouseArea.forceActiveFocus();
                return;
            }
            // Detect if it was a click -> Try to select targeted region
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                if (root.targetedRegionX >= 0 && root.targetedRegionY >= 0) {
                    const pad = Config.options.regionSelector.targetRegions.selectionPadding;
                    root.regionX = root.targetedRegionX - pad;
                    root.regionY = root.targetedRegionY - pad;
                    root.regionWidth = root.targetedRegionWidth + pad * 2;
                    root.regionHeight = root.targetedRegionHeight + pad * 2;
                }
            } else
            // Circle dragging?
            if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                const padding = Config.options.regionSelector.circle.padding + Config.options.regionSelector.circle.strokeWidth / 2;
                const dragPoints = (root.points.length > 0) ? root.points : [
                    {
                        x: mouseArea.mouseX,
                        y: mouseArea.mouseY
                    }
                ];
                const maxX = Math.max(...dragPoints.map(p => p.x));
                const minX = Math.min(...dragPoints.map(p => p.x));
                const maxY = Math.max(...dragPoints.map(p => p.y));
                const minY = Math.min(...dragPoints.map(p => p.y));
                root.regionX = minX - padding;
                root.regionY = minY - padding;
                root.regionWidth = maxX - minX + padding * 2;
                root.regionHeight = maxY - minY + padding * 2;
            }
            root.snip();
        }
        onPositionChanged: mouse => {
            if (root.rulerMode !== null) {
                screenRuler.requestScan(mouse.x, mouse.y);
            } else {
                root.updateTargetedRegion(mouse.x, mouse.y);
                if (!root.dragging)
                    return;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragDiffX = mouse.x - root.dragStartX;
                root.dragDiffY = mouse.y - root.dragStartY;
                root.points.push({
                    x: mouse.x,
                    y: mouse.y
                });
            }
        }
        onWheel: wheel => {
            if (root.rulerMode === null)
                return;
            const step = (wheel.modifiers & Qt.ControlModifier) ? 10 : 1;
            const delta = wheel.angleDelta.y > 0 ? step : -step;
            screenRuler.adjustTolerance(delta, mouseArea.mouseX, mouseArea.mouseY);
        }

        // === Screen ruler (edge detection) ===

        ScreenRuler {
            id: screenRuler
            screenWidth: root.width
            screenHeight: root.height
            monitorScale: root.monitorScale
            screenshotPath: root.screenshotPath
        }

        // === Ruler overlay ===

        Rectangle {
            z: 1
            anchors.fill: parent
            visible: root.rulerMode !== null
            color: root.overlayColor
        }

        // === Unified aimlines (ruler measurements + selection guides) ===

        Aimlines {
            id: aimlines
            z: 2
            anchors.fill: parent
            edges: screenRuler.edges
            mouseX: mouseArea.mouseX
            mouseY: mouseArea.mouseY
            color: root.selectionBorderColor
            rulerLineColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0
            rulerMode: root.rulerMode
            breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            showAimLines: Config.options.regionSelector.rect.aimLines
        }

        // === Region selector visuals ===

        Loader {
            z: 2
            anchors.fill: parent
            active: root.rulerMode === null && root.selectionMode === RegionSelection.SelectionMode.RectCorners
            sourceComponent: RectCornersSelectionDetails {
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.rulerMode === null && root.selectionMode === RegionSelection.SelectionMode.Circle
            sourceComponent: CircleSelectionDetails {
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                points: root.points
            }
        }

        CursorGuide {
            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            displayText: root.rulerMode !== null ? aimlines.measurementText : ""
            x: mouseArea.mouseX
            y: mouseArea.mouseY
            action: root.action
            selectionMode: root.selectionMode
        }

        // Target regions (windows, layers, content)
        Repeater {
            model: (root.phase === RegionSelection.Phase.Select) ? root.allRegionDescriptors : []
            delegate: TargetRegion {
                required property var modelData
                z: modelData.z
                clientDimensions: modelData
                showIcon: modelData.showIcon ?? false
                targeted: root.isTargeted(modelData)
                opacity: root.draggedAway ? 0 : modelData.opacity
                borderColor: modelData.borderColor
                fillColor: targeted ? modelData.fillColor : "transparent"
                text: modelData.text
                radius: modelData.radius ?? 4
            }
        }

        // Controls
        Row {
            id: regionSelectionControls
            z: 10
            visible: root.phase === RegionSelection.Phase.Select
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: -height
            }
            opacity: 0
            Connections {
                target: root
                function onVisibleChanged() {
                    if (!visible)
                        return;
                    regionSelectionControls.anchors.bottomMargin = 8;
                    regionSelectionControls.opacity = 1;
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on anchors.bottomMargin {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            spacing: 6

            OptionsToolbar {
                Synchronizer on action {
                    property alias source: root.action
                }
                Synchronizer on selectionMode {
                    property alias source: root.selectionMode
                }
                Synchronizer on rulerMode {
                    property alias source: root.rulerMode
                }
            }

            Item {
                anchors {
                    verticalCenter: parent.verticalCenter
                }
                implicitWidth: closeFab.implicitWidth
                implicitHeight: closeFab.implicitHeight
                StyledRectangularShadow {
                    target: closeFab
                    radius: closeFab.buttonRadius
                }
                FloatingActionButton {
                    id: closeFab
                    baseSize: 48
                    iconText: "close"
                    onClicked: root.requestDismiss()
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

        // Tolerance indicator pill (ruler mode)
        Item {
            id: tolPill
            z: 10
            visible: root.rulerMode !== null && opacity > 0
            opacity: screenRuler.tolIndicatorVisible ? 1 : 0
            anchors {
                verticalCenter: regionSelectionControls.verticalCenter
                right: regionSelectionControls.left
                rightMargin: 6
            }
            implicitWidth: Math.max(implicitHeight, tolDigit.implicitWidth + 24)
            implicitHeight: 56

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            StyledRectangularShadow {
                target: tolPillBg
                anchors.fill: tolPillBg
            }

            Rectangle {
                id: tolPillBg
                anchors.fill: parent
                radius: height / 2
                color: Appearance.m3colors.m3surfaceContainer

                StyledText {
                    id: tolDigit
                    anchors.centerIn: parent
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    text: Math.round(screenRuler.liveTolerance).toString()
                }
            }
        }
    }
}
