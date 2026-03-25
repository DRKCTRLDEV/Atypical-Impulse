import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    fillWidth: true

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Cheat sheet")

        ContentSubsection {
            title: Translation.tr("Super key symbol")
            tooltip: Translation.tr("You can also manually edit cheatsheet.superKey")
            ConfigSelectionArray {
                currentValue: Config.options.cheatsheet.superKey
                onSelected: newValue => {
                    Config.options.cheatsheet.superKey = newValue;
                }
                // Use a nerdfont to see the icons
                options: (["󰖳", "", "󰨡", "", "󰌽", "󰣇", "", "", "", "", "", "󱄛", "", "", "", "⌘", "󰀲", "󰟍", ""]).map(icon => {
                    return {
                        displayName: icon,
                        value: icon
                    };
                })
            }
        }

        ConfigSwitch {
            buttonIcon: "󰘵"
            text: Translation.tr("Use macOS-like symbols for mods keys")
            checked: Config.options.cheatsheet.macSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.macSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("e.g. 󰘴  for Ctrl, 󰘵  for Alt, 󰘶  for Shift, etc")
            }
        }

        ConfigSwitch {
            buttonIcon: "󱊶"
            text: Translation.tr("Use symbols for function keys")
            checked: Config.options.cheatsheet.fnSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.fnSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("e.g. 󱊫 for F1, 󱊶  for F12")
            }
        }
        ConfigSwitch {
            buttonIcon: "󰍽"
            text: Translation.tr("Use symbols for mouse")
            checked: Config.options.cheatsheet.mouseSymbol
            onCheckedChanged: {
                Config.options.cheatsheet.mouseSymbol = checked;
            }
            StyledToolTip {
                text: Translation.tr("Replace 󱕐   for \"Scroll ↓\", 󱕑   \"Scroll ↑\", L󰍽   \"LMB\", R󰍽   \"RMB\", 󱕒   \"Scroll ↑/↓\" and ⇞/⇟ for \"Page_↑/↓\"")
            }
        }
        ConfigSwitch {
            buttonIcon: "highlight_keyboard_focus"
            text: Translation.tr("Split buttons")
            checked: Config.options.cheatsheet.splitButtons
            onCheckedChanged: {
                Config.options.cheatsheet.splitButtons = checked;
            }
            StyledToolTip {
                text: Translation.tr("Display modifiers and keys in multiple keycap (e.g., \"Ctrl + A\" instead of \"Ctrl A\" or \"󰘴 + A\" instead of \"󰘴 A\")")
            }
        }

        ConfigSpinBox {
            text: Translation.tr("Keybind font size")
            value: Config.options.cheatsheet.fontSize.key
            from: 8
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.cheatsheet.fontSize.key = value;
            }
        }
        ConfigSpinBox {
            text: Translation.tr("Description font size")
            value: Config.options.cheatsheet.fontSize.comment
            from: 8
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.cheatsheet.fontSize.comment = value;
            }
        }
    }
    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            enabled: Config.options.dock.enable
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
        ConfigSwitch {
            enabled: Config.options.dock.enable
            buttonIcon: "colors"
            text: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
        }
        ConfigSwitch {
            enabled: Config.options.dock.enable
            buttonIcon: "keep"
            text: Translation.tr("Show pin button")
            checked: Config.options.dock.pinButton
            onCheckedChanged: {
                Config.options.dock.pinButton = checked;
            }
        }
        ConfigSwitch {
            enabled: Config.options.dock.enable
            buttonIcon: "apps"
            text: Translation.tr("Show launcher button")
            checked: Config.options.dock.launcherButton
            onCheckedChanged: {
                Config.options.dock.launcherButton = checked;
            }
        }
    }

    ContentSection {
        icon: "play_circle"
        title: Translation.tr("Media")
        ConfigSwitch {
            buttonIcon: "filter_alt"
            text: Translation.tr("Filter duplicate players")
            checked: Config.options.media.filterDuplicatePlayers
            onCheckedChanged: {
                Config.options.media.filterDuplicatePlayers = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hide duplicate MPRIS players (e.g. browser + plasma integration)")
            }
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock screen")

        ConfigSwitch {
            buttonIcon: "water_drop"
            text: Translation.tr('Use Hyprlock (instead of Quickshell)')
            checked: Config.options.lock.hyprlock
            onCheckedChanged: {
                Config.options.lock.hyprlock = checked;
            }
            StyledToolTip {
                text: Translation.tr("If you want to somehow use fingerprint unlock...")
            }
        }

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: Translation.tr('Launch on startup')
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
        }

        ConfigRow {
            uniform: true
            enabled: !Config.options.lock.hyprlock
            ConfigSwitch {
                buttonIcon: "schedule"
                text: Translation.tr('Show clock')
                checked: Config.options.lock.clock
                onCheckedChanged: {
                    Config.options.lock.clock = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "calendar_month"
                text: Translation.tr('Show date')
                enabled: Config.options.lock.clock
                checked: Config.options.lock.date
                onCheckedChanged: {
                    Config.options.lock.date = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: Translation.tr('Require password to power off/restart')
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
                }
            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: Translation.tr('Also unlock keyring')
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }
                StyledToolTip {
                    text: Translation.tr("This is usually safe and needed for your browser anyways. \nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: general")

            ConfigSwitch {
                buttonIcon: "shapes"
                text: Translation.tr('Use varying shapes for password characters')
                checked: Config.options.lock.materialShapeChars
                onCheckedChanged: {
                    Config.options.lock.materialShapeChars = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Style: Blurred")

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr('Enable blur')
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
            }

            ConfigSpinBox {
                enabled: Config.options.lock.blur.enable
                buttonIcon: "loupe"
                text: Translation.tr("Extra wallpaper zoom (%)")
                value: Config.options.lock.blur.extraZoom * 100
                from: 1
                to: 150
                stepSize: 2
                onValueChanged: {
                    Config.options.lock.blur.extraZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ConfigSpinBox {
            buttonIcon: "av_timer"
            text: Translation.tr("Timeout duration (if not defined by notification) (ms)")
            value: Config.options.notifications.timeout
            from: 1000
            to: 60000
            stepSize: 1000
            onValueChanged: {
                Config.options.notifications.timeout = value;
            }
        }
    }

    ContentSection {
        icon: "select_window"
        title: Translation.tr("Overlay: General")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "high_density"
                text: Translation.tr("Zoom animation")
                checked: Config.options.overlay.openingZoomAnimation
                onCheckedChanged: {
                    Config.options.overlay.openingZoomAnimation = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Scale animation when opening the overlay")
                }
            }
            ConfigSwitch {
                buttonIcon: "texture"
                text: Translation.tr("Darken screen")
                checked: Config.options.overlay.darkenScreen
                onCheckedChanged: {
                    Config.options.overlay.darkenScreen = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Dim the screen behind open widgets")
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "format_align_justify"
                text: Translation.tr("Show arrange button")
                checked: Config.options.overlay.showArrangeButton
                onCheckedChanged: {
                    Config.options.overlay.showArrangeButton = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Show the arrange button in the overlay taskbar")
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: Translation.tr("Gaps out (edge margin)")
                value: Config.options.overlay.gapsOut
                from: 0
                to: 200
                stepSize: 2
                onValueChanged: {
                    Config.options.overlay.gapsOut = value;
                }
                StyledToolTip {
                    text: Translation.tr("Space between widgets and screen edges (added on top of bar size)")
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Gaps in (widget gap)")
                value: Config.options.overlay.gapsIn
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.overlay.gapsIn = value;
                }
                StyledToolTip {
                    text: Translation.tr("Space between widgets when arranging")
                }
            }
        }
    }

    ContentSection {
        icon: "point_scan"
        title: Translation.tr("Overlay: Crosshair")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
            text: Config.options.crosshair.code
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.crosshair.code = text;
            }
        }

        RowLayout {
            StyledText {
                Layout.leftMargin: 10
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                text: Translation.tr("Press Super+G to open the overlay and pin the crosshair")
            }
            Item {
                Layout.fillWidth: true
            }
            RippleButton {
                id: editorButton
                buttonRadius: Appearance.rounding.full
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open editor")
                onClicked: {
                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                }
                StyledToolTip {
                    text: "www.vcrdb.net"
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_frame_2"
        title: Translation.tr("Region selector (screen snipping/Image Search)")

        ContentSubsection {
            title: Translation.tr("Hint target regions")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "select_window"
                    text: Translation.tr('Windows')
                    checked: Config.options.regionSelector.targetRegions.windows
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.windows = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "right_panel_open"
                    text: Translation.tr('Layers')
                    checked: Config.options.regionSelector.targetRegions.layers
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.layers = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "nearby"
                    text: Translation.tr('Content')
                    checked: Config.options.regionSelector.targetRegions.content
                    onCheckedChanged: {
                        Config.options.regionSelector.targetRegions.content = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally.")
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Image Search")

            ConfigSelectionArray {
                currentValue: Config.options.regionSelector.circleSelection ? "circle" : "rectangles"
                onSelected: newValue => {
                    Config.options.regionSelector.circleSelection = (newValue === "circle");
                }
                options: [
                    {
                        icon: "activity_zone",
                        value: "rectangles",
                        displayName: Translation.tr("Rectangular selection")
                    },
                    {
                        icon: "gesture",
                        value: "circle",
                        displayName: Translation.tr("Circle to Search")
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Rectangular selection")

            ConfigSwitch {
                buttonIcon: "point_scan"
                text: Translation.tr("Show aim lines")
                checked: Config.options.regionSelector.rect.aimLines
                onCheckedChanged: {
                    Config.options.regionSelector.rect.aimLines = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Circle selection")

            ConfigSpinBox {
                buttonIcon: "eraser_size_3"
                text: Translation.tr("Stroke width")
                value: Config.options.regionSelector.circle.strokeWidth
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.circle.strokeWidth = value;
                }
            }

            ConfigSpinBox {
                buttonIcon: "screenshot_frame_2"
                text: Translation.tr("Padding")
                value: Config.options.regionSelector.circle.padding
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.regionSelector.circle.padding = value;
                }
            }
        }
    }

    ContentSection {
        icon: "straighten"
        title: Translation.tr("Screen Ruler")

        ContentSubsection {
            title: Translation.tr("General")

            ConfigSpinBox {
                buttonIcon: "straighten"
                text: Translation.tr("Default mode")
                value: Config.options.regionSelector.screenRuler.defaultMode
                from: 0
                to: 2
                stepSize: 1
                onValueChanged: {
                    Config.options.regionSelector.screenRuler.defaultMode = value;
                }
                StyledToolTip {
                    text: Translation.tr("0=Crosshair, 1=Horizontal, 2=Vertical")
                }
            }

            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Continuous capture")
                checked: Config.options.regionSelector.screenRuler.continuousCapture
                onCheckedChanged: {
                    Config.options.regionSelector.screenRuler.continuousCapture = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Continuously re-grab the screen while the ruler is open")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Edge detection")

            ConfigSpinBox {
                buttonIcon: "tune"
                text: Translation.tr("Edge tolerance")
                value: Config.options.regionSelector.screenRuler.edgeTolerance
                from: 0
                to: 255
                stepSize: 5
                onValueChanged: {
                    Config.options.regionSelector.screenRuler.edgeTolerance = value;
                }
                StyledToolTip {
                    text: Translation.tr("Pixel colour difference threshold for edge detection. Lower = more sensitive. Default: 30")
                }
            }

            ConfigSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Per-channel edge comparison")
                checked: Config.options.regionSelector.screenRuler.perChannelEdge
                onCheckedChanged: {
                    Config.options.regionSelector.screenRuler.perChannelEdge = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Compare R, G, B channels individually instead of summed difference")
                }
            }
        }
    }

    ContentSection {
        icon: "side_navigation"
        title: Translation.tr("Sidebars")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr('Keep right sidebar loaded')
                checked: Config.options.sidebar.keepRightSidebarLoaded
                onCheckedChanged: {
                    Config.options.sidebar.keepRightSidebarLoaded = checked;
                }
                StyledToolTip {
                    text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
                }
            }

            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr('Keep left sidebar loaded')
                checked: Config.options.sidebar.keepLeftSidebarLoaded
                onCheckedChanged: {
                    Config.options.sidebar.keepLeftSidebarLoaded = checked;
                }
                StyledToolTip {
                    text: Translation.tr("When enabled keeps the content of the left sidebar loaded to reduce the delay when opening,\nat the cost of a small amount of consistent RAM usage.")
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "translate"
                text: Translation.tr('Translator')
                checked: Config.options.sidebar.translator.enable
                onCheckedChanged: {
                    Config.options.sidebar.translator.enable = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "123"
                text: Translation.tr("char count")
                checked: Config.options.sidebar.translator.charCount
                onCheckedChanged: {
                    Config.options.sidebar.translator.charCount = checked;
                }
            }

            ConfigSpinBox {
                text: Translation.tr("delay (ms)")
                value: Config.options.sidebar.translator.delay
                from: 100
                to: 5000
                stepSize: 100
                onValueChanged: {
                    Config.options.sidebar.translator.delay = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "mouse"
                text: Translation.tr('MouseCtrl')
                checked: Config.options.sidebar.mouseConfig.enable
                onCheckedChanged: {
                    Config.options.sidebar.mouseConfig.enable = checked;
                }
            }
            ConfigSpinBox {
                enabled: Config.options.sidebar.mouseConfig.enable
                buttonIcon: "speed"
                text: Translation.tr("Max DPI")
                value: Config.options.sidebar.mouseConfig.maxDpi
                from: 1000
                to: 12000
                stepSize: 500
                onValueChanged: {
                    Config.options.sidebar.mouseConfig.maxDpi = value;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "music_note"
            text: Translation.tr('Show media controls in right sidebar')
            checked: Config.options.sidebar.mediaControls
            onCheckedChanged: {
                Config.options.sidebar.mediaControls = checked;
            }
            StyledToolTip {
                text: Translation.tr("Show the media player controls between quick toggles and the notification center in the right sidebar")
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")

            ConfigSpinBox {
                buttonIcon: "splitscreen_left"
                text: Translation.tr("Columns")
                value: Config.options.sidebar.quickToggles.columns
                from: 1
                to: 8
                stepSize: 1
                onValueChanged: {
                    Config.options.sidebar.quickToggles.columns = value;
                }
            }

            ContentSubsection {
                title: Translation.tr("Sliders")
                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "brightness_6"
                        text: Translation.tr("Brightness")
                        checked: Config.options.sidebar.quickSliders.brightness
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.brightness = checked;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "volume_up"
                        text: Translation.tr("Volume")
                        checked: Config.options.sidebar.quickSliders.volume
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.volume = checked;
                        }
                    }

                    ConfigSwitch {
                        buttonIcon: "mic"
                        text: Translation.tr("Microphone")
                        checked: Config.options.sidebar.quickSliders.mic
                        onCheckedChanged: {
                            Config.options.sidebar.quickSliders.mic = checked;
                        }
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Corner open")
                tooltip: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")

                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "highlight_mouse_cursor"
                        text: Translation.tr("Hover to trigger")
                        checked: Config.options.sidebar.cornerOpen.clickless
                        onCheckedChanged: {
                            Config.options.sidebar.cornerOpen.clickless = checked;
                        }

                        StyledToolTip {
                            text: Translation.tr("When this is off you'll have to click")
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "call_made"
                        enabled: Config.options.sidebar.cornerOpen.clickless
                        text: Translation.tr("Absolute")
                        checked: Config.options.sidebar.cornerOpen.clicklessCornerEnd
                        onCheckedChanged: {
                            Config.options.sidebar.cornerOpen.clicklessCornerEnd = checked;
                        }

                        StyledToolTip {
                            text: Translation.tr("Only trigger hover at the absolute corner,\nthe rest of the region can be used for volume/brightness scroll")
                        }
                    }
                    ConfigSpinBox {
                        buttonIcon: "arrow_cool_down"
                        text: Translation.tr("Vertical offset")
                        enabled: Config.options.sidebar.cornerOpen.clickless && Config.options.sidebar.cornerOpen.clicklessCornerEnd
                        value: Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset
                        from: 0
                        to: 20
                        stepSize: 1
                        onValueChanged: {
                            Config.options.sidebar.cornerOpen.clicklessCornerVerticalOffset = value;
                        }
                        MouseArea {
                            id: mouseArea
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            StyledToolTip {
                                extraVisibleCondition: mouseArea.containsMouse
                                text: Translation.tr("Why this is cool:\nFor non-0 values, it won't trigger when you reach the\nscreen corner along the horizontal edge, but it will when\nyou do along the vertical edge")
                            }
                        }
                    }
                }

                ConfigRow {
                    uniform: true
                    ConfigSwitch {
                        buttonIcon: "vertical_align_bottom"
                        text: Translation.tr("Place at bottom")
                        checked: Config.options.sidebar.cornerOpen.bottom
                        onCheckedChanged: {
                            Config.options.sidebar.cornerOpen.bottom = checked;
                        }

                        StyledToolTip {
                            text: Translation.tr("Place the corners to trigger at the bottom")
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "unfold_more_double"
                        text: Translation.tr("Value scroll")
                        checked: Config.options.sidebar.cornerOpen.valueScroll
                        onCheckedChanged: {
                            Config.options.sidebar.cornerOpen.valueScroll = checked;
                        }

                        StyledToolTip {
                            text: Translation.tr("Brightness and volume")
                        }
                    }
                    ConfigSwitch {
                        buttonIcon: "visibility"
                        text: Translation.tr("Visualize")
                        checked: Config.options.sidebar.cornerOpen.visualize
                        onCheckedChanged: {
                            Config.options.sidebar.cornerOpen.visualize = checked;
                        }
                    }
                }
                ConfigRow {
                    uniform: true
                    ConfigSpinBox {
                        buttonIcon: "arrow_range"
                        text: Translation.tr("Region width")
                        value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                        from: 1
                        to: 300
                        stepSize: 1
                        onValueChanged: {
                            Config.options.sidebar.cornerOpen.cornerRegionWidth = value;
                        }
                    }
                    ConfigSpinBox {
                        buttonIcon: "height"
                        text: Translation.tr("Region height")
                        value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                        from: 1
                        to: 300
                        stepSize: 1
                        onValueChanged: {
                            Config.options.sidebar.cornerOpen.cornerRegionHeight = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "voting_chip"
            title: Translation.tr("On-screen display")

            ConfigSpinBox {
                buttonIcon: "av_timer"
                text: Translation.tr("Timeout (ms)")
                value: Config.options.osd.timeout
                from: 100
                to: 3000
                stepSize: 100
                onValueChanged: {
                    Config.options.osd.timeout = value;
                }
            }
        }

        ContentSection {
            icon: "overview_key"
            title: Translation.tr("Overview")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.overview.enable
                onCheckedChanged: {
                    Config.options.overview.enable = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "center_focus_strong"
                text: Translation.tr("Center icons")
                enabled: Config.options.overview.enable
                checked: Config.options.overview.centerIcons
                onCheckedChanged: {
                    Config.options.overview.centerIcons = checked;
                }
            }
            ConfigSpinBox {
                enabled: Config.options.overview.enable
                buttonIcon: "loupe"
                text: Translation.tr("Scale (%)")
                value: Config.options.overview.scale * 100
                from: 1
                to: 100
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.scale = value / 100;
                }
            }
            ConfigRow {
                uniform: true
                enabled: Config.options.overview.enable
                ConfigSpinBox {
                    buttonIcon: "splitscreen_bottom"
                    text: Translation.tr("Rows")
                    value: Config.options.overview.rows
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.overview.rows = value;
                    }
                }
                ConfigSpinBox {
                    buttonIcon: "splitscreen_right"
                    text: Translation.tr("Columns")
                    value: Config.options.overview.columns
                    from: 1
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.overview.columns = value;
                    }
                }
            }
            ConfigRow {
                enabled: Config.options.overview.enable

                ConfigSelectionArray {
                    currentValue: Config.options.overview.orderRightLeft
                    onSelected: newValue => {
                        Config.options.overview.orderRightLeft = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Left to right"),
                            icon: "arrow_forward",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Right to left"),
                            icon: "arrow_back",
                            value: 1
                        }
                    ]
                }

                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignRight

                    ConfigSelectionArray {
                        currentValue: Config.options.overview.orderBottomUp
                        onSelected: newValue => {
                            Config.options.overview.orderBottomUp = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Top-down"),
                                icon: "arrow_downward",
                                value: 0
                            },
                            {
                                displayName: Translation.tr("Bottom-up"),
                                icon: "arrow_upward",
                                value: 1
                            }
                        ]
                    }
                }
            }
        }

        ContentSection {
            icon: "text_format"
            title: Translation.tr("Fonts")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Main font (e.g., Google Sans Flex)")
                    text: Config.options.appearance.fonts.main
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.main = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Numbers font")
                    text: Config.options.appearance.fonts.numbers
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.numbers = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Title font")
                    text: Config.options.appearance.fonts.title
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.title = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Monospace font (e.g., JetBrains Mono NF)")
                    text: Config.options.appearance.fonts.monospace
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.monospace = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Nerd font icons")
                    text: Config.options.appearance.fonts.iconNerd
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.iconNerd = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Reading font (e.g., Readex Pro)")
                    text: Config.options.appearance.fonts.reading
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.reading = text;
                    }
                }
            }

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Expressive font (e.g., Space Grotesk)")
                    text: Config.options.appearance.fonts.expressive
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.appearance.fonts.expressive = text;
                    }
                }
            }
        }
    }
}
