#!/bin/bash

declare -A apps
declare -A pids

# =========================================================
# 1. Detect applications with Hyprland windows
# =========================================================

title=""
class=""
pid=""

while IFS= read -r line; do
    if [[ $line =~ ^Window[[:space:]]+([^[:space:]]+)[[:space:]]+\-\>[[:space:]]*(.*)$ ]]; then
        title="${BASH_REMATCH[2]}"

    elif [[ $line =~ ^[[:space:]]+class:[[:space:]]+(.*)$ ]]; then
        class="${BASH_REMATCH[1]}"

    elif [[ $line =~ ^[[:space:]]+pid:[[:space:]]+([0-9]+)$ ]]; then
        pid="${BASH_REMATCH[1]}"

        if [[ -n "$class" && -n "$title" && -n "$pid" ]]; then
            name="$class — $title"
            apps["$name"]="$pid"
        fi

        title=""
        class=""
        pid=""
    fi
done < <(hyprctl clients)


# =========================================================
# 2. Detect running GUI / system-tray applications
# =========================================================

while IFS= read -r desktop; do

    # Get application name
    name=$(grep -m1 '^Name=' "$desktop" | cut -d= -f2-)

    # Get Exec command
    exec_line=$(grep -m1 '^Exec=' "$desktop" | cut -d= -f2-)

    [ -z "$name" ] && continue
    [ -z "$exec_line" ] && continue

    # Remove field codes such as %U, %u, %F, etc.
    exec_line=$(printf '%s\n' "$exec_line" |
        sed -E 's/[[:space:]]+%[fFuUdDnNickvm]//g')

    # First executable in Exec=
    executable=$(printf '%s\n' "$exec_line" |
        awk '{print $1}')

    # Ignore commands that aren't actual executables
    [ -z "$executable" ] && continue

    # Resolve executable basename
    executable=$(basename "$executable")

    # Find running process belonging to our user
    running_pid=$(pgrep -u "$USER" -x "$executable" | head -n1)

    [ -z "$running_pid" ] && continue

    # Don't duplicate applications already detected by Hyprland
    already_found=false

    for existing_pid in "${pids[@]}"; do
        if [ "$existing_pid" = "$running_pid" ]; then
            already_found=true
            break
        fi
    done

    for existing_name in "${!apps[@]}"; do
        if [ "${apps[$existing_name]}" = "$running_pid" ]; then
            already_found=true
            break
        fi
    done

    [ "$already_found" = true ] && continue

    apps["$name [Tray]"]="$running_pid"

done < <(find \
    /usr/share/applications \
    "$HOME/.local/share/applications" \
    -type f -name '*.desktop' 2>/dev/null)


# =========================================================
# 3. Show applications
# =========================================================

choice=$(printf '%s\n' "${!apps[@]}" |
    sort -f |
    wofi --dmenu \
        --prompt "Kill application" \
        --cache-file /dev/null)

[ -z "$choice" ] && exit 0


# =========================================================
# 4. Kill selected process
# =========================================================

pid="${apps[$choice]}"

[ -z "$pid" ] && exit 0

kill "$pid"
