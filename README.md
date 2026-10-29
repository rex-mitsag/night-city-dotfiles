# Night City Dotfiles

A personal Night City-inspired Arch Linux rice built around Hyprland
and Quickshell.

## Components

- Hyprland, Hyprlock, Hypridle and Hyprpaper
- Quickshell shell and audio/network controls
- Kitty terminal and Night City theme
- Wofi launcher, Wi-Fi and power menus
- SwayNC notification center
- CAVA configuration and shaders

## Requirements

Arch Linux, GNU Stow and the packages listed in `packages/required.txt`.

## Install

Review `install.sh` before running it.

Preview the planned changes:

    ./install.sh --dry-run

Install after reviewing the preview:

    ./install.sh

The installer offers to install missing packages and backs up
conflicting configuration directories before linking them.

## Uninstall

    ./uninstall.sh

This removes the managed links and attempts to restore the saved
configuration backup. Review the output before logging out.

## Wallpaper

The original setup expects:

    ~/Pictures/Wallpapers/cyberpunk-city.jpg

Supply your own image or update `~/.config/hypr/hyprpaper.conf`.

## Notes

This project is tailored to the author's setup. Review hardware,
monitor, audio and session settings before using it on another machine.
