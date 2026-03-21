import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    fillWidth: true

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigSwitch {
            buttonIcon: "hardware"
            text: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.appsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.appsAndShell = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: Translation.tr("Qt apps")
            enabled: Config.options.appearance.wallpaperTheming.appsAndShell
            checked: Config.options.appearance.wallpaperTheming.qtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.qtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            buttonIcon: "terminal"
            text: Translation.tr("Terminal")
            enabled: Config.options.appearance.wallpaperTheming.appsAndShell
            checked: Config.options.appearance.wallpaperTheming.terminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.terminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigRow {
            uniform: true
            enabled: Config.options.appearance.wallpaperTheming.terminal
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Force dark mode in terminal")
                checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                onCheckedChanged: {
                    Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Ignored if terminal theming is not enabled")
                }
            }
        }

        ConfigSpinBox {
            enabled: Config.options.appearance.wallpaperTheming.terminal
            buttonIcon: "invert_colors"
            text: Translation.tr("Terminal: Harmony (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
            }
        }
        ConfigSpinBox {
            enabled: Config.options.appearance.wallpaperTheming.terminal
            buttonIcon: "gradient"
            text: Translation.tr("Terminal: Harmonize threshold")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value;
            }
        }
        ConfigSpinBox {
            enabled: Config.options.appearance.wallpaperTheming.terminal
            buttonIcon: "format_color_text"
            text: Translation.tr("Terminal: Foreground boost (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
            }
        }
    }

    ContentSection {
        icon: "healing"
        title: Translation.tr("Hacks")
        ConfigSwitch {
            buttonIcon: "grid_on"
            text: Translation.tr("Dead pixel workaround")
            checked: Config.options.interactions.deadPixelWorkaround.enable
            onCheckedChanged: {
                Config.options.interactions.deadPixelWorkaround.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Fix 1px gap on the right edge in Hyprland")
            }
        }
        ConfigSwitch {
            buttonIcon: "ad"
            text: Translation.tr('Use System File Dialog')
            checked: Config.options.wallpaperSelector.systemFileDialog
            onCheckedChanged: {
                Config.options.wallpaperSelector.systemFileDialog = checked;
            }
        }
    }
}
