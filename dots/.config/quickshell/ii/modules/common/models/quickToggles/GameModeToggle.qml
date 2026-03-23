import QtQuick
import qs.modules.common
import qs.modules.common.models.hyprland
import qs.services

QuickToggleModel {
    name: Translation.tr("Game mode")
    toggled: !confOpt.value
    icon: "gamepad"

    property int previousCornerStyle: 0

    mainAction: () => {
        if (confOpt.value) {
            previousCornerStyle = Config.options.bar.cornerStyle;
            Config.options.bar.cornerStyle = 2;
            HyprlandConfig.setMany({
                "animations:enabled": 0,
                "decoration:shadow:enabled": 0,
                "decoration:blur:enabled": 0,
                "general:gaps_in": 0,
                "general:gaps_out": 0,
                "general:border_size": 1,
                "decoration:rounding": 0,
                "general:allow_tearing": 1
            });
        } else {
            Config.options.bar.cornerStyle = previousCornerStyle;
            HyprlandConfig.resetMany(["animations:enabled", "decoration:shadow:enabled", "decoration:blur:enabled", "general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "general:allow_tearing"]);
        }
    }

    HyprlandConfigOption {
        id: confOpt
        key: "animations:enabled"
    }

    tooltipText: Translation.tr("Game mode")
}
