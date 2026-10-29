#!/bin/bash

# Get Wi-Fi networks
wifi=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list |
    awk -F: '
    {
        mark = ($1 == "*") ? "● " : "○ "
        if ($2 != "")
            print mark $2 "  [" $3 "%]"
    }' |
    sort -u |
    wofi --dmenu --prompt "Wi-Fi")

[ -z "$wifi" ] && exit 0

ssid=$(echo "$wifi" |
    sed -E 's/^[●○] //; s/  \[[0-9]+%\]$//')

# Check NetworkManager connection profile
known=false

if nmcli -t -f NAME connection show |
    grep -Fxq "$ssid"; then
    known=true
fi

# Check whether this network is currently connected
connected=false

if nmcli -t -f NAME connection show --active |
    grep -Fxq "$ssid"; then
    connected=true
fi

# Determine network security
security=$(nmcli -t -f SSID,SECURITY device wifi list |
    awk -F: -v ssid="$ssid" '$1 == ssid {print $2; exit}')

# Build action menu
if [ "$connected" = true ]; then

    action=$(printf '%s\n' \
        '󰋼  Status' \
        '󰤭  Disconnect' \
        '󰆴  Forget' |
        wofi --dmenu --prompt "$ssid")

elif [ "$known" = true ]; then

    action=$(printf '%s\n' \
        '󰋼  Status' \
        '󰆴  Forget' |
        wofi --dmenu --prompt "$ssid")

else

    action=$(printf '%s\n' \
        '󰋼  Status' \
        '󰤨  Connect' |
        wofi --dmenu --prompt "$ssid")

fi

[ -z "$action" ] && exit 0

case "$action" in

    '󰋼  Status')
        status=$(nmcli device wifi show-password 2>/dev/null)

        if [ -z "$status" ]; then
            status=$(nmcli connection show "$ssid" 2>/dev/null)
        fi

        printf '%s\n' "$status" |
            wofi --dmenu --prompt "Status"
        ;;

    '󰤨  Connect')
        if [ -n "$security" ]; then

            password=$(printf '' |
                wofi --dmenu \
                    --prompt "Password" \
                    --password)

            [ -z "$password" ] && exit 0

            nmcli device wifi connect "$ssid" password "$password"

        else
            nmcli device wifi connect "$ssid"
        fi
        ;;

    '󰤭  Disconnect')
        nmcli connection down "$ssid"
        ;;

    '󰆴  Forget')
        nmcli connection delete "$ssid"
        ;;

esac
