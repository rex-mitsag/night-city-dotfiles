#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
STATE="$HOME/.local/state/night-city-dotfiles"

if [[ ! -f /etc/arch-release ]]; then
    echo "This script currently supports Arch Linux only."
    exit 1
fi

command -v stow >/dev/null || {
    echo "GNU Stow is required to uninstall."
    exit 1
}

mapfile -t PACKAGES < <(
    find "$REPO/stow" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
)

read -r -p "Remove Night City links and restore recorded backups? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

for pkg in "${PACKAGES[@]}"; do
    TARGET="$HOME/.config/$pkg"
    SOURCE="$REPO/stow/$pkg/.config/$pkg"

    if [[ -L "$TARGET" ]] &&
       [[ "$(readlink -f -- "$TARGET" 2>/dev/null || true)" == "$(readlink -f -- "$SOURCE")" ]]; then
        stow -D -d "$REPO/stow" -t "$HOME" "$pkg"
        echo "Removed Night City links: $pkg"
    else
        echo "Skipping $pkg: target is not a symlink to this repo."
    fi
done

if [[ -f "$STATE/last-backup" ]]; then
    BACKUP="$(<"$STATE/last-backup")"

    case "$BACKUP" in
        "$STATE"/backups/*) ;;
        *)
            echo "Unsafe backup path; refusing to restore."
            exit 1
            ;;
    esac

    if [[ -d "$BACKUP/configs" ]]; then
        for pkg in "${PACKAGES[@]}"; do
            SAVED="$BACKUP/configs/$pkg"
            TARGET="$HOME/.config/$pkg"

            if [[ -e "$SAVED" || -L "$SAVED" ]]; then
                if [[ -e "$TARGET" || -L "$TARGET" ]]; then
                    echo "Refusing to overwrite $TARGET; backup remains at $SAVED"
                    continue
                fi
                mv -- "$SAVED" "$TARGET"
                echo "Restored $pkg"
            fi
        done
    fi
else
    echo "No recorded backup found."
fi

echo "Uninstall finished. Review your configs before logging out."
