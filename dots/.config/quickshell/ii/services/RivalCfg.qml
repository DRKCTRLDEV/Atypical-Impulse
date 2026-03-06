pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool available: false
    property string errorMessage: ""
    property bool needsUdevInstall: false

    property string deviceName: ""
    property string devicePid: ""
    property string connectionType: ""

    property bool hasBattery: false
    property int batteryLevel: 100
    property bool isCharging: false

    // Applied state (reflects what's on the device)
    property var appliedSensitivity: []
    property var appliedBindings: ({})

    property var availableButtons: []

    property bool hasSensitivity: false
    property bool hasButtons: false
    property var sensitivityRange: ({min:100, max:18000})

    readonly property string venvPath: "/home/alfie/.local/state/quickshell/.venv"
    readonly property string wrapperScript: Qt.resolvedUrl("../scripts/rivalcfg/rivalcfg_wrapper.py").toString().replace("file://","")

    signal settingsApplied()
    signal settingsError(string error)
    signal settingsLoaded()
    signal settingsReset()

    function looksLikeFactoryDefaults(p) {
        return !p || !p.length || p.every(function(v) { return typeof v === "number" && v >= 400 && v % 400 === 0 })
    }

    onActiveChanged: if (active) refresh()

    function refresh() {
        if (!active) return
        errorMessage = ""
        run(["detect"], onDetect)
    }

    function applyAll(sens, bindings) {
        var payload = {}
        if (sens && sens.length > 0) payload.sensitivity = sens
        if (bindings && Object.keys(bindings).length > 0) payload.buttons = bindings
        if (Object.keys(payload).length === 0) return
        var capturedSens = sens ? sens.slice() : []
        var capturedBindings = bindings ? Object.assign({}, bindings) : {}
        run(["apply-all", JSON.stringify(payload)], function(data) {
            var r = parseJson(data)
            if (r && r.success) {
                if (capturedSens.length > 0) appliedSensitivity = capturedSens
                if (Object.keys(capturedBindings).length > 0) appliedBindings = capturedBindings
                settingsApplied()
            } else {
                settingsError(r ? r.error || "Failed" : "Failed")
            }
        })
    }

    function resetToDefaults() { run(["reset"], onReset) }
    function installUdevRules() { installUdevProc.running = true }

    // DRY runner with safe arg passing (sh -c 'exec ... "$@"' sh args...)
    Component {
        id: procComp
        Process {
            property string out: ""
            stdout: SplitParser { onRead: function(d) { out += d } }
            stderr: SplitParser { onRead: function(d) { if (d.trim()) console.warn("[RivalCfg]", d) } }
        }
    }

    function run(args, onDone) {
        var baseCmd = "source " + venvPath + "/bin/activate && exec python3 " + wrapperScript + " \"$@\""
        var cmd = ["/bin/sh", "-c", baseCmd, "sh"].concat(args)
        var p = procComp.createObject(root, {command: cmd})
        p.running = true
        p.onExited.connect(function() {
            onDone(p.out)
            p.destroy()
        })
    }

    // Callbacks (unchanged)
    function onDetect(data) {
        var r = parseJson(data)
        if (!r) { return }
        if (r.available) {
            available = true
            needsUdevInstall = false
            deviceName = r.device.name || ""
            devicePid = r.device.pid || ""
            connectionType = r.device.connection_type || "unknown"
            hasBattery = r.battery.supported || false
            batteryLevel = r.battery.level || 100
            isCharging = r.battery.is_charging || false
            hasSensitivity = r.capabilities.has_sensitivity || false
            hasButtons = r.capabilities.has_buttons || false
            availableButtons = (r.capabilities.buttons || []).length > 0 ? r.capabilities.buttons : ["Button1","Button2","Button3","Button4","Button5","Button6","Button7","Button8","Button9"]
            sensitivityRange = r.capabilities.sensitivity_range || {min:100, max:18000}
            run(["settings"], onSettings)
            return
        }
        available = false
        needsUdevInstall = r.needs_udev_install || false
        errorMessage = r.error || "No SteelSeries mouse detected."
    }

    function onSettings(data) {
        var r = parseJson(data)
        if (r && r.success && r.settings) {
            var sp = r.settings.sensitivity || []
            if (sp.length > 0) {
                // Keep applied settings if device reports factory-like defaults
                // (some devices can't report back modified settings)
                if (appliedSensitivity.length === 0 || !looksLikeFactoryDefaults(sp))
                    appliedSensitivity = sp
            }
            if (r.settings.buttons && Object.keys(r.settings.buttons).length > 0)
                appliedBindings = r.settings.buttons
        }
        settingsLoaded()
        if (hasBattery) batteryTimer.running = true
    }

    function onReset(data) {
        var r = parseJson(data)
        if (r && r.success) {
            appliedSensitivity = [800, 1600, 3200]
            appliedBindings = {}
            settingsReset()
        } else settingsError(r ? r.error || "Reset failed" : "Reset failed")
    }

    function parseJson(d) {
        try { return JSON.parse(d) } catch(e) { console.error("[RivalCfg] JSON fail:", e); return null }
    }

    // Battery poll
    Process {
        id: batteryProc
        command: ["/bin/sh", "-c", "source " + venvPath + "/bin/activate && exec python3 " + wrapperScript + " battery"]
        stdout: SplitParser { onRead: function(d) { batteryProc.out += d } }
        property string out: ""
        onExited: {
            var r = parseJson(out)
            if (r && r.supported) {
                hasBattery = true
                batteryLevel = r.level || 100
                isCharging = r.is_charging || false
            }
            out = ""
        }
    }

    // Udev install (added back prompt if needsUdevInstall - already in error loader)
    Process {
        id: installUdevProc
        command: ["/bin/sh", "-c", `if [ -x "${venvPath}/bin/rivalcfg" ]; then pkexec "${venvPath}/bin/rivalcfg" --update-udev; else pkexec rivalcfg --update-udev; fi`]
        onExited: {
            if (exitCode === 0) { errorMessage = ""; Qt.callLater(refresh) }
            else errorMessage = "Failed to install udev rules. Run 'sudo rivalcfg --update-udev' manually."
        }
    }

    Timer {
        id: batteryTimer
        interval: 10000
        repeat: true
        onTriggered: batteryProc.running = true
    }
}