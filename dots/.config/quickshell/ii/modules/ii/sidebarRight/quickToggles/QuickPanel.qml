pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root
    property bool editMode: false
    Layout.fillWidth: true

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()

    // Model factory — registered once per panel, not per button
    Component { id: cNetwork;           NetworkToggle {}          }
    Component { id: cBluetooth;         BluetoothToggle {}        }
    Component { id: cDarkMode;          DarkModeToggle {}         }
    Component { id: cAudio;             AudioToggle {}            }
    Component { id: cMic;               MicToggle {}              }
    Component { id: cNightLight;        NightLightToggle {}       }
    Component { id: cPowerProfile;      PowerProfilesToggle {}    }
    Component { id: cEasyEffects;       EasyEffectsToggle {}      }
    Component { id: cIdleInhibitor;     IdleInhibitorToggle {}    }
    Component { id: cCloudflareWarp;    CloudflareWarpToggle {}   }
    Component { id: cNotifications;     NotificationToggle {}     }
    Component { id: cColorPicker;       ColorPickerToggle {}      }
    Component { id: cOnScreenKeyboard;  OnScreenKeyboardToggle {} }
    Component { id: cScreenSnip;        ScreenSnipToggle {}       }
    Component { id: cGameMode;          GameModeToggle {}         }
    Component { id: cAntiFlashbang;     AntiFlashbangToggle {}    }
    Component { id: cMusicRecognition;  MusicRecognitionToggle {} }

    readonly property var _modelComponents: ({
        "network":          cNetwork,
        "bluetooth":        cBluetooth,
        "darkMode":         cDarkMode,
        "audio":            cAudio,
        "mic":              cMic,
        "nightLight":       cNightLight,
        "powerProfile":     cPowerProfile,
        "easyEffects":      cEasyEffects,
        "idleInhibitor":    cIdleInhibitor,
        "cloudflareWarp":   cCloudflareWarp,
        "notifications":    cNotifications,
        "colorPicker":      cColorPicker,
        "onScreenKeyboard": cOnScreenKeyboard,
        "screenSnip":       cScreenSnip,
        "gameMode":         cGameMode,
        "antiFlashbang":    cAntiFlashbang,
        "musicRecognition": cMusicRecognition,
    })

    function _makeModel(type, parent) {
        const comp = root._modelComponents[type];
        return comp ? comp.createObject(parent) : null;
    }

    // Sizes
    implicitHeight: (editMode ? contentItem.implicitHeight : usedRows.implicitHeight) + root.padding * 2
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    property real spacing: 6
    property real padding: 6
    readonly property real baseCellWidth: {
        // This is the wrong calculation, but it looks correct in reality???
        // (theoretically spacing should be multiplied by 1 column less)
        const availableWidth = root.width - (root.padding * 2) - (root.spacing * (root.columns))
        return availableWidth / root.columns
    }
    readonly property real baseCellHeight: 56

    // Toggles
    readonly property list<string> availableToggleTypes: ["network", "bluetooth", "idleInhibitor", "easyEffects", "nightLight", "darkMode", "cloudflareWarp", "gameMode", "screenSnip", "colorPicker", "onScreenKeyboard", "mic", "audio", "notifications", "powerProfile","musicRecognition", "antiFlashbang"]
    readonly property int columns: Config.options.sidebar.quickToggles.columns
    readonly property list<var> toggles: Config.ready ? Config.options.sidebar.quickToggles.toggles : []
    readonly property list<var> toggleRows: toggleRowsForList(toggles)
    readonly property list<var> unusedToggles: {
        const types = availableToggleTypes.filter(type => !toggles.some(toggle => (toggle && toggle.type === type)))
        return types.map(type => { return { type: type, size: 1 } })
    }
    readonly property list<var> unusedToggleRows: toggleRowsForList(unusedToggles)

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0;
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            if (totalSize + togglesList[i].size > columns) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            row.push(togglesList[i]);
            totalSize += togglesList[i].size;
        }
        if (row.length > 0) {
            rows.push(row);
        }
        return rows;
    }

    // Menu signal routing
    function _routeMenuDialog(type) {
        switch (type) {
            case "audio": root.openAudioOutputDialog(); break;
            case "bluetooth": root.openBluetoothDialog(); break;
            case "mic": root.openAudioInputDialog(); break;
            case "network": root.openWifiDialog(); break;
            case "nightLight":
            case "antiFlashbang": root.openNightLightDialog(); break;
        }
    }

    Column {
        id: contentItem
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 12

        Column {
            id: usedRows
            spacing: root.spacing

            Repeater {
                id: usedRowsRepeater
                model: ScriptModel {
                    values: Array(root.toggleRows.length)
                }
                delegate: ButtonGroup {
                    id: toggleRow
                    required property int index
                    property var modelData: root.toggleRows[index]
                    property int startingIndex: {
                        const rows = root.toggleRows;
                        let sum = 0;
                        for (let i = 0; i < index; i++) {
                            sum += rows[i].length;
                        }
                        return sum;
                    }
                    spacing: root.spacing

                    Repeater {
                        model: ScriptModel {
                            values: toggleRow?.modelData ?? []
                            objectProp: "type"
                        }
                        delegate: QuickToggleButton {
                            required property int index
                            required property var modelData
                            buttonIndex: toggleRow.startingIndex + index
                            buttonData: modelData
                            editMode: root.editMode
                            expandedSize: modelData.size > 1
                            baseCellWidth: root.baseCellWidth
                            baseCellHeight: root.baseCellHeight
                            cellSpacing: root.spacing
                            cellSize: modelData.size
                            onOpenMenu: root._routeMenuDialog(modelData.type)
                            Component.onCompleted: toggleModel = root._makeModel(modelData.type, this)
                        }
                    }
                }
            }
        }

        FadeLoader {
            shown: root.editMode
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: root.baseCellHeight / 2
                rightMargin: root.baseCellHeight / 2
            }
            sourceComponent: Rectangle {
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
            }
        }

        FadeLoader {
            shown: root.editMode
            sourceComponent: Column {
                id: unusedRows
                spacing: root.spacing

                Repeater {
                    model: ScriptModel {
                        values: Array(root.unusedToggleRows.length)
                    }
                    delegate: ButtonGroup {
                        id: unusedToggleRow
                        required property int index
                        property var modelData: root.unusedToggleRows[index]
                        spacing: root.spacing

                        Repeater {
                            model: ScriptModel {
                                values: unusedToggleRow?.modelData ?? []
                                objectProp: "type"
                            }
                            delegate: QuickToggleButton {
                                required property int index
                                required property var modelData
                                buttonIndex: -1
                                buttonData: modelData
                                editMode: root.editMode
                                expandedSize: modelData.size > 1
                                baseCellWidth: root.baseCellWidth
                                baseCellHeight: root.baseCellHeight
                                cellSpacing: root.spacing
                                cellSize: modelData.size
                                Component.onCompleted: toggleModel = root._makeModel(modelData.type, this)
                            }
                        }
                    }
                }
            }
        }
    }
}
