pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.mouseConfig
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop
    radius: Appearance.rounding.small
    color: Appearance.colors.colLayer2
    implicitHeight: settingsCol.implicitHeight + 24

    property string listeningButton: ""
    property string capturedButton: ""
    property string capturedAction: ""
    property int maxDpi: Config.options.sidebar.mouseConfig.maxDpi
    property var editablePresets: RivalCfg.appliedSensitivity && RivalCfg.appliedSensitivity.length > 0 ? RivalCfg.appliedSensitivity.slice() : [800, 1600, 3200]
    property var editableBindings: Object.assign({}, RivalCfg.appliedBindings)
    property int selectedIndex: 0
    readonly property bool dirty: JSON.stringify(editablePresets) !== JSON.stringify(RivalCfg.appliedSensitivity)
        || JSON.stringify(editableBindings) !== JSON.stringify(RivalCfg.appliedBindings)

    signal startListening(string button)
    signal stopListening
    signal captureProcessed

    onCapturedButtonChanged: {
        if (capturedButton && capturedAction) {
            updateBinding(capturedButton, capturedAction)
            captureProcessed()
        }
    }

    function syncFromApplied() {
        editablePresets = RivalCfg.appliedSensitivity.length > 0 ? RivalCfg.appliedSensitivity.slice() : [800, 1600, 3200]
        editableBindings = Object.assign({}, RivalCfg.appliedBindings)
        selectedIndex = Math.min(selectedIndex, Math.max(0, editablePresets.length - 1))
    }

    function updateBinding(btn, action) {
        var b = Object.assign({}, editableBindings)
        b[btn] = action
        editableBindings = b
    }

    function applyChanges() {
        RivalCfg.applyAll(editablePresets, editableBindings)
    }

    function revertChanges() {
        syncFromApplied()
    }

    Connections {
        target: RivalCfg
        function onSettingsLoaded() { root.syncFromApplied() }
        function onSettingsReset() { root.syncFromApplied() }
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            var roundedValue = Math.round(dpiSlider.value)
            if (editablePresets[selectedIndex] !== roundedValue) {
                var np = editablePresets.slice()
                np[selectedIndex] = roundedValue
                editablePresets = np
            }
        }
    }

    ColumnLayout {
        id: settingsCol
        anchors.fill: parent
        anchors.margins: 12

        // DPI Section
        StyledSlider {
            id: dpiSlider
            configuration: StyledSlider.Configuration.M
            from: 100; to: root.maxDpi; stepSize: 50
            value: editablePresets[selectedIndex] !== undefined ? editablePresets[selectedIndex] : 800
            tooltipContent: Math.round(value) + " DPI"
            onMoved: debounce.restart()
            onPressedChanged: if (!pressed && debounce.running) { debounce.stop(); debounce.triggered() }
        }

        Flickable {
            Layout.fillWidth: true
            implicitHeight: presetRow.implicitHeight
            contentWidth: presetRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Row {
                id: presetRow
                spacing: 4
                Repeater {
                    model: editablePresets
                    delegate: PresetChip {
                        required property var modelData
                        required property int index
                        dpiValue: modelData
                        presetIndex: index
                        isSelected: root.selectedIndex === index
                        leftmost: index === 0
                        rightmost: index === editablePresets.length - 1
                        onPresetSelected: function(idx) {
                            root.selectedIndex = idx
                        }
                        onPresetRemoveRequested: function(idx) {
                            if (editablePresets.length <= 1) return
                            var np = editablePresets.slice()
                            np.splice(idx, 1)
                            editablePresets = np
                            if (root.selectedIndex >= idx && root.selectedIndex > 0) {
                                root.selectedIndex--
                            }
                        }
                    }
                }
                GroupButton {
                    id: addPresetButton
                    baseWidth: 36; baseHeight: 36
                    bounce: false
                    buttonRadius: Appearance.rounding.full
                    enabled: editablePresets.length < 5
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "add"
                        iconSize: Appearance.font.pixelSize.larger + 2
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    onClicked: {
                        var last = editablePresets[editablePresets.length - 1] || 800
                        var nv = Math.min(last + 400, root.maxDpi)
                        while (editablePresets.includes(nv) && nv < root.maxDpi) nv += 50
                        if (editablePresets.includes(nv)) {
                            nv = Math.max(100, last - 400)
                            while (editablePresets.includes(nv) && nv > 100) nv -= 50
                        }
                        if (editablePresets.includes(nv)) return
                        var np = editablePresets.slice()
                        np.push(nv)
                        np.sort((a,b)=>a-b)
                        editablePresets = np
                        root.selectedIndex = np.indexOf(nv)
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.margins: 6; implicitHeight: 1; color: Appearance.colors.colLayer3 }

        // Bind Section
        ColumnLayout {
            spacing: 6

            Repeater {
                model: RivalCfg.availableButtons
                delegate: ButtonBindingRow {
                    required property string modelData
                    buttonId: modelData
                    currentAction: root.editableBindings[modelData] || KeyLib.getDefaultAction(modelData)
                    actionDisplay: KeyLib.getActionDisplay(currentAction)
                    isListening: root.listeningButton === modelData
                    availableActions: KeyLib.getAvailableActionsForButton(modelData, currentAction)
                    onStartListeningClicked: root.startListening(modelData)
                    onActionSelected: function(a) { root.updateBinding(modelData, a) }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.margins: 6; implicitHeight: 1; color: Appearance.colors.colLayer3 }

            // Apply / Revert / Reset row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    materialIcon: "check"
                    enabled: root.dirty
                    mainText: "Apply configuration"
                    onClicked: root.applyChanges()
                }
                GroupButton {
                    baseWidth: 36; baseHeight: 36
                    bounce: false
                    enabled: root.dirty
                    contentItem: MaterialSymbol {
                        text: "undo"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    onClicked: root.revertChanges()
                    StyledToolTip { text: "Undo changes" }
                }
                GroupButton {
                    baseWidth: 36; baseHeight: 36
                    bounce: false
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    contentItem: MaterialSymbol {
                        text: "restart_alt"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                    onClicked: RivalCfg.resetToDefaults()
                    StyledToolTip { text: "Reset to factory defaults" }
                }
            }
        }
    }

    component ButtonBindingRow: RowLayout {
        property string buttonId: ""
        property string currentAction: ""
        property string actionDisplay: ""
        property bool isListening: false
        property var availableActions: []
        signal startListeningClicked
        signal actionSelected(string action)
        spacing: 6
        StyledComboBox {
            implicitHeight: 36
            buttonRadius: Appearance.rounding.small
            enabled: !isListening
            model: availableActions
            textRole: "displayText"
            valueRole: "value"
            currentIndex: { var idx = model.findIndex(function(i) { return i.value === currentAction }); return idx !== -1 ? idx : 0 }
            onActivated: function(idx) { var a = model[idx].value; if (a !== currentAction) actionSelected(a) }
        }
        GroupButton {
            baseWidth: 36; baseHeight: 36
            bounce: false
            colBackground: isListening ? Appearance.colors.colError : Appearance.colors.colSecondaryContainer
            colBackgroundHover: isListening ? Appearance.colors.colErrorContainerHover : Appearance.colors.colSecondaryContainerHover
            colBackgroundActive: isListening ? Appearance.colors.colErrorContainerActive : Appearance.colors.colSecondaryContainerActive
            contentItem: MaterialSymbol {
                text: isListening ? "stop" : "fiber_manual_record"
                color: isListening ? Appearance.colors.colOnError : Appearance.colors.colOnSecondaryContainer
                iconSize: Appearance.font.pixelSize.larger
                fill: isListening ? 1 : 0
            }
            onClicked: isListening ? root.stopListening() : startListeningClicked()
            StyledToolTip { text: isListening ? "Stop recording" : "Record key binding" }
        }
    }
}