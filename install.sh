#!/usr/bin/env bash
set -Eeuo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]"
    exit 2
fi

if [[ ! -f /etc/arch-release ]]; then
    echo "This installer currently supports Arch Linux only."
    exit 1
fi

mapfile -t PACKAGES < <(
    find "$REPO/stow" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
)

((${#PACKAGES[@]})) || {
    echo "No Stow packages found."
    exit 1
}

# Validate all configuration sources before changing anything.
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$REPO/stow/$pkg/.config/$pkg" ]] || {
        echo "Missing config source for: $pkg"
        exit 1
    }
done

command -v pacman >/dev/null || {
    echo "pacman is required."
    exit 1
}

mapfile -t REQUIRED < <(
    grep -Ev '^[[:space:]]*(#|$)' "$REPO/packages/required.txt"
)

MISSING=()
for pkg in "${REQUIRED[@]}"; do
    pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
done

if ((${#MISSING[@]})); then
    printf 'Missing packages: %s\n' "${MISSING[*]}"
    if (( DRY_RUN )); then
        echo "Dry run: would ask permission to install dependencies."
    else
        read -r -p "Install missing packages using pacman? [y/N] " answer
        [[ "$answer" =~ ^[Yy]$ ]] || {
            echo "Install dependencies first, then rerun."
            exit 1
        }
        sudo pacman -S --needed "${MISSING[@]}"
    fi
fi

if (( DRY_RUN )); then
    echo "DRY RUN: no files or packages changed."
    printf 'Would manage: %s\n' "${PACKAGES[*]}"
    exit 0
fi

command -v stow >/dev/null || {
    echo "GNU Stow is required. Install the 'stow' package first."
    exit 1
}

STATE="$HOME/.local/state/night-city-dotfiles"
mkdir -p "$STATE/backups" "$HOME/.config"

BACKUP="$(mktemp -d "$STATE/backups/backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir -p "$BACKUP/configs"

BACKUP_CREATED=0
LINKED=()
BACKED_UP=()

rollback() {
    local status=$?
    trap - ERR
    echo "Installation failed; attempting rollback." >&2

    # Undo completed Stow operations in reverse order.
    for ((i=${#LINKED[@]}-1; i>=0; i--)); do
        stow -D -d "$REPO/stow" -t "$HOME" "${LINKED[i]}" \
            >/dev/null 2>&1 || true
    done

    # Restore only configs this run moved into its backup.
    for pkg in "${BACKED_UP[@]}"; do
        local saved="$BACKUP/configs/$pkg"
        local target="$HOME/.config/$pkg"

        if [[ -e "$saved" || -L "$saved" ]]; then
            if [[ ! -e "$target" && ! -L "$target" ]]; then
                mv -- "$saved" "$target" || {
                    echo "Restore failed; backup remains at $saved" >&2
                }
            else
                echo "Target exists; backup remains at $saved" >&2
            fi
        fi
    done

    echo "Inspect backup directory: $BACKUP" >&2
    exit "$status"
}

# Activate rollback only after its state and function are initialized.
trap rollback ERR

# Back up conflicting targets.
for pkg in "${PACKAGES[@]}"; do
    TARGET="$HOME/.config/$pkg"
    SOURCE="$REPO/stow/$pkg/.config/$pkg"

    if [[ -L "$TARGET" ]] &&
       [[ "$(readlink -f -- "$TARGET" 2>/dev/null || true)" == "$(readlink -f -- "$SOURCE")" ]]; then
        echo "Already linked: $pkg"
        continue
    fi

    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        mv -- "$TARGET" "$BACKUP/configs/$pkg"
        BACKED_UP+=("$pkg")
        BACKUP_CREATED=1
    fi
done

if (( BACKUP_CREATED )); then
    printf '%s\n' "$BACKUP" > "$STATE/last-backup"
else
    rm -f -- "$STATE/last-backup"
fi

for pkg in "${PACKAGES[@]}"; do
    TARGET="$HOME/.config/$pkg"
    SOURCE="$REPO/stow/$pkg/.config/$pkg"

    if [[ -L "$TARGET" ]] &&
       [[ "$(readlink -f -- "$TARGET" 2>/dev/null || true)" == "$(readlink -f -- "$SOURCE")" ]]; then
        continue
    fi

    stow -S -d "$REPO/stow" -t "$HOME" "$pkg"
    LINKED+=("$pkg")
done

trap - ERR

echo "Night City dotfiles linked successfully."
if (( BACKUP_CREATED )); then
    echo "Previous configurations backed up to: $BACKUP"
fi
echo "Restart Quickshell or log out and back in to load changes."
