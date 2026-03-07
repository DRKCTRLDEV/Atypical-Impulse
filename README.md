# Atypical Impulse (Dots Hyprland)

A minimalist Hyprland configuration forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), focused on simplicity, performance, and clean aesthetics.

## About This Fork

This fork provides a lightweight, fast, and distraction-free desktop experience while preserving the core strengths of the original project.

### Key Differences

- **Minimalist direction**: Anime assets and AI-related components removed
- **Gaming peripheral support**: `RivalCFG` integration for SteelSeries Rival devices
- **Refined UI/UX**:
    - Unified QuickToggles
    - Improved Bottom Widget Group
    - SidebarRight Media Player
- **ScreenRuler**: Measurement tool built with RegionSelector components
- **Bar modularization**: Toggleable/customizable widgets *(planned)*

## Features

- **RivalCFG / MouseConfig** for SteelSeries Rival peripherals
- **SidebarRight Media Player** in the right sidebar
- **Unified QuickToggles** with a consistent modern design
- **Translator** with a clean and intuitive interface
- **ToggleSplit** keybind: ``SUPER + ` ``

## Roadmap

- Bar widget modularization (via `config.qml`, then Settings app)
- Dependency reduction (`systemsettings`, `kde-material-you-colors`)
- Custom colorscheme support
- Redesigned Settings application

## Installation

```bash
git clone https://github.com/drkctrldev/atypical-impulse.git
cd atypical-impulse
./setup install
```

Follow the on-screen prompts to complete installation.

## dots-extra

Optional tweaks are available in the `dots-extra` directory.  
See each subdirectory README for setup instructions.

## License

See the `LICENSE` file and the `licenses/` directory for details.

## Acknowledgements

- [end-4/dots-hyprland (IllogicalImpulse)](https://github.com/end-4/dots-hyprland)
- [Hyprland](https://github.com/hyprwm/Hyprland)
- [QuickShell](https://github.com/QuickShell)
