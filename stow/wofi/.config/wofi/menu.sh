#!/bin/bash

choice=$(printf '%s\n' \
    '󰀻  Applications' \
    '󰸉  Wallpaper' \
    '󰘳  Utilities' \
    '󰈆  Kill application' \
    '󰩹  Trash' \
    '󰌾  Lock screen' \
    '󰍃  Log out' \
    '⏻  Shutdown' \
    '󰜉  Reboot' |
    wofi --dmenu --prompt "Night City" --cache-file /dev/null)

case "$choice" in
    '󰀻  Applications')
        wofi --show drun
        ;;

    '󰸉  Wallpaper')
        wallpaper=$(find "$HOME/Pictures/Wallpapers" \
            -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) |
            while read -r file; do
                basename "$file"
            done |
            sort |
            wofi --dmenu --prompt "Wallpaper")

        if [ -n "$wallpaper" ]; then
            wallpaper_path="$HOME/Pictures/Wallpapers/$wallpaper"
            hyprctl hyprpaper wallpaper ",$wallpaper_path"
        fi
        ;;

    '󰘳  Utilities')
        utility=$(printf '%s\n' \
            '󰤨  Wi-Fi' \
            '󰂯  Bluetooth' \
            '󰃬  Calculator' \
	    '󰆼  Clear Cache' |
            wofi --dmenu --prompt "Utilities")

        case "$utility" in
            '󰤨  Wi-Fi')
		~/.config/wofi/wifi.sh
                ;;

            '󰂯  Bluetooth')
		GTK_THEME=NightCity blueman-manager
                ;;

            '󰖔  Dark mode')
                ;;

            '󰃬  Calculator')
		kitty --title "Calculator" qalc
                ;;

	    '󰆼  Clear Cache')
                kitty --title "Cache Cleaner" ~/.local/bin/clear-cache
                ;;
        esac
        ;;

    '󰩹  Trash')
        kitty --title "Trash" yazi ~/.local/share/Trash/files
        ;;

    '󰈆  Kill application')
        ~/.config/wofi/kill-app.sh
        ;;

    '󰌾  Lock screen')
        hyprlock
        ;;

    '󰍃  Log out')
	loginctl terminate-session "$XDG_SESSION_ID"
        ;;

    '⏻  Shutdown')
        systemctl poweroff
        ;;

    '󰜉  Reboot')
        systemctl reboot
        ;;
esac
