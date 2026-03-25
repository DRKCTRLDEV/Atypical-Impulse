import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    required property real screenWidth
    required property real screenHeight
    required property real monitorScale
    required property string screenshotPath

    property real liveTolerance: Config.options.regionSelector.screenRuler.edgeTolerance
    property bool tolIndicatorVisible: false
    property bool screenshotReady: false
    property var edges: ({
            left: 0,
            right: root.screenWidth,
            top: 0,
            bottom: root.screenHeight,
            width: root.screenWidth,
            height: root.screenHeight
        })

    property real pendingMx: 0
    property real pendingMy: 0
    property bool scanPending: false

    function loadScreenshot() {
        pixelCanvas.loadScreenshot();
    }

    Timer {
        id: tolFadeTimer
        interval: 1200
        onTriggered: root.tolIndicatorVisible = false
    }

    Timer {
        id: scanThrottle
        interval: 16
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
        if (!scanThrottle.running)
            scanThrottle.start();
    }

    function adjustTolerance(delta, mx, my) {
        root.liveTolerance = Math.max(0, Math.min(255, root.liveTolerance + delta));
        root.tolIndicatorVisible = true;
        tolFadeTimer.restart();
        root.edges = root.scanEdges(mx, my);
    }

    Canvas {
        id: pixelCanvas
        width: Math.round(root.screenWidth * root.monitorScale)
        height: Math.round(root.screenHeight * root.monitorScale)

        property var pixelData: null
        property var dataArray: null
        property int pw: 0
        property int ph: 0
        property bool ready: false
        property string currentSource: ""

        function loadScreenshot() {
            const src = "file://" + root.screenshotPath;
            if (currentSource === src)
                unloadImage(src);
            currentSource = src;
            loadImage(src);
        }

        onImageLoaded: {
            if (visible)
                requestPaint();
        }

        onPaint: {
            if (!currentSource)
                return;
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

    function scanEdges(mx, my) {
        const d = pixelCanvas.dataArray;
        if (!pixelCanvas.ready || !d)
            return root.edges;

        const scale = root.monitorScale;
        const pw = pixelCanvas.pw;
        const ph = pixelCanvas.ph;
        const tol = root.liveTolerance;
        const perCh = Config.options.regionSelector.screenRuler.perChannelEdge;

        function isEdge(i1, i2) {
            const dr = Math.abs(d[i1] - d[i2]);
            const dg = Math.abs(d[i1 + 1] - d[i2 + 1]);
            const db = Math.abs(d[i1 + 2] - d[i2 + 2]);
            return perCh ? (dr > tol || dg > tol || db > tol) : (dr + dg + db > tol);
        }

        const px = Math.min(Math.max(Math.round(mx * scale), 1), pw - 2);
        const py = Math.min(Math.max(Math.round(my * scale), 1), ph - 2);
        const rowBytes = pw << 2;

        let left = 0;
        for (let x = px; x > 0; x--) {
            if (isEdge((py * pw + x) << 2, (py * pw + x - 1) << 2)) { left = x / scale; break; }
        }
        let right = root.screenWidth;
        for (let x = px; x < pw - 1; x++) {
            if (isEdge((py * pw + x) << 2, (py * pw + x + 1) << 2)) { right = (x + 1) / scale; break; }
        }
        let top = 0;
        for (let y = py; y > 0; y--) {
            if (isEdge((y * pw + px) << 2, ((y - 1) * pw + px) << 2)) { top = y / scale; break; }
        }
        let bottom = root.screenHeight;
        for (let y = py; y < ph - 1; y++) {
            if (isEdge((y * pw + px) << 2, ((y + 1) * pw + px) << 2)) { bottom = (y + 1) / scale; break; }
        }

        return { left, right, top, bottom, width: right - left, height: bottom - top };
    }
}
