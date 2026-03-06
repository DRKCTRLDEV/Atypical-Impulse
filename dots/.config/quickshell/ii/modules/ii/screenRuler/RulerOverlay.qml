pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

OverlayWindow {
    id: root
    wlrNamespace: "quickshell:screenRuler"
    screenshotPath: `${Directories.screenshotTemp}/ruler-${screen.name}`

    // Modes: Crosshair includes sub-modes cycled by re-clicking the tab
    // 0=Crosshair  1=Horizontal  2=Vertical  3=Triangle  4=Square
    enum RulerMode { Crosshair, Horizontal, Vertical, Triangle, Square }
    property int rulerMode: Config.options.screenRuler.defaultMode

    property color lineColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0
    property color accentColor: Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary

    // -- Runtime tolerance (scrollwheel adjustable) --
    property real liveTolerance: Config.options.screenRuler.edgeTolerance
    property bool tolIndicatorVisible: false
    Timer { id: tolFadeTimer; interval: 1200; onTriggered: root.tolIndicatorVisible = false }

    // -- Screenshot & pixel-based edge detection --
    onScreenshotFinished: {
        pixelCanvas.loadScreenshot();
        root.visible = true;
    }

    // Edge bounds for cursor position
    property var edges: ({
        left: 0, right: root.width, top: 0, bottom: root.height,
        width: root.width, height: root.height
    })

    // Pending cursor position for throttled scanning
    property real pendingMx: 0
    property real pendingMy: 0
    property bool scanPending: false

    Timer {
        id: scanThrottle
        interval: 16  // ~60 fps cap
        repeat: false
        onTriggered: {
            if (root.scanPending) {
                root.edges = root.scanEdges(root.pendingMx, root.pendingMy);
                root.scanPending = false;
            }
        }
    }

    function requestScan(mx, my) {
        root.pendingMx = mx;
        root.pendingMy = my;
        root.scanPending = true;
        if (!scanThrottle.running) scanThrottle.start();
    }

    // Hidden canvas — loads the screenshot and caches pixel data for scanning
    Canvas {
        id: pixelCanvas
        visible: false
        width: Math.round(root.width * root.monitorScale)
        height: Math.round(root.height * root.monitorScale)

        property var pixelData: null
        property var dataArray: null  // Typed Uint8Array cached for fast access
        property int pw: 0
        property int ph: 0
        property bool ready: false
        property string currentSource: ""

        function loadScreenshot() {
            const src = "file://" + root.screenshotPath;
            if (currentSource === src) unloadImage(src);
            currentSource = src;
            loadImage(src);
        }

        onImageLoaded: requestPaint()

        onPaint: {
            if (!currentSource) return;
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(currentSource, 0, 0, width, height);
            pixelData = ctx.getImageData(0, 0, width, height);
            if (pixelData) {
                dataArray = pixelData.data;
                pw = width;
                ph = height;
            }
            ready = pixelData !== null;
        }
    }

    // Continuous capture: periodically re-grab pixel data from the live view
    Timer {
        running: Config.options.screenRuler.continuousCapture && root.visible
        interval: 300
        onTriggered: {
            screencopyView.grabToImage(function(result) {
                if (pixelCanvas.currentSource)
                    pixelCanvas.unloadImage(pixelCanvas.currentSource);
                pixelCanvas.currentSource = result.url.toString();
                pixelCanvas.loadImage(pixelCanvas.currentSource);
            });
        }
    }

    // -- Pixel-tolerance edge scanning (optimised) --
    function scanEdges(mx, my) {
        const d = pixelCanvas.dataArray;
        if (!pixelCanvas.ready || !d)
            return { left: 0, right: root.width, top: 0, bottom: root.height,
                     width: root.width, height: root.height };

        const scale = root.monitorScale;
        const pw    = pixelCanvas.pw;
        const ph    = pixelCanvas.ph;
        const tol   = root.liveTolerance;
        const perCh = Config.options.screenRuler.perChannelEdge;

        const px = Math.min(Math.max(Math.round(mx * scale), 1), pw - 2);
        const py = Math.min(Math.max(Math.round(my * scale), 1), ph - 2);

        // Inline edge test (avoids function-call overhead in hot loop)
        // Scan left
        let left = 0;
        for (let x = px; x > 0; x--) {
            const i1 = (py * pw + x) << 2, i2 = i1 - 4;
            if (perCh ? (Math.abs(d[i1] - d[i2]) > tol || Math.abs(d[i1+1] - d[i2+1]) > tol || Math.abs(d[i1+2] - d[i2+2]) > tol)
                      : ((Math.abs(d[i1] - d[i2]) + Math.abs(d[i1+1] - d[i2+1]) + Math.abs(d[i1+2] - d[i2+2])) > tol))
            { left = x / scale; break; }
        }
        // Scan right
        let right = root.width;
        for (let x = px; x < pw - 1; x++) {
            const i1 = (py * pw + x) << 2, i2 = i1 + 4;
            if (perCh ? (Math.abs(d[i1] - d[i2]) > tol || Math.abs(d[i1+1] - d[i2+1]) > tol || Math.abs(d[i1+2] - d[i2+2]) > tol)
                      : ((Math.abs(d[i1] - d[i2]) + Math.abs(d[i1+1] - d[i2+1]) + Math.abs(d[i1+2] - d[i2+2])) > tol))
            { right = (x + 1) / scale; break; }
        }
        // Scan up
        const rowBytes = pw << 2;
        let top = 0;
        for (let y = py; y > 0; y--) {
            const i1 = (y * pw + px) << 2, i2 = i1 - rowBytes;
            if (perCh ? (Math.abs(d[i1] - d[i2]) > tol || Math.abs(d[i1+1] - d[i2+1]) > tol || Math.abs(d[i1+2] - d[i2+2]) > tol)
                      : ((Math.abs(d[i1] - d[i2]) + Math.abs(d[i1+1] - d[i2+1]) + Math.abs(d[i1+2] - d[i2+2])) > tol))
            { top = y / scale; break; }
        }
        // Scan down
        let bottom = root.height;
        for (let y = py; y < ph - 1; y++) {
            const i1 = (y * pw + px) << 2, i2 = i1 + rowBytes;
            if (perCh ? (Math.abs(d[i1] - d[i2]) > tol || Math.abs(d[i1+1] - d[i2+1]) > tol || Math.abs(d[i1+2] - d[i2+2]) > tol)
                      : ((Math.abs(d[i1] - d[i2]) + Math.abs(d[i1+1] - d[i2+1]) + Math.abs(d[i1+2] - d[i2+2])) > tol))
            { bottom = (y + 1) / scale; break; }
        }

        return { left, right, top, bottom,
                 width: right - left, height: bottom - top };
    }

    // -- Triangle / Square drag state --
    property real dragStartX: -1; property real dragStartY: -1
    property real draggingX: -1;  property real draggingY: -1
    property bool dragging: false
    readonly property real triW: Math.abs(draggingX - dragStartX)
    readonly property real triH: Math.abs(draggingY - dragStartY)
    readonly property real triHyp: Math.sqrt(triW * triW + triH * triH)
    readonly property real triAngA: triW > 0 ? Math.atan2(triH, triW) * 180 / Math.PI : 0
    // Axis-aligned bounding box for the drag rectangle (Square mode)
    readonly property real rectLeft: Math.min(dragStartX, draggingX)
    readonly property real rectRight: Math.max(dragStartX, draggingX)
    readonly property real rectTop: Math.min(dragStartY, draggingY)
    readonly property real rectBottom: Math.max(dragStartY, draggingY)

    // -- Helpers --
    readonly property bool showH: rulerMode === RulerOverlay.RulerMode.Crosshair || rulerMode === RulerOverlay.RulerMode.Horizontal
    readonly property bool showV: rulerMode === RulerOverlay.RulerMode.Crosshair || rulerMode === RulerOverlay.RulerMode.Vertical
    readonly property bool isTri: rulerMode === RulerOverlay.RulerMode.Triangle
    readonly property bool isSquare: rulerMode === RulerOverlay.RulerMode.Square
    readonly property bool isDragMode: isTri || isSquare
    readonly property bool triVis: isTri && dragging && triW > 2 && triH > 2
    readonly property bool squareVis: isSquare && dragging && triW > 2 && triH > 2
    readonly property bool anglesVis: (triVis || squareVis) && triW > 40 && triH > 40

    component RulerLabel : StyledText {
        z: 20; font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.smaller
    }

    ScreencopyView {
        id: screencopyView
        anchors.fill: parent
        live: Config.options.screenRuler.continuousCapture
        captureSource: root.screen
    }

    Item {
        anchors.fill: parent

        // Uniform dark overlay
        Rectangle { z: 1; anchors.fill: parent; color: root.overlayColor }

        MouseArea {
            id: mouseArea; anchors.fill: parent; z: 5
            cursorShape: root.isDragMode ? Qt.CrossCursor : Qt.BlankCursor
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            focus: root.visible
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) { root.dragging = false; root.dismiss(); }
                else if (event.key === Qt.Key_1) root.rulerMode = RulerOverlay.RulerMode.Crosshair;
                else if (event.key === Qt.Key_2) root.rulerMode = RulerOverlay.RulerMode.Horizontal;
                else if (event.key === Qt.Key_3) root.rulerMode = RulerOverlay.RulerMode.Vertical;
                else if (event.key === Qt.Key_4) root.rulerMode = RulerOverlay.RulerMode.Triangle;
                else if (event.key === Qt.Key_5) root.rulerMode = RulerOverlay.RulerMode.Square;
            }

            onPositionChanged: (mouse) => {
                root.requestScan(mouse.x, mouse.y);
                if (root.dragging) { root.draggingX = mouse.x; root.draggingY = mouse.y; }
            }
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) { root.dismiss(); return; }
                if (root.isDragMode) {
                    root.dragStartX = mouse.x; root.dragStartY = mouse.y;
                    root.draggingX = mouse.x;  root.draggingY = mouse.y;
                    root.dragging = true;
                }
            }
            onReleased: { root.dragging = false; mouseArea.forceActiveFocus(); }
            onWheel: (wheel) => {
                const step = (wheel.modifiers & Qt.ControlModifier) ? 10 : 1;
                const delta = wheel.angleDelta.y > 0 ? step : -step;
                root.liveTolerance = Math.max(0, Math.min(255, root.liveTolerance + delta));
                root.tolIndicatorVisible = true;
                tolFadeTimer.restart();
                // Re-scan immediately with new tolerance
                root.edges = root.scanEdges(mouseArea.mouseX, mouseArea.mouseY);
            }

            // -- Measurement lines with glow --
            Rectangle { visible: root.showH; z: 3; x: root.edges.left; y: mouseArea.mouseY - 1; width: root.edges.width; height: 3; color: Qt.alpha(root.lineColor, 0.25) }
            Rectangle { visible: root.showH; z: 3; x: root.edges.left; y: mouseArea.mouseY; width: root.edges.width; height: 1; color: root.lineColor }
            Rectangle { visible: root.showV; z: 3; x: mouseArea.mouseX - 1; y: root.edges.top; width: 3; height: root.edges.height; color: Qt.alpha(root.lineColor, 0.25) }
            Rectangle { visible: root.showV; z: 3; x: mouseArea.mouseX; y: root.edges.top; width: 1; height: root.edges.height; color: root.lineColor }

            // -- Tick marks at edges --
            Rectangle { visible: root.showH; z: 3; x: root.edges.left;      y: mouseArea.mouseY - 5; width: 1; height: 11; color: root.lineColor }
            Rectangle { visible: root.showH; z: 3; x: root.edges.right - 1; y: mouseArea.mouseY - 5; width: 1; height: 11; color: root.lineColor }
            Rectangle { visible: root.showV; z: 3; x: mouseArea.mouseX - 5; y: root.edges.top;        width: 11; height: 1; color: root.lineColor }
            Rectangle { visible: root.showV; z: 3; x: mouseArea.mouseX - 5; y: root.edges.bottom - 1; width: 11; height: 1; color: root.lineColor }

            // -- Tooltip --
            Rectangle {
                id: tooltip; z: 20; visible: !root.isDragMode
                x: { let t = mouseArea.mouseX + 16; return (t + width > root.width) ? mouseArea.mouseX - width - 16 : t; }
                y: { let t = mouseArea.mouseY + 16; return (t + height > root.height) ? mouseArea.mouseY - height - 16 : t; }
                implicitWidth: tipText.implicitWidth + 16; implicitHeight: tipText.implicitHeight + 10
                radius: Appearance.rounding.verysmall; color: Appearance.colors.colTooltip
                border.width: 1; border.color: Appearance.m3colors.m3outlineVariant
                StyledText {
                    id: tipText; anchors.centerIn: parent; color: Appearance.colors.colOnTooltip
                    font.family: Appearance.font.family.monospace; font.pixelSize: Appearance.font.pixelSize.normal
                    text: {
                        const e = root.edges;
                        if (root.showH && root.showV) return `W: ${Math.round(e.width)}px  H: ${Math.round(e.height)}px`;
                        if (root.showH) return `W: ${Math.round(e.width)}px`;
                        return `H: ${Math.round(e.height)}px`;
                    }
                }
            }

            // -- Triangle mode --
            Shape {
                z: 3; anchors.fill: parent; visible: root.triVis
                ShapePath {
                    strokeColor: root.lineColor; strokeWidth: 1.5; fillColor: Qt.alpha(root.accentColor, 0.08)
                    strokeStyle: ShapePath.DashLine; dashPattern: [8, 4]
                    startX: root.dragStartX; startY: root.dragStartY
                    PathLine { x: root.draggingX; y: root.dragStartY }
                    PathLine { x: root.draggingX; y: root.draggingY }
                    PathLine { x: root.dragStartX; y: root.dragStartY }
                }
            }
            // Right-angle marker
            Rectangle {
                z: 5; visible: root.triVis && root.triW > 20 && root.triH > 20
                property real sz: 8
                x: root.draggingX + (root.dragStartX > root.draggingX ? 0 : -sz)
                y: root.dragStartY + (root.draggingY > root.dragStartY ? 0 : -sz)
                width: sz; height: sz; color: "transparent"; border.width: 1; border.color: root.lineColor
            }
            // Triangle dimension labels
            RulerLabel {
                visible: root.triVis && root.triW > 30; color: root.lineColor
                x: (root.dragStartX + root.draggingX) / 2 - implicitWidth / 2
                y: root.dragStartY + (root.draggingY > root.dragStartY ? -implicitHeight - 4 : 4)
                text: `${Math.round(root.triW)}px`
            }
            RulerLabel {
                visible: root.triVis && root.triH > 30; color: root.lineColor
                x: root.draggingX + (root.dragStartX > root.draggingX ? 4 : -implicitWidth - 4)
                y: (root.dragStartY + root.draggingY) / 2 - implicitHeight / 2
                text: `${Math.round(root.triH)}px`
            }
            RulerLabel {
                visible: root.triVis && root.triHyp > 50; color: root.accentColor
                x: (root.dragStartX + root.draggingX) / 2 + (root.draggingX > root.dragStartX ? 10 : -implicitWidth - 10)
                y: (root.dragStartY + root.draggingY) / 2 + (root.draggingY > root.dragStartY ? 10 : -implicitHeight - 10)
                text: `${Math.round(root.triHyp)}px`
            }
            // Angle labels
            RulerLabel {
                visible: root.anglesVis && root.isTri
                x: root.dragStartX + (root.draggingX > root.dragStartX ? 14 : -implicitWidth - 14)
                y: root.dragStartY + (root.draggingY > root.dragStartY ? -implicitHeight - 4 : 4)
                color: root.accentColor; text: `${root.triAngA.toFixed(1)}\u00b0`
            }
            RulerLabel {
                visible: root.anglesVis && root.isTri
                x: root.draggingX + (root.dragStartX > root.draggingX ? 14 : -implicitWidth - 14)
                y: root.draggingY + (root.dragStartY > root.draggingY ? -implicitHeight - 4 : 4)
                color: root.accentColor; text: `${(90 - root.triAngA).toFixed(1)}\u00b0`
            }
            RulerLabel {
                visible: root.anglesVis && root.isTri
                x: root.draggingX + (root.dragStartX > root.draggingX ? 12 : -implicitWidth - 12)
                y: root.dragStartY + (root.draggingY > root.dragStartY ? 4 : -implicitHeight - 4)
                color: root.lineColor; text: "90\u00b0"
            }

            // ========================================================
            // -- Square / Rectangle mode --
            // ========================================================
            // Rectangle outline
            Shape {
                z: 3; anchors.fill: parent; visible: root.squareVis
                ShapePath {
                    strokeColor: root.lineColor; strokeWidth: 1.5
                    fillColor: Qt.alpha(root.accentColor, 0.08)
                    strokeStyle: ShapePath.DashLine; dashPattern: [8, 4]
                    startX: root.dragStartX; startY: root.dragStartY
                    PathLine { x: root.draggingX; y: root.dragStartY }
                    PathLine { x: root.draggingX; y: root.draggingY }
                    PathLine { x: root.dragStartX; y: root.draggingY }
                    PathLine { x: root.dragStartX; y: root.dragStartY }
                }
            }
            // Diagonal
            Shape {
                z: 4; anchors.fill: parent; visible: root.squareVis && root.triHyp > 10
                ShapePath {
                    strokeColor: root.accentColor; strokeWidth: 1
                    fillColor: "transparent"
                    strokeStyle: ShapePath.DashLine; dashPattern: [6, 3]
                    startX: root.dragStartX; startY: root.dragStartY
                    PathLine { x: root.draggingX; y: root.draggingY }
                }
            }
            // Right-angle markers at all four corners
            Repeater {
                model: root.squareVis && root.triW > 20 && root.triH > 20 ? 4 : 0
                Rectangle {
                    required property int index
                    z: 5; property real sz: 8
                    x: (index === 0 || index === 3) ? root.rectLeft : root.rectRight - sz
                    y: (index === 0 || index === 1) ? root.rectTop : root.rectBottom - sz
                    width: sz; height: sz; color: "transparent"
                    border.width: 1; border.color: root.lineColor
                }
            }
            // Width label (above rectangle)
            RulerLabel {
                visible: root.squareVis && root.triW > 30; color: root.lineColor
                x: (root.rectLeft + root.rectRight) / 2 - implicitWidth / 2
                y: root.rectTop - implicitHeight - 6
                text: `${Math.round(root.triW)}px`
            }
            // Height label (right of rectangle)
            RulerLabel {
                visible: root.squareVis && root.triH > 30; color: root.lineColor
                x: root.rectRight + 6
                y: (root.rectTop + root.rectBottom) / 2 - implicitHeight / 2
                text: `${Math.round(root.triH)}px`
            }
            // Diagonal label
            RulerLabel {
                visible: root.squareVis && root.triHyp > 50; color: root.accentColor
                x: (root.dragStartX + root.draggingX) / 2 + (root.draggingX > root.dragStartX ? 10 : -implicitWidth - 10)
                y: (root.dragStartY + root.draggingY) / 2 + (root.draggingY > root.dragStartY ? -implicitHeight - 10 : 10)
                text: `\u2571 ${Math.round(root.triHyp)}px`
            }
            // Angle labels at diagonal endpoints
            RulerLabel {
                visible: root.anglesVis && root.isSquare
                x: root.dragStartX + (root.draggingX > root.dragStartX ? 14 : -implicitWidth - 14)
                y: root.dragStartY + (root.draggingY > root.dragStartY ? 4 : -implicitHeight - 4)
                color: root.accentColor; text: `${root.triAngA.toFixed(1)}\u00b0`
            }
            RulerLabel {
                visible: root.anglesVis && root.isSquare
                x: root.draggingX + (root.dragStartX > root.draggingX ? 14 : -implicitWidth - 14)
                y: root.draggingY + (root.dragStartY > root.draggingY ? 4 : -implicitHeight - 4)
                color: root.accentColor; text: `${(90 - root.triAngA).toFixed(1)}\u00b0`
            }

            OverlayToolbarRow {
                id: toolbarRow
                visibilityTarget: root
                onDismiss: root.dismiss()

                RulerToolbar {
                    Synchronizer on rulerMode { property alias source: root.rulerMode }
                }
            }

            // -- Tolerance indicator pill (positioned left of toolbar) --
            Rectangle {
                id: tolPill
                z: 10
                visible: opacity > 0
                opacity: root.tolIndicatorVisible ? 1 : 0
                anchors {
                    verticalCenter: toolbarRow.verticalCenter
                    right: toolbarRow.left
                    rightMargin: 6
                }
                implicitWidth: Math.max(implicitHeight, tolDigit.implicitWidth + 16)
                implicitHeight: toolbarRow.implicitHeight
                radius: height / 2
                color: Appearance.m3colors.m3surfaceContainer

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

                StyledText {
                    id: tolDigit
                    anchors.centerIn: parent
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onBackground
                    text: Math.round(root.liveTolerance).toString()
                }
            }
        }
    }
}
